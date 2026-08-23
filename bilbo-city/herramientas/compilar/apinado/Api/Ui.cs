// UnityEngine.UI (uGUI), UnityEngine.EventSystems y Tilemaps.
using System;
using System.Collections.Generic;
using UnityEngine.Events;

namespace UnityEngine {

public class RectTransform : Transform {
    public Vector2 anchorMin { get => default; set { } }
    public Vector2 anchorMax { get => default; set { } }
    public Vector2 anchoredPosition { get => default; set { } }
    public Vector3 anchoredPosition3D { get => default; set { } }
    public Vector2 sizeDelta { get => default; set { } }
    public Vector2 pivot { get => default; set { } }
    public Vector2 offsetMin { get => default; set { } }
    public Vector2 offsetMax { get => default; set { } }
    public Rect rect => default;
    public void SetInsetAndSizeFromParentEdge(Edge edge, float inset, float size) { }
    public void SetSizeWithCurrentAnchors(Axis axis, float size) { }
    public void GetWorldCorners(Vector3[] fourCornersArray) { }
    public void ForceUpdateRectTransforms() { }
    public enum Edge { Left, Right, Top, Bottom }
    public enum Axis { Horizontal, Vertical }
}

public sealed class Canvas : Behaviour {
    public RenderMode renderMode { get => default; set { } }
    public int sortingOrder { get => 0; set { } }
    public string sortingLayerName { get => ""; set { } }
    public Camera worldCamera { get => default; set { } }
    public bool pixelPerfect { get => false; set { } }
    public float planeDistance { get => 0f; set { } }
    public float scaleFactor => 0f;
    public float referencePixelsPerUnit => 0f;
    public bool overrideSorting { get => false; set { } }
    public AdditionalCanvasShaderChannels additionalShaderChannels { get => default; set { } }
    public Canvas rootCanvas => default;
}

public enum RenderMode { ScreenSpaceOverlay = 0, ScreenSpaceCamera = 1, WorldSpace = 2 }
[Flags] public enum AdditionalCanvasShaderChannels { None = 0, TexCoord1 = 1, TexCoord2 = 2, TexCoord3 = 4, Normal = 8, Tangent = 16 }

public class CanvasGroup : Behaviour {
    public float alpha { get => 0f; set { } }
    public bool interactable { get => false; set { } }
    public bool blocksRaycasts { get => false; set { } }
    public bool ignoreParentGroups { get => false; set { } }
}

public class CanvasRenderer : Component {
    public void SetColor(Color color) { }
    public Color GetColor() => default;
}

}

