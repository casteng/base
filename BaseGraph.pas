(*
 @Abstract(Base Graphics Unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains abstract classes for drawing 2D graphics
*)
{$Include GDefines.inc}
unit BaseGraph;

interface

uses
  Logger,
  BaseTypes, Basics, BaseClasses, Base3D, BaseMsg;

const
  // Initial Z value for 2D primitives
  ClearingZ = 0.9999;

type
  // Font style flags
  TFontStyleFlags = (fsBold, fsItalic, fsUnderline, fsStrikeOut);
  // Font style
  TFontStyle = set of TFontStyleFlags;

  // Graphics-related messages base class
  TGraphMessage = class(TMessage)
  end;

  // 2D transformations class
  T2DTransform = Base3D.TMatrix4s;                       // ToDo: Reduce to 3x3 or 2x2?

  // Rectangular viewport
  TViewport = record
    Left, Top, Right, Bottom: Single;
  end;

  // Base font class
  TFont = class(BaseClasses.TItem)
    // Font face name
    FaceName: string;
    // Font style
    Style: TFontStyle;
    // Font size
    Size: Single;
    // Fills <b>Width</b> and <b>Height</b> with width and height of the given string printed with the font
    procedure GetTextExtent(const Text: string; out Width, Height: Single); virtual; abstract;
  end;

  // Base class for bitmap (texture) based font
  TBaseBitmapFont = class(TFont)
    // UV map which points to character images on the texture
    UVMap: BaseTypes.TUVMap;
    // Number of entries in the UV map
    TotalUVs: Longword;
    // Code to character map
    CharMap: BaseTypes.TCharMap;
    // Total characters
    TotalCharacters: Longword;
    // Format of the bitmap (texture)
    BitmapFormat: Integer;
    // Bitmap data pointer
    Bitmap: Pointer;
    // Scale of the font by X
    XScale: Single;
    // Scale of the font by Y
    YScale: Single;
    constructor Create(AManager: BaseClasses.TItemsManager); override;
    // Sets UV and character maps
    procedure SetMapResources(const AUVMap: BaseTypes.TUVMap; ATotalUVs: Integer; const ACharMap: BaseTypes.TCharMap; ATotalCharacters: Integer); virtual;
    // Sets scale
    procedure SetScale(AXScale, AYScale: Single); virtual;
    procedure GetTextExtent(const Text: string; out Width, Height: Single); override;
  end;

  // True type font class
  TTrueTypeFont = class(TFont)
    Charset: Integer;
    Monospaced: Boolean;
  end;

  // Bitmap class
  TBitmap = class
    // Bitmap width
    Width: Integer;
    // Bitmap height
    Height: Integer;
    // Bitmap data pointer
    Data: Pointer;
  end;

  // Base class to handle 2D output
  TScreen = class(TSubsystem)
  private
    // Screen width
    FWidth: Single;
    // Screen height
    FHeight: Single;
  public
    // Current drawing color
    Color: BaseTypes.TColor;
    // Current drawing font
    Font: TFont;
    // Current drawing UV map
    UV: BaseTypes.TUV;
    // Current drawing bitmap
    Bitmap: TBitmap;
    // Current position by X
    CurrentX,
    // Current position by Y
    CurrentY,
    // Current position by X in local corrdinate system
    LocalX,
    // Current position by Y in local corrdinate system
    LocalY: Single;
    // Current position by Z (depth) (used for correct primitive order imitation via zbuffer)
    CurrentZ: Single;

    // Current transform. Point of origin, rotation, scaling
    Transform: T2DTransform;
    // Current clipping viewport in local coordinates
    Viewport: TViewport;
    constructor Create;
    // Resets the screen
    procedure Reset; virtual;
    // Message handler
    procedure HandleMessage(const Msg: TMessage); override;

    // Set current viewport
    procedure SetViewport(ALeft, ATop, ARight, ABottom: Single);
    // Transforms a point with current transform
    procedure TransformPoint(var X, Y: Single); {$I inline.Inc}
    // Transforms a point without translation
    procedure RotateScalePoint(var X, Y: Single);
    // Transforms a point with the given transform
    procedure TransformPointWith(const ATransform: T2DTransform; var X, Y: Single);
    // Transforms a point with the given transform without translation
    procedure RotateScalePointWith(const ATransform: T2DTransform; var X, Y: Single);

    // Set current drawing color
    procedure SetColor(const AColor: BaseTypes.TColor);
    // Set current font
    procedure SetFont(const AFont: TFont); virtual;
    // Set current UV frame
    procedure SetUV(const AUV: BaseTypes.TUV);
    // Set current bitmap
    procedure SetBitmap(const ABitmap: TBitmap);

    // Moves current position
    procedure MoveTo(const X, Y: Single); virtual;
    // Draws a line from current position to the given point and moves current position to the given point
    procedure LineTo(const X, Y: Single); virtual; abstract;
    // Moves current position
    procedure MoveToVec(const Vec: TVector3s);
    // Draws a line from current position to the given point and moves current position to the given point
    procedure LineToVec(const Vec: TVector3s); 
    // Draws a line between the given points
    procedure Line(X1, Y1, X2, Y2: Single); virtual;
    // Draws a rectangle with the given coordinates
    procedure Rectangle(X1, Y1, X2, Y2: Single); virtual;
    // Draws a filled rectangle with the given coordinates
    procedure Bar(X1, Y1, X2, Y2: Single); virtual; abstract;

    // Draw the given text string at current position
    procedure PutText(const Str: string); virtual; abstract;
    // Draw the given text string at the specified position
    procedure PutTextXY(const X, Y: Single; const Str: string); virtual; abstract;

    // Resets current viewport and transform
    procedure ResetViewport; virtual;

    // Clears and resets the screen
    procedure Clear; virtual;

    // Screen width
    property Width: Single read FWidth;
    // Screen height
    property Height: Single read FHeight;
  end;

  // Returns list of classes introduced by the unit
  function GetUnitClassList: TClassArray;
  // Clips the given line with Cohen-Sutherland algorithm and returns True if at least some part of the line is visible
  function ClipLine(var X1, Y1: Single; var X2, Y2: Single; VPLeft, VPTop, VPRight, VPBottom: Single): Boolean;
  // Clips the given colored and textured line with Cohen-Sutherland algorithm and returns True if at least some part of the line is visible
  function ClipLineColorTex(var X1, Y1, U1, V1: Single; var Color1: BaseTypes.TColor; var X2, Y2, U2, V2: Single; var Color2: BaseTypes.TColor; VPLeft, VPTop, VPRight, VPBottom: Single): Boolean;

var
  // Screen reference which should be used for 2D output
  Screen: TScreen;

implementation

function GetUnitClassList: TClassArray;
begin
  Result := GetClassList([TFont]);
end;

function ClipLineColorTex(var X1, Y1, U1, V1: Single; var Color1: BaseTypes.TColor; var X2, Y2, U2, V2: Single; var Color2: BaseTypes.TColor; VPLeft, VPTop, VPRight, VPBottom: Single): Boolean;
begin
  Result := ClipLine(X1, Y1, X2, Y2, VPLeft, VPTop, VPRight, VPBottom);
end;

function ClipLine(var X1, Y1: Single; var X2, Y2: Single; VPLeft, VPTop, VPRight, VPBottom: Single): Boolean;

  function GetCode(X, Y: Single): Integer;
  begin
    Result := Ord(X < VPLeft)       or Ord(X > VPRight)  shl 1 or
              Ord(Y < VPTop)  shl 2 or Ord(Y > VPBottom) shl 3;
  end;

var i, t, Code1, Code2, SwCount: Integer; DX, DY, DXDY, DYDX, ts: Single;

begin
  Code1 := GetCode(X1, Y1);
  Code2 := GetCode(X2, Y2);

  Result := True;
  if Code1 or Code2 = 0 then Exit;                                      // Completely visible
  Result := False;
  if Code1 and Code2 <> 0 then Exit;                                    // Completely invisible

  DX := X2 - X1;
  DY := Y2 - Y1;
  DYDX := 0;
  DXDY := 0;
  if DX <> 0 then DYDX := DY / DX else if dy = 0 then Exit;
  if DY <> 0 then DXDY := DX / DY;

  SwCount := 0;
  i := 4;
  repeat
    if Code1 and Code2 <> 0 then begin Result := False; Break; end;     // Invisible
    if Code1 or Code2 = 0 then begin Result := True; Break; end;        // Visible

    if Code1 = 0 then begin
      t := Code1; Code1 := Code2; Code2 := t;                           // Swap Code1 and Code2
      ts := X1; X1 := X2; X2 := ts;
      ts := Y1; Y1 := Y2; Y2 := ts;
      Inc(SwCount);
    end;

    if Code1 and 1 > 0 then begin                                       // Check intersection with the left side
       Y1 := Y1 + DYDX * (VPLeft - X1);
       X1 := VPLeft;
    end else if Code1 and 2 > 0 then begin                              // Check intersection with the right side
       Y1 := Y1 + DYDX * (VPRight - X1);
       X1 := VPRight;
    end else if Code1 and 4 > 0 then begin                              // Check intersection with the top side
       X1 := X1 + DXDY * (VPTop - Y1);
       Y1 := VPTop;
    end else if Code1 and 8 > 0 then begin                              // Check intersection with the bottom side
       X1 := X1 + DXDY * (VPBottom - Y1);
       Y1 := VPBottom;
    end;
    Code1 := GetCode(X1, Y1);                                           // Recalculate the code
    Dec(i);
  until i = 0;

  if Odd(SwCount) then begin
    ts := X1; X1 := X2; X2 := ts;
    ts := Y1; Y1 := Y2; Y2 := ts;
  end;
end;

{ TBitmapFont }

constructor TBaseBitmapFont.Create(AManager: BaseClasses.TItemsManager);
begin
  inherited;
  TotalUVs := 0; TotalCharacters := 0;
  UVMap := nil; CharMap := nil;
  SetScale(128, 128);
end;

procedure TBaseBitmapFont.SetMapResources(const AUVMap: BaseTypes.TUVMap; ATotalUVs: Integer; const ACharMap: BaseTypes.TCharMap; ATotalCharacters: Integer);
begin
  TotalUVs := ATotalUVs;
  UVMap := AUVMap;
  TotalCharacters := ATotalCharacters;
  CharMap := ACharMap;
end;

procedure TBaseBitmapFont.SetScale(AXScale, AYScale: Single);
begin
  XScale := AXscale; YScale := AYScale;
end;

procedure TBaseBitmapFont.GetTextExtent(const Text: string; out Width, Height: Single);
var i: Integer; UV: BaseTypes.TUV;
begin
  Width := 0; Height := 0;

  if (UVMap = nil) or (CharMap = nil) then begin
     Log(ClassName + '.GetTextExtent: UV map or character map resource is invalid', lkError); 
    Exit;
  end;

  for i := 0 to Length(Text)-1 do begin
    UV := UVMap^[CharMap^[Ord(Text[i+1])]];
    Width := Width + UV.W;
    if Height < UV.H then Height := UV.H;
  end;

  Width  := Width  * XScale;
  Height := Height * YScale;
end;

{ TScreen }

constructor TScreen.Create;
begin
  inherited;
  Reset;
end;

procedure TScreen.Reset;
begin
  ResetViewport;
  Font     := nil;
  Color.C  := $FFFFFFFF;
  CurrentX := 0;
  CurrentY := 0;
  LocalX   := 0;
  LocalY   := 0;
  CurrentZ := ClearingZ;
  UV       := DefaultUV;
end;

procedure TScreen.HandleMessage(const Msg: TMessage);
begin
  if Msg.ClassType = TWindowResizeMsg then with TWindowResizeMsg(Msg) do begin
    FWidth  := NewWidth;
    FHeight := NewHeight;
  end;
end;

procedure TScreen.SetViewport(ALeft, ATop, ARight, ABottom: Single);
begin
  Viewport.Left      := ALeft;
  Viewport.Top       := ATop;
  Viewport.Right     := ARight;
  Viewport.Bottom    := ABottom;
end;

procedure TScreen.TransformPoint(var X, Y: Single);
//var V: TVector4s;                       // ToDo: Optimize (eliminate) it.
var t: Single;
begin
//  V := GetVector4s(X, Y, 0, 1);
//  V := Transform4Vector4s(Transform, V);
//  X := V.X; Y := V.Y;
  t := X;
  X := X * Transform._11 + Y * Transform._21 + Transform._41;
  Y := t * Transform._12 + Y * Transform._22 + Transform._42;
end;

procedure TScreen.RotateScalePoint(var X, Y: Single);
var V: TVector3s;                       // ToDo: Optimize (eliminate) it.
begin
  V := GetVector3s(X, Y, 0);
  V := Transform3Vector3s(CutMatrix3s(Transform), V);
  X := V.X; Y := V.Y;
end;

procedure TScreen.TransformPointWith(const ATransform: T2DTransform; var X, Y: Single);
var V: TVector4s;                       // ToDo: Optimize (eliminate) it.
begin
  V := GetVector4s(X, Y, 0, 1);
  V := Transform4Vector4s(ATransform, V);
  X := V.X; Y := V.Y;
end;

procedure TScreen.RotateScalePointWith(const ATransform: T2DTransform; var X, Y: Single);
var V: TVector3s;                       // ToDo: Optimize (eliminate) it.
begin
  V := GetVector3s(X, Y, 0);
  V := Transform3Vector3s(CutMatrix3s(ATransform), V);
  X := V.X; Y := V.Y;
end;

procedure TScreen.SetColor(const AColor: BaseTypes.TColor);
begin
  Color := AColor;
end;

procedure TScreen.SetFont(const AFont: TFont);
begin
  Font := AFont;
end;

procedure TScreen.SetUV(const AUV: BaseTypes.TUV);
begin
  UV := AUV;
end;

procedure TScreen.SetBitmap(const ABitmap: TBitmap);
begin
  Bitmap := ABitmap;
end;

procedure TScreen.MoveTo(const X, Y: Single);
begin
  LocalX := X; LocalY := Y;
  CurrentX := X; CurrentY := Y;
//  TransformPoint(CurrentX, CurrentY);
end;

procedure TScreen.Line(X1, Y1, X2, Y2: Single);
begin
  MoveTo(X1, Y1);
  LineTo(X2, Y2);
end;

procedure TScreen.Rectangle(X1, Y1, X2, Y2: Single);
begin
  MoveTo(X1, Y1);
  LineTo(X2, Y1);
  LineTo(X2, Y2);
  LineTo(X1, Y2);
  LineTo(X1, Y1);
end;

procedure TScreen.ResetViewport;
begin
  Transform := IdentityMatrix4s;
  SetViewport(0, 0, Width, Height);
end;

procedure TScreen.Clear;
begin
  ResetViewport;
end;

procedure TScreen.LineToVec(const Vec: TVector3s);
begin
  LineTo(Vec.X, Vec.Y);
end;

procedure TScreen.MoveToVec(const Vec: TVector3s);
begin
  MoveTo(Vec.X, Vec.Y);
end;

begin
  GlobalClassList.Add('BaseGraph', GetUnitClassList);
end.