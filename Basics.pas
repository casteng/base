(*
 @Abstract(Basic utilities unit)
 (C) 2003-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains basic utilities, constants and types
*)
{$Include GDefines.inc}
unit Basics;

interface

uses BaseMsg, BaseTypes, SysUtils;

const
  // Minimum capacity of reference counted container
  MinRefCContainerLength = 8;

//  feOK = 0; feNotFound = -1; feCannotRead = -2; feCannotWrite = -3; feInvalidFileFormat = -4; feCannotSeek = -5; feCannotOpen = -6;
  // File usage: do not open
  fuDoNotOpen = 0;
  // File usage: open to read 
  fuRead = 1;
  // File usage: open to read and write
  fuReadWrite = 2;
  // File usage: open to write
  fuWrite = 3;
  // File usage: open to append
  fuAppend = 4;
  
  // File sharing mode: allow all operations
  smAllowAll = 0;
  // File sharing mode: allow read
  smAllowRead = 1;
  // File sharing mode: do not allow anything (exlusive)
  smExclusive = 2;

  // 1.0 floating point value in integer representation
  OneAsInt: LongWord = $3F800000;
  OneAsInt2: LongWord = $3F800000 shl 1;
  OneOver100 = 1/100;

    // Pixel formats
  // Number of known pixel formats
  TotalPixelFormats = 40;
  // Known pixel formats should be in sync with BaseStr.PixelFormatsEnum
  pfUndefined    = 0;  pfR8G8B8   = 1;  pfA8R8G8B8 = 2;  pfX8R8G8B8 = 3;
  pfR5G6B5       = 4;  pfX1R5G5B5 = 5;  pfA1R5G5B5 = 6;  pfA4R4G4B4 = 7;
  pfA8           = 8;  pfX4R4G4B4 = 9;  pfA8P8     = 10; pfP8       = 11; pfL8     = 12; pfA8L8      = 13; pfA4L4 = 14;
  pfV8U8         = 15; pfL6V5U5   = 16; pfX8L8V8U8 = 17; pfQ8W8V8U8 = 18; pfV16U16 = 19; pfW11V11U10 = 20;
  pfD16_LOCKABLE = 21; pfD32      = 22; pfD15S1    = 23; pfD24S8    = 24; pfD16    = 25; pfD24X8     = 26; pfD24X4S4 = 27;
  pfB8G8R8       = 28; pfR8G8B8A8 = 29; pfA1B5G5R5 = 30;
  pfReserved1    = 31; pfReserved2 = 32; pfReserved3 = 33; pfReserved4= 34;
  pfATIDF16      = 35; pfATIDF24  = 36;
  pfDXT1         = 37;
  pfDXT3         = 38;
  pfDXT5         = 39;
  pfAuto         = $FFFFFFFF;

  OneOver255 = 1/255;
  // IDF file format constants
  icNone = 0; icRLE = 1; icLZW = 2; icHuffman = 3; icWavelet = 4;
  IDFSignature = 'IDF';

type
  // Pixel format type
  TPixelFormat = Integer;
  // IDF file header (deprecated)
  TIDFHeader = record
    Signature: array[0..2] of AnsiChar;
    Compression, PixelFormat, MipLevels, Width, Height: Cardinal;
  end;

  // Error class for streaming operations
  TStreamError = class(TError)
  end;
  // Error class for invalid format errors
  TInvalidFormat = class(TError)
  end;
  // Error class for invalid argument errors
  TInvalidArgument = class(TError)
  end;
  // Error class for file operations
  TFileError = class(TError)
  end;

  // A delegate with file name
  TFileDelegate          = function(const FileName: string): Boolean of object;
  // A delegate for string comparison
  TStringCompareDelegate = function(const s1, s2: string): Integer of object;

  { @Abstract(Reference-counted container of temporary objects and memory buffers )
    Create an instance with @Link(CreateRefcountedContainer). The container can be used to accumulate temporary objects and buffers.
    When no more references points to the container it destroys itself and all accumulated objects and buffers.
    Usage:
    with CreateRefcountedContainer do begin
      obj := TSomeObject.Create();
      Container.AddObject(obj);
    end;
    The container and all added objects will be destroyed after the current routine execution (but not after "with" statement end). }
  IRefcountedContainer = interface
    // Adds an object instance
    function AddObject(Obj: TObject): TObject;
    // Adds a memory buffer
    function AddPointer(Ptr: Pointer): Pointer;
    // Adds an array of object instances
    procedure AddObjects(Objs: array of TObject);
    // Adds an array of memory buffers
    procedure AddPointers(Ptrs: array of Pointer);
    // Returns self for use within "with" statement
    function GetContainer(): IRefcountedContainer;
    // Returns self for use within "with" statement
    property Container: IRefcountedContainer read GetContainer;
  end;

  { @Abstract(Base class for streams)
    Streams can read from and/or write to files (including text ones), memory, etc }
  TStream = class
  private
    FPosition, FSize: Cardinal;
    procedure SetPosition(const Value: Cardinal);
  protected
    // Changes current size of the stream
    procedure SetSize(const Value: Cardinal); virtual;
  public
    // Changes the current position of the stream (if such changes are supported by particular stream class)
    function Seek(const NewPos: Cardinal): Boolean; virtual;
    // Reads <b>Count</b> bytes from the stream to <b>Buffer</b>, moves current position forward for number of bytes read and returns this number
    function Read(out Buffer; const Count: Cardinal): Cardinal; virtual; abstract;
    // Reads <b>Count</b> bytes from the stream to <b>Buffer</b>, moves current position forward for number of bytes read and returns @True if success
    function ReadCheck(out Buffer; const Count: Cardinal): Boolean;
    // Writes <b>Count</b> bytes from <b>Buffer</b> to the stream, moves current position forward for the number of bytes written and returns this number
    function Write(const Buffer; const Count: Cardinal): Cardinal; virtual; abstract;
    // Writes <b>Count</b> bytes from <b>Buffer</b> to the stream, moves current position forward for the number of bytes written and returns @True if success
    function WriteCheck(const Buffer; const Count: Cardinal): Boolean;

    // Current size of the stream in bytes
    property Size: Cardinal read FSize write SetSize;
    // Current position within the stream in bytes
    property Position: Cardinal read FPosition write SetPosition;
  end;

  { @Abstract(File stream class)
    Provides streaming implementation for binary files }
  TFileStream = class(TStream)
  private
    Opened: Boolean;
    FFileName: string;
    F: file;
  protected
    // Changes current size of the stream
    procedure SetSize(const Value: Cardinal); override;
  public
    // Creates a file stream associating it with file with the given file name
    constructor Create(const AFileName: string; const Usage: Integer = fuReadWrite; const ShareMode: Integer = smAllowAll);
    destructor Destroy; override;
    // Open file with the specified usage and sharing mode
    function Open(const Usage: Integer; const ShareMode: Integer): Boolean;
    // Close file
    procedure Close;
    function Seek(const NewPos: Cardinal): Boolean; override;
    function Read(out Buffer; const Count: Cardinal): Cardinal; override;
    function Write(const Buffer; const Count: Cardinal): Cardinal; override;

    // Associated file name
    property Filename: string read FFileName;
  end;

  { @Abstract(Memory stream class)
    Provides streaming implementation for buffers in memory }
  TMemoryStream = class(TStream)
  private
    FData: Pointer;
    FCapacity: Cardinal;
    procedure SetCapacity(const NewCapacity: Cardinal);
    procedure Allocate(const NewSize: Cardinal);
  protected
    // Changes current size of the stream
    procedure SetSize(const Value: Cardinal); override;
