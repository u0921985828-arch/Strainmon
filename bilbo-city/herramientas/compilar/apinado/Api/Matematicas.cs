// Superficie matemática de UnityEngine. Firmas fieles al motor: si aquí compila,
// en Unity compila. Los cuerpos no importan — esto nunca se ejecuta.
using System;

namespace UnityEngine {

public static class Mathf {
    public const float PI = 3.14159274f;
    public const float Infinity = float.PositiveInfinity;
    public const float NegativeInfinity = float.NegativeInfinity;
    public const float Deg2Rad = 0.0174532924f;
    public const float Rad2Deg = 57.29578f;
    public const float Epsilon = 1.401298E-45f;

    public static float Abs(float f) => 0f;
    public static int Abs(int value) => 0;
    public static float Sin(float f) => 0f;
    public static float Cos(float f) => 0f;
    public static float Tan(float f) => 0f;
    public static float Asin(float f) => 0f;
    public static float Acos(float f) => 0f;
    public static float Atan(float f) => 0f;
    public static float Atan2(float y, float x) => 0f;
    public static float Sqrt(float f) => 0f;
    public static float Pow(float f, float p) => 0f;
    public static float Exp(float power) => 0f;
    public static float Log(float f) => 0f;
    public static float Log(float f, float p) => 0f;
    public static float Log10(float f) => 0f;
    public static float Ceil(float f) => 0f;
    public static float Floor(float f) => 0f;
    public static float Round(float f) => 0f;
    public static int CeilToInt(float f) => 0;
    public static int FloorToInt(float f) => 0;
    public static int RoundToInt(float f) => 0;
    public static float Sign(float f) => 0f;
    public static float Clamp(float value, float min, float max) => 0f;
    public static int Clamp(int value, int min, int max) => 0;
    public static float Clamp01(float value) => 0f;
    public static float Lerp(float a, float b, float t) => 0f;
    public static float LerpUnclamped(float a, float b, float t) => 0f;
    public static float LerpAngle(float a, float b, float t) => 0f;
    public static float MoveTowards(float current, float target, float maxDelta) => 0f;
    public static float MoveTowardsAngle(float current, float target, float maxDelta) => 0f;
    public static float SmoothStep(float from, float to, float t) => 0f;
    public static float DeltaAngle(float current, float target) => 0f;
    public static float Repeat(float t, float length) => 0f;
    public static float PingPong(float t, float length) => 0f;
    public static float InverseLerp(float a, float b, float value) => 0f;
    public static bool Approximately(float a, float b) => false;
    public static float PerlinNoise(float x, float y) => 0f;
    public static float SmoothDamp(float current, float target, ref float currentVelocity, float smoothTime) => 0f;
    public static float SmoothDamp(float current, float target, ref float currentVelocity, float smoothTime, float maxSpeed) => 0f;
    public static float SmoothDamp(float current, float target, ref float currentVelocity, float smoothTime, float maxSpeed, float deltaTime) => 0f;
    public static float Max(float a, float b) => 0f;
    public static float Max(params float[] values) => 0f;
    public static int Max(int a, int b) => 0;
    public static int Max(params int[] values) => 0;
    public static float Min(float a, float b) => 0f;
    public static float Min(params float[] values) => 0f;
    public static int Min(int a, int b) => 0;
    public static int Min(params int[] values) => 0;
    public static int NextPowerOfTwo(int value) => 0;
    public static int ClosestPowerOfTwo(int value) => 0;
    public static bool IsPowerOfTwo(int value) => false;
}

public struct Vector2 : IEquatable<Vector2> {
    public float x, y;
    public Vector2(float x, float y) { this.x = x; this.y = y; }

    public float this[int index] { get => 0f; set { } }
    public float magnitude => 0f;
    public float sqrMagnitude => 0f;
    public Vector2 normalized => default;

    public static Vector2 zero => default;
    public static Vector2 one => default;
    public static Vector2 up => default;
    public static Vector2 down => default;
    public static Vector2 left => default;
    public static Vector2 right => default;
    public static Vector2 positiveInfinity => default;
    public static Vector2 negativeInfinity => default;