namespace UnityEngine.EventSystems {

public class UIBehaviour : MonoBehaviour { }

public class EventSystem : UIBehaviour {
    public static EventSystem current { get => default; set { } }
    public GameObject firstSelectedGameObject { get => default; set { } }
    public GameObject currentSelectedGameObject => default;
    public void SetSelectedGameObject(GameObject selected) { }
    public bool IsPointerOverGameObject() => false;
    public bool IsPointerOverGameObject(int pointerId) => false;
}

public abstract class BaseInputModule : UIBehaviour { }
public class PointerInputModule : BaseInputModule { }
public class StandaloneInputModule : PointerInputModule { }

public class BaseEventData {
    public BaseEventData(EventSystem eventSystem) { }
    public GameObject selectedObject { get => default; set { } }
    public void Use() { }
    public bool used => false;
}

public class PointerEventData : BaseEventData {
    public PointerEventData(EventSystem eventSystem) : base(eventSystem) { }
    public GameObject pointerEnter { get => default; set { } }
    public GameObject pointerPress { get => default; set { } }
    public int pointerId { get => 0; set { } }
    public Vector2 position { get => default; set { } }
    public Vector2 delta { get => default; set { } }
    public Vector2 pressPosition { get => default; set { } }
    public InputButton button { get => default; set { } }
    public bool dragging { get => false; set { } }
    public enum InputButton { Left = 0, Right = 1, Middle = 2 }
}

public interface IEventSystemHandler { }
public interface IPointerDownHandler : IEventSystemHandler { void OnPointerDown(PointerEventData eventData); }
public interface IPointerUpHandler : IEventSystemHandler { void OnPointerUp(PointerEventData eventData); }
public interface IPointerClickHandler : IEventSystemHandler { void OnPointerClick(PointerEventData eventData); }
public interface IPointerEnterHandler : IEventSystemHandler { void OnPointerEnter(PointerEventData eventData); }
public interface IPointerExitHandler : IEventSystemHandler { void OnPointerExit(PointerEventData eventData); }
public interface IBeginDragHandler : IEventSystemHandler { void OnBeginDrag(PointerEventData eventData); }
public interface IDragHandler : IEventSystemHandler { void OnDrag(PointerEventData eventData); }
public interface IEndDragHandler : IEventSystemHandler { void OnEndDrag(PointerEventData eventData); }

public enum EventTriggerType {
    PointerEnter = 0, PointerExit = 1, PointerDown = 2, PointerUp = 3, PointerClick = 4,
    Drag = 5, Drop = 6, Scroll = 7, UpdateSelected = 8, Select = 9, Deselect = 10,
    Move = 11, InitializePotentialDrag = 12, BeginDrag = 13, EndDrag = 14, Submit = 15, Cancel = 16
}

public class EventTrigger : MonoBehaviour {
    [Serializable] public class TriggerEvent : UnityEvent<BaseEventData> { }
    [Serializable] public class Entry {
        public EventTriggerType eventID = EventTriggerType.PointerClick;
        public TriggerEvent callback = new TriggerEvent();
    }
    public List<Entry> triggers { get => default; set { } }
}

public abstract class BaseRaycaster : UIBehaviour { }

}

