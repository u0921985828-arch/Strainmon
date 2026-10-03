// Objetos de escena, ciclo de vida y servicios estáticos de UnityEngine.
using System;
using System.Collections;
using System.Collections.Generic;

namespace UnityEngine {

public class Object {
    public string name { get => ""; set { } }
    public HideFlags hideFlags { get => default; set { } }
    public int GetInstanceID() => 0;
    public override string ToString() => "";
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;

    public static void Destroy(Object obj) { }
    public static void Destroy(Object obj, float t) { }
    public static void DestroyImmediate(Object obj) { }
    public static void DestroyImmediate(Object obj, bool allowDestroyingAssets) { }
    public static void DontDestroyOnLoad(Object target) { }
    public static T Instantiate<T>(T original) where T : Object => default;
    public static T Instantiate<T>(T original, Transform parent) where T : Object => default;
    public static Object Instantiate(Object original, Vector3 position, Quaternion rotation) => default;
    public static T FindObjectOfType<T>() where T : Object => default;
    public static T[] FindObjectsOfType<T>() where T : Object => default;

    public static bool operator ==(Object x, Object y) => false;
    public static bool operator !=(Object x, Object y) => false;
    public static implicit operator bool(Object exists) => false;
}

public enum HideFlags { None = 0, HideInHierarchy = 1, HideInInspector = 2, DontSaveInEditor = 4, NotEditable = 8, DontSaveInBuild = 16, DontUnloadUnusedAsset = 32, DontSave = 52, HideAndDontSave = 61 }

public class Component : Object {
    public Transform transform => default;
    public GameObject gameObject => default;
    public string tag { get => ""; set { } }
    public T GetComponent<T>() => default;
    public Component GetComponent(Type type) => default;
    public Component GetComponent(string type) => default;
    public T GetComponentInChildren<T>() => default;
    public T GetComponentInChildren<T>(bool includeInactive) => default;
    public T GetComponentInParent<T>() => default;
    public T[] GetComponentsInChildren<T>() => default;
    public T[] GetComponentsInChildren<T>(bool includeInactive) => default;
    public T[] GetComponents<T>() => default;
    public bool TryGetComponent<T>(out T component) { component = default; return false; }
    public bool CompareTag(string tag) => false;
    public void SendMessage(string methodName) { }
    public void SendMessage(string methodName, object value) { }
}

public class Behaviour : Component {
    public bool enabled { get => false; set { } }
    public bool isActiveAndEnabled => false;
}

public sealed class Coroutine : YieldInstruction { }
public class YieldInstruction { }
public sealed class WaitForSeconds : YieldInstruction { public WaitForSeconds(float seconds) { } }
public sealed class WaitForSecondsRealtime : CustomYieldInstruction { public WaitForSecondsRealtime(float time) { } public override bool keepWaiting => false; }
public sealed class WaitForEndOfFrame : YieldInstruction { }
public sealed class WaitForFixedUpdate : YieldInstruction { }
public abstract class CustomYieldInstruction : IEnumerator {
    public abstract bool keepWaiting { get; }
    public object Current => null;
    public bool MoveNext() => false;
    public void Reset() { }
}

public class MonoBehaviour : Behaviour {
    public bool useGUILayout { get => false; set { } }
    public Coroutine StartCoroutine(IEnumerator routine) => default;
    public Coroutine StartCoroutine(string methodName) => default;
    public Coroutine StartCoroutine(string methodName, object value) => default;
    public void StopCoroutine(Coroutine routine) { }
    public void StopCoroutine(IEnumerator routine) { }
    public void StopCoroutine(string methodName) { }
    public void StopAllCoroutines() { }
    public void Invoke(string methodName, float time) { }
    public void InvokeRepeating(string methodName, float time, float repeatRate) { }
    public void CancelInvoke() { }
    public void CancelInvoke(string methodName) { }
    public bool IsInvoking() => false;
    public bool IsInvoking(string methodName) => false;
    public static void print(object message) { }
}

public class ScriptableObject : Object {
    public static ScriptableObject CreateInstance(Type type) => default;
    public static T CreateInstance<T>() where T : ScriptableObject => default;
}

public sealed class GameObject : Object {
    public GameObject() { }
    public GameObject(string name) { }
    public GameObject(string name, params Type[] components) { }

    public Transform transform => default;
    public int layer { get => 0; set { } }
    public string tag { get => ""; set { } }
    public bool activeSelf => false;
    public bool activeInHierarchy => false;
    public bool isStatic { get => false; set { } }
    public Scene scene => default;

    public void SetActive(bool value) { }
    public T AddComponent<T>() where T : Component => default;
    public Component AddComponent(Type componentType) => default;
    public T GetComponent<T>() => default;
    public Component GetComponent(Type type) => default;
    public T GetComponentInChildren<T>() => default;
    public T GetComponentInChildren<T>(bool includeInactive) => default;
    public T GetComponentInParent<T>() => default;
    public T[] GetComponentsInChildren<T>() => default;
    public T[] GetComponentsInChildren<T>(bool includeInactive) => default;
    public T[] GetComponents<T>() => default;
    public bool TryGetComponent<T>(out T component) { component = default; return false; }
    public bool CompareTag(string tag) => false;
    public void SendMessage(string methodName) { }

