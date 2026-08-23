// Texturas, sprites, render y cámara.
using System;

namespace UnityEngine {

public class Texture : Object {
    public int width { get => 0; set { } }
    public int height { get => 0; set { } }
    public FilterMode filterMode { get => default; set { } }
    public TextureWrapMode wrapMode { get => default; set { } }
    public int anisoLevel { get => 0; set { } }
    public float mipMapBias { get => 0f; set { } }
}

public class Texture2D : Texture {
    public Texture2D(int width, int height) { }
    public Texture2D(int width, int height, TextureFormat textureFormat, bool mipChain) { }
    public Texture2D(int width, int height, TextureFormat textureFormat, bool mipChain, bool linear) { }

    public TextureFormat format => default;
    public int mipmapCount => 0;
    public bool isReadable => false;

    public void SetPixel(int x, int y, Color color) { }
    public void SetPixels(Color[] colors) { }
    public void SetPixels(int x, int y, int blockWidth, int blockHeight, Color[] colors) { }
    public void SetPixels32(Color32[] colors) { }
    public void SetPixels32(Color32[] colors, int miplevel) { }
    public Color GetPixel(int x, int y) => default;
    public Color GetPixelBilinear(float u, float v) => default;
    public Color[] GetPixels() => default;
    public Color32[] GetPixels32() => default;
    public void Apply() { }
    public void Apply(bool updateMipmaps) { }
    public void Apply(bool updateMipmaps, bool makeNoLongerReadable) { }
    public byte[] EncodeToPNG() => default;

    public static Texture2D whiteTexture => default;
    public static Texture2D blackTexture => default;
}

public enum TextureFormat { Alpha8 = 1, RGB24 = 3, RGBA32 = 4, ARGB32 = 5, BGRA32 = 14, RGBAFloat = 17 }
public enum FilterMode { Point = 0, Bilinear = 1, Trilinear = 2 }
public enum TextureWrapMode { Repeat = 0, Clamp = 1, Mirror = 2, MirrorOnce = 3 }
public enum SpriteMeshType { FullRect = 0, Tight = 1 }
public enum SpriteAlignment { Center = 0, TopLeft = 1, Custom = 9 }

public sealed class Sprite : Object {
    public Bounds bounds => default;
    public Rect rect => default;
    public float pixelsPerUnit => 0f;
    public Texture2D texture => default;
    public Vector2 pivot => default;
    public Vector4 border => default;
    public Rect textureRect => default;

