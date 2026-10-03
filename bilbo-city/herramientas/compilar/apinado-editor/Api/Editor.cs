// Superficie de UnityEditor que usa el instalador de escena.
using System;

namespace UnityEditor {

using UnityEngine;

[AttributeUsage(AttributeTargets.Method)]
public sealed class MenuItem : Attribute {
    public MenuItem(string itemName) { }
    public MenuItem(string itemName, bool isValidateFunction) { }
    public MenuItem(string itemName, bool isValidateFunction, int priority) { }
}

[AttributeUsage(AttributeTargets.Method)]
public sealed class InitializeOnLoadMethod : Attribute { }
[AttributeUsage(AttributeTargets.Class)]
public sealed class InitializeOnLoad : Attribute { }

public static class AssetDatabase {
    public static bool IsValidFolder(string path) => false;
    public static string CreateFolder(string parentFolder, string newFolderName) => "";
    public static void CreateAsset(UnityEngine.Object asset, string path) { }
    public static void SaveAssets() { }
    public static void Refresh() { }
    public static T LoadAssetAtPath<T>(string assetPath) where T : UnityEngine.Object => default;
    public static string[] FindAssets(string filter) => default;
    public static string GUIDToAssetPath(string guid) => "";
}

public static class EditorUtility {
    public static bool DisplayDialog(string title, string message, string ok) => false;
    public static bool DisplayDialog(string title, string message, string ok, string cancel) => false;
    public static void SetDirty(UnityEngine.Object target) { }
    public static void DisplayProgressBar(string title, string info, float progress) { }
    public static void ClearProgressBar() { }
}

public static class EditorApplication {
    public static bool isPlaying { get => false; set { } }
    public static bool isPlayingOrWillChangePlaymode => false;
    public static void ExecuteMenuItem(string menuItemPath) { }
}

public static class Selection {
    public static GameObject activeGameObject { get => default; set { } }
    public static UnityEngine.Object activeObject { get => default; set { } }
}

public static class PlayerSettings {
    public static string companyName { get => ""; set { } }
    public static string productName { get => ""; set { } }
    public static string bundleVersion { get => ""; set { } }
    public static UIOrientation defaultInterfaceOrientation { get => default; set { } }
    public static bool allowedAutorotateToPortrait { get => false; set { } }
    public static bool allowedAutorotateToPortraitUpsideDown { get => false; set { } }
    public static bool allowedAutorotateToLandscapeLeft { get => false; set { } }
    public static bool allowedAutorotateToLandscapeRight { get => false; set { } }
    public static ColorSpace colorSpace { get => default; set { } }
    public static bool useAnimatedAutorotation { get => false; set { } }
    public static class Android {
        public static int minSdkVersion { get => 0; set { } }
        public static bool forceInternetPermission { get => false; set { } }
    }
}

public enum UIOrientation { Portrait = 0, PortraitUpsideDown = 1, LandscapeRight = 2, LandscapeLeft = 3, AutoRotation = 4 }

public static class EditorBuildSettings {
    public static EditorBuildSettingsScene[] scenes { get => default; set { } }
}

public class EditorBuildSettingsScene {
    public EditorBuildSettingsScene(string path, bool enabled) { }
    public string path { get => ""; set { } }
    public bool enabled { get => false; set { } }
}

public static class EditorUserBuildSettings {
    public static BuildTarget activeBuildTarget => default;
}

public enum BuildTarget { StandaloneWindows = 5, iOS = 9, Android = 13, StandaloneOSX = 2, StandaloneLinux64 = 24 }

public class Editor : UnityEngine.ScriptableObject { }
public class EditorWindow : UnityEngine.ScriptableObject { }

}

namespace UnityEditor.SceneManagement {

using UnityEngine;

public enum NewSceneSetup { EmptyScene = 0, DefaultGameObjects = 1 }
public enum NewSceneMode { Single = 0, Additive = 1 }

public static class EditorSceneManager {
    public static Scene NewScene(NewSceneSetup setup) => default;
    public static Scene NewScene(NewSceneSetup setup, NewSceneMode mode) => default;
    public static bool SaveScene(Scene scene) => false;
    public static bool SaveScene(Scene scene, string dstScenePath) => false;
    public static bool SaveScene(Scene scene, string dstScenePath, bool saveAsCopy) => false;
    public static Scene OpenScene(string scenePath) => default;
    public static bool SaveOpenScenes() => false;
    public static bool MarkSceneDirty(Scene scene) => false;
    public static Scene GetActiveScene() => default;
}

}