namespace UnityEngine.UI {

using UnityEngine.EventSystems;

public class GraphicRaycaster : BaseRaycaster {
    public bool ignoreReversedGraphics { get => false; set { } }
}

public abstract class Graphic : UIBehaviour {
    public Color color { get => default; set { } }
    public bool raycastTarget { get => false; set { } }
    public Material material { get => default; set { } }
    public RectTransform rectTransform => default;
    public Canvas canvas => default;
    public CanvasRenderer canvasRenderer => default;
    public int depth => 0;
    public virtual void SetAllDirty() { }
    public virtual void SetVerticesDirty() { }
    public void SetNativeSize() { }
}

public abstract class MaskableGraphic : Graphic {
    public bool maskable { get => false; set { } }
}

public class Image : MaskableGraphic {
    public Sprite sprite { get => default; set { } }
    public Sprite overrideSprite { get => default; set { } }
    public Type type { get => default; set { } }
    public bool preserveAspect { get => false; set { } }
    public bool fillCenter { get => false; set { } }
    public FillMethod fillMethod { get => default; set { } }
    public float fillAmount { get => 0f; set { } }
    public bool fillClockwise { get => false; set { } }
    public int fillOrigin { get => 0; set { } }
    public float pixelsPerUnitMultiplier { get => 0f; set { } }
    public enum Type { Simple = 0, Sliced = 1, Tiled = 2, Filled = 3 }
    public enum FillMethod { Horizontal = 0, Vertical = 1, Radial90 = 2, Radial180 = 3, Radial360 = 4 }
    public enum OriginHorizontal { Left = 0, Right = 1 }
    public enum OriginVertical { Bottom = 0, Top = 1 }
    public enum Origin360 { Bottom = 0, Right = 1, Top = 2, Left = 3 }
}

public class RawImage : MaskableGraphic {
    public Texture texture { get => default; set { } }
    public Rect uvRect { get => default; set { } }
}

public class Text : MaskableGraphic {
    public string text { get => ""; set { } }
    public Font font { get => default; set { } }
    public int fontSize { get => 0; set { } }
    public FontStyle fontStyle { get => default; set { } }
    public TextAnchor alignment { get => default; set { } }
    public bool alignByGeometry { get => false; set { } }
    public float lineSpacing { get => 0f; set { } }
    public bool supportRichText { get => false; set { } }
    public bool resizeTextForBestFit { get => false; set { } }
    public int resizeTextMinSize { get => 0; set { } }
    public int resizeTextMaxSize { get => 0; set { } }
    public HorizontalWrapMode horizontalOverflow { get => default; set { } }
    public VerticalWrapMode verticalOverflow { get => default; set { } }
    public float preferredWidth => 0f;
    public float preferredHeight => 0f;
}

public class Shadow : UIBehaviour {
    public Color effectColor { get => default; set { } }
    public Vector2 effectDistance { get => default; set { } }
}
public class Outline : Shadow { }

public abstract class Selectable : UIBehaviour {
    public bool interactable { get => false; set { } }
    public Graphic targetGraphic { get => default; set { } }
    public Transition transition { get => default; set { } }
    public ColorBlock colors { get => default; set { } }
    public Navigation navigation { get => default; set { } }
    public void Select() { }
    public enum Transition { None = 0, ColorTint = 1, SpriteSwap = 2, Animation = 3 }
}

public struct ColorBlock {
    public Color normalColor { get => default; set { } }
    public Color highlightedColor { get => default; set { } }
    public Color pressedColor { get => default; set { } }
    public Color disabledColor { get => default; set { } }
    public float colorMultiplier { get => 0f; set { } }
    public float fadeDuration { get => 0f; set { } }
    public static ColorBlock defaultColorBlock => default;
}

public struct Navigation {
    public Mode mode { get => default; set { } }
    public enum Mode { None = 0, Horizontal = 1, Vertical = 2, Automatic = 3, Explicit = 4 }
}

public class Button : Selectable {
    [Serializable] public class ButtonClickedEvent : UnityEvent { }
    public ButtonClickedEvent onClick { get => default; set { } }
}

public class Toggle : Selectable {
    [Serializable] public class ToggleEvent : UnityEvent<bool> { }
    public bool isOn { get => false; set { } }
    public ToggleEvent onValueChanged { get => default; set { } }
    public Graphic graphic { get => default; set { } }
}

public class Slider : Selectable {
    [Serializable] public class SliderEvent : UnityEvent<float> { }
    public float value { get => 0f; set { } }
    public float minValue { get => 0f; set { } }
    public float maxValue { get => 0f; set { } }
    public bool wholeNumbers { get => false; set { } }
    public SliderEvent onValueChanged { get => default; set { } }
}

public class Scrollbar : Selectable {
    [Serializable] public class ScrollEvent : UnityEvent<float> { }
    public float value { get => 0f; set { } }
    public float size { get => 0f; set { } }
    public ScrollEvent onValueChanged { get => default; set { } }
}

public class ScrollRect : UIBehaviour {
    [Serializable] public class ScrollRectEvent : UnityEvent<Vector2> { }
    public RectTransform content { get => default; set { } }
    public RectTransform viewport { get => default; set { } }
    public bool horizontal { get => false; set { } }
    public bool vertical { get => false; set { } }
    public MovementType movementType { get => default; set { } }
    public float elasticity { get => 0f; set { } }
    public bool inertia { get => false; set { } }
    public float decelerationRate { get => 0f; set { } }
    public float scrollSensitivity { get => 0f; set { } }
    public Scrollbar horizontalScrollbar { get => default; set { } }
    public Scrollbar verticalScrollbar { get => default; set { } }
    public Vector2 normalizedPosition { get => default; set { } }
    public float verticalNormalizedPosition { get => 0f; set { } }
    public float horizontalNormalizedPosition { get => 0f; set { } }
    public ScrollRectEvent onValueChanged { get => default; set { } }
    public enum MovementType { Unrestricted = 0, Elastic = 1, Clamped = 2 }
}

public class Mask : UIBehaviour { public bool showMaskGraphic { get => false; set { } } }
public class RectMask2D : UIBehaviour { }

public class CanvasScaler : UIBehaviour {
    public ScaleMode uiScaleMode { get => default; set { } }
    public float referencePixelsPerUnit { get => 0f; set { } }
    public float scaleFactor { get => 0f; set { } }
    public Vector2 referenceResolution { get => default; set { } }
    public ScreenMatchMode screenMatchMode { get => default; set { } }
    public float matchWidthOrHeight { get => 0f; set { } }
    public Unit physicalUnit { get => default; set { } }
    public float fallbackScreenDPI { get => 0f; set { } }
    public float defaultSpriteDPI { get => 0f; set { } }
    public float dynamicPixelsPerUnit { get => 0f; set { } }
    public enum ScaleMode { ConstantPixelSize = 0, ScaleWithScreenSize = 1, ConstantPhysicalSize = 2 }
    public enum ScreenMatchMode { MatchWidthOrHeight = 0, Expand = 1, Shrink = 2 }
    public enum Unit { Centimeters = 0, Millimeters = 1, Inches = 2, Points = 3, Picas = 4 }
}

public abstract class LayoutGroup : UIBehaviour {
    public RectOffset padding { get => default; set { } }
    public TextAnchor childAlignment { get => default; set { } }
}

public abstract class HorizontalOrVerticalLayoutGroup : LayoutGroup {
    public float spacing { get => 0f; set { } }
    public bool childForceExpandWidth { get => false; set { } }
    public bool childForceExpandHeight { get => false; set { } }
    public bool childControlWidth { get => false; set { } }
    public bool childControlHeight { get => false; set { } }
    public bool childScaleWidth { get => false; set { } }
    public bool childScaleHeight { get => false; set { } }
    public bool reverseArrangement { get => false; set { } }
}

public class HorizontalLayoutGroup : HorizontalOrVerticalLayoutGroup { }
public class VerticalLayoutGroup : HorizontalOrVerticalLayoutGroup { }

public class GridLayoutGroup : LayoutGroup {
    public Vector2 cellSize { get => default; set { } }
    public Vector2 spacing { get => default; set { } }
    public int constraintCount { get => 0; set { } }
    public Constraint constraint { get => default; set { } }
    public enum Constraint { Flexible = 0, FixedColumnCount = 1, FixedRowCount = 2 }
}

public class LayoutElement : UIBehaviour {
    public bool ignoreLayout { get => false; set { } }
    public float minWidth { get => 0f; set { } }
    public float minHeight { get => 0f; set { } }
    public float preferredWidth { get => 0f; set { } }
    public float preferredHeight { get => 0f; set { } }
    public float flexibleWidth { get => 0f; set { } }
    public float flexibleHeight { get => 0f; set { } }
    public int layoutPriority { get => 0; set { } }
}

public class ContentSizeFitter : UIBehaviour {
    public FitMode horizontalFit { get => default; set { } }
    public FitMode verticalFit { get => default; set { } }
    public enum FitMode { Unconstrained = 0, MinSize = 1, PreferredSize = 2 }
}

public class AspectRatioFitter : UIBehaviour {
    public float aspectRatio { get => 0f; set { } }
    public AspectMode aspectMode { get => default; set { } }
    public enum AspectMode { None = 0, WidthControlsHeight = 1, HeightControlsWidth = 2, FitInParent = 3, EnvelopeParent = 4 }
}

public static class LayoutRebuilder {
    public static void ForceRebuildLayoutImmediate(RectTransform layoutRoot) { }
    public static void MarkLayoutForRebuild(RectTransform rect) { }
}

}