    public static Sprite Create(Texture2D texture, Rect rect, Vector2 pivot) => default;
    public static Sprite Create(Texture2D texture, Rect rect, Vector2 pivot, float pixelsPerUnit) => default;
    public static Sprite Create(Texture2D texture, Rect rect, Vector2 pivot, float pixelsPerUnit, uint extrude) => default;
    public static Sprite Create(Texture2D texture, Rect rect, Vector2 pivot, float pixelsPerUnit, uint extrude, SpriteMeshType meshType) => default;
    public static Sprite Create(Texture2D texture, Rect rect, Vector2 pivot, float pixelsPerUnit, uint extrude, SpriteMeshType meshType, Vector4 border) => default;
}

public class Renderer : Component {
    public bool enabled { get => false; set { } }
    public Material material { get => default; set { } }
    public Material sharedMaterial { get => default; set { } }
    public Material[] materials { get => default; set { } }
    public int sortingOrder { get => 0; set { } }
    public string sortingLayerName { get => ""; set { } }
    public int sortingLayerID { get => 0; set { } }
    public Bounds bounds => default;
    public bool isVisible => false;
}

public class SpriteRenderer : Renderer {
    public Sprite sprite { get => default; set { } }
    public Color color { get => default; set { } }
    public bool flipX { get => false; set { } }
    public bool flipY { get => false; set { } }
    public SpriteDrawMode drawMode { get => default; set { } }
    public Vector2 size { get => default; set { } }
    public SpriteMaskInteraction maskInteraction { get => default; set { } }
}

public enum SpriteDrawMode { Simple = 0, Sliced = 1, Tiled = 2 }
public enum SpriteMaskInteraction { None = 0, VisibleInsideMask = 1, VisibleOutsideMask = 2 }

public class Material : Object {
    public Material(Shader shader) { }
    public Material(Material source) { }
    public Color color { get => default; set { } }
    public Texture mainTexture { get => default; set { } }
    public Shader shader { get => default; set { } }
    public int renderQueue { get => 0; set { } }
    public void SetColor(string name, Color value) { }
    public void SetFloat(string name, float value) { }
    public void SetTexture(string name, Texture value) { }
    public void SetInt(string name, int value) { }
    public bool HasProperty(string name) => false;
}

public sealed class Shader : Object {
    public static Shader Find(string name) => default;
}

public class Camera : Behaviour {
    public static Camera main => default;
    public static Camera current => default;
    public bool orthographic { get => false; set { } }
    public float orthographicSize { get => 0f; set { } }
    public float fieldOfView { get => 0f; set { } }
    public float nearClipPlane { get => 0f; set { } }
    public float farClipPlane { get => 0f; set { } }
    public float aspect { get => 0f; set { } }
    public Color backgroundColor { get => default; set { } }
    public CameraClearFlags clearFlags { get => default; set { } }
    public int cullingMask { get => 0; set { } }
    public int depth { get => 0; set { } }
    public Rect pixelRect { get => default; set { } }
    public int pixelWidth => 0;
    public int pixelHeight => 0;
    public Vector3 WorldToScreenPoint(Vector3 position) => default;
    public Vector3 ScreenToWorldPoint(Vector3 position) => default;
    public Vector3 WorldToViewportPoint(Vector3 position) => default;
    public Vector3 ViewportToWorldPoint(Vector3 position) => default;
}

public enum CameraClearFlags { Skybox = 1, Color = 2, SolidColor = 2, Depth = 3, Nothing = 4 }

public class AudioListener : Behaviour {
    public static float volume { get => 0f; set { } }
    public static bool pause { get => false; set { } }
}

public sealed class AudioClip : Object {
    public float length => 0f;
    public int samples => 0;
    public int channels => 0;
    public int frequency => 0;
    public delegate void PCMReaderCallback(float[] data);
    public delegate void PCMSetPositionCallback(int position);
    public static AudioClip Create(string name, int lengthSamples, int channels, int frequency, bool stream) => default;
    public static AudioClip Create(string name, int lengthSamples, int channels, int frequency, bool stream, PCMReaderCallback pcmreadercallback) => default;
    public static AudioClip Create(string name, int lengthSamples, int channels, int frequency, bool stream, PCMReaderCallback pcmreadercallback, PCMSetPositionCallback pcmsetpositioncallback) => default;
    public bool SetData(float[] data, int offsetSamples) => false;
    public bool GetData(float[] data, int offsetSamples) => false;
}

public class AudioSource : Behaviour {
    public AudioClip clip { get => default; set { } }
    public float volume { get => 0f; set { } }
    public float pitch { get => 0f; set { } }
    public bool loop { get => false; set { } }
    public bool mute { get => false; set { } }
    public bool playOnAwake { get => false; set { } }
    public bool isPlaying => false;
    public float time { get => 0f; set { } }
    public int timeSamples { get => 0; set { } }
    public float spatialBlend { get => 0f; set { } }
    public float panStereo { get => 0f; set { } }
    public float dopplerLevel { get => 0f; set { } }
    public int priority { get => 0; set { } }
    public void Play() { }
    public void Play(ulong delay) { }
    public void Stop() { }
    public void Pause() { }
    public void UnPause() { }
    public void PlayOneShot(AudioClip clip) { }
    public void PlayOneShot(AudioClip clip, float volumeScale) { }
    public static void PlayClipAtPoint(AudioClip clip, Vector3 position) { }
}

public static class AudioSettings {
    public static int outputSampleRate { get => 0; set { } }
}

public sealed class Font : Object {
    public static Font CreateDynamicFontFromOSFont(string fontname, int size) => default;
    public int fontSize => 0;
    public Material material { get => default; set { } }
    public string[] fontNames { get => default; set { } }
}

public enum TextAnchor { UpperLeft = 0, UpperCenter = 1, UpperRight = 2, MiddleLeft = 3, MiddleCenter = 4, MiddleRight = 5, LowerLeft = 6, LowerCenter = 7, LowerRight = 8 }
public enum FontStyle { Normal = 0, Bold = 1, Italic = 2, BoldAndItalic = 3 }
public enum HorizontalWrapMode { Wrap = 0, Overflow = 1 }
public enum VerticalWrapMode { Truncate = 0, Overflow = 1 }

public static class Input {
    public static bool GetKey(KeyCode key) => false;
    public static bool GetKey(string name) => false;
    public static bool GetKeyDown(KeyCode key) => false;
    public static bool GetKeyDown(string name) => false;
    public static bool GetKeyUp(KeyCode key) => false;
    public static bool GetMouseButton(int button) => false;
    public static bool GetMouseButtonDown(int button) => false;
    public static bool GetMouseButtonUp(int button) => false;
    public static Vector3 mousePosition => default;
    public static float GetAxis(string axisName) => 0f;
    public static float GetAxisRaw(string axisName) => 0f;
    public static bool GetButton(string buttonName) => false;
    public static bool GetButtonDown(string buttonName) => false;
    public static int touchCount => 0;
    public static Touch[] touches => default;
    public static Touch GetTouch(int index) => default;
    public static bool touchSupported => false;
    public static bool multiTouchEnabled { get => false; set { } }
    public static bool anyKey => false;
    public static bool anyKeyDown => false;
}

public struct Touch {
    public int fingerId { get => 0; set { } }
    public Vector2 position { get => default; set { } }
    public Vector2 rawPosition { get => default; set { } }
    public Vector2 deltaPosition { get => default; set { } }
    public float deltaTime { get => 0f; set { } }
    public int tapCount { get => 0; set { } }
    public TouchPhase phase { get => default; set { } }
    public float pressure { get => 0f; set { } }
    public float radius { get => 0f; set { } }
}

public enum TouchPhase { Began = 0, Moved = 1, Stationary = 2, Ended = 3, Canceled = 4 }

public enum KeyCode {
    None = 0, Backspace = 8, Tab = 9, Return = 13, Escape = 27, Space = 32,
    Delete = 127,
    UpArrow = 273, DownArrow = 274, RightArrow = 275, LeftArrow = 276,
    Alpha0 = 48, Alpha1 = 49, Alpha2 = 50, Alpha3 = 51, Alpha4 = 52,
    Alpha5 = 53, Alpha6 = 54, Alpha7 = 55, Alpha8 = 56, Alpha9 = 57,
    A = 97, B = 98, C = 99, D = 100, E = 101, F = 102, G = 103, H = 104,
    I = 105, J = 106, K = 107, L = 108, M = 109, N = 110, O = 111, P = 112,
    Q = 113, R = 114, S = 115, T = 116, U = 117, V = 118, W = 119, X = 120,
    Y = 121, Z = 122,
    LeftShift = 304, RightShift = 303, LeftControl = 306, RightControl = 305,
    LeftAlt = 308, RightAlt = 307, Mouse0 = 323, Mouse1 = 324, Mouse2 = 325
}

}
