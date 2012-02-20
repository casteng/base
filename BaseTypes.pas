(*
 @Abstract(Base types unit)
 (C) 2007 George "Mirage" Bakhtadze <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Created: Apr 09, 2007 <br>
 Unit contains most basic types
*)
{$Include GDefines.inc}
unit BaseTypes;

interface

const
  // Number of bits in a byte
  BitsInByte = 8;
  // Degrees to radians multiplier
  DegToRad   = pi/180;
  // Radians to degrees multiplier
  RadToDeg   = 180/pi;

  MaxPadeg = 6;

  // Floating point equality check precision
  epsilon = 0.0001;
  // Max single precision floating point value
  MaxFloatValue = 3.4e+38;

type
    // Platform independent basic types
  // 32-bit signed
  Int32 = Longint;
  // 16-bit signed
  Int16 = SmallInt;
  // 8-bit signed
  Int8  = ShortInt;
  // 32-but unsinged (natural)
  Nat32 = Longword;
  // 16-bit unsigned
  Nat16 = Word;
  // 8-bit unsigned 
  Nat8  = Byte;

    // Platform dependent basic types
  IntNative = Integer;

const
  // Max and mins for signed
  MaxInt32: Int32 =  $7FFFFFFF;
  MinInt32: Int32 = -$7FFFFFFF-1;  // -$80000000
  MaxInt16: Int16 =  $7FFF;
  MinInt16: Int16 = -$8000;
  MaxInt8:  Int8  =  $7F;
  MinInt8:  Int8  = -$80;
  // Max for unsigned
  MaxNat32: Nat32 = $FFFFFFFF;
  MaxNat16: Nat16 = $FFFF;
  MaxNat8:  Nat8  = $FF;

