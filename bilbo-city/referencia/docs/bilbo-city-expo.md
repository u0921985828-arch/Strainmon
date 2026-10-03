# BILBO CITY — migración a Expo (React Native)

Objetivo: llevar el prototipo HTML a una app instalable (Play Store / TestFlight) sin reescribir
la lógica del juego.

---

## Decisión: tres caminos

| Camino | Esfuerzo | Rendimiento | Cuándo |
|---|---|---|---|
| **A. WebView** | 1 tarde | 45–60 fps en gama media | Validar rápido, subir a tiendas ya |
| **B. expo-gl + 2d canvas polyfill** | 2–3 días | 60 fps estable | Cuando la ciudad crezca |
| **C. Reescritura en `react-native-skia`** | 1–2 semanas | El mejor | Producto final |

Recomendación: **A ahora, B cuando el mapa pase de 96×96 o metas más de ~60 entidades.**

---

## Camino A — WebView (el archivo tal cual)

```bash
npx create-expo-app bilbo-city --template blank
cd bilbo-city
npx expo install react-native-webview expo-screen-orientation expo-keep-awake expo-asset
```

`app.json`:
```json
{
  "expo": {
    "name": "Bilbo City",
    "slug": "bilbo-city",
    "orientation": "portrait",
    "userInterfaceStyle": "dark",
    "backgroundColor": "#0b0e12",
    "android": { "package": "com.tuestudio.bilbocity" },
    "ios": { "bundleIdentifier": "com.tuestudio.bilbocity" }
  }
}
```

Mete el HTML en `assets/game.html` y añade en `metro.config.js`:
```js
const config = require('expo/metro-config').getDefaultConfig(__dirname);
config.resolver.assetExts.push('html');
module.exports = config;
```

`App.js`:
```jsx
import { useEffect } from 'react';
import { View, StatusBar } from 'react-native';
import { WebView } from 'react-native-webview';
import { Asset } from 'expo-asset';
import * as ScreenOrientation from 'expo-screen-orientation';
import { useKeepAwake } from 'expo-keep-awake';
import AsyncStorage from '@react-native-async-storage/async-storage';

const html = Asset.fromModule(require('./assets/game.html'));

export default function App() {
  useKeepAwake();
  useEffect(() => { ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP); }, []);

  const onMessage = async (e) => {
    const { tipo, clave, valor } = JSON.parse(e.nativeEvent.data);
    if (tipo === 'guardar') await AsyncStorage.setItem(clave, valor);
  };

  return (
    <View style={{ flex: 1, backgroundColor: '#0b0e12' }}>
      <StatusBar hidden />
      <WebView
        source={{ uri: html.uri }}
        originWhitelist={['*']}
        allowFileAccess
        allowFileAccessFromFileURLs
        javaScriptEnabled
        domStorageEnabled
        bounces={false}
        overScrollMode="never"
        scrollEnabled={false}
        setBuiltInZoomControls={false}
        androidLayerType="hardware"
        onMessage={onMessage}
        injectedJavaScriptBeforeContentLoaded={`window.ESNATIVO = true; true;`}
        style={{ flex: 1, backgroundColor: '#0b0e12' }}
      />
    </View>
  );
}
```

### Puente de guardado
En el juego, el objeto `almacen` ya está aislado. Añádele una rama nativa:

```js
const almacen = {
  async get(k){
    if (window.ESNATIVO) return new Promise(r => {
      window.__resolveGet = r;
      window.ReactNativeWebView.postMessage(JSON.stringify({tipo:'cargar', clave:k}));
    });
    if (window.storage) { const r = await window.storage.get(k); return r ? r.value : null; }
    return localStorage.getItem(k);
  },
  async set(k, v){
    if (window.ESNATIVO) return window.ReactNativeWebView.postMessage(
      JSON.stringify({tipo:'guardar', clave:k, valor:v}));
    if (window.storage) return window.storage.set(k, v);
    localStorage.setItem(k, v);
  }
};
```
Y desde React Native, para responder al `cargar`:
```js
webRef.current.injectJavaScript(`window.__resolveGet(${JSON.stringify(valor)}); true;`);
```

### Ajustes obligatorios en el HTML
- `user-scalable=no` y `viewport-fit=cover` — ya están.
- `touch-action:none` en `body` — ya está.
- Quita el `select` del texto y el menú contextual largo (ya cubierto con `user-select:none`).
- En Android, fuerza `androidLayerType="hardware"` o el canvas va a tirones.

### Build
```bash
npm i -g eas-cli && eas login
eas build:configure
eas build -p android --profile preview   # APK para probar en tu móvil
eas build -p android --profile production
eas build -p ios --profile production
```

---

## Camino B — expo-gl (mismo código de dibujo, contexto nativo)

```bash
npx expo install expo-gl expo-gl-cpp expo-asset expo-file-system
npm i expo-2d-context
```

```jsx
import { GLView } from 'expo-gl';
import Expo2DContext from 'expo-2d-context';

<GLView style={{flex:1}} onContextCreate={(gl) => {
  const ctx = new Expo2DContext(gl);
  ctx.imageSmoothingEnabled = false;
  arrancarJuego(ctx, gl.drawingBufferWidth, gl.drawingBufferHeight);
}} />
```

Qué hay que tocar del juego:
1. **Sacar el canvas del DOM.** `lienzo()` pasa a devolver texturas precargadas con `expo-asset`
   en vez de `document.createElement('canvas')` → aquí el pack de sprites ya te viene bien,
   porque el arte pasa a ser PNG en disco.
2. **HUD fuera del canvas.** Todo lo que hoy es HTML (`#hud`, `#tel`, `#dlg`, `#tienda`)
   se reescribe como componentes React Native normales. Es la parte más larga pero también
   la que mejor queda: tipografía nativa, scroll nativo, safe areas de verdad.
3. **Entrada.** Sustituye los listeners de `touchstart/move/end` por `PanResponder`
   o `react-native-gesture-handler` (mejor: `Gesture.Pan()` para el joystick,
   `Gesture.Tap()` para los botones).
4. **Bucle.** `requestAnimationFrame` funciona igual dentro de `GLView`.

Estado y lógica (`S`, `act()`, `rejilla()`, trabajos, reputación) se copian **sin cambios**.
Están escritos sin tocar el DOM, por eso.

---

## Orden de trabajo sugerido

1. Camino A + build de prueba → juégalo en el móvil una semana, ajusta balance.
2. Mete el arte del pack de sprites (sigue valiendo en WebView).
3. Cuando el mapa o las entidades te tiren los fps, salta a B: primero el HUD nativo,
   luego el renderizador.
4. Guardado en la nube: Supabase con auth anónima (lo mismo que ya montaste en CERCA)
   — tabla `partidas(user_id uuid pk, estado jsonb, actualizado timestamptz)` con RLS
   `auth.uid() = user_id`.

---

## Checklist antes de subir a tiendas

- [ ] Icono 1024×1024 y splash con el fondo `#0b0e12`
- [ ] Política de privacidad (si metes Supabase, es obligatoria)
- [ ] Clasificación por edades: PEGI 12 / ESRB Teen por violencia leve y temática delictiva
- [ ] `expo-keep-awake` activo solo durante la partida
- [ ] Probar en un móvil de gama baja real, no solo en el emulador
- [ ] Botón de borrar partida accesible (ya está en el móvil del juego, pestaña Partida)