    public static GameObject Find(string name) => default;
    public static GameObject FindWithTag(string tag) => default;
    public static GameObject[] FindGameObjectsWithTag(string tag) => default;
    public static GameObject CreatePrimitive(PrimitiveType type) => default;
}

public enum PrimitiveType { Sphere, Capsule, Cylinder, Cube, Plane, Quad }

public class Transform : Component, IEnumerable {
    public Vector3 position { get => default; set { } }
    public Vector3 localPosition { get => default; set { } }
    public Vector3 eulerAngles { get => default; set { } }
    public Vector3 localEulerAngles { get => default; set { } }
    public Quaternion rotation { get => default; set { } }
    public Quaternion localRotation { get => default; set { } }
    public Vector3 localScale { get => default; set { } }
    public Vector3 lossyScale => default;
    public Vector3 right { get => default; set { } }
    public Vector3 up { get => default; set { } }
    public Vector3 forward { get => default; set { } }
    public Transform parent { get => default; set { } }
    public Transform root => default;
    public int childCount => 0;

    public void SetParent(Transform p) { }
    public void SetParent(Transform p, bool worldPositionStays) { }
    public Transform GetChild(int index) => default;
    public Transform Find(string n) => default;
    public void SetAsFirstSibling() { }
    public void SetAsLastSibling() { }
    public void SetSiblingIndex(int index) { }
    public int GetSiblingIndex() => 0;
    public void Translate(Vector3 translation) { }
    public void Translate(float x, float y, float z) { }
    public void Rotate(Vector3 eulers) { }
    public void Rotate(float xAngle, float yAngle, float zAngle) { }
    public void LookAt(Transform target) { }
    public void DetachChildren() { }
    public Vector3 TransformPoint(Vector3 position) => default;
    public Vector3 InverseTransformPoint(Vector3 position) => default;
    public IEnumerator GetEnumerator() => default;
}

public struct Scene {
    public string name { get => ""; set { } }
    public string path => "";
    public int buildIndex => 0;
    public int rootCount => 0;
    public bool IsValid() => false;
    public bool isLoaded => false;
    public GameObject[] GetRootGameObjects() => default;
}

public static class Time {
    public static float time => 0f;
    public static float timeSinceLevelLoad => 0f;
    public static float deltaTime => 0f;
    public static float unscaledTime => 0f;
    public static float unscaledDeltaTime => 0f;
    public static float fixedDeltaTime { get => 0f; set { } }
    public static float fixedTime => 0f;
    public static float maximumDeltaTime { get => 0f; set { } }
    public static float smoothDeltaTime => 0f;
    public static float timeScale { get => 0f; set { } }
    public static int frameCount => 0;
    public static float realtimeSinceStartup => 0f;
}

public static class Debug {
    public static void Log(object message) { }
    public static void Log(object message, Object context) { }
    public static void LogWarning(object message) { }
    public static void LogWarning(object message, Object context) { }
    public static void LogError(object message) { }
    public static void LogError(object message, Object context) { }
    public static void LogException(Exception exception) { }
    public static void LogFormat(string format, params object[] args) { }
    public static void DrawLine(Vector3 start, Vector3 end) { }
    public static void DrawLine(Vector3 start, Vector3 end, Color color) { }
    public static void DrawRay(Vector3 start, Vector3 dir, Color color) { }
    public static void Assert(bool condition) { }
    public static bool isDebugBuild => false;
}

public static class Application {
    public static int targetFrameRate { get => 0; set { } }
    public static bool isPlaying => false;
    public static bool isEditor => false;
    public static bool isMobilePlatform => false;
    public static bool isFocused => false;
    public static string persistentDataPath => "";
    public static string dataPath => "";
    public static string streamingAssetsPath => "";
    public static string temporaryCachePath => "";
    public static string version => "";
    public static string productName => "";
    public static string companyName => "";
    public static RuntimePlatform platform => default;
    public static SystemLanguage systemLanguage => default;
    public static void Quit() { }
    public static void Quit(int exitCode) { }
    public static void OpenURL(string url) { }
    public static event Action<bool> focusChanged { add { } remove { } }
    public static event Action quitting { add { } remove { } }
    public static bool runInBackground { get => false; set { } }
}

public enum RuntimePlatform { OSXEditor, OSXPlayer, WindowsPlayer, WindowsEditor, IPhonePlayer, Android, LinuxPlayer, LinuxEditor, WebGLPlayer }
public enum SystemLanguage { Basque, Spanish, English, Unknown }

public static class Screen {
    public static int width => 0;
    public static int height => 0;
    public static float dpi => 0f;
    public static Resolution currentResolution => default;
    public static bool fullScreen { get => false; set { } }
    public static int sleepTimeout { get => 0; set { } }
    public static ScreenOrientation orientation { get => default; set { } }
    public static bool autorotateToPortrait { get => false; set { } }
    public static bool autorotateToLandscapeLeft { get => false; set { } }
    public static Rect safeArea => default;
    public static void SetResolution(int width, int height, bool fullscreen) { }
}

public struct Resolution { public int width { get => 0; set { } } public int height { get => 0; set { } } public int refreshRate { get => 0; set { } } }
public enum ScreenOrientation { Portrait = 1, PortraitUpsideDown = 2, LandscapeLeft = 3, LandscapeRight = 4, AutoRotation = 5 }

public static class SleepTimeout {
    public const int NeverSleep = -1;
    public const int SystemSetting = -2;
}

public static class QualitySettings {
    public static int vSyncCount { get => 0; set { } }
    public static int antiAliasing { get => 0; set { } }
    public static ColorSpace activeColorSpace => default;
    public static void SetQualityLevel(int index) { }
}

public enum ColorSpace { Gamma = 0, Linear = 1 }

public static class SystemInfo {
    public static string deviceModel => "";
    public static string deviceName => "";
    public static int processorCount => 0;
    public static int systemMemorySize => 0;
    public static int graphicsMemorySize => 0;
    public static bool supportsInstancing => false;
}

public static class PlayerPrefs {
    public static void SetInt(string key, int value) { }
    public static int GetInt(string key) => 0;
    public static int GetInt(string key, int defaultValue) => 0;
    public static void SetFloat(string key, float value) { }
    public static float GetFloat(string key) => 0f;
    public static float GetFloat(string key, float defaultValue) => 0f;
    public static void SetString(string key, string value) { }
    public static string GetString(string key) => "";
    public static string GetString(string key, string defaultValue) => "";
    public static bool HasKey(string key) => false;
    public static void DeleteKey(string key) { }
    public static void DeleteAll() { }
    public static void Save() { }
}

public static class JsonUtility {
    public static string ToJson(object obj) => "";
    public static string ToJson(object obj, bool prettyPrint) => "";
    public static T FromJson<T>(string json) => default;
    public static object FromJson(string json, Type type) => default;
    public static void FromJsonOverwrite(string json, object objectToOverwrite) { }
}

public static class Resources {
    public static T Load<T>(string path) where T : Object => default;
    public static Object Load(string path) => default;
    public static T GetBuiltinResource<T>(string path) where T : Object => default;
    public static Object GetBuiltinResource(Type type, string path) => default;
    public static void UnloadUnusedAssets() { }
}

public struct LayerMask {
    public int value { get => 0; set { } }
    public static int NameToLayer(string layerName) => 0;
    public static string LayerToName(int layer) => "";
    public static int GetMask(params string[] layerNames) => 0;
    public static implicit operator int(LayerMask mask) => 0;
    public static implicit operator LayerMask(int intVal) => default;
}

[AttributeUsage(AttributeTargets.Field)]
public sealed class SerializeField : Attribute { }
[AttributeUsage(AttributeTargets.Field)]
public sealed class HideInInspector : Attribute { }
[AttributeUsage(AttributeTargets.Field)]
public sealed class RangeAttribute : PropertyAttribute { public RangeAttribute(float min, float max) { } }
[AttributeUsage(AttributeTargets.Field)]
public sealed class TooltipAttribute : PropertyAttribute { public TooltipAttribute(string tooltip) { } }
public abstract class PropertyAttribute : Attribute { }
[AttributeUsage(AttributeTargets.Class)]
public sealed class RequireComponent : Attribute { public RequireComponent(Type requiredComponent) { } }
[AttributeUsage(AttributeTargets.Class)]
public sealed class DisallowMultipleComponent : Attribute { }
[AttributeUsage(AttributeTargets.Class)]
public sealed class ExecuteInEditMode : Attribute { }
[AttributeUsage(AttributeTargets.Class)]
public sealed class AddComponentMenu : Attribute { public AddComponentMenu(string menuName) { } }
[AttributeUsage(AttributeTargets.Method)]
public sealed class ContextMenu : Attribute { public ContextMenu(string itemName) { } }
[AttributeUsage(AttributeTargets.Class)]
public sealed class CreateAssetMenuAttribute : Attribute { public string fileName { get; set; } public string menuName { get; set; } public int order { get; set; } }

}

namespace UnityEngine.SceneManagement {
    public static class SceneManager {
        public static Scene GetActiveScene() => default;
        public static void LoadScene(string sceneName) { }
        public static void LoadScene(int sceneBuildIndex) { }
        public static int sceneCount => 0;
    }
}

namespace UnityEngine.Events {
    [Serializable] public class UnityEventBase { public void RemoveAllListeners() { } public int GetPersistentEventCount() => 0; }
    [Serializable] public class UnityEvent : UnityEventBase {
        public void AddListener(UnityAction call) { }
        public void RemoveListener(UnityAction call) { }
        public void Invoke() { }
    }
    [Serializable] public class UnityEvent<T0> : UnityEventBase {
        public void AddListener(UnityAction<T0> call) { }
        public void RemoveListener(UnityAction<T0> call) { }
        public void Invoke(T0 arg0) { }
    }
    public delegate void UnityAction();
    public delegate void UnityAction<T0>(T0 arg0);
    public delegate void UnityAction<T0, T1>(T0 arg0, T1 arg1);
}