type
  // 32-bit set
  TSet32 = set of 0..31;
  // Globally unique identifier
  TSGUID12 = string[12];
  // File signature
  TFileSignature = array [0..3] of AnsiChar;

  // Type for time values
  TTimeUnit = Double;

  // Command - parameterless procedure method
  TCommand = procedure() of object;

  {$IFNDEF UNICODE}
  // Unicode string type
  UnicodeString = WideString;
  {$ENDIF}

  // Non-localizable name type
  TNameString = AnsiString;
  // Non-localizable short name type
  TShortName = string[31];
  // Non-localizable short message type
  TShortMessage = string[127];
  // File name type
  TFileName = string;

  // Message flag
  TMessageFlag = (// Message has been handled or discarded. No need to handle it anymore.
                  mfInvalid,
                  // Message has a recipient
                  mfRecipient,
                  // Message is a notification message from parent to immediate childs
                  mfChilds,
                  // Message is a broadcasted message from some item down through hierarchy
                  mfBroadcast,
                  // Message's destination is core handle
                  mfCore,
                  // Message is asyncronous
                  mfAsync);
  // Message flag set
  TMessageFlags = set of TMessageFlag;

  // Array of classes
  TClasses = array of TClass;

  // General method pointer
  TDelegate = procedure(Data: Pointer) of object; 
  // Method pointer used by time-consuming routines to report progess in range [0..1]
  TProgressDelegate = procedure(TaskId: TShortName; Progress: Single) of object;

  // Pointer to source code location
  PCodeLocation = ^TCodeLocation;
  // Describes location in code - file, unit, procedure name and line number
  TCodeLocation = record
    // Address of the location. Nil if the record is not initilized or failed to obtain the location info.
    Address: Pointer;
    // Source file name
    SourceFilename: string;
    // Unit name
    UnitName: string;
    // Procedure name
    ProcedureName: string;
    // Line number in source file
    LineNumber: Integer;
  end;
  // Stack trace
  TBaseStackTrace = array of TCodeLocation;

  // Pointer to a two-dimensional vector
  PVector2s = ^TVector2s;
  // Two-dimensional vector
  TVector2s = packed record
    case Integer of
      0: (X, Y: Single);
      1: (V: array[0..1] of Single);
  end;
  // Pointer to a three-dimensional vector
  PVector3s = ^TVector3s;
  // Three-dimensional vector
  TVector3s = packed record
    case Integer of
      0: (X, Y, Z: Single);
      1: (V: array[0..2] of Single);
  end;

  // Four-dimensional (homogeneous) vector
  TVector4s = packed record
    case Integer of
      0: (X, Y, Z, W: Single);
      1: (V: array[0..3] of Single);
      2: (xyz: TVector3s);
  end;

  // Pointer to 32-bit color
  PColor = ^TColor;
  // 32-bit color (A8R8G8B8)
  TColor = packed record
    case Boolean of
      False: (C: Longword);
      True: (B, G, R, A: Byte);
  end;

  // Color with floating-point components
  TColor4s = packed record
  case Integer of
    0: (R, G, B, A: Single;);
    1: (RGB: TVector3s);
    2: (RGBA: TVector4s);
  end;

  TARGB = TColor;
  TARGBInt = packed record B, G, R, A: Integer; end;
  TRGBA = packed record
    case Boolean of
      False: (C: Longword);
      True: (A, B, G, R: Byte);
  end;

  // Palette color
  TPaletteItem = TARGB;
  // Image palette for paletted graphics file formats
  TPalette = array[0..255] of TPaletteItem;
  PPalette = ^TPalette;

  PByteBuffer = ^TByteBuffer;
  PWordBuffer = ^TWordBuffer;
  PSmallintBuffer = ^TSmallintBuffer;

  TByteBuffer     = array[0..$6FFFFFFF] of Byte;
  TWordBuffer     = array[0..$0FFFFFFF] of Word;
  TSmallintBuffer = array[0..$0FFFFFFF] of Smallint;
  TDWordBuffer    = array[0..$0FFFFFFF] of Cardinal;
  TColorBuffer    = array[0..$0FFFFFFF] of TColor;
  TSingleBuffer   = array[0..$0FFFFFFF] of Single;
  TRGBArray       = array[0..$0FFFFFFF] of packed record B, G, R: Byte; end;
  TARGBArray      = array[0..$0FFFFFFF] of TARGB;
  TRGBAArray      = array[0..$0FFFFFFF] of TRGBA;

  TPointerArray    = array of Pointer;
  TAnsiStringArray = array of AnsiString;
  TUnicodeStringArray     = array of UnicodeString;
  TStringArray     = array of String;
  TIndArray        = array of Integer;
  TSingleArray     = array of Single;

  PImageBuffer  = ^TImageBuffer;
  TImageBuffer  = TColorBuffer;
  PDWordBuffer  = ^TDWordBuffer;
  PAnsiStringArray  = ^TAnsiStringArray;
  PSingleBuffer = ^TSingleBuffer;

  // Pointer to @Link(TUV)
  PUV = ^TUV;
  // Rectangular area within a bitmap (texture)  
  TUV = packed record U, V, W, H: Single; end;
  TUVArray = array[0..$FFFFFF] of TUV;
  TUVMap = ^TUVArray;

  // Character map
  TCharMapItem = Longword;
  TCharmapArray = array[0..$FFFFFF] of TCharMapItem;
  TCharMap = ^TCharmapArray;

  // Last pixel convention: not include
  TRect = packed record
    case Integer of
      0:(Left, Top, Right, Bottom: Integer);
      1:(X, Y, W, H: Integer);
      2:(a1, a2, Width, Height: Integer);
  end;
  PRect = ^TRect;

  TRect3D = packed record
    case Integer of
      0:(Left, Top, Right, Bottom, Front, Back: Integer);
      1:(X, Y, W, H: Integer);
      2:(a1, a2, Width, Height: Integer);
  end;
  PRect3D = ^TRect3D;

  TArea = record                                   // Last pixel convention: not include
    X1, Y1, X2, Y2: Single;
  end;
  PArea = ^TArea;

  // Modifier keys
  TKeyModifier  = (// Any CTRL
                   kmControl,
                   // Left CTRL
                   kmLControl,
                   // Right CTRL
                   kmRControl,
                   // Any Shift
                   kmShift,
                   // Left Shift
                   kmLShift,
                   // Right Shift
                   kmRShift,
                   // Any Alt
                   kmAlt,
                   // Left Alt
                   kmLAlt,
                   // Right Alt
                   kmRAlt,
                   // Left Win
                   kmLOS,
                   // Right Win
                   kmROS,
                   // Any Win key
                   kmOS);
  // Modifier keys set
  TKeyModifiers = set of TKeyModifier;

