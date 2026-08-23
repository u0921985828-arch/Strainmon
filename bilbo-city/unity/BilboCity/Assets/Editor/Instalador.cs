#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace BilboCity {

/// <summary>
/// Prepara la escena sin tener que tocar nada a mano. No se incluye ningún .unity
/// en el repositorio a propósito: es mejor que Unity la construya que arriesgarse
/// a una escena corrupta.
/// </summary>
public static class Instalador {

    [MenuItem("BilboCity/Preparar escena")]
    public static void PrepararEscena() {
        var escena = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        var camGo = new GameObject("Main Camera");
        camGo.tag = "MainCamera";
        var cam = camGo.AddComponent<Camera>();
        cam.orthographic = true;
        cam.orthographicSize = 7f;
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = Paleta.Negro;
        camGo.transform.position = new Vector3(80, 80, -10);
        camGo.AddComponent<AudioListener>();

        var juego = new GameObject("BilboCity");
        juego.AddComponent<Juego>();

        string ruta = "Assets/Scenes";
        if (!AssetDatabase.IsValidFolder(ruta)) AssetDatabase.CreateFolder("Assets", "Scenes");
        EditorSceneManager.SaveScene(escena, ruta + "/Bilbo.unity");
        Debug.Log("Escena creada en " + ruta + "/Bilbo.unity. Dale a Play.");
    }

    [MenuItem("BilboCity/Ajustes recomendados para Android")]
    public static void AjustesAndroid() {
        PlayerSettings.companyName = "BilboCity";
        PlayerSettings.productName = "Bilbo City";
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
        PlayerSettings.allowedAutorotateToLandscapeLeft = false;
        PlayerSettings.allowedAutorotateToLandscapeRight = false;
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = 60;
        Debug.Log("Ajustes aplicados: retrato, sin vsync, 60 fps objetivo.");
    }
}

}
#endif
