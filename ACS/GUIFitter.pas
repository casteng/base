(*
 @Abstract(GUI fitter unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains base GUI fitter class and 2D fitter class
*)
{$Include GDefines.inc}
unit GUIFitter;

interface

uses
  Logger, SysUtils,
  BaseTypes, Basics, Props, Models, BaseClasses, BaseMsg, BaseGraph, ACSBase,
  Base3D;

const
  // Hot areas
  haCenter = 0; haTop = 1; haLeft = 2; haRight = 3; haBottom = 4;
  haTopLeft = 5; haTopRight = 6; haBottomLeft = 7; haBottomRight = 8;
    // Aliases
  haXMove = 1; haYMove = 2; haZMove = 3;
  haXRotate = 4; haYRotate = 5; haZRotate = 6;

type
  TFitterOpParams = record
    X, Y, Width, Height: Single;
  end;

  TGUIFitterOp = class(Models.TOperation)
  private
    AffectedGUIItem: TGUIItem;
    Params: TFitterOpParams;
  protected
    procedure DoApply; override;
    function DoMerge(AOperation: Models.TOperation): Boolean; override;
  public
    function Init(AAffectedGUIItem: TGUIItem; AX, AY, AWidth, AHeight: Single): Boolean;
  end;

  TFitter = class(TGUIItem)
  protected
    HoverArea: Integer;
    PushX, PushY: Single;
    Areas: array of BaseTypes.TArea;
    RoundShift: Single;                                              // A value used to draw "rounded" hot spots
    procedure BuildAreas; virtual; abstract;
    procedure HandleMove(AX, AY: Single); virtual; abstract;
    function GetAffectedItem: TItem; virtual; abstract;
    procedure SetAffectedItem(const Value: TItem); virtual; abstract;
  public
    UseOperations: Boolean;
    DefaultSize: Single;
    constructor Create(AManager: TItemsManager); override;

    function IsWithin(AX, AY: Single): Boolean; override;

    procedure ResetFitter; virtual;

    property AffectedItem: TItem read GetAffectedItem write SetAffectedItem;
  end;

  T2DFitter = class(TFitter)
  private
    XSize, YSize: Single;
  protected
    procedure BuildAreas; override;
    procedure HandleMove(AX, AY: Single); override;
    function GetAffectedItem: TItem; override;
    procedure SetAffectedItem(const Value: TItem); override;
  public
    AffectedGUIItem: TGUIItem;
    GridX, GridY: Integer;
    constructor Create(AManager: TItemsManager); override;
    destructor Destroy; override;

    function GUIHandleMessage(const Msg: TMessage): Boolean; override;
    procedure Draw; override;
  end;

implementation

{ TFitter }

constructor TFitter.Create(AManager: TItemsManager);
var i: Integer;
begin
  inherited;
  DefaultSize := 8.0;
  SetLength(Areas, 9);
  for i := 0 to High(Areas) do Areas[i] := GetArea(-1, -1, -1, -1);
  HoverArea := -1;
  RoundShift := 2;
end;

function TFitter.IsWithin(AX, AY: Single): Boolean;
var i: Integer;
begin
  ScreenToClient(AX, AY);
  i := High(Areas);
  while (i >= 0) and not IsInArea(AX, AY, Areas[i]) do Dec(i);
  Result := i >= 0; 
end;

procedure TFitter.ResetFitter;
// Resets fitter's state. Used if the fitter is unable to receive all messages (e.g. TGUIMouseUp)
begin
  HoverArea := -1;
  FFocused  := False;
  Hover     := False;
  Pushed    := False;
end;

{ T2DFitter }

procedure T2DFitter.BuildAreas;
begin
  XSize := MaxS(2, MinS(DefaultSize, Width/4));
  YSize := MaxS(2, MinS(DefaultSize, Height/4));

  Areas[haCenter]      := GetArea((Width-XSize)*0.5, (Height-YSize)*0.5, (Width+XSize)*0.5, (Height+YSize)*0.5);
  Areas[haTop]         := GetArea((Width-XSize)*0.5, 0,                  (Width+XSize)*0.5, YSize);
  Areas[haLeft]        := GetArea(0,                 (Height-YSize)*0.5, XSize,             (Height+YSize)*0.5);
  Areas[haRight]       := GetArea(Width-XSize,       (Height-YSize)*0.5, Width,             (Height+YSize)*0.5);
  Areas[haBottom]      := GetArea((Width-XSize)*0.5, Height-YSize,       (Width+XSize)*0.5, Height);
  Areas[haTopLeft]     := GetArea(0,                 0,                  XSize,             YSize);
  Areas[haTopRight]    := GetArea(Width-XSize,       0,                  Width,             YSize);
  Areas[haBottomLeft]  := GetArea(0,                 Height-YSize,       XSize,             Height);
  Areas[haBottomRight] := GetArea(Width-XSize,       Height-YSize,       Width,             Height);
end;

procedure T2DFitter.HandleMove(AX, AY: Single);
var t: Single; Op: TGUIFitterOp;
begin
//  OldX := X;
//  OldY := Y;

  AX := MaxS(-MaxInt, MinS(MaxInt, AX));
  AY := MaxS(-MaxInt, MinS(MaxInt, AY));
  AX := Frac(AX) + Trunc(AX) div GridX * GridX;
  AY := Frac(AY) + Trunc(AY) div GridY * GridY;

  if (AX = PushX) and (AY = PushY) then Exit;
  if HoverArea = haCenter then begin                                        // Center hot area
    X := X + (AX - PushX);
    Y := Y + (AY - PushY);
  end;

  if HoverArea in [haTop, haTopLeft, haTopRight] then begin                 // Top hot areas
    t := Height;
    Height := Height - (AY - PushY);
    Height := Frac(Height) + Trunc(Height) div GridY * GridY - Trunc(Y) mod GridY;
    Y := Y + (t - Height);
  end;
  if HoverArea in [haLeft, haTopLeft, haBottomLeft] then begin              // Left hot areas
    t := Width;
    Width := Width - (AX - PushX);
    Width := Frac(Width) + Trunc(Width) div GridX * GridX - Trunc(X) mod GridX;
    X := X + (t - Width);
  end;

  if HoverArea in [haRight, haTopRight, haBottomRight] then begin           // Right hot areas
    Width := Width + (AX - PushX);
    Width := Frac(Width) + Trunc(Width) div GridX * GridX - Trunc(X) mod GridX;
    PushX := Width - GridX;// - Trunc(X) mod GridX;
    //AX - Trunc(X) mod GridX;
  end;
  if HoverArea in [haBottom, haBottomLeft, haBottomRight] then begin        // Bottom hot areas
    Height := Height + (AY - PushY);
    Height := Frac(Height) + Trunc(Height) div GridY * GridY - Trunc(Y) mod GridY;
    PushY := Height - GridY;
  end;

  if HoverArea in [haCenter, haLeft, haTopLeft, haBottomLeft] then          // Snap X to grid
    X := Frac(X) + Trunc(X) div GridX * GridX;
  if HoverArea in [haCenter, haTop, haTopLeft, haTopRight] then             // Snap Y to grid
    Y := Frac(Y) + Trunc(Y) div GridY * GridY;

  if Assigned(AffectedItem) then
    if UseOperations then begin
      Op := TGUIFitterOp.Create;
      if Op.Init(AffectedGUIItem, X, Y, Width, Height) then
        SendMessage(TOperationMsg.Create(Op), nil, [mfCore])
      else
        Op.Free;
    end else begin
      AffectedGUIItem.PxWidth  := Width;
      AffectedGUIItem.PxHeight := Height;
      AffectedGUIItem.PxX      := X;//AffectedGUIItem.PxX + (X - OldX);
      AffectedGUIItem.PxY      := Y;//AffectedGUIItem.PxY + (Y - OldY);
    end;
end;

function T2DFitter.GetAffectedItem: TItem;
begin
  Result := AffectedGUIItem;
end;

procedure T2DFitter.SetAffectedItem(const Value: TItem);
begin
  if Value is TGUIItem then begin
    AffectedGUIItem := Value as TGUIItem;
    Parent := AffectedGUIItem.Parent;
{    Parent := nil;
    AffectedGUIItem.Parent.InsertChild(Self, 0);}
  end else begin
     Log(ClassName + '.SetAffectedItem: Affected item is not a TGUIItem', lkError); 
  end;
end;

constructor T2DFitter.Create(AManager: TItemsManager);
begin
  inherited;
  GridX := 10;
  GridY := 10;
  Align := alAbsolute;
end;

destructor T2DFitter.Destroy;
begin
  Areas := nil;
  inherited;
end;

procedure T2DFitter.Draw;
var i: Integer;
begin
  inherited;
  BuildAreas;
  Screen.SetColor(NormalColor);
  for i := haCenter to haBottomRight do if i <> HoverArea then
    Screen.Bar(Areas[i].X1, Areas[i].Y1, Areas[i].X2, Areas[i].Y2);
  Screen.SetColor(Color);
  if HoverArea <> -1 then
    Screen.Bar(Areas[HoverArea].X1, Areas[HoverArea].Y1, Areas[HoverArea].X2, Areas[HoverArea].Y2);
end;

function T2DFitter.GUIHandleMessage(const Msg: TMessage): Boolean;
var OMX, OMY: Integer; MX, MY: Single; Processed: Boolean;
begin
  if Msg is TMouseMsg then with TMouseMsg(Msg) do begin
    OMX := X; OMY := Y;
    MX := X; MY := Y;
    ScreenToClient(MX, MY);
  end else begin
    OMX := 0; OMY := 0;
  end;  
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;
  if Msg is TMouseMsg then with TMouseMsg(Msg) do begin
    Processed := False;
    if (Msg.ClassType = TMouseDownMsg) then begin
      if Hover then begin
        if kmOS in ModifierState then AffectedGUIItem := TGUIItem(AffectedGUIItem.Clone());
        
        PushX := Frac(MX) + Trunc(MX) div GridX * GridX;
        PushY := Frac(MY) + Trunc(MY) div GridY * GridY;
        Processed := True;
      end;
    end else if (Msg.ClassType = TMouseMoveMsg) then begin
      Processed := True;
      if Pushed then HandleMove(MX, MY) else begin
        HoverArea := haCenter;
        while (HoverArea <= haBottomRight) and not IsInArea(MX, MY, Areas[HoverArea]) do Inc(HoverArea);
        Processed := HoverArea <= haBottomRight;
        if not Processed then HoverArea := -1;
      end;
    end;
    if not Processed then begin                           // Restore mouse coordinates to allow the message handling by other controls
      X := OMX;
      Y := OMY;
    end;
  end;
end;

{ TGUIFitterOp }

procedure TGUIFitterOp.DoApply;
var t: Single;
begin
  t                        := AffectedGUIItem.PxWidth;
  AffectedGUIItem.PxWidth  := Params.Width;
  Params.Width             := t;

  t                        := AffectedGUIItem.PxHeight;
  AffectedGUIItem.PxHeight := Params.Height;
  Params.Height            := t;

  t                        := AffectedGUIItem.PxX;
  AffectedGUIItem.PxX      := Params.X;
  Params.X                 := t;

  t                        := AffectedGUIItem.PxY;
  AffectedGUIItem.PxY      := Params.Y;
  Params.Y                 := t;
end;

function TGUIFitterOp.DoMerge(AOperation: TOperation): Boolean;
begin
  Result := (AOperation is TGUIFitterOp) and (TGUIFitterOp(AOperation).AffectedGUIItem = AffectedGUIItem);
  if Result and not (ofApplied in Flags) then Params := TGUIFitterOp(AOperation).Params;
end;

function TGUIFitterOp.Init(AAffectedGUIItem: TGUIItem; AX, AY, AWidth, AHeight: Single): Boolean;
begin
  Assert(Assigned(AAffectedGUIItem));
  Result := False;
  if (AAffectedGUIItem.X = AX) and (AAffectedGUIItem.Y = AY) and (AAffectedGUIItem.Width = AWidth) and (AAffectedGUIItem.Height = AHeight) then Exit;

  AffectedGUIItem := AAffectedGUIItem;
  Params.X        := AX;
  Params.Y        := AY;
  Params.Width    := AWidth;
  Params.Height   := AHeight;

  Result := True;
end;

end.