const
  NullSignature: TFileSignature = (#0, #0, #0, #0);
  // Default area on image
  DefaultUV: TUV = (U: 0; V: 0; W: 1; H: 1);
  // Floating point color black
  clBlack4s: TColor4s = (R: 0; G: 0; B: 0; A: 0);
  // Floating point color black
  clWhite4s: TColor4s = (R: 1; G: 1; B: 1; A: 1);
  // Shift key
  skShift: TKeyModifiers = [kmShift, kmLShift, kmRShift];

  // Returns complement to the specified set (bitwise NOT)
  function SetComplement(ASet: TSet32): TSet32; {$I inline.inc}
  // Returns exclusive union (symmetric difference) of the specified sets (bitwise XOR)
  function SetXUnion(ASet1, ASet2: TSet32): TSet32; {$I inline.inc}

  // Returns TColor record
  function GetColor(const R, G, B, A: Byte): TColor; overload; {$I inline.inc}
  // Returns TColor record
  function GetColor(const C: Longword): TColor; overload; {$I inline.inc}
  // Returns TColor4s record
  function GetColor4S(const R, G, B, A: Single): TColor4s; {$I inline.inc}

  // Converts a TColor to TColor4s
  procedure ColorTo4S(var Result: TColor4s; const Color: TColor); overload; {$I inline.inc}
  // Converts a TColor to TColor4s
  function ColorTo4S(const Color: TColor): TColor4s; overload;
  // Converts a TColor to TColor4s
  procedure ColorTo4S(var Result: TColor4s; const Color: Longword); overload; {$I inline.inc}
  // Converts a TColor to TColor4s
  function ColorTo4S(const Color: Longword): TColor4s; overload; {$I inline.inc}
  // Converts RGB color to BGR. Asm version untested
  function RGBReverse(const Color: TColor): TColor;
  // Converts ARGB color to BGRA. Asm version untested  
  function ARGBReverse(const Color: TColor): TColor;

  // Convert time unit to milliseconds
  function TimeUnitToMs(const TimeStamp: TTimeUnit): Int64; {$I inline.inc}

  // Fills the specified rectangle record and returns it in Result
  procedure Rect(ALeft, ATop, ARight, ABottom: Integer; out Result: TRect); {$I inline.inc}
  // Returns the specified by its bounds rectangle record
  function GetRect(ALeft, ATop, ARight, ABottom: Integer): TRect; {$I inline.inc}
  // Returns the specified by width and height rectangle record
  function GetRectWH(ALeft, ATop, AWidth, AHeight: Integer): TRect; {$I inline.inc}
  // Returns the specified by UV coordinates on an image rectangle record
  function GetRectOnImage(UV: TUV; AImageWidth, AImageHeight: Integer): TRect; {$I inline.inc}
  // Returns in Result source rectangle moved by (MoveX, MoveY)
  procedure RectMove(const ARect: TRect; MoveX, MoveY: Integer; out Result: TRect); {$I inline.inc}
  // Returns source rectangle moved by (MoveX, MoveY)
  function GetRectMoved(const ARect: TRect; MoveX, MoveY: Integer): TRect; {$I inline.inc}
  // Returns in Result source rectangle scaled by (SX, SY)
  procedure RectScale(const ARect: TRect; SX, SY: Single; out Result: TRect); {$I inline.inc}
  // Returns source rectangle scaled by (SX, SY)
  function GetRectScaled(const ARect: TRect; SX, SY: Single): TRect; {$I inline.inc}
  // Returns in Result source rectangle expanded by (EX, EY)
  procedure RectExpand(const ARect: TRect; EX, EY: Integer; out Result: TRect); {$I inline.inc}
  // Returns source rectangle expanded by (EX, EY)
  function GetRectExpanded(const ARect: TRect; EX, EY: Integer): TRect; {$I inline.inc}
  // Fills and returns the specified area record
  function GetArea(AX1, AY1, AX2, AY2: Single): TArea; {$I inline.inc}

  // Returns ResTrue if cond and ResFalse otherwise
  function IFF(Cond: Boolean; const ResTrue, ResFalse: string): string; overload; {$I inline.inc}
  // Returns ResTrue if cond and ResFalse otherwise
  function IFF(Cond: Boolean; const ResTrue, ResFalse: Integer): Integer; overload; {$I inline.inc}
  // Returns ResTrue if cond and ResFalse otherwise
  function IFF(Cond: Boolean; const ResTrue, ResFalse: Double): Double; overload; {$I inline.inc}

  // Converts int to string
  function IntToStr(v: Integer): string;

  // Returns base pointer shifted by offset
  function PtrOffs(Base: Pointer; Offset: Integer): Pointer; {$I inline.inc}

  // Returns filled code location structure
  function GetCodeLoc(const ASourceFilename, AUnitName, AProcedureName: string; ALineNumber: Integer; AAddress: Pointer): TCodeLocation;

  // Converts code location to a readable string
  function CodeLocToStr(const CodeLoc: TCodeLocation): string;

  // Returns True if AClass equals or descends from one of classes from the AClasses
  function IsClassFrom(AClass: TClass; AClasses: TClasses): Boolean;
  // Constructs TClasses array from array of classes
  function TClassesFromArrayOf(AClasses: array of TClass): TClasses;

  { Replaces assert error procedure with the specified one.
    Old assert error procedure is save to be restored with AssertRestore.
    Returns True if hook successful or False otherwise.
    Used internally for Assert-based features.
    Thread safe if MULTITHREADASSERT defined. }
  function AssertHook(NewAssertProc: TAssertErrorProc): Boolean;
  { Restores assert error procedure changed by AssertHook.
    Used internally for Assert-based features.
    Thread safe if MULTITHREADASSERT defined. }
  procedure AssertRestore();

implementation

{$IFDEF MULTITHREADASSERT}
  uses SyncObjs;
{$ENDIF}

function SetComplement(ASet: TSet32): TSet32;
begin
  Result := [0..31] - ASet;
end;
                                                                 // (x or y) and not (x and y)      not x and y
function SetXUnion(ASet1, ASet2: TSet32): TSet32;
begin
  Result := (ASet1 + ASet2) * ([0..31] - (ASet1 * ASet2));
end;

function GetColor(const R, G, B, A: Byte): TColor;
begin
  Result.R := R; Result.G := G; Result.B := B; Result.A := A;
end;

function GetColor(const C: Longword): TColor;
begin
  Result.C := C;
end;

function GetColor4S(const R, G, B, A: Single): TColor4s;
begin
  Result.B := B; Result.G := G; Result.R := R; Result.A := A;
end;

procedure ColorTo4S(var Result: TColor4s; const Color: TColor); overload;
const Norm = 1/255;
begin
  Result.B :=  (Color.C and 255) * Norm;
  Result.G := ((Color.C shr 8)  and 255) * Norm;
  Result.R := ((Color.C shr 16) and 255) * Norm;
  Result.A :=  (Color.C shr 24) * Norm;
end;

function ColorTo4S(const Color: TColor): TColor4s;
begin
  ColorTo4S(Result, Color);
end;

procedure ColorTo4S(var Result: TColor4s; const Color: Longword); overload;
begin
  ColorTo4S(Result, TColor(Color));
end;

function ColorTo4S(const Color: Longword): TColor4s; overload;
begin
  ColorTo4S(Result, TColor(Color));
end;

function ARGBReverse(const Color: TColor): TColor;
{$IFDEF PUREPASCAL}
begin
  Result.A := Color.B;
  Result.R := Color.G;
  Result.G := Color.R;
  Result.B := Color.A;
end;
{$ELSE}
asm
  BSWAP EAX
end;
{$ENDIF}

function RGBReverse(const Color: TColor): TColor;
{$IFDEF PUREPASCAL}
begin
  Result.R := Color.B;
  Result.G := Color.G;
  Result.B := Color.R;
end;
{$ELSE}
asm
 BSWAP EAX;
 ROR EAX, 8
end;
{$ENDIF}

procedure Rect(ALeft, ATop, ARight, ABottom: Integer; out Result: TRect);
begin
  with Result do begin
    Left := ALeft; Top := ATop;
    Right:= ARight; Bottom := ABottom;
  end;
end;

function TimeUnitToMs(const TimeStamp: TTimeUnit): Int64;
begin
  Result := Round(TimeStamp*1000);
end;

function GetRect(ALeft, ATop, ARight, ABottom: Integer): TRect;
begin
  Rect(ALeft, ATop, ARight, ABottom, Result);
end;

function GetRectWH(ALeft, ATop, AWidth, AHeight: Integer): TRect;
begin
  Rect(ALeft, ATop, ALeft + AWidth, ATop + AHeight, Result);
end;

function GetRectOnImage(UV: TUV; AImageWidth, AImageHeight: Integer): TRect;
begin
  with Result do begin
    Left   := Trunc(0.5 + UV.U * AImageWidth);
    Top    := Trunc(0.5 + UV.V * AImageHeight);
    Right  := Left + Trunc(0.5 + UV.W * AImageWidth);
    Bottom := Top  + Trunc(0.5 + UV.H * AImageHeight);
  end;
end;

procedure RectMove(const ARect: TRect; MoveX, MoveY: Integer; out Result: TRect);
begin
  Result.Left   := ARect.Left   + MoveX;
  Result.Top    := ARect.Top    + MoveY;
  Result.Right  := ARect.Right  + MoveX;
  Result.Bottom := ARect.Bottom + MoveY;
end;

function GetRectMoved(const ARect: TRect; MoveX, MoveY: Integer): TRect;
begin
  RectMove(ARect, MoveX, MoveY, Result);
end;

procedure RectScale(const ARect: TRect; SX, SY: Single; out Result: TRect);
begin
  Result.Left   := Round(ARect.Left   * SX);
  Result.Top    := Round(ARect.Top    * SY);
  Result.Right  := Round(ARect.Right  * SX);
  Result.Bottom := Round(ARect.Bottom * SY);
end;

function GetRectScaled(const ARect: TRect; SX, SY: Single): TRect;
begin
  RectScale(ARect, SX, SY, Result);
end;

procedure RectExpand(const ARect: TRect; EX, EY: Integer; out Result: TRect);
begin
  Result.Left   := ARect.Left   - EX;
  Result.Top    := ARect.Top    - EY;
  Result.Right  := ARect.Right  + EX;
  Result.Bottom := ARect.Bottom + EY;
end;

function GetRectExpanded(const ARect: TRect; EX, EY: Integer): TRect;
begin
  RectExpand(ARect, EX, EY, Result);
end;

function GetArea(AX1, AY1, AX2, AY2: Single): TArea;
begin
  with Result do begin
    X1 := AX1; Y1 := AY1;
    X2 := AX2; Y2 := AY2;
  end;
end;

function IntToStr(v: Integer): string;
var s: ShortString;
begin
  Str(v, s);
  Result := string(s);
end;

function PtrOffs(Base: Pointer; Offset: Integer): Pointer; {$I inline.inc}
begin
  Result := Base;
  Inc(PByte(Result), Offset);
end;

function IFF(Cond: Boolean; const ResTrue, ResFalse: string): string; overload; {$I inline.inc}
begin
  if Cond then Result := ResTrue else Result := ResFalse;
end;

function IFF(Cond: Boolean; const ResTrue, ResFalse: Integer): Integer; overload; {$I inline.inc}
begin
  if Cond then Result := ResTrue else Result := ResFalse;
end;
function IFF(Cond: Boolean; const ResTrue, ResFalse: Double): Double; overload; {$I inline.inc}
begin
  if Cond then Result := ResTrue else Result := ResFalse;
end;

function GetCodeLoc(const ASourceFilename, AUnitName, AProcedureName: string; ALineNumber: Integer; AAddress: Pointer): TCodeLocation;
begin
  Result.Address        := AAddress;
  Result.SourceFilename := ASourceFilename;
  Result.UnitName       := AUnitName;
  Result.ProcedureName  := AProcedureName;
  Result.LineNumber     := ALineNumber;
end;

function CodeLocToStr(const CodeLoc: TCodeLocation): string;
begin
  Result := IFF(CodeLoc.UnitName <> '', CodeLoc.UnitName + '.', '') + CodeLoc.ProcedureName
          + '(' + IFF(CodeLoc.SourceFilename <> '', CodeLoc.SourceFilename, 'Unknown source') + ':'
          + IFF(CodeLoc.LineNumber > 0, IntToStr(CodeLoc.LineNumber), '-') + ')';
end;

function IsClassFrom(AClass: TClass; AClasses: TClasses): Boolean;
var i: Integer;
begin
  i := High(AClasses);
  while (i >= 0) and not (AClass.InheritsFrom(AClasses[i])) do Dec(i);
  Result := i >= 0;
end;

function TClassesFromArrayOf(AClasses: array of TClass): TClasses;
var i: Integer;
begin
  SetLength(Result, Length(AClasses));
  for i := 0 to High(AClasses) do Result[i] := AClasses[i];
end;

var
  StoredAssertProc: TAssertErrorProc = nil;
  {$IFDEF MULTITHREADASSERT}
    AssertCriticalSection: TCriticalSection;
  {$ENDIF}

function AssertHook(NewAssertProc: TAssertErrorProc): Boolean;
begin
  Assert(@StoredAssertProc = nil, 'Assert already hooked');
  {$IFDEF MULTITHREADASSERT}
    AssertCriticalSection.Enter();
  {$ENDIF}
  StoredAssertProc := AssertErrorProc;
  AssertErrorProc  := NewAssertProc;
  Result := True;
end;

procedure AssertRestore();
begin
  AssertErrorProc := StoredAssertProc;
  StoredAssertProc := nil;
  {$IFDEF MULTITHREADASSERT}
    AssertCriticalSection.Leave();
  {$ENDIF}
end;

{$IFDEF MULTITHREADASSERT}
  initialization
    AssertCriticalSection := TCriticalSection.Create();
  finalization
    AssertCriticalSection.Free();
{$ENDIF}
end.