    public void Set(float newX, float newY) { }
    public void Normalize() { }
    public void Scale(Vector2 scale) { }
    public bool Equals(Vector2 other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public override string ToString() => "";
    public string ToString(string format) => "";

    public static float Distance(Vector2 a, Vector2 b) => 0f;
    public static float Dot(Vector2 lhs, Vector2 rhs) => 0f;
    public static float Angle(Vector2 from, Vector2 to) => 0f;
    public static float SignedAngle(Vector2 from, Vector2 to) => 0f;
    public static Vector2 Lerp(Vector2 a, Vector2 b, float t) => default;
    public static Vector2 LerpUnclamped(Vector2 a, Vector2 b, float t) => default;
    public static Vector2 MoveTowards(Vector2 current, Vector2 target, float maxDistanceDelta) => default;
    public static Vector2 ClampMagnitude(Vector2 vector, float maxLength) => default;
    public static Vector2 Scale(Vector2 a, Vector2 b) => default;
    public static Vector2 Reflect(Vector2 inDirection, Vector2 inNormal) => default;
    public static Vector2 Perpendicular(Vector2 inDirection) => default;
    public static Vector2 Min(Vector2 lhs, Vector2 rhs) => default;
    public static Vector2 Max(Vector2 lhs, Vector2 rhs) => default;
    public static Vector2 SmoothDamp(Vector2 current, Vector2 target, ref Vector2 currentVelocity, float smoothTime) => default;
    public static Vector2 SmoothDamp(Vector2 current, Vector2 target, ref Vector2 currentVelocity, float smoothTime, float maxSpeed) => default;
    public static Vector2 SmoothDamp(Vector2 current, Vector2 target, ref Vector2 currentVelocity, float smoothTime, float maxSpeed, float deltaTime) => default;
    public static float SqrMagnitude(Vector2 a) => 0f;
    public float SqrMagnitude() => 0f;

    public static Vector2 operator +(Vector2 a, Vector2 b) => default;
    public static Vector2 operator -(Vector2 a, Vector2 b) => default;
    public static Vector2 operator *(Vector2 a, Vector2 b) => default;
    public static Vector2 operator /(Vector2 a, Vector2 b) => default;
    public static Vector2 operator -(Vector2 a) => default;
    public static Vector2 operator *(Vector2 a, float d) => default;
    public static Vector2 operator *(float d, Vector2 a) => default;
    public static Vector2 operator /(Vector2 a, float d) => default;
    public static bool operator ==(Vector2 lhs, Vector2 rhs) => false;
    public static bool operator !=(Vector2 lhs, Vector2 rhs) => false;
    public static implicit operator Vector2(Vector3 v) => default;
    public static implicit operator Vector3(Vector2 v) => default;
}

public struct Vector3 : IEquatable<Vector3> {
    public float x, y, z;
    public Vector3(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
    public Vector3(float x, float y) { this.x = x; this.y = y; this.z = 0f; }

    public float this[int index] { get => 0f; set { } }
    public float magnitude => 0f;
    public float sqrMagnitude => 0f;
    public Vector3 normalized => default;

    public static Vector3 zero => default;
    public static Vector3 one => default;
    public static Vector3 up => default;
    public static Vector3 down => default;
    public static Vector3 left => default;
    public static Vector3 right => default;
    public static Vector3 forward => default;
    public static Vector3 back => default;

    public void Set(float newX, float newY, float newZ) { }
    public void Normalize() { }
    public void Scale(Vector3 scale) { }
    public bool Equals(Vector3 other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public override string ToString() => "";

    public static float Distance(Vector3 a, Vector3 b) => 0f;
    public static float Dot(Vector3 lhs, Vector3 rhs) => 0f;
    public static Vector3 Cross(Vector3 lhs, Vector3 rhs) => default;
    public static float Angle(Vector3 from, Vector3 to) => 0f;
    public static Vector3 Lerp(Vector3 a, Vector3 b, float t) => default;
    public static Vector3 LerpUnclamped(Vector3 a, Vector3 b, float t) => default;
    public static Vector3 MoveTowards(Vector3 current, Vector3 target, float maxDistanceDelta) => default;
    public static Vector3 Normalize(Vector3 value) => default;
    public static Vector3 Scale(Vector3 a, Vector3 b) => default;
    public static Vector3 Min(Vector3 lhs, Vector3 rhs) => default;
    public static Vector3 Max(Vector3 lhs, Vector3 rhs) => default;
    public static Vector3 ClampMagnitude(Vector3 vector, float maxLength) => default;

    public static Vector3 operator +(Vector3 a, Vector3 b) => default;
    public static Vector3 operator -(Vector3 a, Vector3 b) => default;
    public static Vector3 operator -(Vector3 a) => default;
    public static Vector3 operator *(Vector3 a, float d) => default;
    public static Vector3 operator *(float d, Vector3 a) => default;
    public static Vector3 operator /(Vector3 a, float d) => default;
    public static bool operator ==(Vector3 lhs, Vector3 rhs) => false;
    public static bool operator !=(Vector3 lhs, Vector3 rhs) => false;
}

public struct Vector4 : IEquatable<Vector4> {
    public float x, y, z, w;
    public Vector4(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
    public bool Equals(Vector4 other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public static implicit operator Vector4(Vector3 v) => default;
    public static implicit operator Vector3(Vector4 v) => default;
    public static implicit operator Vector4(Vector2 v) => default;
    public static implicit operator Vector2(Vector4 v) => default;
}

public struct Vector2Int : IEquatable<Vector2Int> {
    public int x { get; set; }
    public int y { get; set; }
    public Vector2Int(int x, int y) { this.x = x; this.y = y; }

    public float magnitude => 0f;
    public int sqrMagnitude => 0;
    public static Vector2Int zero => default;
    public static Vector2Int one => default;
    public static Vector2Int up => default;
    public static Vector2Int down => default;
    public static Vector2Int left => default;
    public static Vector2Int right => default;

    public void Set(int x, int y) { }
    public bool Equals(Vector2Int other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public override string ToString() => "";

    public static float Distance(Vector2Int a, Vector2Int b) => 0f;
    public static Vector2Int Min(Vector2Int lhs, Vector2Int rhs) => default;
    public static Vector2Int Max(Vector2Int lhs, Vector2Int rhs) => default;
    public static Vector2Int Scale(Vector2Int a, Vector2Int b) => default;
    public static Vector2Int FloorToInt(Vector2 v) => default;
    public static Vector2Int CeilToInt(Vector2 v) => default;
    public static Vector2Int RoundToInt(Vector2 v) => default;

    public static Vector2Int operator +(Vector2Int a, Vector2Int b) => default;
    public static Vector2Int operator -(Vector2Int a, Vector2Int b) => default;
    public static Vector2Int operator *(Vector2Int a, Vector2Int b) => default;
    public static Vector2Int operator -(Vector2Int v) => default;
    public static Vector2Int operator *(int a, Vector2Int b) => default;
    public static Vector2Int operator *(Vector2Int a, int b) => default;
    public static Vector2Int operator /(Vector2Int a, int b) => default;
    public static bool operator ==(Vector2Int lhs, Vector2Int rhs) => false;
    public static bool operator !=(Vector2Int lhs, Vector2Int rhs) => false;
    public static implicit operator Vector2(Vector2Int v) => default;
    public static explicit operator Vector3Int(Vector2Int v) => default;
}

public struct Vector3Int : IEquatable<Vector3Int> {
    public int x { get; set; }
    public int y { get; set; }
    public int z { get; set; }
    public Vector3Int(int x, int y) { this.x = x; this.y = y; this.z = 0; }
    public Vector3Int(int x, int y, int z) { this.x = x; this.y = y; this.z = z; }

    public float magnitude => 0f;
    public int sqrMagnitude => 0;
    public static Vector3Int zero => default;
    public static Vector3Int one => default;
    public static Vector3Int up => default;
    public static Vector3Int down => default;
    public static Vector3Int left => default;
    public static Vector3Int right => default;
    public static Vector3Int forward => default;
    public static Vector3Int back => default;

    public void Set(int x, int y, int z) { }
    public bool Equals(Vector3Int other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public override string ToString() => "";

    public static float Distance(Vector3Int a, Vector3Int b) => 0f;
    public static Vector3Int Min(Vector3Int lhs, Vector3Int rhs) => default;
    public static Vector3Int Max(Vector3Int lhs, Vector3Int rhs) => default;
    public static Vector3Int Scale(Vector3Int a, Vector3Int b) => default;
    public static Vector3Int FloorToInt(Vector3 v) => default;
    public static Vector3Int CeilToInt(Vector3 v) => default;
    public static Vector3Int RoundToInt(Vector3 v) => default;

    public static Vector3Int operator +(Vector3Int a, Vector3Int b) => default;
    public static Vector3Int operator -(Vector3Int a, Vector3Int b) => default;
    public static Vector3Int operator *(Vector3Int a, Vector3Int b) => default;
    public static Vector3Int operator -(Vector3Int v) => default;
    public static Vector3Int operator *(Vector3Int a, int b) => default;
    public static Vector3Int operator *(int a, Vector3Int b) => default;
    public static bool operator ==(Vector3Int lhs, Vector3Int rhs) => false;
    public static bool operator !=(Vector3Int lhs, Vector3Int rhs) => false;
    public static implicit operator Vector3(Vector3Int v) => default;
}

public struct Quaternion : IEquatable<Quaternion> {
    public float x, y, z, w;
    public Quaternion(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
    public static Quaternion identity => default;
    public Vector3 eulerAngles { get => default; set { } }
    public bool Equals(Quaternion other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public static Quaternion Euler(float x, float y, float z) => default;
    public static Quaternion Euler(Vector3 euler) => default;
    public static Quaternion AngleAxis(float angle, Vector3 axis) => default;
    public static Quaternion LookRotation(Vector3 forward) => default;
    public static Quaternion Lerp(Quaternion a, Quaternion b, float t) => default;
    public static Quaternion Slerp(Quaternion a, Quaternion b, float t) => default;
    public static Quaternion operator *(Quaternion lhs, Quaternion rhs) => default;
    public static Vector3 operator *(Quaternion rotation, Vector3 point) => default;
    public static bool operator ==(Quaternion lhs, Quaternion rhs) => false;
    public static bool operator !=(Quaternion lhs, Quaternion rhs) => false;
}

public struct Matrix4x4 {
    public static Matrix4x4 identity => default;
    public static Matrix4x4 TRS(Vector3 pos, Quaternion q, Vector3 s) => default;
    public static Matrix4x4 Translate(Vector3 vector) => default;
    public static Matrix4x4 Scale(Vector3 vector) => default;
    public static Matrix4x4 Rotate(Quaternion q) => default;
}

public struct Rect : IEquatable<Rect> {
    public Rect(float x, float y, float width, float height) { }
    public Rect(Vector2 position, Vector2 size) { }
    public Rect(Rect source) { }
    public float x { get => 0f; set { } }
    public float y { get => 0f; set { } }
    public float width { get => 0f; set { } }
    public float height { get => 0f; set { } }
    public Vector2 position { get => default; set { } }
    public Vector2 center { get => default; set { } }
    public Vector2 min { get => default; set { } }
    public Vector2 max { get => default; set { } }
    public Vector2 size { get => default; set { } }
    public float xMin { get => 0f; set { } }
    public float yMin { get => 0f; set { } }
    public float xMax { get => 0f; set { } }
    public float yMax { get => 0f; set { } }
    public static Rect zero => default;
    public bool Contains(Vector2 point) => false;
    public bool Overlaps(Rect other) => false;
    public bool Equals(Rect other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public static bool operator ==(Rect lhs, Rect rhs) => false;
    public static bool operator !=(Rect lhs, Rect rhs) => false;
}

public struct RectInt {
    public RectInt(int xMin, int yMin, int width, int height) { }
    public int x { get => 0; set { } }
    public int y { get => 0; set { } }
    public int width { get => 0; set { } }
    public int height { get => 0; set { } }
}

public struct Bounds {
    public Bounds(Vector3 center, Vector3 size) { }
    public Vector3 center { get => default; set { } }
    public Vector3 size { get => default; set { } }
    public Vector3 extents { get => default; set { } }
    public Vector3 min { get => default; set { } }
    public Vector3 max { get => default; set { } }
    public bool Contains(Vector3 point) => false;
    public bool Intersects(Bounds bounds) => false;
    public void Encapsulate(Vector3 point) { }
}

public struct BoundsInt {
    public BoundsInt(int xMin, int yMin, int zMin, int sizeX, int sizeY, int sizeZ) { }
    public BoundsInt(Vector3Int position, Vector3Int size) { }
    public Vector3Int position { get => default; set { } }
    public Vector3Int size { get => default; set { } }
    public Vector3Int min { get => default; set { } }
    public Vector3Int max { get => default; set { } }
    public int x { get => 0; set { } }
    public int y { get => 0; set { } }
    public int z { get => 0; set { } }
    public int xMin { get => 0; set { } }
    public int yMin { get => 0; set { } }
    public int zMin { get => 0; set { } }
    public int xMax { get => 0; set { } }
    public int yMax { get => 0; set { } }
    public int zMax { get => 0; set { } }
    public bool Contains(Vector3Int position) => false;
}

public struct Color : IEquatable<Color> {
    public float r, g, b, a;
    public Color(float r, float g, float b) { this.r = r; this.g = g; this.b = b; this.a = 1f; }
    public Color(float r, float g, float b, float a) { this.r = r; this.g = g; this.b = b; this.a = a; }

    public float this[int index] { get => 0f; set { } }
    public float grayscale => 0f;
    public Color linear => default;
    public Color gamma => default;
    public float maxColorComponent => 0f;

    public static Color red => default;
    public static Color green => default;
    public static Color blue => default;
    public static Color white => default;
    public static Color black => default;
    public static Color yellow => default;
    public static Color cyan => default;
    public static Color magenta => default;
    public static Color gray => default;
    public static Color grey => default;
    public static Color clear => default;

    public bool Equals(Color other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public override string ToString() => "";

    public static Color Lerp(Color a, Color b, float t) => default;
    public static Color LerpUnclamped(Color a, Color b, float t) => default;
    public static Color HSVToRGB(float H, float S, float V) => default;
    public static void RGBToHSV(Color rgbColor, out float H, out float S, out float V) { H = 0f; S = 0f; V = 0f; }

    public static Color operator +(Color a, Color b) => default;
    public static Color operator -(Color a, Color b) => default;
    public static Color operator *(Color a, Color b) => default;
    public static Color operator *(Color a, float b) => default;
    public static Color operator *(float b, Color a) => default;
    public static Color operator /(Color a, float b) => default;
    public static bool operator ==(Color lhs, Color rhs) => false;
    public static bool operator !=(Color lhs, Color rhs) => false;
    public static implicit operator Vector4(Color c) => default;
    public static implicit operator Color(Vector4 v) => default;
}

public struct Color32 : IEquatable<Color32> {
    public byte r, g, b, a;
    public Color32(byte r, byte g, byte b, byte a) { this.r = r; this.g = g; this.b = b; this.a = a; }
    public byte this[int index] { get => 0; set { } }
    public bool Equals(Color32 other) => false;
    public override bool Equals(object other) => false;
    public override int GetHashCode() => 0;
    public override string ToString() => "";
    public static Color32 Lerp(Color32 a, Color32 b, float t) => default;
    public static implicit operator Color32(Color c) => default;
    public static implicit operator Color(Color32 c) => default;
}

public static class Random {
    public static float value => 0f;
    public static Vector2 insideUnitCircle => default;
    public static Vector3 insideUnitSphere => default;
    public static Quaternion rotation => default;
    public static int seed { get => 0; set { } }
    public static float Range(float minInclusive, float maxInclusive) => 0f;
    public static int Range(int minInclusive, int maxExclusive) => 0;
    public static void InitState(int seed) { }
}

}