//    property Capacity: Cardinal read FCapacity;
  public
    // Creates a memory stream of the specified size associating it with the specified address in memory
    constructor Create(AData: Pointer; const ASize: Cardinal);
    destructor Destroy; override;
    function Read(out Buffer; const Count: Cardinal): Cardinal; override;
    function Write(const Buffer; const Count: Cardinal): Cardinal; override;

    // Pointer to buffer in memory
    property Data: Pointer read FData;
  end;

  { @Abstract(Non-unicode string stream class)
    Provides streaming implementation for non-unicode strings }
  TAnsiStringStream = class(TStream)
    // string data container
    Data: AnsiString;
    // Carriage return character sequence. #13#10 for Windows.
    ReturnSequence: TShortName;
    constructor Create(AData: Pointer; const ASize: Cardinal; const AReturnsequence: TShortName = #13#10);
    function Read(out Buffer; const Count: Cardinal): Cardinal; override;
    function Write(const Buffer; const Count: Cardinal): Cardinal; override;
    function Readln(out Buffer: AnsiString): Integer; virtual;
    function Writeln(const Buffer: AnsiString): Integer; virtual;
  end;

  {/
    Pseudo-random numbers generator
    Generates a sequence of pseudo-random numbers.
    }
  TRandomGenerator = class
  public
    constructor Create;
    // Initializes the current sequence with the specified chain value and the specified seed
    procedure InitSequence(Chain, Seed: Longword);
    // Generate a raw random number. Fastest method
    function GenerateRaw: Longword; virtual;
    // Generate a floating point random number within the given range
    function Rnd(Range: Single): Single;
    // Generate a floating point random number within the range [-<b>Range..Range</b>]
    function RndSymm(Range: Single): Single;
    // Generate an integer random number within the range [0..<b>Range</b>-1]
    function RndI(Range: Integer): Integer;
  protected
    // Seeds for sequences
    RandomSeed: array of Longword;
    // Chain values for sequences
    RandomChain: array of Longword;
    // Current sequence
    FCurrentSequence: Cardinal;
    // Number of sequences
    procedure SetMaxSequence(AMaxSequence: Integer);
    procedure SetCurrentSequence(const Value: Cardinal);
  public
    // Current sequence
    property CurrentSequence: Cardinal read FCurrentSequence write SetCurrentSequence;
  end;

  // Returns floating point random number from [-1..1] range. 23 random bits. Depends on IEEE 754 standard therefore platform dependent.
  // not tested  
  function FastRandom(var Seed: Integer): Single;

  // Create an instance of reference counted container
  function CreateRefcountedContainer: IRefcountedContainer;

    // Some math routines
  //
  function Sign(x: Integer): Integer; overload;
  function Sign(x: Single): Single; overload;

  function Ceil(const X: Single): Integer;
  function Floor(const X: Single): Integer;

  function IsNan(const AValue: Single): Boolean;
  function MaxS(V1, V2: Single): Single;
  function MinS(V1, V2: Single): Single;
  function ClampS(V, Min, Max: Single): Single;
  function MaxI(V1, V2: Integer): Integer;
  function MinI(V1, V2: Integer): Integer;
  function MaxC(V1, V2: Cardinal): Cardinal;
  function MinC(V1, V2: Cardinal): Cardinal;

  function Max(V1, V2: Single): Single; overload; {$I inline.inc}
  function Min(V1, V2: Single): Single; overload; {$I inline.inc}
  function Max(V1, V2: Integer): Integer; overload; {$I inline.inc}
  function Min(V1, V2: Integer): Integer; overload; {$I inline.inc}

  function ClampI(V, Min, Max: Integer): Integer;
  procedure SwapI(var a, b: Integer);
  function BitTest(Data: Cardinal; BitIndex: Byte): Boolean;
  function InterleaveBits(x, y: Smallint): Integer;

  // Returns color max component value
  function GetColor4SIntensity(const Color: TColor4s): Single;

  function VectorToColor(const v: TVector3s): TColor;

  function GetColorFrom4s(const ColorS: TColor4s): TColor;
  
  // Returns color max component value
  function GetColorIntensity(const Color: TColor): Integer;

  // Returns scale color. S is desired koefficient multiplied by 256
  function ScaleColorI(const Color: TColor; S: Cardinal): TColor;
  function ScaleColorS(const Color: TColor; S: Single): TColor;
  function AddColorW(const Color1, Color2: TColor; W1, W2: Single): TColor;
  function BlendColor(const Color1, Color2: TColor; K: Single): TColor;

  function IsDepthFormat(Format: Integer): Boolean;

  function GetSteppedSize(CurrentSize, Step: Integer): Integer;

  function CmpMem(P1, P2: Pointer; Size: Integer): Boolean;
  procedure MoveReverse8(Src, Dest: Pointer; Count: Integer);
  procedure MoveReverse16(Src, Dest: Pointer; Count: Integer);

  procedure Swap(var V1, V2); {$I inline.inc}
  // Fast (if SSE optimization are allowed) implementation of Trunc(x)
  function FastTrunc(X: Single): Integer;
  procedure SinCos(a: Single; out OSin, OCos: Single);
  // Fast (if assembler optimization are allowed) implementation of Sqrt(x) with accurasy ~0.25%
  function FastSqrt(x: Single): Single;
  // Fast (if assembler optimization are allowed) implementation of 1/Sqrt(x)
  function InvSqrt(x: Single): Single;
  function Log2I(x: Integer): Integer;
  function IntPower(Base: Single; Exponent: Integer): Single;
  function Power(const Base, Exponent: Single): Single;

  // Return True if x is a power of 2 or zero
  function IsPowerOf2(const x: Integer): Boolean; {$I inline.inc}
  // Return power of two value next to x
  function NextPowerOf2(const x: Integer): Integer; {$I inline.inc}
  // Returns number of trailing zeros in x
  function CountTrailingZeros(x: Integer): Integer; {$I inline.inc}

  procedure RectIntersect(const ARect1, ARect2: TRect; out Result: TRect);
  function GetRectIntersect(const ARect1, ARect2: TRect): TRect;
  function GetCorrectRect(ALeft, ATop, ARight, ABottom: Integer): TRect;
  function IsInArea(const X, Y, X1, Y1, X2, Y2: Single): Boolean; overload;
  function IsInArea(const X, Y: Single; const Area: TArea): Boolean; overload;

  procedure FillDWord(var Dest; Count: Cardinal; Value: LongWord);

  function GetDefaultUVMap: TUVMap;

  function CompareValues(v1, v2: Extended): Integer;
  function CompareDates(ADate: TDateTime; Year, Month, Day: Integer): Integer;

  function isSameGUID(GUID1, GUID2: TGUID): Boolean;

  function IsPalettedFormat(PixelFormat: TPixelFormat): Boolean;
  function GetBytesPerPixel(PixelFormat: TPixelFormat): Integer;
  function GetBitsPerPixel(PixelFormat: TPixelFormat): Integer;

    // Sorting via indices not affecting values itself
  // Performs a quick sort on an array of unicode (if supported) strings in ascending order and returns sorted indices not affecting the source array
  procedure QuickSortStrInd(N: Integer; Values: TUnicodeStringArray; Inds: TIndArray; Acc: Boolean); overload;
  // Performs a quick sort on an array of ansi strings in ascending order and returns sorted indices not affecting the source array
  procedure QuickSortStrInd(N: Integer; Values: TAnsiStringArray; Inds: TIndArray; Acc: Boolean); overload;
  // Performs a quick sort on an array of integers in ascending order and returns sorted indices not affecting the source array
  procedure QuickSortIntInd(N: Integer; Values, Inds: TIndArray; Acc: Boolean);
  // Performs a quick sort on an array of floating point numbers in ascending order and returns sorted indices not affecting the source array
  procedure QuickSortSInd(N: Integer; Values: TSingleArray; Inds: TIndArray; Acc: Boolean);
    // Sorting values
  // Performs a quick sort on an array of unicode (if supported) strings in ascending order
  procedure QuickSortStr(N: Integer; Values: TUnicodeStringArray); overload;
  // Performs a quick sort on an array of ansi strings in ascending order
  procedure QuickSortStr(N: Integer; Values: TAnsiStringArray); overload;
  // Performs a quick sort on an array of integers in ascending order
  procedure QuickSortInt(N: Integer; Values: TIndArray);
  // Performs a quick sort on an array of integers in descending order
  procedure QuickSortIntDsc(N: Integer; Values: TIndArray);
  // Performs a quick sort on an array of single-precision floating point numbers in ascending order
  procedure QuickSortS(N: Integer; Values: TSingleArray);

  // Saves a string to a stream. Returns @True if success
  function SaveString(Stream: TStream; const s: AnsiString): Boolean; overload;
  // Loads a string from a stream. Returns @True if success
  function LoadString(Stream: TStream; out   s: AnsiString): Boolean; overload;
  // Saves a unicode string to a stream. Returns @True if success
  function SaveString(Stream: TStream; const s: UnicodeString): Boolean; overload;
  // Loads a unicode string from a stream. Returns @True if success
  function LoadString(Stream: TStream; out   s: UnicodeString): Boolean; overload;

  { Calls the <b>Delegate</b> for each file passing the given mask and attribute filter and returns number of such files.
    Stops if the delegate returns @False }
  function ForEachFile(const PathAndMask: string; AttributeFilter: Integer; Delegate: TFileDelegate): Integer;

  procedure CalcCRC32(Bytes: PByteBuffer; ByteCount: Cardinal; var CRCValue: Longword);

  { Performs wait cycle with the given number of iterations }
  procedure SpinWait(Iterations: Integer);

type
  // FPU exception masking flags enumeration
  TFPUException = (fpueInvalidOperation, fpueDenormalizedOperand, fpueZeroDivide, fpueOverflow, fpueUnderflow, fpuePrecision);
  // Set of FPU exception masking flags
  TFPUExceptionSet = set of TFPUException;
  // FPU precision modes enumeration
  TFPUPrecision = (fpup24Bit, fpup53Bit, fpup64Bit);
  // FPU rounding modes enumeration
  TFPURounding = (fpurNearestOrEven, fpurInfinityNeg, fpurInfinityPos, fpurTrunc);

const
  // All FPU exceptions set
  FPUAllExceptions: TFPUExceptionSet = [fpueInvalidOperation, fpueDenormalizedOperand, fpueZeroDivide, fpueOverflow, fpueUnderflow, fpuePrecision];

  // Sets x87 FPU control word. Affine infinity should be True to respect sign of an infinity.
  procedure SetFPUControlWord(MaskedExceptions: TFPUExceptionSet; EnableInterrupts: Boolean; Precision: TFPUPrecision; Rounding: TFPURounding; AffineInfinity: Boolean);

var
  // Table used in trailing zero count routine
  CtzTable: array[0..31] of Byte;
  { This handler caled when an error occurs. Default handler simply logs the error class.
    Application can set its own handler to handle errors, raise exceptions, continue the workflow, etc.
    To continue the normal workflow application's handler should call <b>Invalidate()</b> method of the error message. }
  ErrorHandler: TErrorHandler;

  // Key codes
  //
  IK_NONE: Integer = 0;
  IK_ESCAPE,
  IK_1, IK_2, IK_3, IK_4, IK_5, IK_6, IK_7, IK_8, IK_9, IK_0,
  IK_MINUS, IK_EQUALS, IK_BACK, IK_TAB,
  IK_Q, IK_W, IK_E, IK_R, IK_T, IK_Y, IK_U, IK_I, IK_O, IK_P,
  IK_LBRACKET, IK_RBRACKET,
  IK_RETURN,
  IK_LCONTROL,
  IK_A, IK_S, IK_D, IK_F, IK_G, IK_H, IK_J, IK_K, IK_L,
  IK_SEMICOLON, IK_APOSTROPHE, IK_GRAVE,
  IK_LSHIFT,
  IK_BACKSLASH,
  IK_Z, IK_X, IK_C, IK_V, IK_B, IK_N, IK_M,
  IK_COMMA, IK_PERIOD, IK_SLASH,
  IK_RSHIFT,
  IK_MULTIPLY,
  IK_LMENU,
  IK_SPACE,
  IK_CAPITAL,
  IK_F1, IK_F2, IK_F3, IK_F4, IK_F5, IK_F6, IK_F7, IK_F8, IK_F9, IK_F10,
  IK_NUMLOCK, IK_SCROLL,
  IK_NUMPAD7, IK_NUMPAD8, IK_NUMPAD9, IK_SUBTRACT, IK_NUMPAD4, IK_NUMPAD5, IK_NUMPAD6,
  IK_ADD, IK_NUMPAD1, IK_NUMPAD2, IK_NUMPAD3, IK_NUMPAD0, IK_DECIMAL,

  IK_OEM_102,
  IK_F11, IK_F12,
  IK_F13, IK_F14, IK_F15,
  IK_KANA, IK_ABNT_C1,
  IK_CONVERT, IK_NOCONVERT,
  IK_YEN, IK_ABNT_C2,
  IK_NUMPADEQUALS, IK_CIRCUMFLEX,
  IK_AT, IK_COLON, IK_UNDERLINE, IK_KANJI,
  IK_STOP,
  IK_AX, IK_UNLABELED,
  IK_NEXTTRACK,
  IK_NUMPADENTER,
  IK_RCONTROL,
  IK_MUTE, IK_CALCULATOR, IK_PLAYPAUSE, IK_MEDIASTOP,
  IK_VOLUMEDOWN, IK_VOLUMEUP,
  IK_WEBHOME,
  IK_NUMPADCOMMA, IK_DIVIDE,
  IK_SYSRQ, IK_RMENU, IK_PAUSE,
  IK_HOME, IK_UP, IK_PRIOR, IK_LEFT, IK_RIGHT, IK_END, IK_DOWN,
  IK_NEXT, IK_INSERT, IK_DELETE,
  IK_LOS, IK_ROS,
  IK_APPS, IK_POWER, IK_SLEEP, IK_WAKE,
  IK_WEBSEARCH, IK_WEBFAVORITES, IK_WEBREFRESH, IK_WEBSTOP, IK_WEBFORWARD, IK_WEBBACK,
  IK_MYCOMPUTER, IK_MAIL, IK_MEDIASELECT,
  //  Alternate names
  //
  IK_BACKSPACE, IK_NUMPADSTAR, IK_LALT, IK_CAPSLOCK,
  IK_NUMPADMINUS, IK_NUMPADPLUS, IK_NUMPADPERIOD, IK_NUMPADSLASH,
  IK_RALT,
  IK_UPARROW, IK_PGUP, IK_LEFTARROW, IK_RIGHTARROW, IK_DOWNARROW, IK_PGDN,
  IK_PREVTRACK, IK_MOUSELEFT, IK_MOUSERIGHT, IK_MOUSEMIDDLE,
  IK_SHIFT, IK_CONTROL, IK_ALT: Integer;
  IK_MOUSEBUTTON: array[TMouseButton] of Integer;

implementation

//uses TextFile;

type
  // Version of interfaced object with non thread-safe reference counting which is much faster and suitable for the TRefcountedContainer
  TLiteInterfacedObject = class(TObject, IInterface)
  protected
    FRefCount: Integer;
{    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;}
    function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
    function _AddRef: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
    function _Release: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
  public
    procedure AfterConstruction; override;
    class function NewInstance: TObject; override;
  end;

  TRefcountedContainer = class(TLiteInterfacedObject, IRefcountedContainer)
  private
    ObjList: array of TObject;
    PtrList: array of Pointer;
    ObjCount, PtrCount: Integer;
  public
    destructor Destroy; override;

    function AddObject(Obj: TObject): TObject;
    function AddPointer(Ptr: Pointer): Pointer;
    procedure AddObjects(Objs: array of TObject);
    procedure AddPointers(Ptrs: array of Pointer);
    function GetContainer(): IRefcountedContainer;
  end;

procedure SetFPUControlWord(MaskedExceptions: TFPUExceptionSet; EnableInterrupts: Boolean; Precision: TFPUPrecision; Rounding: TFPURounding; AffineInfinity: Boolean);
const
  PrecArr:  array[TFPUPrecision] of Integer = (0, 2*256, 3*256);
  RoundArr: array[TFPURounding]  of Integer = (0, 1*1024, 2*1024, 3*1024);
begin
  Set8087CW( Ord(fpueInvalidOperation in MaskedExceptions) or (Ord(fpueDenormalizedOperand in MaskedExceptions)*02) or
            (Ord(fpueZeroDivide in MaskedExceptions)*4)    or (Ord(fpueOverflow            in MaskedExceptions)*08) or
            (Ord(fpueUnderflow in MaskedExceptions)*16)    or (Ord(fpuePrecision           in MaskedExceptions)*32) or

            (Ord(not EnableInterrupts) * 128) or

             PrecArr[Precision] or

             RoundArr[Rounding] or

            (Ord(AffineInfinity) * 4096) );
end;

// not tested
function FastRandom(var Seed: Integer): Single;
begin
    Seed := Seed * 16807;
    Cardinal((@Result)^) := (Cardinal(Seed) shr 9) or $40000000;
    Result := Result - 3;
//    *((unsigned int *) &res) = ( ((unsigned int)seed[0])>>9 ) | 0x40000000;
end;

function CreateRefcountedContainer: IRefcountedContainer;
begin
  Result := TRefcountedContainer.Create;
end;

function Sign(x: Integer): Integer; overload;
begin
  Result := Ord(X > 0) - Ord(X < 0);
//  if x > 0 then Result := 1 else if x < 0 then Result := -1 else Result := 0;
end;

function Sign(x: Single): Single; overload;
begin
  if x > 0 then Result := 1 else if x < 0 then Result := -1 else Result := 0;
end;

function IsNan(const AValue: Single): Boolean;
begin
  Result := ((Longword((@AValue)^) and $7F800000)  = $7F800000) and
            ((Longword((@AValue)^) and $007FFFFF) <> $00000000);
end;

function Ceil(const X: Single): Integer;
begin
  Result := Integer(Trunc(X));
  if Frac(X) > 0 then Inc(Result);
end;

function Floor(const X: Single): Integer;
begin
  Result := Integer(Trunc(X));
  if Frac(X) < 0 then Dec(Result);
end;

//-----------------------------------------

function MaxI(V1, V2: Integer): Integer;
begin
//  if V1 > V2 then Result := V1 else Result := V2;
  Result := V1 * Ord(V1 >= V2) + V2 * Ord(V1 < V2);
  Assert((Result >= V1) and (Result >= V2));
end;

function MinI(V1, V2: Integer): Integer;
begin
//  if V1 < V2 then Result := V1 else Result := V2;
  Result := V1 * Ord(V1 <= V2) + V2 * Ord(V1 > V2);
  Assert((Result <= V1) and (Result <= V2));
end;

{$IFDEF USEP6ASM}
function MaxS(V1, V2: Single): Single; assembler;
asm
  fld     dword ptr [ebp+$08]
  fld     dword ptr [ebp+$0c]
  fcomi   st(0), st(1)
  fcmovb  st(0), st(1)
  ffree   st(1)
end;

function MinS(V1, V2: Single): Single; assembler;
asm
  fld     dword ptr [ebp+$08]
  fld     dword ptr [ebp+$0c]
  fcomi   st(0), st(1)
  fcmovnb st(0), st(1)
  ffree   st(1)
end;
{$ELSE}
function MaxS(V1, V2: Single): Single;
begin
  if V1 > V2 then Result := V1 else Result := V2;
end;

function MinS(V1, V2: Single): Single;
begin
  if V1 < V2 then Result := V1 else Result := V2;
end;
{$ENDIF}

function ClampS(V, Min, Max: Single): Single;
begin
  Result := MinS(MaxS(V, Min), Max);
end;

function MaxC(V1, V2: Cardinal): Cardinal;
begin
  Result := V1 * Cardinal(Ord(V1 >= V2)) + V2 * Cardinal(Ord(V1 < V2));
  Assert((Result >= V1) and (Result >= V2));
end;

function MinC(V1, V2: Cardinal): Cardinal;
begin
  Result := V1 * Cardinal(Ord(V1 <= V2)) + V2 * Cardinal(Ord(V1 > V2));
  Assert((Result <= V1) and (Result <= V2));
end;

function Max(V1, V2: Single): Single; overload;
begin
  Result := MaxS(V1, V2);
end;

function Min(V1, V2: Single): Single; overload;
begin
  Result := MinS(V1, V2);
end;

function Max(V1, V2: Integer): Integer; overload;
begin
  Result := MaxI(V1, V2);
end;

function Min(V1, V2: Integer): Integer; overload;
begin
  Result := MinI(V1, V2);
end;

function ClampI(V, Min, Max: Integer): Integer;
begin
//  if V < B1 then Result := B1 else if V > B2 then Result := B2 else Result := V;
  Result := V + (Min - V) * Ord(V < Min) - (V - Max) * Ord(V > Max);
  Assert((Result >= Min) and (Result <= Max));
end;

procedure SwapI(var a, b: Integer);
begin
  a := a xor b;
  b := b xor a;
  a := a xor b;
end;

function BitTest(Data: Cardinal; BitIndex: Byte): Boolean;
begin
  Result := Odd(Data shr BitIndex);
end;

function InterleaveBits(x, y: Smallint): Integer;
var i: Integer;
begin
  Result := 0;
  for i := 0 to SizeOf(x) * BitsInByte-1 do Result := Result or (x and (1 shl i)) shl i or (y and (1 shl i)) shl (i + 1);
{ Another (faster) way:
x = (x | (x << S[3])) & B[3];
x = (x | (x << S[2])) & B[2];
x = (x | (x << S[1])) & B[1];
x = (x | (x << S[0])) & B[0];

y = (y | (y << S[3])) & B[3];
y = (y | (y << S[2])) & B[2];
y = (y | (y << S[1])) & B[1];
y = (y | (y << S[0])) & B[0];

z = x | (y << 1);}
end;

function GetColor4SIntensity(const Color: TColor4s): Single;
begin
  Result := MaxS(MaxS(Color.R, Color.G), Color.B);
end;

function VectorToColor(const v: TVector3s): TColor;
begin
  Result.r := Round(127.0 * v.x + 128.0);
  Result.g := Round(127.0 * v.y + 128.0);
  Result.b := Round(127.0 * v.z + 128.0);
end;

function GetColorFrom4s(const ColorS: TColor4s): TColor;
begin
  Result.A := Round(MinS(1, MaxS(0, ColorS.A))*255);
  Result.R := Round(MinS(1, MaxS(0, ColorS.R))*255);
  Result.G := Round(MinS(1, MaxS(0, ColorS.G))*255);
  Result.B := Round(MinS(1, MaxS(0, ColorS.B))*255);
end;

function GetColorIntensity(const Color: TColor): Integer;
begin
  Result := MaxI(MaxI(Color.R, Color.G), Color.B);
end;

function ScaleColorI(const Color: TColor; S: Cardinal): TColor;
begin
  Result.C := MinI(255,  (Color.C and 255)        *S) shr 8 +
              MinI(255, ((Color.C shr 8)  and 255)*S)       +
              MinI(255, ((Color.C shr 16) and 255)*S) shl 8 +
              MinI(255, ((Color.C shr 24) and 255)*S) shl 16;
end;

function ScaleColorS(const Color: TColor; S: Single): TColor;
begin
  Result.C := Cardinal(Round(MinS(255,  (Color.C and 255)        *S)))        +
              Cardinal(Round(MinS(255, ((Color.C shr 8)  and 255)*S))) shl 8  +
              Cardinal(Round(MinS(255, ((Color.C shr 16) and 255)*S))) shl 16 +
              Cardinal(Round(MinS(255, ((Color.C shr 24) and 255)*S))) shl 24;
end;

function AddColorW(const Color1, Color2: TColor; W1, W2: Single): TColor;
begin
  Result.R := ClampI(Round(Color1.R * W1 + Color2.R * W2), 0, 255);
  Result.G := ClampI(Round(Color1.G * W1 + Color2.G * W2), 0, 255);
  Result.B := ClampI(Round(Color1.B * W1 + Color2.B * W2), 0, 255);
  Result.A := ClampI(Round(Color1.A * W1 + Color2.A * W2), 0, 255);
end;

function BlendColor(const Color1, Color2: TColor; K: Single): TColor;
begin
  if K > 1 then K := 1; if K < 0 then K := 0;
  Result := AddColorW(Color1, Color2, 1-K, K);
end;

function IsDepthFormat(Format: Integer): Boolean;
begin
  Result := (Format >= pfD16_LOCKABLE) and (Format <= pfD24X4S4) or
            (Format = pfATIDF16) or (Format = pfATIDF24);
end;

function GetSteppedSize(CurrentSize, Step: Integer): Integer;
begin
//  Assert(get
//  Result := MaxI(0, (CurrentSize-1)) and (Step-1) + Step)
  Result := MaxI(0, (CurrentSize-1)) div Step * Step + Step;
end;
          
{$IFDEF PUREPASCAL}
function CmpMem(P1, P2: Pointer; Size: Integer): Boolean;
var i: Integer;
begin
  Result := False;
  // Compare dwords
  i := Size div 4-1;
  while (i >= 0) and (TDWordBuffer(P1^)[i] = TDWordBuffer(P2^)[i]) do Dec(i);
  if i >= 0 then Exit;
  // Compare rest bytes
  i := Size div 4 * 4;
  while (i < Size) and (TByteBuffer(P1^)[i] = TByteBuffer(P2^)[i]) do Inc(i);
  Result := i >= Size;
end;
{$ELSE}
function CmpMem(P1, P2: Pointer; Size: Integer): Boolean; assembler;
asm
   add   eax, ecx
   add   edx, ecx
   xor   ecx, -1
   add   eax, -8
   add   edx, -8
   add   ecx, 9
   push  ebx
   jg    @Dword
   mov   ebx, [eax+ecx]
   cmp   ebx, [edx+ecx]
   jne   @Ret0
   lea   ebx, [eax+ecx]
   add   ecx, 4
   and   ebx, 3
   sub   ecx, ebx
   jg    @Dword
@DwordLoop:
   mov   ebx, [eax+ecx]
   cmp   ebx, [edx+ecx]
   jne   @Ret0
   mov   ebx, [eax+ecx+4]
   cmp   ebx, [edx+ecx+4]
   jne   @Ret0
   add   ecx, 8
   jg    @Dword
   mov   ebx, [eax+ecx]
   cmp   ebx, [edx+ecx]
   jne   @Ret0
   mov   ebx, [eax+ecx+4]
   cmp   ebx, [edx+ecx+4]
   jne   @Ret0
   add   ecx, 8
   jle   @DwordLoop
@Dword:
   cmp   ecx, 4
   jg    @Word
   mov   ebx, [eax+ecx]
   cmp   ebx, [edx+ecx]
   jne   @Ret0
   add   ecx, 4
@Word:
   cmp   ecx, 6
   jg    @Byte
   movzx ebx, word ptr [eax+ecx]
   cmp   bx, [edx+ecx]
   jne   @Ret0
   add   ecx, 2
@Byte:
   cmp   ecx, 7
   jg    @Ret1
   movzx ebx, byte ptr [eax+7]
   cmp   bl, [edx+7]
   jne   @Ret0
@Ret1:
   mov   eax, 1
   pop   ebx
   ret
@Ret0:
   xor   eax, eax
   pop   ebx
end;
{$ENDIF}

procedure MoveReverse8(Src, Dest: Pointer; Count: Integer);
var i: Integer;
begin
  if Count <= 0 then Exit;
  for i := 0 to Count-1 do PByteBuffer(Dest)^[i] := PByteBuffer(Src)^[Count-1 - i];
end;

procedure MoveReverse16(Src, Dest: Pointer; Count: Integer);
var i: Integer;
begin
  if Count <= 0 then Exit;
  for i := 0 to Count-1 do PWordBuffer(Dest)^[i] := PWordBuffer(Src)^[Count-1 - i];
end;

procedure Swap(var V1, V2);
var T: Pointer;
begin
  T := Pointer(V1);
  Pointer(V1) := Pointer(V2); Pointer(V2) := T;
end;

function FastTrunc(X: Single): Integer;
{$IFDEF USESSE}
asm
  CVTTSS2SI  eax, [ebp+offset X]
end;
{$ELSE}
begin
  Result := Trunc(X);
end;
{$ENDIF}

{$IFDEF PUREPASCAL}
procedure SinCos(a: Single; out OSin, OCos: Single);
begin
  OSin := Sin(a);
  OCos := Cos(a);
end;
{$ELSE}
procedure SinCos(a: Single; out OSin, OCos: Single); assembler; register;
// EAX contains address of OSin
// EDX contains address of OCos
// a is passed over the stack
asm
  FLD  a
  FSINCOS
  FSTP [OCos]
  FSTP [OSin]
//  FWAIT
end;
{$ENDIF}

{$IFDEF PUREPASCAL}
function FastSqrt(x: Single): Single;
begin
  Result := Sqrt(x);
{$ELSE}
function FastSqrt(x: Single): Single; assembler;
  asm
    MOV      EAX, x
    SUB      EAX, 0C0800000H
    TEST     EAX, 000800000H
    MOV      ECX, EAX
    JZ       @NoNeg
    NEG      EAX
@NoNeg:
    AND      EAX, 000FFFFFFH
    SHR      ECX, 1
    MUL      EAX
    NEG      EDX
    LEA      EAX, [ECX+EDX*8]
    LEA      EDX, [EDX+EDX*8]
    LEA      EAX, [EAX+EDX*4]
    mov      Result, eax
{$ENDIF}
end;

function InvSqrt(x: Single): Single;
{$IFDEF PUREPASCAL}
begin
  Result := 1/Sqrt(x);
{$ELSE}
var tmp: LongWord;
begin
  asm
    mov        eax, OneAsInt
    sub        eax, x
    add        eax, OneAsInt2
    shr        eax, 1
    mov        tmp, eax
  end;
  Result := Single((@tmp)^) * (1.47 - 0.47 * x * Single((@tmp)^) * Single((@tmp)^));
{$ENDIF}
end;

function Log2I(x: Integer): Integer;
begin
  Result := 0;
  x := x shr 1;
  while x > 0 do begin
    x := x shr 1;
    Inc(Result);
  end;
end;

function IntPower(Base: Single; Exponent: Integer): Single;
var a: Integer;
begin
  a := Abs(Exponent);
  Result := 1;
  while a > 0 do begin
    while not Odd(a) do begin
      Base := Sqr(Base);
      a := a shr 1;
    end;
    Result := Result * Base;
    Dec(a);
  end;
  if Exponent < 0 then Result := 1/Result
end;

function Power(const Base, Exponent: Single): Single;
begin
  if Exponent = 0.0 then
    Result := 1.0
  else if (Base = 0.0) and (Exponent > 0.0) then
    Result := 0.0
  else if (Frac(Exponent) = 0) and (Abs(Exponent) <= MaxInt) then
    Result := IntPower(Base, Trunc(Exponent))
  else
    Result := Exp(Exponent * Ln(Base));
end;

function IsPowerOf2(const x: Integer): Boolean; {$I inline.inc}
begin
  Result := x and (x-1) = 0;
end;

function NextPowerOf2(const x: Integer): Integer; {$I inline.inc}
begin
  Result := x-1;
  Result := Result or Result shr 1;
  Result := Result or Result shr 2;
  Result := Result or Result shr 4;
  Result := Result or Result shr 8;
  Result := Result or Result shr 16;
  {$IFDEF CPU64}
  Result := Result or Result shr 32;
  {$ENDIF}
  Inc(Result);
end;

function CountTrailingZeros(x: Integer): Integer;
begin
  {$OVERFLOWCHECKS OFF}
  Result := CtzTable[((x and (-x)) * $077CB531) shr 27] * Ord(x > 0) + 32 * Ord(x=0);
end;

procedure RectIntersect(const ARect1, ARect2: TRect; out Result: TRect);
begin
  Result.Left   := MaxI(ARect1.Left,   ARect2.Left);
  Result.Top    := MaxI(ARect1.Top,    ARect2.Top);
  Result.Right  := MinI(ARect1.Right,  ARect2.Right);
  Result.Bottom := MinI(ARect1.Bottom, ARect2.Bottom);
end;

function GetRectIntersect(const ARect1, ARect2: TRect): TRect;
begin
  RectIntersect(ARect1, ARect2, Result);
end;

function GetCorrectRect(ALeft, ATop, ARight, ABottom: Integer): TRect;
begin
  with Result do begin
    Left := MinI(ALeft, ARight); Top := MinI(ATop, ABottom);
    Right:= MaxI(ALeft, ARight); Bottom := MaxI(ATop, ABottom);
  end;
end;

function IsInArea(const X, Y, X1, Y1, X2, Y2: Single): Boolean; overload;
begin
  Result := (X >= X1) and (Y >= Y1) and (X < X2) and (Y < Y2);
end;

function IsInArea(const X, Y: Single; const Area: TArea): Boolean; overload;
begin
  Result := IsInArea(X, Y, Area.X1, Area.Y1, Area.X2, Area.Y2);
end;

function GetDefaultUVMap: TUVMap;
begin
  Result := @DefaultUV;
end;

{ TLiteInterfacedObject }

procedure TLiteInterfacedObject.AfterConstruction;
begin
  FRefCount := FRefCount-1; // Release the constructor's implicit refcount
end;

// Set an implicit refcount so that refcounting
// during construction won't destroy the object.
class function TLiteInterfacedObject.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TLiteInterfacedObject(Result).FRefCount := 1;
end;

function TLiteInterfacedObject.QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  Result := E_NOINTERFACE;
end;

function TLiteInterfacedObject._AddRef: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  FRefCount := FRefCount+1;
  Result := FRefCount;
end;

function TLiteInterfacedObject._Release: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  FRefCount := FRefCount-1;
  Result := FRefCount;
  if Result = 0 then Destroy;
end;

{ TRefcountedContainer }

destructor TRefcountedContainer.Destroy;
var i: Integer;
begin
  for i := ObjCount-1 downto 0 do if Assigned(ObjList[i]) then FreeAndNil(ObjList[i]);
  for i := PtrCount-1 downto 0 do if Assigned(PtrList[i]) then FreeMem(PtrList[i]);
  ObjList := nil;
  PtrList := nil;
  inherited;
end;

function TRefcountedContainer.AddObject(Obj: TObject): TObject;
begin
  Inc(ObjCount);
  if ObjCount > Length(ObjList) then SetLength(ObjList, MaxI(MinRefCContainerLength, Length(ObjList) * 2));
  ObjList[ObjCount-1] := Obj;
  Result := Obj;
end;

function TRefcountedContainer.AddPointer(Ptr: Pointer): Pointer;
begin
  Inc(PtrCount);
  if PtrCount > Length(PtrList) then SetLength(PtrList, MaxI(MinRefCContainerLength, Length(PtrList) * 2));
  PtrList[PtrCount-1] := Ptr;
  Result := Ptr;
end;

procedure TRefcountedContainer.AddObjects(Objs: array of TObject);
var i: Integer;
begin
  for i := Low(Objs) to High(Objs) do AddObject(Objs[i]);
end;

procedure TRefcountedContainer.AddPointers(Ptrs: array of Pointer);
var i: Integer;
begin
  for i := Low(Ptrs) to High(Ptrs) do AddPointer(Ptrs[i]);
end;

function TRefcountedContainer.GetContainer: IRefcountedContainer;
begin
  Result := Self;
end;

{ TStream }

procedure TStream.SetPosition(const Value: Cardinal);
begin
  Seek(Value);
end;

procedure TStream.SetSize(const Value: Cardinal);
begin
  FSize := Value;
end;

function TStream.Seek(const NewPos: Cardinal): Boolean;
begin
  Result := NewPos <= Size;
  if Result then FPosition := NewPos else ErrorHandler(TStreamError.Create('Invalid seek'));
end;

function TStream.ReadCheck(out Buffer; const Count: Cardinal): Boolean;
begin
  Result := Read(Buffer, Count) = Count;
end;

function TStream.WriteCheck(const Buffer; const Count: Cardinal): Boolean;
begin
  Result := Write(Buffer, Count) = Count;
end;

{ TFileStream }

constructor TFileStream.Create(const AFileName: string; const Usage: Integer; const ShareMode: Integer);
begin
  Opened := False;
  if AFileName = '' then Exit;
  FFileName := ExpandFileName(AFileName);
  if Usage <> fuDoNotOpen then Open(Usage, ShareMode);
end;

destructor TFileStream.Destroy;
begin
  Close;
end;

function TFileStream.Open(const Usage, ShareMode: Integer): Boolean;
var OldFileMode: Byte;
begin
  Opened := False;
  Result := False;

  OldFileMode := FileMode;
{$I-}
  case ShareMode of
    smAllowAll: FileMode := 0;
    smAllowRead: FileMode := fmShareDenyWrite;
    smExclusive: FileMode := fmShareExclusive;
  end;  
  AssignFile(F, FileName);
  case Usage of
    fuRead: begin
      FileMode := FileMode or fmOpenRead;
      Reset(F, 1);
    end;
    fuReadWrite: begin
      FileMode := FileMode or fmOpenReadWrite;
      Reset(F, 1);
      if (IOResult <> 0) and not FileExists(FFileName) then Rewrite(F, 1);
    end;
    fuWrite: Rewrite(F, 1);
    fuAppend: if FileExists(FileName) then begin
      FileMode := FileMode or fmOpenReadWrite;
      Reset(F, 1);
      FSize := FileSize(F);
      Seek(Size);
    end else Rewrite(F, 1);
  end;

  if IOResult <> 0 then Exit;

  FSize := FileSize(F);

  FileMode := OldFileMode;

  Opened := True;
  Result := True;
end;

procedure TFileStream.Close;
begin
  if Opened then CloseFile(F);
  Opened := False;
end;

function TFileStream.Seek(const NewPos: Cardinal): Boolean;
begin
  Result := False;
  if not Opened then if not ErrorHandler(TStreamError.Create('File stream is not opened')) then Exit;
{$I-}
  System.Seek(F, NewPos);
  Result := IOResult = 0;
  if Result then FPosition := NewPos;
end;

procedure TFileStream.SetSize(const Value: Cardinal);
begin
  if not Opened then if not ErrorHandler(TStreamError.Create('File stream is not opened')) then Exit;
{$I-}
  System.Seek(F, Value);
  if IOResult <> 0 then if not ErrorHandler(TStreamError.Create('Seek operation failed')) then Exit;
  System.Truncate(F);
  if IOResult <> 0 then if not ErrorHandler(TStreamError.Create('Truncate operation failed')) then Exit;
  Position := MinI(Value, FPosition);
  inherited;
end;

function TFileStream.Read(out Buffer; const Count: Cardinal): Cardinal;
begin
  Result := 0;
  if not Opened then if not ErrorHandler(TStreamError.Create('File stream is not opened')) then Exit;
  BlockRead(F, Buffer, Count, Result);
  if Result > 0 then FPosition := FPosition + Result;
end;

function TFileStream.Write(const Buffer; const Count: Cardinal): Cardinal;
begin
  Result := 0;
  if not Opened then if not ErrorHandler(TStreamError.Create('File stream is not opened')) then Exit;
  BlockWrite(F, Buffer, Count, Result);
  if Result > 0 then FPosition := FPosition + Result;
  FSize := FPosition;
end;

{ TMemoryStream }

procedure TMemoryStream.SetCapacity(const NewCapacity: Cardinal);
begin
  if FCapacity = 0 then GetMem(FData, NewCapacity) else ReallocMem(FData, NewCapacity);
  FCapacity := NewCapacity;
  if FSize > FCapacity then FSize := FCapacity;
  Seek(FPosition);
end;

procedure TMemoryStream.Allocate(const NewSize: Cardinal);
const MinCap = $40; CapPower = 10; MaxCapStep = $10000;
var NewCapacity: Cardinal;
begin
  if NewSize > FCapacity then begin
    if NewSize < MinCap then
      NewCapacity := MinCap
    else if (NewSize < MaxCapStep) and (NewSize <= FCapacity*2) then
      NewCapacity := FCapacity*2
    else begin
      NewCapacity := (NewSize shr CapPower) shl CapPower;
      if NewCapacity < NewSize then Inc(NewCapacity, 1 shl CapPower);
    end;
    Assert(NewCapacity >= NewSize, ClassName + '.Allocate: Error');
    SetCapacity(NewCapacity);
  end;
  FSize := NewSize;
end;

procedure TMemoryStream.SetSize(const Value: Cardinal);
begin
  SetCapacity(Value);
  Position := MinI(Value, FPosition);
  inherited;
end;

constructor TMemoryStream.Create(AData: Pointer; const ASize: Cardinal);
begin
  FData := nil;
  if ASize > 0 then Allocate(ASize);
  if AData <> nil then Move(AData^, Data^, ASize);
end;

destructor TMemoryStream.Destroy;
begin
  FreeMem(Data);
end;

function TMemoryStream.Read(out Buffer; const Count: Cardinal): Cardinal;
begin
  Result := FSize - FPosition;
  if Result > Count then Result := Count;
  if Result > 0 then begin
    Move(Pointer(Cardinal(FData) + FPosition)^, Buffer, Result);
    Inc(FPosition, Result);
  end;
end;

function TMemoryStream.Write(const Buffer; const Count: Cardinal): Cardinal;
var NewPos: Cardinal;
begin
  NewPos := FPosition + Count;
  if NewPos > FSize then Allocate(NewPos);
  Move(Buffer, Pointer(Cardinal(FData) + FPosition)^, Count);
  FPosition := NewPos;
  Result := Count;
end;

{ TStringStream }

constructor TAnsiStringStream.Create(AData: Pointer; const ASize: Cardinal; const AReturnsequence: TShortName = #13#10);
var i: Integer;
begin
  ReturnSequence := AReturnSequence;
  SetLength(Data, ASize);
  if (AData <> nil) and (ASize > 0) then
    for i := 0 to ASize-1 do Data[i+1] := AnsiChar(BaseTypes.PByteBuffer(AData)^[i]);
  FSize := ASize;
end;

function TAnsiStringStream.Read(out Buffer; const Count: Cardinal): Cardinal;
begin
  Result := Count;
  AnsiString(Buffer) := Copy(Data, FPosition+1, Count);
end;

function TAnsiStringStream.Readln(out Buffer: AnsiString): Integer;
var i: Integer;
begin
  Result := 0;
  i := 0;
  Buffer := '';
  while (FPosition < Size) and (i < Length(ReturnSequence)) do begin
    if Data[FPosition+1] = ReturnSequence[i+1] then Inc(i) else begin
      if i > 0 then begin
        Buffer := Buffer + Copy(ReturnSequence, 1, i);
        i := 0;
        Buffer := Buffer + Data[FPosition+1];
      end else Buffer := Buffer + Data[FPosition+1];
    end;
    Inc(FPosition);
    Inc(Result);
  end;
end;

function TAnsiStringStream.Write(const Buffer; const Count: Cardinal): Cardinal;
begin
  Result := Count;
  SetLength(Data, FPosition);
  Data := Data + Copy(AnsiString(Buffer), 1, Count);
  FPosition := FPosition + Count;
  FSize := FPosition;
end;

function TAnsiStringStream.Writeln(const Buffer: AnsiString): Integer;
var p: Pointer; BufLen: Integer;
begin
  BufLen := Length(Buffer);
  Result := BufLen + Length(ReturnSequence);
  p := @Buffer[1];
  Write(p, BufLen);
  p := @ReturnSequence[1];
  Write(p, Length(ReturnSequence));
end;

{ TRandomGenerator }

constructor TRandomGenerator.Create;
begin
  SetMaxSequence(8);
  CurrentSequence := 0;
  InitSequence(1, 1);
end;

procedure TRandomGenerator.InitSequence(Chain, Seed: Longword);
begin
  RandomChain[FCurrentSequence] := Chain;
  RandomSeed [FCurrentSequence] := Seed;
end;

function TRandomGenerator.GenerateRaw: Longword;
begin
{$Q-}
  RandomSeed[FCurrentSequence] := 97781173 * RandomSeed[FCurrentSequence] + RandomChain[FCurrentSequence];
  Result := RandomSeed[FCurrentSequence];
end;

function TRandomGenerator.Rnd(Range: Single): Single;
const RandomNorm = 1/$FFFFFFFF;
begin
  Result := GenerateRaw * RandomNorm * Range;
end;

function TRandomGenerator.RndSymm(Range: Single): Single;
begin
  Result := Rnd(2*Range) - Range;
end;

function TRandomGenerator.RndI(Range: Integer): Integer;
begin
  Result := Round(Rnd(MaxI(0, Range-1)));
end;

procedure TRandomGenerator.SetMaxSequence(AMaxSequence: Integer);
begin
  SetLength(RandomSeed, AMaxSequence);
  SetLength(RandomChain, AMaxSequence);
end;

procedure TRandomGenerator.SetCurrentSequence(const Value: Cardinal);
begin
  FCurrentSequence := Value;
  if Integer(Value) > High(RandomSeed) then SetMaxSequence(Value+1);
end;

{--------------------------}

procedure FillDWord(var Dest; Count: Cardinal; Value: LongWord);
{$IFDEF PUREPASCAL}
begin
  FillChar(Dest, Count * 4, Value);
{$ELSE}
assembler;
asm
{     ->EAX     Pointer to destination  }
{       EDX     count   }
{       CX      value   }

        PUSH    EDI

        MOV     EDI,EAX { Point EDI to destination              }

        MOV     EAX,ECX
        CLD
        MOV     ECX,EDX

        REP     STOSD   { Fill count dwords       }

@@exit:
        POP     EDI
{$ENDIF}
end;

function CompareValues(v1, v2: Extended): Integer;
begin
  if v1 > v2 then
    Result := 1
  else if v1 < v2 then
    Result := -1
  else
    Result := 0;
end;

function CompareDates(ADate: TDateTime; Year, Month, Day: Integer): Integer;
var AYear, AMonth, ADay: Word;
begin
  DecodeDate(ADate, AYear, AMonth, ADay);
  Result := CompareValues(AYear * 512 + AMonth * 32 + ADay, Year * 512 + Month * 32 + Day);
end;

function isSameGUID(GUID1, GUID2: TGUID): Boolean;
begin
  Result := (GUID1.D1 = GUID2.D1) and (GUID1.D2 = GUID2.D2) and (GUID1.D3 = GUID2.D3) and
            (GUID1.D4[0] = GUID2.D4[0]) and (GUID1.D4[1] = GUID2.D4[1]) and (GUID1.D4[2] = GUID2.D4[2]) and (GUID1.D4[3] = GUID2.D4[3]) and
            (GUID1.D4[4] = GUID2.D4[4]) and (GUID1.D4[5] = GUID2.D4[5]) and (GUID1.D4[6] = GUID2.D4[6]) and (GUID1.D4[7] = GUID2.D4[7]);
end;

function IsPalettedFormat(PixelFormat: TPixelFormat): Boolean;
begin
  Result := (PixelFormat = pfP8) or (PixelFormat = pfA8P8);
end;

function GetBytesPerPixel(PixelFormat: TPixelFormat): Integer;
begin
  case PixelFormat of
    pfA8R8G8B8, pfX8R8G8B8, pfX8L8V8U8, pfQ8W8V8U8, pfV16U16, pfW11V11U10, pfD32, pfD24S8, pfD24X8, pfD24X4S4, pfR8G8B8A8: Result := 4;                  // 11 formats
    pfR8G8B8, pfB8G8R8, pfATIDF24: Result := 3;                                                                                                          // 3 formats
    pfR5G6B5, pfX1R5G5B5, pfA1R5G5B5, pfA4R4G4B4, pfX4R4G4B4, pfA8P8, pfA8L8, pfV8U8, pfL6V5U5,
    pfD16_LOCKABLE, pfD15S1, pfD16, pfA1B5G5R5, pfATIDF16: Result := 2;                                                                                  // 14 formats
    pfA8, pfP8, pfL8, pfA4L4: Result := 1;                                                                                                               // 4 formats
//    pfDXT1
//    pfDXT3
//    pfDXT5
    else Result := 0;
  end;
end;

function GetBitsPerPixel(PixelFormat: TPixelFormat): Integer;
begin
  Result := GetBytesPerPixel(PixelFormat) * 8;
end;

procedure QuickSortStrInd(N: Integer; Values: TUnicodeStringArray; Inds: TIndArray; Acc: Boolean);
type _QSDataType = UnicodeString;
{$DEFINE COMPARABLE}
{$I basics_quicksort_ind.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

procedure QuickSortStrInd(N: Integer; Values: TAnsiStringArray; Inds: TIndArray; Acc: Boolean);
type _QSDataType = AnsiString;
{$DEFINE COMPARABLE}
{$I basics_quicksort_ind.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

procedure QuickSortIntInd(N: Integer; Values, Inds: TIndArray; Acc: Boolean);
type _QSDataType = Integer;
{$DEFINE COMPARABLE}
{$I basics_quicksort_ind.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

procedure QuickSortSInd(N: Integer; Values: TSingleArray; Inds: TIndArray; Acc: Boolean);
type _QSDataType = Single;
{$DEFINE COMPARABLE}
{$I basics_quicksort_ind.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

procedure QuickSortStr(N: Integer; Values: TUnicodeStringArray);
type _QSDataType = UnicodeString;
{$DEFINE COMPARABLE}
{$I basics_quicksort.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

procedure QuickSortStr(N: Integer; Values: TAnsiStringArray);
type _QSDataType = AnsiString;
{$DEFINE COMPARABLE}
{$I basics_quicksort.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

procedure QuickSortInt(N: Integer; Values: TIndArray);
type _QSDataType = Integer;
{$DEFINE COMPARABLE}
{$I basics_quicksort.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

procedure QuickSortIntDsc(N: Integer; Values: TIndArray);
type _QSDataType = Integer;
{$DEFINE DESCENDING}
{$DEFINE COMPARABLE}
{$I basics_quicksort.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

procedure QuickSortS(N: Integer; Values: TSingleArray);
type _QSDataType = Single;
{$DEFINE COMPARABLE}
{$I basics_quicksort.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

function SaveString(Stream: TStream; const s: AnsiString): Boolean;
var l: Integer;
begin
  l := Length(s);
  Result := Stream.WriteCheck(l, SizeOf(l));
  if Result and (l > 0) then Result := Stream.WriteCheck(Pointer(s)^, l * SizeOf(AnsiChar));
end;

function SaveString(Stream: TStream; const s: UnicodeString): Boolean;
var l: Integer;
begin
  l := Length(s);
  Result := Stream.WriteCheck(l, SizeOf(l));
  if Result and (l > 0) then Result := Stream.WriteCheck(Pointer(s)^, l * SizeOf(WideChar));
end;


function LoadString(Stream: TStream; out s: AnsiString): Boolean;
var l: Cardinal;
begin
  Result := Stream.Read(l, SizeOf(l)) = SizeOf(l);
  if Result then begin
    SetLength(s, l);
    if l > 0 then Result := Stream.Read(Pointer(s)^, l * SizeOf(AnsiChar)) = l * SizeOf(AnsiChar);
  end;
end;

function LoadString(Stream: TStream; out   s: UnicodeString): Boolean;
var l: Cardinal;
begin
  Result := Stream.Read(l, SizeOf(l)) = SizeOf(l);
  if Result then begin
    SetLength(s, l);
    if l > 0 then Result := Stream.Read(Pointer(s)^, l * SizeOf(WideChar)) = l * SizeOf(WideChar);
  end;
end;

const CRCTable: array[0..255] of Longword =
     ($00000000, $77073096, $EE0E612C, $990951BA,
      $076DC419, $706AF48F, $E963A535, $9E6495A3,
      $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988,
      $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
      $1DB71064, $6AB020F2, $F3B97148, $84BE41DE,
      $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
      $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC,
      $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
      $3B6E20C8, $4C69105E, $D56041E4, $A2677172,
      $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
      $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940,
      $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
      $26D930AC, $51DE003A, $C8D75180, $BFD06116,
      $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
      $2802B89E, $5F058808, $C60CD9B2, $B10BE924,
      $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,

      $76DC4190, $01DB7106, $98D220BC, $EFD5102A,
      $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
      $7807C9A2, $0F00F934, $9609A88E, $E10E9818,
      $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
      $6B6B51F4, $1C6C6162, $856530D8, $F262004E,
      $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
      $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C,
      $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
      $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2,
      $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
      $4369E96A, $346ED9FC, $AD678846, $DA60B8D0,
      $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
      $5005713C, $270241AA, $BE0B1010, $C90C2086,
      $5768B525, $206F85B3, $B966D409, $CE61E49F,
      $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4,
      $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,

      $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A,
      $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
      $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8,
      $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
      $F00F9344, $8708A3D2, $1E01F268, $6906C2FE,
      $F762575D, $806567CB, $196C3671, $6E6B06E7,
      $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC,
      $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
      $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252,
      $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
      $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60,
      $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
      $CB61B38C, $BC66831A, $256FD2A0, $5268E236,
      $CC0C7795, $BB0B4703, $220216B9, $5505262F,
      $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04,
      $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,

      $9B64C2B0, $EC63F226, $756AA39C, $026D930A,
      $9C0906A9, $EB0E363F, $72076785, $05005713,
      $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38,
      $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
      $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E,
      $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
      $88085AE6, $FF0F6A70, $66063BCA, $11010B5C,
      $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
      $A00AE278, $D70DD2EE, $4E048354, $3903B3C2,
      $A7672661, $D06016F7, $4969474D, $3E6E77DB,
      $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0,
      $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
      $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6,
      $BAD03605, $CDD70693, $54DE5729, $23D967BF,
      $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94,
      $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);

procedure CalcCRC32(Bytes: PByteBuffer; ByteCount: Cardinal; var CRCValue: Longword);
var i: Cardinal;
begin
  for i := 0 to ByteCount - 1 do
    CRCvalue := (CRCvalue shr 8) xor CRCTable[Bytes^[i] xor (CRCvalue and $000000FF)];
end;

function ForEachFile(const PathAndMask: string; AttributeFilter: Integer; Delegate: TFileDelegate): Integer;
var SR: SysUtils.TSearchRec; Dir: string;
begin
  Result := 0;
  if SysUtils.FindFirst(PathAndMask, AttributeFilter, SR) = 0 then begin
    Dir := ExtractFilePath(PathAndMask);
    repeat
      Inc(Result);
      if not Delegate(Dir + SR.Name) then Break;
    until SysUtils.FindNext(SR) <> 0;
    SysUtils.FindClose(SR);
  end;
end;

procedure SpinWait(Iterations: Integer);
var i: Integer;
begin
  for i := 0 to Iterations-1 do begin
    {$IFDEF PUREPASCAL}
      // no operation
    {$ELSE}
      asm
         rep nop
      end;
    {$ENDIF}
  end;
end;

procedure InitTables();
var i: Integer;
begin
  for i := 0 to 31 do CtzTable[($077CB531 shl i) shr 27] := i;
end;

type
  TDefaultErrorHandler = class
    // This function used as default error handler
    function DefaultErrorHandler(const Error: TError): Boolean;
  end;

  function TDefaultErrorHandler.DefaultErrorHandler(const Error: TError): Boolean;
  begin
//    Log('An unhandled error of class "' + Error.ClassName + '": ' + Error.ErrorMessage, lkError);
    Result := False;                    // Do not continue
  end;

var err: TDefaultErrorHandler;

initialization
  InitTables();
  ErrorHandler := err.DefaultErrorHandler;
end.