namespace UnityEngine {
public sealed class RectOffset {
    public RectOffset() { }
    public RectOffset(int left, int right, int top, int bottom) { }
    public int left { get => 0; set { } }
    public int right { get => 0; set { } }
    public int top { get => 0; set { } }
    public int bottom { get => 0; set { } }
    public int horizontal => 0;
    public int vertical => 0;
}
}

namespace UnityEngine.Tilemaps {

using System.Collections.Generic;

public abstract class TileBase : ScriptableObject {
    public virtual void RefreshTile(Vector3Int position, ITilemap tilemap) { }
    public virtual bool StartUp(Vector3Int position, ITilemap tilemap, GameObject go) => false;
}

public class Tile : TileBase {
    public Sprite sprite { get => default; set { } }
    public Color color { get => default; set { } }
    public Matrix4x4 transform { get => default; set { } }
    public GameObject gameObject { get => default; set { } }
    public TileFlags flags { get => default; set { } }
    public ColliderType colliderType { get => default; set { } }
    public enum ColliderType { None = 0, Sprite = 1, Grid = 2 }
}

[Flags] public enum TileFlags { None = 0, LockColor = 1, LockTransform = 2, InstantiateGameObjectRuntimeOnly = 4, LockAll = 3 }

public class ITilemap { }

public class GridLayout : Behaviour {
    public Vector3 cellSize => default;
    public Vector3 cellGap => default;
    public CellLayout cellLayout => default;
    public CellSwizzle cellSwizzle => default;
    public Vector3 CellToWorld(Vector3Int cellPosition) => default;
    public Vector3Int WorldToCell(Vector3 worldPosition) => default;
    public Vector3 GetCellCenterWorld(Vector3Int position) => default;
    public enum CellLayout { Rectangle = 0, Hexagon = 1, Isometric = 2, IsometricZAsY = 3 }
    public enum CellSwizzle { XYZ = 0, XZY = 1, YXZ = 2 }
}

public class Tilemap : GridLayout {
    public new Vector3 cellSize => default;
    public Vector3 tileAnchor { get => default; set { } }
    public Color color { get => default; set { } }
    public Orientation orientation { get => default; set { } }
    public BoundsInt cellBounds => default;
    public Vector3Int origin { get => default; set { } }
    public Vector3Int size { get => default; set { } }
    public float animationFrameRate { get => 0f; set { } }
    public Grid layoutGrid => default;

