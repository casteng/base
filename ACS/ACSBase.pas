(*
 @Abstract(ACS GUI library base unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains basic GUI classes and constants
*)
{$Include GDefines.inc}
unit ACSBase;

interface

uses
  Logger,
  SysUtils,
  BaseTypes, Basics, Props, Base3D, BaseGraph, Markup, Resources, Models,
  BaseClasses, BaseMsg, ItemMsg;

const
  // Anchors
  aLeft = 0; aTop = 1; aRight = 2; aBottom = 3;
  // Origins
  HOriginEnum = 'Left\&Center\&Right';
  VOriginEnum = 'Top\&Center\&Bottom';
  // Frames
  frNormal = 0; frHover = 1; frPushed = 2; frFocused = 3; frDisabled = 4;
  // GetItemAt results if missed any item
  miLeft = -1; miRight = -2; miUp = -3; miDown = -4;
  // Bound values
  pvLeft = 0; pvTop = 1; pvWidth = 2; pvHeight = 3;
  BoundValuesEnum = 'Left\&Top\&Width\&Height';
  // Align
  AlignEnum = 'None\&Top\&Left\&Right\&Bottom\&Client';

type
  TAlign       = (alNone, alTop, alLeft, alRight, alBottom, alClient, alAbsolute);
  THOrigin     = (hoLeft, hoCenter, hoRight);
  TVOrigin     = (voTop,  voCenter, voBottom);
//  TBoundValues = (pvLeft, pvTop, pvWidth, pvHeight);

  TGUIItem = class;

  TGUIStateDelegate = function(Caller: TGUIItem): Boolean of object;

  TConstraints = record
    MinWidth, MinHeight, MaxWidth, MaxHeight: Single;
  end;

  /// Responsibilies: Item aggregation, GUI messages forwarding
  TBaseGUIItem = class(TBaseProcessing)
  private
    DefaultModel: TModel;
  protected
    function GetModel: TModel; virtual;
    procedure SetModel(const Value: TModel);
    function GetNonGUIDummyParent: TItem;
    procedure ObtainParentDimensions(out PWidth, PHeight: Single);
    procedure RealignChilds(StartIndex: Integer); virtual;
  public
    AggregatedItem: TItem;                                             // An aggregated item of AggregatedClass if needed
    constructor Create(AManager: TItemsManager); override;
    destructor Destroy; override;

    procedure HandleMessage(const Msg: TMessage); override;
    function GUIHandleMessage(const Msg: TMessage): Boolean; virtual;
    procedure ReturnMessage(const Msg: TMessage); virtual;             // Return a message through the hierarchy

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    procedure Draw; virtual; abstract;

    property Model: TModel read GetModel write SetModel;
  end;

  TGUIRootItem = class(TBaseGUIItem)
  /// Root GUI item:
  /// Responsibilities: GUI<->general messages forwarding, keyboard focus/mouse capture items handling
  private
    FFocusedItem: TGUIItem;
    procedure SetFocusedItem(const Item: TGUIItem);
  public
    // Keys
    KeyEnter, KeyEscape, KeyUp, KeyDown, KeyLeft, KeyRight: Integer;
    constructor Create(AManager: TItemsManager); override;

    procedure OnSceneAdd; override;
    procedure OnSceneRemove; override;

    procedure HandleMessage(const Msg: TMessage); override;
    procedure ReturnMessage(const Msg: TMessage); override;

    function IsWithinGUI(AX, AY: Single): Boolean;

    procedure Draw; override;
    property FocusedItem: TGUIItem read FFocusedItem write SetFocusedItem;
  end;

  TGUIBounds = class(TBaseGUIItem)
  /// Responsibilities: Bounds handling, layout
  private
    FTransform: TMatrix4s;                               // Transform including translation, rotation and scale
    FLocalViewport: BaseGraph.TViewport;                 // Clipping area in local coordinates
    TransformValid, DisableRealign: Boolean;
    AlignRect: TArea;                                    // A rectangle within which align of the control is done
    FAlign: TAlign;
    FAnchors: BaseTypes.TSet32;
    FHOrigin: THOrigin;                                  // Horizontal and vertival
    FVOrigin: TVOrigin;                                  // origins of coordinates
    FConstraints: TConstraints;
    FPercentValues: BaseTypes.TSet32;                              // X, Y, Width and Height can be interpreted as percents of parent's dimensions
    // Coordinates entered via properties
    FX, FY, FWidth, FHeight, FAngle: Single;
    // Coordinates in pixels in parent's frame
    FPxX, FPxY, FPxWidth, FPxHeight: Single;
    // Client area dimensions
//    FInnerWidth, FInnerHeight: Single;
    // Client (scrollable) viewport
    FClientX, FClientY, FClientWidth, FClientHeight: Single;
    // Scroll position
    FScrollX, FScrollY: Single;
    // Client viewport border (nonclient area)
    FBorder: Integer;

    procedure InvalidateTransform;

    procedure SetX(const Value: Single);
    procedure SetY(const Value: Single);
    procedure SetAngle(const Value: Single);
    procedure SetPxX(Value: Single);
    procedure SetPxY(Value: Single);
    procedure SetPxWidth(Value: Single);
    procedure SetPxHeight(Value: Single);

    procedure SetAlign(const Value: TAlign);
    procedure SetHOrigin(const Value: THOrigin);
    procedure SetVOrigin(const Value: TVOrigin);
    procedure SetPercentValues(const Value: BaseTypes.TSet32);

    procedure SetBorder(const Value: Integer);

    function GetTransform: TMatrix4s;
    function GetLocalViewport: BaseGraph.TViewport;
    procedure ComputeTransform;
  protected
    procedure Realign;
    // Recalculates control's bounds according to anchors when size if control's container (parent) changes
    procedure CalcBounds(var ARect: BaseTypes.TArea);
    procedure ApplyAnchors(ParentDeltaWidth, ParentDeltaHeight: Single); virtual;
    procedure CalcClientArea; virtual;

    procedure SetWidth(const Value: Single); virtual;
    procedure SetHeight(const Value: Single); virtual;
  public
    constructor Create(AManager: TItemsManager); override;          // Regular constructor
    procedure HandleMessage(const Msg: TMessage); override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    function IsWithin(AX, AY: Single): Boolean; virtual;                 // AX and AY are in screen space
    procedure ClientToScreen(var AX, AY: Single);
    procedure ScreenToClient(var AX, AY: Single);

    property Transform: TMatrix4s read GetTransform;
    /// Coordinates and dimensions
    property X:      Single read FX      write SetX;
    property Y:      Single read FY      write SetY;
    property Width:  Single read FWidth  write SetWidth;
    property Height: Single read FHeight write SetHeight;
    property Angle:  Single read FAngle  write SetAngle;
    /// Coordinates and dimensions in pixels
    property PxX:      Single read FPxX      write SetPxX;
    property PxY:      Single read FPxY      write SetPxY;
    property PxWidth:  Single read FPxWidth  write SetPxWidth;
    property PxHeight: Single read FPxHeight write SetPxHeight;
    /// Client viewport
    property ClientX: Single      read FClientX;
    property ClientY: Single      read FClientY;
    property ClientWidth: Single  read FClientWidth;
    property ClientHeight: Single read FClientHeight;

    property Border: Integer read FBorder write SetBorder;
    /// Scroll position
    property ScrollX: Single read FScrollX;
    property ScrollY: Single read FScrollY;
    /// Layout settings
    property HOrigin: THOrigin read FHOrigin write SetHOrigin;
    property VOrigin: TVOrigin read FVOrigin write SetVOrigin;
    property Align:   TAlign   read FAlign   write SetAlign;

    property PercentValues: BaseTypes.TSet32 read FPercentValues write SetPercentValues;
  end;

  TGUIItem = class(TGUIBounds)
  private
    function GetAbility: Boolean;
    procedure SetAbility(const Value: Boolean);

    function GetVisibility: Boolean;
    procedure SetVisibility(const Value: Boolean);

    procedure SetFocused(const Value: Boolean);
    function GetGUIRoot: TGUIRootItem;
    function CanBeFocused: Boolean;
  protected
    CanFocus: Boolean;
    FFocused, Hover, Pushed: Boolean;
    procedure SetState(const Value: TSet32); override;
    function GetStatesSource: TGUIItem;
    procedure UpdateVisualParameters; virtual;
    function isVisibleAndEnabled: Boolean;
    procedure HandleClick(Button, MX, MY: Integer); virtual;
  public
    ParentState: Boolean;
    Color, NormalColor, HoverColor, FocusedColor, PushedColor, DisabledColor: TColor;

    IsVisibleDelegate, IsEnabledDelegate: TGUIStateDelegate;
    constructor Create(AManager: TItemsManager); override;          // Regular constructor

    procedure OnSceneAdd; override;

    procedure HandleMessage(const Msg: TMessage); override;
    function GUIHandleMessage(const Msg: TMessage): Boolean; override;
    procedure ReturnMessage(const Msg: TMessage); override;

    procedure Draw; override;
    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    property Enabled: Boolean read GetAbility write SetAbility;
    property Visible: Boolean read GetVisibility write SetVisibility;
    property Focused: Boolean read FFocused write SetFocused;
  end;

  TTextGUIItem = class(TGUIItem)
  private
    FText, RText: string;                                            // Text property value and text to render
  protected
    Colored: Boolean;
    procedure SetText(const AText: string); virtual;
    procedure ResolveLinks; override;
    function GetSizeAdjustable: Boolean; virtual;
  public
    Font: TFont;
    Markup: TMarkup;

    procedure CalcClientArea; override;

    function GetClearedText: string;

    function GUIHandleMessage(const Msg: TMessage): Boolean; override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    procedure DrawText(AX, AY: Single); virtual;

    destructor Destroy; override;

    property Text: string read FText write SetText;
    property CText: string read GetClearedText;
  end;

  TUVGUIItem = class(TGUIItem)
  private
    MaxFrame: Integer;
    FFrame: Integer;
    FUVMap: TUVMap;
  protected
    NormalFrame: Integer;
    UsedFrames: BaseTypes.TSet32;
    procedure UpdateVisualParameters; override;
  public
    constructor Create(AManager: TItemsManager); override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    procedure ResolveLinks; override;

    procedure SetUVMap(const AUVMap: TUVMap; ATotalFrames: Integer);
    procedure SetFrame(const Value: Integer); virtual;

    property Frame: Integer read FFrame write SetFrame;
    property UVMap: TUVMap read FUVMap;
  end;

var AggregatedClass: CItem;

implementation

uses GUIMsg;

function isItemVisibleAndEnabled(Item: TItem): Boolean;
begin
  Result := (Item is TGUIItem) and TGUIItem(Item).Enabled and TGUIItem(Item).Visible;
end;

{ TBaseGUIItem }

function TBaseGUIItem.GetModel: TModel;
begin
  Result := DefaultModel;
end;

procedure TBaseGUIItem.SetModel(const Value: TModel);
begin
  if Model = Value then Exit;
  if Assigned(DefaultModel) then FreeAndNil(DefaultModel);
  Model := Value;
end;

function TBaseGUIItem.GetNonGUIDummyParent: TItem;
begin
  Result := Parent;
  while Result is TDummyItem do Result := Result.Parent;                        // Skip dummy items
end;

procedure TBaseGUIItem.ObtainParentDimensions(out PWidth, PHeight: Single);
var ParItem: TItem;
begin
  ParItem := GetNonGUIDummyParent;

  if ParItem is TGUIBounds then begin
    PWidth  := TGUIBounds(ParItem).PxWidth;
    PHeight := TGUIBounds(ParItem).PxHeight;
  end else begin
    PWidth  := Screen.Width;
    PHeight := Screen.Height;
  end;
end;

procedure TBaseGUIItem.RealignChilds(StartIndex: Integer);
var Rect: TArea; Cur: TItem;
begin
  Rect.X1 := 0;
  Rect.Y1 := 0;
  if Self is TGUIBounds then begin
    Rect.X2 := TGUIBounds(Self).PxWidth;
    Rect.Y2 := TGUIBounds(Self).PxHeight;
  end else begin
    Rect.X2 := Screen.Width;
    Rect.Y2 := Screen.Height;
  end;
  Cur := nil;
  while FindNextChildInclDummy(Cur) do if (Cur is TGUIBounds) then TGUIBounds(Cur).CalcBounds(Rect);
end;

constructor TBaseGUIItem.Create(AManager: TItemsManager);
begin
  inherited;
  if AggregatedClass <> nil then begin
    AggregatedItem := AggregatedClass.Create(AManager);
    SendMessage(TAggregateMsg.Create(Self), AggregatedItem, [mfRecipient]);
  end;
  State := State + [isVisible];
end;

destructor TBaseGUIItem.Destroy;
begin
  if Assigned(AggregatedItem) then FreeAndNil(AggregatedItem);
  if Assigned(DefaultModel) then FreeAndNil(DefaultModel);
  inherited;
end;

procedure TBaseGUIItem.HandleMessage(const Msg: TMessage);
begin
  if Assigned(AggregatedItem) then begin
    if Msg.ClassType = ItemMsg.TAddToSceneMsg then
      AggregatedItem.HandleMessage(ItemMsg.TAddToSceneMsg.Create(AggregatedItem))
    else
      AggregatedItem.HandleMessage(Msg);
  end;
  inherited;
end;

function TBaseGUIItem.GUIHandleMessage(const Msg: TMessage): Boolean;

  procedure HandleFor(Item: TItem);
  var i: Integer;
  begin
    Result := True;
    i := Item.TotalChilds-1;
    while (i >= 0) {and Result} do begin
      if isItemVisibleAndEnabled(Item.Childs[i]) then
        TBaseGUIItem(Item.Childs[i]).GUIHandleMessage(Msg)
      else
        if Item.Childs[i] is TDummyItem then HandleFor(Item.Childs[i]);
      Dec(i);
    end;
  end;

begin
  HandleFor(Self);
end;

procedure TBaseGUIItem.ReturnMessage(const Msg: TMessage);
begin
end;

procedure TBaseGUIItem.AddProperties(const Result: Props.TProperties);
var Props: TProperties; 
begin
  inherited;
  Props := TProperties.Create;
  if AggregatedItem <> nil then begin
    AggregatedItem.AddProperties(Props);
    Result.Merge(Props, False);
  end;
  if Assigned(Model) then begin
    Props.Clear;
    Model.GetProperties(Props);
    Result.Merge(Props, False);
  end;
  FreeAndNil(Props);
end;

procedure TBaseGUIItem.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Assigned(AggregatedItem) then AggregatedItem.SetProperties(Properties);
  if Assigned(Model)          then Model.SetProperties(Properties);
end;

{ TGUIRootItem }

procedure TGUIRootItem.SetFocusedItem(const Item: TGUIItem);
var OPushed: Boolean;
begin
  if FFocusedItem = Item then Exit;
  if not Item.CanBeFocused then Exit;                             // The item can't be focused
  if Assigned(FFocusedItem) then with FFocusedItem do begin
    FFocused := False;
    OPushed  := Pushed;
    Pushed   := False;
    UpdateVisualParameters;
  end else OPushed := False;
  FFocusedItem          := Item;
  FFocusedItem.FFocused := True;
  FFocusedItem.Pushed   := OPushed;
  FFocusedItem.UpdateVisualParameters;
end;

constructor TGUIRootItem.Create(AManager: TItemsManager);
begin
  inherited;
  KeyEnter  := IK_RETURN;
  KeyEscape := IK_ESCAPE;
  KeyUp     := IK_UP;
  KeyDown   := IK_DOWN;
  KeyLeft   := IK_LEFT;
  KeyRight  := IK_RIGHT;
end;

procedure TGUIRootItem.HandleMessage(const Msg: TMessage);
var i, Index, ind: Integer;

  function GetIndexInParent(Item: TItem): Integer;
  begin
    Result := -1;
    if (Item = nil) or (Item.Parent = nil) then Exit;
    for Result := 0 to Item.Parent.TotalChilds-1 do 
      if Item.Parent.Childs[Result] = Item then Exit;
    Result := -1;
  end;

begin
  if (Msg is TWindowResizeMsg) then SendMessage(Msg, nil, [mfChilds]) else if (Msg is TMouseMsg) then begin
    GUIHandleMessage(Msg);
  end else if (FFocusedItem <> nil) and (Msg is TKeyboardMsg) then begin             // Forward a keyboard message to the focused item
    FFocusedItem.GUIHandleMessage(Msg);
  end else if (Msg is TGUIMessage) then with TGUIMessage(Msg) do begin
    if (Msg.ClassType = TGUIFocusNext) or (Msg.ClassType = TGUIFocusPrev) then begin
      Index := GetIndexInParent(Item);
      ind   := Index;

      for i := 0 to Item.Parent.TotalChilds-1 do begin
        ind := (ind + Ord(Msg.ClassType = TGUIFocusNext) - Ord(Msg.ClassType = TGUIFocusPrev) + Item.Parent.TotalChilds) mod Item.Parent.TotalChilds;
        if (ind <> Index) and (Item.Parent.Childs[ind] is TGUIItem) and ((Item.Parent.Childs[ind] as TGUIItem).CanBeFocused) then begin
          FocusedItem := (Item.Parent.Childs[ind] as TGUIItem);
          Break;
        end;
      end;
    end;
  end else if not (mfCore in Msg.Flags) then              // Filter out messages sent to the item as a subsystem and call inherited handler
    inherited;
end;

procedure TGUIRootItem.ReturnMessage(const Msg: TMessage);
begin
  SendMessage(Msg, nil, [mfCore]);             // Forward the message to the application
end;

function TGUIRootItem.IsWithinGUI(AX, AY: Single): Boolean;

  function CheckItem(AItem: TItem): Boolean;
  var i: Integer;
  begin
    Result := False;
    i := AItem.TotalChilds-1;
    while (i >= 0) and not Result do begin
      if not (AItem.Childs[i] is TGUIItem) then
        Result := CheckItem(AItem.Childs[i])
      else
        Result := isItemVisibleAndEnabled(AItem.Childs[i]) and (TGUIItem(AItem.Childs[i]).IsWithin(AX, AY));
      Dec(i);
    end;
    Result := Result or (i >= 0);
  end;

begin
  Result := CheckItem(Self);
end;

procedure TGUIRootItem.Draw;
begin
  Screen.CurrentZ := ClearingZ;                                   // ToDo: Eliminate it
end;

procedure TGUIRootItem.OnSceneAdd;
begin
  inherited;
  SendMessage(TSubsystemMsg.Create(saConnect, Self), nil, [mfCore]);
end;

procedure TGUIRootItem.OnSceneRemove;
begin
  inherited;
  SendMessage(TSubsystemMsg.Create(saDisconnect, Self), nil, [mfCore]);
end;

{ TGUIBounds }

procedure TGUIBounds.InvalidateTransform;

procedure InvalidateChilds(Item: TItem);
var i: Integer;
begin
  for i := 0 to Item.TotalChilds-1 do begin
    if (Item.Childs[i] is TGUIBounds) then begin
      TGUIBounds(Item.Childs[i]).TransformValid := False;
      InvalidateChilds(Item.Childs[i]);
    end;
    if (Item.Childs[i] is TDummyItem) then InvalidateChilds(Item.Childs[i]);
  end;
end;

begin
  if not TransformValid then Exit;
  TransformValid := False;
  InvalidateChilds(Self);
end;

procedure TGUIBounds.SetHOrigin(const Value: THOrigin);
begin
  FHOrigin := Value;
  Realign;
end;

procedure TGUIBounds.SetVOrigin(const Value: TVOrigin);
begin
  FVOrigin := Value;
  Realign;
end;

/// Recalculates control's bounds according to layout parameters
procedure TGUIBounds.Realign;
var ParItem: TItem;
begin
  if DisableRealign then Exit;
  ParItem := GetNonGUIDummyParent;
  if ParItem is TBaseGUIItem then TBaseGUIItem(ParItem).RealignChilds(0);
end;

procedure TGUIBounds.CalcBounds(var ARect: BaseTypes.TArea);
var OfsX, OfsY, ParW, ParH, NewPxW, NewPxH: Single; Msg: TWindowResizeMsg;
begin
//  ObtainParentDimensions(ParW, ParH);
  OfsX := ARect.X1;
  OfsY := ARect.Y1;
  ParW := ARect.X2 - ARect.X1;
  ParH := ARect.Y2 - ARect.Y1;

  AlignRect := ARect;

  if pvWidth  in FPercentValues then NewPxW  := ParW/100 * FWidth  else NewPxW := FWidth;
  if pvHeight in FPercentValues then NewPxH  := ParH/100 * FHeight else NewPxH := FHeight;

  case FAlign of
    alNone, alAbsolute: begin
      if FAlign = alAbsolute then begin                      // Use original rect
        OfsX := 0; OfsY := 0;
        ObtainParentDimensions(ParW, ParH);
        AlignRect.X1 := 0;
        AlignRect.Y1 := 0;
        AlignRect.X2 := ParW;
        AlignRect.Y2 := ParH;
      end;
      if pvLeft in FPercentValues then FPxX := OfsX + ParW/100 * FX else FPxX := OfsX + FX;
      if pvTop  in FPercentValues then FPxY := OfsY + ParH/100 * FY else FPxY := OfsY + FY;
      case HOrigin of
        hoCenter: FPxX := FPxX + Round((ParW - NewPxW) * 0.5);
        hoRight:  FPxX := FPxX + ParW - NewPxW;
      end;

      case VOrigin of
        voCenter: FPxY := FPxY + Round((ParH - NewPxH) * 0.5);
        voBottom: FPxY := FPxY + ParH - NewPxH;
      end;
    end;
    alLeft: begin
      FPxX   := OfsX + FX;
      FPxY   := OfsY + FY;
      NewPxH := ParH - FY*2;
      ARect.X1 := ARect.X1 + NewPxW + FX;
    end;
    alTop: begin
      FPxX   := OfsX + FX;
      FPxY   := OfsY + FY;
      NewPxW := ParW - FX*2;
      ARect.Y1 := ARect.Y1 + NewPxH + FY;
    end;
    alRight: begin
      FPxY   := OfsY + FY;
      FPxX   := OfsX + ParW - NewPxW + FX;
      NewPxH := ParH - FY*2;
      ARect.X2 := ARect.X2 - NewPxW + FX;
    end;
    alBottom: begin
      FPxX   := OfsX + FX;
      FPxY   := OfsY + ParH - NewPxH + FY;
      NewPxW := ParW - FX*2;
      ARect.Y2 := ARect.Y2 - NewPxH + FY;
    end;
    alClient: begin
      FPxX   := OfsX + FX;
      FPxY   := OfsY + FY;
      NewPxW := ParW - FX*2;
      NewPxH := ParH - FY*2;
      ARect.X1 := ARect.X2;
      ARect.Y1 := ARect.Y2;
    end;
  end;

  if (FPxWidth <> NewPxW) or (FPxHeight <> NewPxH) then
    Msg := TWindowResizeMsg.Create(FPxWidth, FPxHeight, NewPxW, NewPxH) else
      Msg := nil;

  FPxWidth  := NewPxW;
  FPxHeight := NewPxH;

  CalcClientArea;

  if Assigned(Msg) then SendMessage(Msg, nil, [mfChilds]);

  InvalidateTransform;
end;

procedure TGUIBounds.ApplyAnchors(ParentDeltaWidth, ParentDeltaHeight: Single);
var NewLeft, NewTop, NewWidth, NewHeight: Single;
begin
  if Align <> alNone then Exit;
  NewLeft   := PxX;
  NewTop    := PxY;
  NewWidth  := PxWidth;
  NewHeight := PxHeight;

  DisableRealign := True;                                            // Avoid redundant realign
  
  if not (pvLeft in FPercentValues) then begin                       // Calculate new left bound
    if not (aLeft in FAnchors) then
      if aRight in FAnchors then
        NewLeft := NewLeft + ParentDeltaWidth else
          NewLeft := NewLeft + ParentDeltaWidth*0.5;
  end;
  if not (pvTop in FPercentValues) then begin                        // Calculate new top bound
    if not (aTop in FAnchors) then
      if aBottom in FAnchors then
        NewTop := NewTop + ParentDeltaHeight else
          NewTop := NewTop + ParentDeltaHeight*0.5;
  end;
  if not (pvWidth in FPercentValues) then begin                      // Calculate new width
    if aRight in FAnchors then
      if aLeft in FAnchors then
        NewWidth := NewWidth + ParentDeltaWidth;
  end;
  if not (pvHeight in FPercentValues) then begin                     // Calculate new height
    if aBottom in FAnchors then
      if aTop in FAnchors then
        NewHeight := NewHeight + ParentDeltaHeight;
  end;

  PxX      := NewLeft;
  PxY      := NewTop;
  PxWidth  := NewWidth;
  pxHeight := NewHeight;

  DisableRealign := False;

  Realign;
end;

procedure TGUIBounds.CalcClientArea;
begin
  FClientX      := Border;
  FClientY      := Border;
  FClientWidth  := PxWidth  - Border;
  FClientHeight := PxHeight - Border;
  InvalidateTransform;
end;

procedure TGUIBounds.SetWidth(const Value: Single);
var NewWidth: Single;
begin
  NewWidth := MinS(MaxS(Value, FConstraints.MinWidth), FConstraints.MaxWidth);
  if FWidth = NewWidth then Exit;
  FWidth := NewWidth;
  Realign;
end;

procedure TGUIBounds.SetHeight(const Value: Single);
var NewHeight: Single;
begin
  NewHeight := MinS(MaxS(Value, FConstraints.MinHeight), FConstraints.MaxHeight);
  if FHeight = NewHeight then Exit;
  FHeight := NewHeight;
  Realign;
end;

procedure TGUIBounds.SetX(const Value: Single);
begin
  FX := Value;
  Realign;
//  InvalidateTransform;
end;

procedure TGUIBounds.SetY(const Value: Single);
begin
  FY := Value;
  Realign;
//  InvalidateTransform;
end;

procedure TGUIBounds.SetPxX(Value: Single);
begin
  case HOrigin of
    hoLeft:   Value := Value - AlignRect.X1;
    hoCenter: Value := Value - Round((AlignRect.X1 + AlignRect.X2 - PxWidth) * 0.5);
    hoRight:  Value := Value - AlignRect.X2 + PxWidth;
  end;

  if pvLeft in FPercentValues then Value := Value/(AlignRect.X2 - AlignRect.X1)*100;

  X := Value;
end;

procedure TGUIBounds.SetPxY(Value: Single);
begin
  case VOrigin of
    voTop:    Value := Value - AlignRect.Y1;
    voCenter: Value := Value - Round((AlignRect.Y1 + AlignRect.Y2 - PxHeight) * 0.5);
    voBottom: Value := Value - AlignRect.Y2 + PxHeight;
  end;

  if pvTop in FPercentValues then Value := Value/(AlignRect.Y2 - AlignRect.Y1)*100;

  Y := Value;
end;

procedure TGUIBounds.SetPxWidth(Value: Single);
begin
  if pvWidth in FPercentValues then Value := Value/(AlignRect.X2-AlignRect.X1)*100;
  Width := Value;
end;

procedure TGUIBounds.SetPxHeight(Value: Single);
begin
  if pvHeight in FPercentValues then Value := Value/(AlignRect.Y2-AlignRect.Y1)*100;
  Height := Value;
end;

procedure TGUIBounds.SetAngle(const Value: Single);
begin
  FAngle := Value;
  Realign;
//  InvalidateTransform;
end;

procedure TGUIBounds.SetAlign(const Value: TAlign);
begin
  FAlign := Value;
  Realign;
end;

procedure TGUIBounds.SetPercentValues(const Value: BaseTypes.TSet32);
begin
  FPercentValues := Value;
  Realign;
end;

procedure TGUIBounds.SetBorder(const Value: Integer);
begin
  FBorder := Value;
  CalcClientArea;
end;

function TGUIBounds.GetTransform: TMatrix4s;
begin
  if not TransformValid then ComputeTransform;
  Result := FTransform;
end;

function TGUIBounds.GetLocalViewport: BaseGraph.TViewport;
begin
  if not TransformValid then ComputeTransform;
  Result := FLocalViewport;
end;

procedure TGUIBounds.ComputeTransform;
var ClX, ClY, ClW, ClH, SX, SY: Single; ParItem: TItem; ParBounds: TGUIBounds; V: TVector4s;
begin
  if TransformValid then Exit;
  TransformValid := True;

  ParItem := GetNonGUIDummyParent;

  ZRotationMatrix4s(FTransform, FAngle/180*pi);
//  FTransform := MulMatrix4s(TranslationMatrix4s(FX, FY, 0), FTransform);
  FTransform.M[3, 0] := PxX;
  FTransform.M[3, 1] := PxY;
//  MulMatrix4s(TransMat, ScaleMatrix4s(FScale.X, FScale.Y, FScale.Z), TransMat);

  if ParItem is TGUIBounds then begin
    ParBounds := TGUIBounds(ParItem);
    FTransform.M[3, 0] := FTransform.M[3, 0] - ParBounds.ScrollX;
    FTransform.M[3, 1] := FTransform.M[3, 1] - ParBounds.ScrollY;
    FTransform := MulMatrix4s(FTransform, ParBounds.Transform);
//    W := TGUIBounds(ParItem).PXWidth; H := TGUIBounds(ParItem).PxHeight;
    ClX := ParBounds.ClientX;
    ClY := ParBounds.ClientY;
    ClW := ParBounds.ClientWidth;
    ClH := ParBounds.ClientHeight;
    SX  := ParBounds.ScrollX;
    SY  := ParBounds.ScrollY;
  end else begin
    ParBounds := nil;
    ClX := 0;
    ClY := 0;
    ClW := Screen.Width;
    ClH := Screen.Height;
    SX  := 0;
    SY  := 0;
  end;

  FLocalViewport.Left   := ClX - PxX + SX;
  FLocalViewport.Top    := ClY - PxY + SY;
  FLocalViewport.Right  := ClW - PxX;
  FLocalViewport.Bottom := ClH - PxY;

  if ParBounds <> nil then begin                                  // Clip the viewport against parent's viewport
    FLocalViewport.Left   := MaxS(FLocalViewport.Left,   ParBounds.GetLocalViewport.Left   - PxX);
    FLocalViewport.Top    := MaxS(FLocalViewport.Top,    ParBounds.GetLocalViewport.Top    - PxY);
    FLocalViewport.Right  := MinS(FLocalViewport.Right,  ParBounds.GetLocalViewport.Right  - PxX);
    FLocalViewport.Bottom := MinS(FLocalViewport.Bottom, ParBounds.GetLocalViewport.Bottom - PxY);
  end;

  V := GetVector4s(0, 0, 0, 1);

  V := Transform4Vector4s(FTransform, V);
end;

                        { *** }
constructor TGUIBounds.Create(AManager: TItemsManager); 
begin
  inherited;

  FConstraints.MinWidth  := 0;
  FConstraints.MinHeight := 0;
  FConstraints.MaxWidth  := 10000;
  FConstraints.MaxHeight := 10000;

  FX := 0; FY := 0;

  FAngle := 0;

  Width  := 96;
  Height := 24;

  FAnchors := [aLeft, aTop];

  FHOrigin := hoLeft;
  FVOrigin := voTop;

  FBorder  := 0;
  FScrollX := 0;

  FPercentValues := [];
end;

procedure TGUIBounds.HandleMessage(const Msg: TMessage);
begin
  inherited;
  if (Msg is TWindowResizeMsg) then with TWindowResizeMsg(Msg) do
    ApplyAnchors(NewWidth - OldWidth, NewHeight - OldHeight);
end;

procedure TGUIBounds.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  Result.AddSetProperty('Layout\Values in percent', FPercentValues, [], BoundValuesEnum, '');

  Result.AddEnumerated('Layout\Align',             [], Ord(FAlign),   AlignEnum);
  Result.AddEnumerated('Layout\Horizontal origin', [], Ord(FHOrigin), HOriginEnum);
  Result.AddEnumerated('Layout\Vertical origin',   [], Ord(FVOrigin), VOriginEnum);

  Result.Add('Layout\Min width',  vtSingle, [], FloatToStr(FConstraints.MinWidth),  '');
  Result.Add('Layout\Min height', vtSingle, [], FloatToStr(FConstraints.MinHeight), '');
  Result.Add('Layout\Max width',  vtSingle, [], FloatToStr(FConstraints.MaxWidth),  '');
  Result.Add('Layout\Max height', vtSingle, [], FloatToStr(FConstraints.MaxHeight), '');

  Result.Add('Layout\X',      vtSingle, [], FloatToStr(FX),      '');
  Result.Add('Layout\Y',      vtSingle, [], FloatToStr(FY),      '');
  Result.Add('Layout\Width',  vtSingle, [], FloatToStr(FWidth),  '');
  Result.Add('Layout\Height', vtSingle, [], FloatToStr(FHeight), '');

  Result.Add('Layout\In pixels\X',      vtSingle, [poDerivative], FloatToStr(PxX),      '');
  Result.Add('Layout\In pixels\Y',      vtSingle, [poDerivative], FloatToStr(PxY),      '');
  Result.Add('Layout\In pixels\Width',  vtSingle, [poDerivative], FloatToStr(PxWidth),  '');
  Result.Add('Layout\In pixels\Height', vtSingle, [poDerivative], FloatToStr(PxHeight), '');

  Result.Add('Layout\Angle', vtSingle, [], FloatToStr(FAngle), '');

  Result.Add('Layout\Anchors\Left',   vtBoolean, [], OnOffStr[aLeft   in FAnchors], '');
  Result.Add('Layout\Anchors\Top',    vtBoolean, [], OnOffStr[aTop    in FAnchors], '');
  Result.Add('Layout\Anchors\Right',  vtBoolean, [], OnOffStr[aRight  in FAnchors], '');
  Result.Add('Layout\Anchors\Bottom', vtBoolean, [], OnOffStr[aBottom in FAnchors], '');

  //  Result.Add('Layout\Width\% by parent''s',  vtBoolean, [], OnOffStr[rvWidth  in FRelativeValues], '');
//  Result.Add('Layout\Height\% by parent''s', vtBoolean, [], OnOffStr[rvHeight in FRelativeValues], '');
end;

procedure TGUIBounds.SetProperties(Properties: Props.TProperties);
begin
  inherited;

  if Properties.SetSetProperty('Layout\Values in percent', FPercentValues, BoundValuesEnum) then PercentValues := FPercentValues;

  if Properties.Valid('Layout\Align')             then Align   := TAlign(Properties.GetAsInteger('Layout\Align'));
  if Properties.Valid('Layout\Horizontal origin') then HOrigin := THOrigin(Properties.GetAsInteger('Layout\Horizontal origin'));
  if Properties.Valid('Layout\Vertical origin')   then VOrigin := TVOrigin(Properties.GetAsInteger('Layout\Vertical origin'));

  if Properties.Valid('Layout\Min width')  then FConstraints.MinWidth  := StrToFloatDef(Properties['Layout\Min width'],  0);
  if Properties.Valid('Layout\Min height') then FConstraints.MinHeight := StrToFloatDef(Properties['Layout\Min height'], 0);
  if Properties.Valid('Layout\Max width')  then FConstraints.MaxWidth  := StrToFloatDef(Properties['Layout\Max width'],  0);
  if Properties.Valid('Layout\Max height') then FConstraints.MaxHeight := StrToFloatDef(Properties['Layout\Max height'], 0);

  if Properties.Valid('Layout\In pixels\X')      then PxX      := StrToFloatDef(Properties['Layout\In pixels\X'],      0);
  if Properties.Valid('Layout\In pixels\Y')      then PxY      := StrToFloatDef(Properties['Layout\In pixels\Y'],      0);
  if Properties.Valid('Layout\In pixels\Width')  then PxWidth  := StrToFloatDef(Properties['Layout\In pixels\Width'],  80);
  if Properties.Valid('Layout\In pixels\Height') then PxHeight := StrToFloatDef(Properties['Layout\In pixels\Height'], 14);

  if Properties.Valid('Layout\X')      then X      := StrToFloatDef(Properties['Layout\X'],      0);
  if Properties.Valid('Layout\Y')      then Y      := StrToFloatDef(Properties['Layout\Y'],      0);
  if Properties.Valid('Layout\Width')  then Width  := StrToFloatDef(Properties['Layout\Width'],  80);
  if Properties.Valid('Layout\Height') then Height := StrToFloatDef(Properties['Layout\Height'], 14);

  if Properties.Valid('Layout\Angle') then Angle := StrToFloatDef(Properties['Layout\Angle'], 0);

  if Properties.Valid('Layout\Anchors\Left')   then if Properties.GetAsInteger('Layout\Anchors\Left')   > 0 then
    FAnchors := FAnchors + [aLeft]   else FAnchors := FAnchors - [aLeft];
  if Properties.Valid('Layout\Anchors\Top')    then if Properties.GetAsInteger('Layout\Anchors\Top')    > 0 then
    FAnchors := FAnchors + [aTop]    else FAnchors := FAnchors - [aTop];
  if Properties.Valid('Layout\Anchors\Right')  then if Properties.GetAsInteger('Layout\Anchors\Right')  > 0 then
    FAnchors := FAnchors + [aRight]  else FAnchors := FAnchors - [aRight];
  if Properties.Valid('Layout\Anchors\Bottom') then if Properties.GetAsInteger('Layout\Anchors\Bottom') > 0 then
    FAnchors := FAnchors + [aBottom] else FAnchors := FAnchors - [aBottom];

  
{  if Properties.Valid('Layout\Width\% by parent''s')  then if Properties.GetAsInteger('Layout\Width\% by parent''s')  > 0 then
    FRelativeValues := FRelativeValues + [rvWidth]  else FRelativeValues := FRelativeValues - [rvWidth];
  if Properties.Valid('Layout\Height\% by parent''s') then if Properties.GetAsInteger('Layout\Height\% by parent''s') > 0 then
    FRelativeValues := FRelativeValues + [rvHeight] else FRelativeValues := FRelativeValues - [rvHeight];}
end;

function TGUIBounds.IsWithin(AX, AY: Single): Boolean;
begin
{  TX := 0; TY := 0;
  ClientToScreen(TX, TY);
  Result := (AX > TX) and (AY > TY) and (AX < TX + Width) and (AY < TY + Height);}
  ScreenToClient(AX, AY);
  Result := (AX > 0) and (AY > 0) and (AX < PxWidth) and (AY < PxHeight);
end;

procedure TGUIBounds.ClientToScreen(var AX, AY: Single);
var V: TVector4s;                       // ToDo -cOptimization: Optimize (eliminate) it.
begin
  V := GetVector4s(AX, AY, 0, 1);
  V := Transform4Vector4s(Transform, V);
  AX := V.X; AY := V.Y;
end;

procedure TGUIBounds.ScreenToClient(var AX, AY: Single);
var V, v1, v2: TVector4s;                       // ToDo -cOptimization: Optimize (eliminate) it.
m1, m2: TMatrix4s;
begin
  V := GetVector4s(AX, AY, 0, 1);

  m1 := InvertMatrix4s(Transform);
  m2 := InvertAffineMatrix4s(Transform);
  V1 := Transform4Vector4s(m1, V);
  V2 := Transform4Vector4s(m2, V);
  if not EqualsVector4s(v1, v2) then begin
    m1 := InvertMatrix4s(Transform);
    m2 := InvertAffineMatrix4s(Transform);
    V.X := 7;
  end;
  V := V1;
//  V.X := V.X - Transform._41;
//  V.Y := V.Y - Transform._42;
  AX := V.X; AY := V.Y;
end;

{ TGUIItem }

function TGUIItem.GetAbility: Boolean;
begin
  if Assigned(IsEnabledDelegate) then
    Result := IsEnabledDelegate(Self) else
      Result := isProcessing in State;
end;

procedure TGUIItem.SetAbility(const Value: Boolean);
begin
  if Value then State := FState + [isProcessing] else State := FState - [isProcessing];
end;

function TGUIItem.GetVisibility: Boolean;
begin
  if Assigned(IsVisibleDelegate) then
    Result := IsVisibleDelegate(Self) else
      Result := isVisible in State;
end;

procedure TGUIItem.SetVisibility(const Value: Boolean);
begin
  if Value then State := FState + [isVisible] else State := FState - [isVisible];
end;

function TGUIItem.GetStatesSource: TGUIItem;
begin
  Result := Self;
  while Result.ParentState and (GetNonGUIDummyParent is TGUIItem) do Result := TGUIItem(GetNonGUIDummyParent);
end;

procedure TGUIItem.SetFocused(const Value: Boolean);
begin
  if not CanBeFocused then Exit;
  if GetGUIRoot <> nil then
    if Value then GetGUIRoot.FocusedItem := Self else GetGUIRoot.FocusedItem := nil;
end;

function TGUIItem.GetGUIRoot: TGUIRootItem;
var Item: TItem;
begin
  Item := Parent;
  while Assigned(Item) and not (Item is TGUIRootItem) do Item := Item.Parent;
  if Assigned(Item) then
    Result := Item as TGUIRootItem
  else
    Result := nil;
{
  Result := nil;
  Item := Parent;
  while Item <> nil do begin
    if Item is TGUIRootItem then begin
      Result := TGUIRootItem(Item);
      Exit;
    end;
    Item := Item.Parent;
  end;}
end;

function TGUIItem.CanBeFocused: Boolean;
begin
  Result := isVisibleAndEnabled and CanFocus;
end;
                        { *** }
constructor TGUIItem.Create(AManager: TItemsManager);
begin
  inherited;
  NormalColor.C   := $80C0C0C0;
  PushedColor.C   := $FFFFFFFF;
  FocusedColor.C  := $FF80FFFF;
  HoverColor.C    := $FFFFFFFF;
  DisabledColor.C := $FF808080;
  Color           := NormalColor;
end;

procedure TGUIItem.HandleMessage(const Msg: TMessage);
begin
  inherited;

  if Msg.ClassType = TGUIStateChangeMsg then UpdateVisualParameters else
    if Msg.ClassType = TWindowResizeMsg then Realign;

    //    if not (isProcessing in OldValue) and (isProcessing in NewValue) then SetControlState(csNormal);
    //    if (isProcessing in OldValue) and not (isProcessing in NewValue) then SetControlState(csDisabled);
  
end;

function TGUIItem.GUIHandleMessage(const Msg: TMessage): Boolean;
begin
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;

  if Msg is TInputMessage then begin
    if ParentState then begin
      Result := False; Exit;
    end;

    if Msg.ClassType = TMouseDownMsg then with TMouseDownMsg(Msg) do begin
      if (Button = IK_MOUSELEFT) and Hover then begin
        ReturnMessage(TGUIDownMsg.Create(Self));
        if CanBeFocused then Focused := True;
        Pushed := True;
        UpdateVisualParameters;
      end;
    end else if Msg.ClassType = TMouseUpMsg then with TMouseUpMsg(Msg) do begin
      if (Button = IK_MOUSELEFT) then begin
        if Pushed and Hover then HandleClick(Button, X, Y);
        Pushed := False;
        UpdateVisualParameters;
      end;
    end else if (Msg.ClassType = TMouseMoveMsg) then with TMouseMoveMsg(Msg) do begin
      if IsWithin(X, Y) then begin
        Hover := True;
        X := -20000;                                   // Move the mouse out of any control
      end else Hover := False;
      UpdateVisualParameters;
    end;
// Keyboard handle for focused controls
    if Focused then begin
      if Msg.ClassType = TKeyClickMsg then with TKeyClickMsg(Msg) do begin
        if Key = GetGUIRoot.KeyDown then SendMessage(TGUIFocusNext.Create(Self), GetGUIRoot, [mfRecipient]);
        if Key = GetGUIRoot.KeyUp   then SendMessage(TGUIFocusPrev.Create(Self), GetGUIRoot, [mfRecipient]);
      end;
      if Msg.ClassType = TKeyDownMsg then with TKeyDownMsg(Msg) do
        if Key = GetGUIRoot.KeyEnter then begin Pushed := True; UpdateVisualParameters; end;
      if Msg.ClassType = TKeyUpMsg then with TKeyUpMsg(Msg) do
        if Key = GetGUIRoot.KeyEnter then begin
          if Pushed then HandleClick(Key, 0, 0);
          Pushed := False; UpdateVisualParameters;
        end;
    end;    
  end;
end;

procedure TGUIItem.Draw;
begin
  Screen.Transform := Transform;
  Screen.Viewport := GetLocalViewport;
end;

procedure TGUIItem.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  AddColor4sProperty(Result, 'Color',          ColorTo4S(NormalColor));
  AddColor4sProperty(Result, 'Color\Hover',    ColorTo4S(HoverColor));
  AddColor4sProperty(Result, 'Color\Pushed',   ColorTo4S(PushedColor));
  AddColor4sProperty(Result, 'Color\Focused',  ColorTo4S(FocusedColor));
  AddColor4sProperty(Result, 'Color\Disabled', ColorTo4S(DisabledColor));

  Result.Add('Enabled', vtBoolean,             [], OnOffStr[isProcessing in State], '');
  Result.Add('Use parent''s state', vtBoolean, [], OnOffStr[ParentState], '');
  Result.Add('Can be focused', vtBoolean,      [], OnOffStr[CanFocus], '');
end;

procedure TGUIItem.SetProperties(Properties: Props.TProperties);
begin
  inherited;

  SetColorProperty(Properties, 'Color',          NormalColor);
  SetColorProperty(Properties, 'Color\Hover',    HoverColor);
  SetColorProperty(Properties, 'Color\Pushed',   PushedColor);
  SetColorProperty(Properties, 'Color\Focused',  FocusedColor);
  SetColorProperty(Properties, 'Color\Disabled', DisabledColor);

  Color := NormalColor;

  if Properties.Valid('Enabled') then
    Enabled := Properties.GetAsInteger('Enabled') > 0;

  if Properties.Valid('Use parent''s state') then ParentState := Properties.GetAsInteger('Use parent''s state') > 0;

  if Properties.Valid('Can be focused') then CanFocus := Properties.GetAsInteger('Can be focused') > 0;

  UpdateVisualParameters;
end;

function TGUIItem.isVisibleAndEnabled: Boolean;
var Item: TItem;
begin
  Result := False;
  Item := Self;
  while Item <> nil do begin
    if (Item is TGUIItem) and (not TGUIItem(Item).Enabled or not TGUIItem(Item).Visible) then Exit;
    Item := Item.Parent;
  end;
  Result := True;
end;

procedure TGUIItem.HandleClick(Button, MX, MY: Integer);
begin
//  if (Button = IK_MOUSELEFT) or (Button = GetGUIRoot.KeyEnter) then
  ReturnMessage(TGUIClickMsg.Create(Self));
end;

procedure TGUIItem.UpdateVisualParameters;
begin
  if not GetStatesSource.Enabled then Color := DisabledColor else
    if GetStatesSource.Pushed then Color := PushedColor else
      if GetStatesSource.Hover then Color := HoverColor else
        if GetStatesSource.Focused then Color := FocusedColor else
          Color := NormalColor;

  SendMessage(TGUIStateChangeMsg.Create(Self), nil, [mfChilds]);

//  if FControlState = csHover then Log('Hovered: "' + Name + '" of class ' + ClassName, lkInfo);

end;

procedure TGUIItem.ReturnMessage(const Msg: TMessage);
var ParItem: TItem;
begin
  Assert(Msg is TGUIMessage, ClassName + '.ReturnMessage: Only GUI messages allowed');
//  if Msg is TGUIMessage then with TGUIMessage(Msg) do
//    if Item = nil then Item := Self as TGUIItem;                    // The message was generated by control Data object
  ParItem := GetNonGUIDummyParent;
  if (ParItem is TBaseGUIItem) then TBaseGUIItem(ParItem).ReturnMessage(Msg);
end;

procedure TGUIItem.SetState(const Value: TSet32);
begin
  inherited;
  UpdateVisualParameters;
end;

procedure TGUIItem.OnSceneAdd;
begin
  inherited;
  if not Assigned(GetGUIRoot()) then
    Log(Format('TGUIItem("%S").OnSceneAdd: all GUI items must be children of TGUIRootItem', [Name]), lkWarning);
end;

{ TTextGUIItem }

procedure TTextGUIItem.ResolveLinks;
var FontRes: TItem;
begin
  if ResolveLink('Font', FontRes) then begin
    if not (FontRes is TFont) then
      Font := FontRes as TFont else
        Font := FontRes as TFont;
  end;
end;

function TTextGUIItem.GetSizeAdjustable: Boolean;
begin
  Result := not Colored;
end;

procedure TTextGUIItem.CalcClientArea;
begin
  inherited;
  if Colored and Assigned(Markup) then MarkUp.Invalidate;
end;

function TTextGUIItem.GetClearedText: string;
begin
  if Colored then begin
    if Markup = nil then Markup := TSimpleMarkup.Create;
    MarkUp.DefaultFont   := Font;
    MarkUp.DefaultWidth  := PxWidth;
    Markup.FormattedText := RText;
    Result := Markup.PureText;
  end else Result := RText;
end;

procedure TTextGUIItem.SetText(const AText: string);
var w, h: Single;
begin
  FText := AText; RText := FText;
  if (Font = nil) then Exit;
  if GetSizeAdjustable then begin
    Font.GetTextExtent(CText, w, h);
    PxWidth  := w;
    PxHeight := h;
  end else GetClearedText;
end;

procedure TTextGUIItem.AddProperties(const Result: Props.TProperties);
begin
  inherited;

  if Assigned(Result) then begin
    Result.Add('Text',    vtString,  [], Text, '');
    Result.Add('CText',   vtString,  [poReadOnly], CText, '');
    Result.Add('Colored', vtBoolean, [], OnOffStr[Colored], '');
  end;  

  AddItemLink(Result, 'Font', [], 'TFont');
end;

procedure TTextGUIItem.SetProperties(Properties: Props.TProperties);
begin
  inherited;

  if Properties.Valid('Text')    then Text := Properties['Text'];
  if Properties.Valid('Colored') then Colored := Properties.GetAsInteger('Colored') > 0;

  if Properties.Valid('Font')    then SetLinkProperty('Font', Properties['Font']);

  ResolveLinks;
end;

destructor TTextGUIItem.Destroy;
begin
  if Markup <> nil then FreeAndNil(Markup);
  inherited;
end;

procedure TTextGUIItem.DrawText(AX, AY: Single);
var i, CurPos: Integer; Tag: TTag;
begin
  if Colored and (MarkUp <> nil) then begin
    GetClearedText;
    CurPos := 0;
    Screen.MoveTo(AX, AY);
    for i := 0 to MarkUp.TotalTags-1 do begin
      Tag := MarkUp.Tags[i];
      if CurPos <> Tag.Position then begin
        Screen.PutText(Copy(MarkUp.PureText, CurPos+1, Tag.Position-CurPos));
        CurPos := Tag.Position;
      end;
      if Tag.ClassType = TMoveToTag     then with TMoveToTag(Tag)     do Screen.MoveTo(X, Y);
      if Tag.ClassType = TColorTag      then with TColorTag(Tag)      do Screen.SetColor(GetColor(Screen.Color.C and $FF000000 or Color.C));
      if Tag.ClassType = TAlphaColorTag then with TAlphaColorTag(Tag) do Screen.SetColor(Color);
      if Tag.ClassType = TColorResetTag then with TColorResetTag(Tag) do Screen.SetColor(Self.Color);
    end;
    Screen.PutText(Copy(MarkUp.PureText, CurPos+1, Length(MarkUp.PureText)));
  end else Screen.PutTextXY(AX, AY, CText);
end;

function TTextGUIItem.GUIHandleMessage(const Msg: TMessage): Boolean;
begin
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;
  if MSg.ClassType = TWindowResizeMsg then if Colored and Assigned(Markup) then MarkUp.Invalidate;
end;

{ TUVGUIItem }

procedure TUVGUIItem.UpdateVisualParameters;
begin
  inherited;
  Frame := NormalFrame;
  if not GetStatesSource.Enabled then begin
    if frDisabled in UsedFrames then Frame := NormalFrame + Ord(frHover in UsedFrames) + Ord(frPushed in UsedFrames) + Ord(frFocused in UsedFrames) + 1;
  end else if GetStatesSource.Pushed then begin
    if frPushed in UsedFrames then Frame := NormalFrame + Ord(frHover in UsedFrames) + 1;
  end else if GetStatesSource.Hover then begin
    if frHover in UsedFrames then Frame := NormalFrame + 1;
  end else if GetStatesSource.Focused then begin
    if frFocused in UsedFrames then Frame := NormalFrame + Ord(frHover in UsedFrames) + Ord(frPushed in UsedFrames) + 1;
  end;
end;

constructor TUVGUIItem.Create(AManager: TItemsManager);
begin
  inherited;
  SetUVMap(nil, 0);
end;

procedure TUVGUIItem.AddProperties(const Result: Props.TProperties);
begin
  inherited;

  AddItemLink(Result, 'UV\Map', [], 'TUVMapResource');

  if not Assigned(Result) then Exit;

  Result.Add('UV\Frame',     vtInt, [],           IntToStr(NormalFrame), '');
  Result.Add('UV\Max frame', vtInt, [poReadOnly], IntToStr(MaxFrame),    '');

  Result.Add('UV\Use hover frame',    vtBoolean, [], OnOffStr[frHover    in UsedFrames], '');
  Result.Add('UV\Use pressed frame',  vtBoolean, [], OnOffStr[frPushed   in UsedFrames], '');
  Result.Add('UV\Use disabled frame', vtBoolean, [], OnOffStr[frDisabled in UsedFrames], '');
end;

procedure TUVGUIItem.SetProperties(Properties: Props.TProperties);
begin
  inherited;

  if Properties.Valid('UV\Map') then SetLinkProperty('UV\Map', Properties['UV\Map']);
  ResolveLinks;

  if Properties.Valid('UV\Frame')              then NormalFrame := StrToIntDef(Properties['UV\Frame'], 0);
  if Properties.Valid('UV\Use hover frame')    then if Properties.GetAsInteger('UV\Use hover frame') > 0 then
    Include(UsedFrames, frHover) else
      Exclude(UsedFrames, frHover);
  if Properties.Valid('UV\Use pushed frame')   then if Properties.GetAsInteger('UV\Use pushed frame') > 0 then
    Include(UsedFrames, frPushed) else
      Exclude(UsedFrames, frPushed);
  if Properties.Valid('UV\Use disabled frame') then if Properties.GetAsInteger('UV\Use disabled frame') > 0 then
    Include(UsedFrames, frDisabled) else
      Exclude(UsedFrames, frDisabled);
  Frame := NormalFrame;
end;

procedure TUVGUIItem.ResolveLinks;
var UVMapRes: TItem;
begin
  inherited;
  if ResolveLink('UV\Map', UVMapRes) then SetUVMap((UVMapRes as TUVMapResource).Data, (UVMapRes as TUVMapResource).TotalElements - 1);
end;

procedure TUVGUIItem.SetUVMap(const AUVMap: TUVMap; ATotalFrames: Integer);
begin
  if (AUVMap <> nil) and (ATotalFrames > 0) then begin
    MaxFrame      := ATotalFrames-1;
    FUVMap   := AUVMap;
  end else FUVMap := GetDefaultUVMap;
  Frame := NormalFrame;
end;

procedure TUVGUIItem.SetFrame(const Value: Integer);
begin
  if (Value = FFrame) or (Value > MaxFrame) then Exit;
  FFrame := Value;
end;

end.