    public void SetTile(Vector3Int position, TileBase tile) { }
    public void SetTiles(Vector3Int[] positionArray, TileBase[] tileArray) { }
    public void SetTilesBlock(BoundsInt position, TileBase[] tileArray) { }
    public TileBase GetTile(Vector3Int position) => default;
    public T GetTile<T>(Vector3Int position) where T : TileBase => default;
    public TileBase[] GetTilesBlock(BoundsInt bounds) => default;
    public bool HasTile(Vector3Int position) => false;
    public void ClearAllTiles() { }
    public void RefreshTile(Vector3Int position) { }
    public void RefreshAllTiles() { }
    public void CompressBounds() { }
    public void ResizeBounds() { }
    public void SetColor(Vector3Int position, Color color) { }
    public Color GetColor(Vector3Int position) => default;
    public void SetTileFlags(Vector3Int position, TileFlags flags) { }
    public void SetTransformMatrix(Vector3Int position, Matrix4x4 transform) { }
    public new Vector3 CellToWorld(Vector3Int cellPosition) => default;
    public new Vector3Int WorldToCell(Vector3 worldPosition) => default;
    public enum Orientation { XY = 0, XZ = 1, YX = 2, YZ = 3, ZX = 4, ZY = 5, Custom = 6 }
}

public class TilemapRenderer : Renderer {
    public Vector3Int chunkSize { get => default; set { } }
    public Vector3 chunkCullingBounds { get => default; set { } }
    public int maxChunkCount { get => 0; set { } }
    public int maxFrameAge { get => 0; set { } }
    public SortOrder sortOrder { get => default; set { } }
    public Mode mode { get => default; set { } }
    public DetectChunkCullingBounds detectChunkCullingBounds { get => default; set { } }
    public enum SortOrder { BottomLeft = 0, BottomRight = 1, TopLeft = 2, TopRight = 3 }
    public enum Mode { Chunk = 0, Individual = 1 }
    public enum DetectChunkCullingBounds { Auto = 0, Manual = 1 }
}

public class TilemapCollider2D : Behaviour { }

}

namespace UnityEngine {
public sealed class Grid : UnityEngine.Tilemaps.GridLayout {
    public new Vector3 cellSize { get => default; set { } }
    public new Vector3 cellGap { get => default; set { } }
    public new UnityEngine.Tilemaps.GridLayout.CellLayout cellLayout { get => default; set { } }
    public new UnityEngine.Tilemaps.GridLayout.CellSwizzle cellSwizzle { get => default; set { } }
}
}
