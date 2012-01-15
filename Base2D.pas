(*
 @Abstract(Basic 2D Unit)
 (C) 2004-2007 George "Mirage" Bakhtadze
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains basic 2D types and routines
*)
{$Include GDefines.inc}
unit Base2D;

interface

uses BaseTypes, Basics, Models;

const
  // Pixel format for image processing
  ProcessingFormat = pfA8R8G8B8;
  // Size in bytes of pixel in ProcessingFormat
  ProcessingFormatBpP = 4;
  // Max value of component (R, G, B, etc) in processing format
  ProcessingComponentMax = 255;
  // Maximum of mip levels an image can have
  MaxMipLevels = 32;
  // Maximum number of image repeats in imagesource
  MaxImageRepeats = 4096;

type
  // Image resize filter
  TImageResizeFilter = (// No filter. Image will not be processed.
                        ifNone,
                        // Simple filter working only when image size is increased/decreased by N tymes where N positive integer value
                        ifSimple2X,
                        // Box filter
                        ifBox,
                        // Triangle filter
                        ifTriangle,
                        // Hermite filter
                        ifHermite,
                        // Bell filter
                        ifBell,
                        // Spline filter
                        ifSpline,
                        // Lanczos filter
                        ifLanczos,
                        // Mitchell filter
                        ifMitchell);
  // Image filter function
  TImageFilterFunction = function (Value: Single): Single;
  // Image origin
  TImageOrigin = (// Top-down image and its origin is the upper-left corner.
                  ioTopLeft,
                  // Bottom-up image and its origin is the lower-left corner
                  ioBottomLeft);
  // Image parameters data structure
  TImageHeader = record
    Format: Integer;
    LineSize: Integer;
    Width, Height: Integer;
    BitsPerPixel, ImageSize: Integer;
    ImageOrigin: TImageOrigin;
    PaletteSize: Cardinal;
    Palette: PPalette;
    Data: Pointer;
  end;

  // Generic image source class
  TBaseImageSource = class
  private
    FFormat: Integer;
    FWidth, FHeight: Integer;
//    PaletteSize: Cardinal;
//    Palette: PPalette;
    function GetBitsPerPixel: Integer;
    function GetBytesPerPixel: Integer;
  protected
    // Copies a rectangular area of the specified mip level of the image to an image with width DestImageWidth and data located in memory at Dest and returns True if success
    function GetData(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean; virtual; abstract;
    // Copies a rectangular area of the specified mip level of the image to an RGBA image with width DestImageWidth and data located in memory at Dest and returns True if success
    function GetDataAsRGBA(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean; virtual; abstract;
  public
    constructor Create(AFormat, AWidth, AHeight: Integer);
    // Calls implementation-dependent GetData() to load image data
    function LoadData(Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean;
    // Calls implementation-dependent GetDataAsRGBA() to load image data
    function LoadDataAsRGBA(Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean;
    // Image width
    property Width: Integer read FWidth;
    // Image height
    property Height: Integer read FHeight;
    // Number of bits per pixel
    property BitsPerPixel: Integer read GetBitsPerPixel;
    // Number of bytes per pixel
    property BytesPerPixel: Integer read GetBytesPerPixel;
  end;

  // Image source impementation for usual bitmap images
  TImageSource = class(TBaseImageSource)
  private
    FFormat: Integer;
    FBuf: Pointer;
  protected
    function GetData(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean; override;
    function GetDataAsRGBA(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean; override;
  public
    constructor Create(const ABuf: Pointer; AFormat, AWidth, AHeight: Integer);
  end;

const
  // Default values for resize filters
  DefaultResizeFilterValue: array [TImageResizeFilter] of Single = (0, 0, 0.5, 1.0, 1.0, 1.5, 2.0, 3.0, 2.0);
type
  // Image mip level record. Width, Height - level dimensions, Size - size of level data in bytes, Offset - offset of level data on bytes from top level data
  TImageLevel = record
    Width, Height: Integer;
    Size, Offset: Integer;
  end;
  // Image levels info
  TImageLevels = array[0..MaxMipLevels-1] of TImageLevel;

  // .bmp file information header data structure
  TBitmapInfoHeader = packed record
    biSize: Cardinal;
    biWidth, biHeight: Longint;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: Cardinal;
    biSizeImage: Cardinal;
    biXPelsPerMeter, biYPelsPerMeter: Longint;
    biClrUsed: Cardinal;
    biClrImportant: Cardinal;
  end;

  // .bmp file header data structure
  TBitmapFileHeader = packed record
    bfType: Word;
    bfSize: Cardinal;
    bfReserved1, bfReserved2: Word;
    bfOffBits: Cardinal;
  end;

  // Determines how source and destination colors should be combined
  TColorCombineOperation = (// Copy source color instead of destination (SrcColor)
                            coSet,
                            // Add corresponding color components (DestColor + SrcColor)
                            coAdd,
                            // Modulate corresponding color components (DestColor * SrcColor)
                            coMod,
                            // Substract corresponding color components (DestColor - SrcColor)
                            coSub);

  // The class incapsulates a brush which is used to paint over images
  TBrush = class
  private
    FShape: TImageHeader;
    FPattern: TImageHeader;
    FSource: TBaseImageSource;
    function GetHeight: Integer;
    function GetShapeData: Pointer;
    function GetWidth: Integer;
    function GetPatternData: Pointer;
  public
    Color: TColor;
    ColorCombineOperation: TColorCombineOperation;
    constructor Create;
    destructor Destroy; override;
    // Inits the brush with size, color combining operation and a bitmaps which determines the shape (8 bits per pixel) and color (32 bits per pixel) pattern of the brush
    procedure Init(AWidth, AHeight: Integer; AShape, APattern: Pointer; ABitmapFormat: Integer; AColor: TColor; AColorCombineOperation: TColorCombineOperation; ASource: TBaseImageSource); virtual;
    // Returns True if the brush can be used for draw operations
    function IsValid: Boolean;

    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
    property ShapeData: Pointer read GetShapeData;
    property PatternData: Pointer read GetPatternData;
    property Source: TBaseImageSource read FSource;
  end;

  // Base class for operations affecting an image
  TImageOperation = class(Models.TOperation)
  protected
    // Pointer to image data
    FImageData,
    // Pointer to operation data
    FData: Pointer;
    // Image pixel format
    FImageFormat,
    // Image line length in pixels
    FImageLineLength,
    // Image bytes per pixel
    FImageBpP: Integer;
    // Rectangle on image affected by the operation
    FRect: BaseTypes.TRect;
    procedure DoApply; override;
  public
    constructor Create(AImageData: Pointer; AImageLineLength, AImageFormat: Integer; const ARect: BaseTypes.TRect);
    // Rectangle on image affected by the operation
    property Rect: BaseTypes.TRect read FRect;
  end;

  // Paint on an image with a brush operation
  TImagePaintOp = class(TImageOperation)
  public
    constructor Create(X, Y: Integer; AImageData: Pointer; AImageLineLength, AImageFormat: Integer; ABrush: TBrush; const ARect: BaseTypes.TRect);
  end;

  // Paint on an image with source image using the shape of a brush operation
  TImageCloneOp = class(TImageOperation)
  public
    constructor Create(X, Y: Integer; AImageData: Pointer; AImageLineLength, AImageFormat: Integer; ABrush: TBrush;
                       SrcX, SrcY: Integer; ASource: TBaseImageSource; const ARect: BaseTypes.TRect);
  end;

function SwapRB(Color: BaseTypes.TColor): BaseTypes.TColor;
function GetIntensity(Color: BaseTypes.TColor): Integer;
function VCLColorToColor(Color: Integer): BaseTypes.TColor;
function ColorToVCLColor(Color: BaseTypes.TColor): Integer;

// Returns the number of mip levels (including 0-th) which an image with the specified dimensions should have and fills in the levels info
function GetSuggestedMipLevelsInfo(Width, Height, Format: Integer; out Levels: TImageLevels): Integer;

// Converts the specified number of pixels from any known format to ProcessingFormat. Returns False if input format is unknown or cannot be converted.
function ConvertToProcessing(Format, Size:Integer; Src: Pointer; PaletteSize: Integer; Palette: PPalette; Dest: Pointer): Boolean;
// Converts the specified number of pixels from ProcessingFormat to any known format. Returns False if input format is unknown or cannot be converted.
function ConvertFromProcessing(Format, Size:Integer; Src: Pointer; var PaletteSize: Integer; Palette: PPalette; Dest: Pointer): Boolean;
// Converts the specified number of pixels from any known format to another known format. Returns False if input format is unknown or cannot be converted.
function ConvertImage(SrcFormat, DestFormat, TotalPixels: Integer; Src: Pointer; PaletteSize: Integer; Palette: PPalette; Dest: Pointer): Boolean;

// Creates in Dest a thumbnail image of the given size and format from a rectangular area of original image. Returns True if success or False if conversion to <b>Format</b> is unsupported.
function CreateThumbnail(SrcFormat, SrcWidth: Integer; const SrcRect: BaseTypes.TRect; Src: Pointer; PaletteSize: Integer; Palette: PPalette; DestFormat, Width, Height: Integer; Dest: Pointer): Boolean;
function ResizeImage(Filter: TImageResizeFilter; FilterValue: Single; Format:Integer; Src: PImageBuffer; const SrcArea: BaseTypes.TRect; SrcLineLength: Integer;
                                                          const Dest: PImageBuffer; const DestArea: BaseTypes.TRect; DestLineLength: Integer): Boolean;
// Stretches a rectangular area of an ARGB image to a rectangular area of another ARGB image
procedure StretchARGBImage(Filter: TImageFilterFunction; const Radius: Single; Src: PImageBuffer; const SrcArea: BaseTypes.TRect; SrcLineLength: Integer; const Dest: PImageBuffer; const DestArea: BaseTypes.TRect; DestLineLength: Integer);
function ImageBoxFilter(Value: Single): Single;
function ImageTriangleFilter(Value: Single): Single;
function ImageHermiteFilter(Value: Single): Single;
function ImageBellFilter(Value: Single): Single;
function ImageSplineFilter(Value: Single): Single;
function ImageLanczos3Filter(Value: Single): Single;
function ImageMitchellFilter(Value: Single): Single;

function SaveIDF(const Stream: TStream; const IDFHeader: TIDFHeader; const Buffers: array of Pointer): Boolean;
function LoadIDF(const Stream: TStream; var IDFHeader: TIDFHeader; var Buffer: Pointer; var TotalSize: Integer): Boolean;
function LoadIDFBuffers(const Stream: TStream; var IDFHeader: TIDFHeader; var Buffers: TPointerArray; var TotalSize: Integer): Boolean;

// Loads a .bmp file header and positions Stream at raw data start. Returns True if sucess.
function LoadBitmapHeader(const Stream: TStream; out Header: TImageHeader): Boolean;
// Loads a .bmp file and returns True if success. 
function LoadBitmap(const Stream: TStream; out LineSize: Integer; out Width: Integer; out Height: Integer; out BitsPerPixel: Integer; out PaletteSize: Cardinal; out Palette: PPalette; out Data: Pointer): Boolean; overload;
// Loads a .bmp file and returns True if success. All image parameters are placed in Header.
function LoadBitmap(const Stream: TStream; var Header: TImageHeader): Boolean; overload;

// Copies a rectangular area from one buffer to another
procedure BufferCopy(const SBuf, DBuf: Pointer; const BufLineLength, BpP: Integer; const Rect: BaseTypes.TRect);
// Copies a rectangular area from one buffer to the top of another assuming width of destination buffer equal to width of the rectangle
procedure BufferCut(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, BpP: Integer; const Rect: BaseTypes.TRect);
// Copies a rectangular area from the top of one buffer to specified Rect of another assuming width of source buffer equal to width of the rectangle
procedure BufferPaste(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, BpP: Integer; const Rect: BaseTypes.TRect);
// Swaps contents of a rectangular area of one buffer with the contents of another assuming width of destination buffer equal to width of the rectangle
procedure BufferSwap(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, BpP: Integer; const Rect: BaseTypes.TRect);

// Copies a rectangular area from one buffer to the top of another changing its format to ARGB and returns True if success
function BufferCutAsRGBA(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, SrcFormat: Integer; const Rect: BaseTypes.TRect): Boolean;
// Copies a rectangular area from the top of RGBA buffer to specified Rect of another buffer with the specified format and returns True if success
function BufferRGBAPaste(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, DestFormat: Integer; const Rect: BaseTypes.TRect): Boolean;
// Combines a rectangular area from the top of RGBA buffer with specified Rect of another buffer with the specified format and returns True if success
function BufferRGBACombine(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, DestFormat: Integer; const Rect: BaseTypes.TRect): Boolean;
// Blends a rectangular area from the top of RGBA buffer with specified Rect of another buffer with the specified format using a separate 8-bit alpha-channel in ABuf and returns True if success
function BufferRGBABlend(const SBuf, DBuf, ABuf: Pointer; const SrcLineLength, DestLineLength, DestFormat: Integer; const Rect: BaseTypes.TRect): Boolean;

var
  OnProgress: TProgressDelegate;

implementation

const
  MaxImageRepeatsHalf = MaxImageRepeats div 2;

type
  PContributor = ^TContributor;
  TContributor = record
    Weight, Pixel: Integer;
  end;
  TContributors = array of TContributor;
  TContributorEntry = record
    N: Integer;
    Contributors: TContributors;
  end;

  TContributorList = array of TContributorEntry;

function SwapRB(Color: BaseTypes.TColor): BaseTypes.TColor;
begin
//  Result := (Color and 255) shl 16 + (Color shr 16) and 255 + Color and (255 shl 8);
  Result := Color;
  Result.R := Color.B;
  Result.B := Color.R;
end;

function GetIntensity(Color: BaseTypes.TColor): Integer;
begin
  Result := MaxI(MaxI(Color.R, Color.G), Color.B);
end;

function VCLColorToColor(Color: Integer): BaseTypes.TColor;
begin
  Result.C := Color;
  Result := SwapRB(Result);
end;

function ColorToVCLColor(Color: BaseTypes.TColor): Integer;
begin
  Color.A := 0;
  Result := SwapRB(Color).C;
end;

function GetSuggestedMipLevelsInfo(Width, Height, Format: Integer; out Levels: TImageLevels): Integer;
var MaxDim: Integer;
begin
  Levels[0].Width  := Width;
  Levels[0].Height := Height;
  Levels[0].Size   := Levels[0].Width * Levels[0].Height * GetBytesPerPixel(Format);
  Levels[0].Offset := 0;

  Result := 1;
  MaxDim := MaxI(Width, Height);
  while MaxDim > 1 do begin
    Levels[Result].Width  := MaxI(1, Levels[Result-1].Width  div 2);
    Levels[Result].Height := MaxI(1, Levels[Result-1].Height div 2);
    Levels[Result].Offset := Levels[Result-1].Offset + Levels[Result-1].Size;
    Levels[Result].Size   := Levels[Result].Width * Levels[Result].Height * GetBytesPerPixel(Format);
    Inc(Result);
    MaxDim := MaxDim div 2;
    Assert(Result < MaxMipLevels);
  end;
end;

function ConvertFromProcessing(Format, Size: Integer; Src: Pointer; var PaletteSize: Integer; Palette: PPalette; Dest: Pointer): Boolean;
var i: Integer;
begin
  Result := True;
  case Format of
    pfR8G8B8: for i := 0 to Size-1 do begin
      TRGBArray(Dest^)[i].R := TARGBArray(Src^)[i].B;
      TRGBArray(Dest^)[i].G := TARGBArray(Src^)[i].G;
      TRGBArray(Dest^)[i].B := TARGBArray(Src^)[i].R;
    end;
    pfB8G8R8: for i := 0 to Size-1 do begin
      TRGBArray(Dest^)[i].R := TARGBArray(Src^)[i].R;
      TRGBArray(Dest^)[i].G := TARGBArray(Src^)[i].G;
      TRGBArray(Dest^)[i].B := TARGBArray(Src^)[i].B;
    end;
    pfR8G8B8A8: for i := 0 to Size-1 do begin
      TRGBAArray(Dest^)[i].C := TARGBArray(Src^)[i].C shl 8;
      TRGBAArray(Dest^)[i].A := TARGBArray(Src^)[i].A;
    end;
    pfA8R8G8B8, pfX8R8G8B8, pfX8L8V8U8, pfQ8W8V8U8: Move(Src^, Dest^, Size*4);
    pfR5G6B5: for i := 0 to Size-1 do
     TWordBuffer(Dest^)[i] := Round(TARGBArray(Src^)[i].R / 255 * 31) shl 11 +
                              Round(TARGBArray(Src^)[i].G / 255 * 63) shl 5 +
                              Round(TARGBArray(Src^)[i].B / 255 * 31);
    pfX1R5G5B5, pfA1R5G5B5: for i := 0 to Size-1 do
     TWordBuffer(Dest^)[i] := Ord(TARGBArray(Src^)[i].A <> 0) shl 15 +
                              Round(TARGBArray(Src^)[i].R / 255 * 31) shl 10 +
                              Round(TARGBArray(Src^)[i].G / 255 * 31) shl 5 +
                              Round(TARGBArray(Src^)[i].B / 255 * 31);
    pfA4R4G4B4, pfX4R4G4B4: for i := 0 to Size-1 do
     TWordBuffer(Dest^)[i] := Round(TARGBArray(Src^)[i].A / 255 * 15) shl 12 +
                              Round(TARGBArray(Src^)[i].R / 255 * 15) shl 8 +
                              Round(TARGBArray(Src^)[i].G / 255 * 15) shl 4 +
                              Round(TARGBArray(Src^)[i].B / 255 * 15);
    pfA8, pfL8: for i := 0 to Size-1 do TByteBuffer(Dest^)[i] := Round((TARGBArray(Src^)[i].R +
                                                                              TARGBArray(Src^)[i].G +
                                                                              TARGBArray(Src^)[i].B) / 3);
//    pfP8:;
//    pfA8P8:;
    pfA8L8: for i := 0 to Size-1 do TWordBuffer(Dest^)[i] := TARGBArray(Src^)[i].A shl 8 + Round((TARGBArray(Src^)[i].R + TARGBArray(Src^)[i].G + TARGBArray(Src^)[i].B) / 3);
    pfV8U8: for i := 0 to Size-1 do TWordBuffer(Dest^)[i] := TARGBArray(Src^)[i].G shl 8 + TARGBArray(Src^)[i].B;
    pfA4L4: for i := 0 to Size-1 do TByteBuffer(Dest^)[i] := TARGBArray(Src^)[i].A and $F0 + Round((TARGBArray(Src^)[i].R + TARGBArray(Src^)[i].G + TARGBArray(Src^)[i].B) / 3/255*15);
//    pfL6V5U5:;
//    pfV16U16:;
//    pfW11V11U10:;
//    pfD32:;
    pfD16: for i := 0 to Size-1 do begin
      TWordBuffer(Dest^)[i] := Round((TARGBArray(Src^)[i].R + TARGBArray(Src^)[i].G + TARGBArray(Src^)[i].B) / 3/255*65535);
    end;
    else Result := False;
  end;
end;

function ConvertToProcessing(Format, Size: Integer; Src: Pointer; PaletteSize: Integer; Palette: PPalette; Dest: Pointer): Boolean;
var i: Integer; Temp: Byte;
begin
  Result := True;
  case Format of
    pfR8G8B8: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := 0;
      TARGBArray(Dest^)[i].R := TByteBuffer(Src^)[i*3];
      TARGBArray(Dest^)[i].G := TByteBuffer(Src^)[i*3 + 1];
      TARGBArray(Dest^)[i].B := TByteBuffer(Src^)[i*3 + 2];
    end;
    pfB8G8R8: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := 0;
      TARGBArray(Dest^)[i].B := TByteBuffer(Src^)[i*3];
      TARGBArray(Dest^)[i].G := TByteBuffer(Src^)[i*3 + 1];
      TARGBArray(Dest^)[i].R := TByteBuffer(Src^)[i*3 + 2];
    end;
    pfR8G8B8A8: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].C := TRGBAArray(Src^)[i].C shr 8;
      TARGBArray(Dest^)[i].A := TRGBAArray(Src^)[i].A;
    end;
    pfA8R8G8B8, pfX8R8G8B8, pfX8L8V8U8, pfQ8W8V8U8: Move(Src^, Dest^, Size*4);
    pfR5G6B5: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := 0;
      TARGBArray(Dest^)[i].R := Round((TWordBuffer(Src^)[i] shr 11) and 31 / 31*255);
      TARGBArray(Dest^)[i].G := Round((TWordBuffer(Src^)[i] shr 5) and 63 / 63*255);
      TARGBArray(Dest^)[i].B := Round( TWordBuffer(Src^)[i] and 31 / 31*255);
    end;
    pfX1R5G5B5, pfA1R5G5B5: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := Round( TWordBuffer(Src^)[i] shr 15 * 255);
      TARGBArray(Dest^)[i].R := Round((TWordBuffer(Src^)[i] shr 10) and 31 / 31*255);
      TARGBArray(Dest^)[i].G := Round((TWordBuffer(Src^)[i] shr 5) and 31 / 31*255);
      TARGBArray(Dest^)[i].B := Round( TWordBuffer(Src^)[i] and 31 / 31*255);
    end;
    pfA4R4G4B4, pfX4R4G4B4: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := Round((TWordBuffer(Src^)[i] shr 12) and 15 / 15*255);
      TARGBArray(Dest^)[i].R := Round((TWordBuffer(Src^)[i] shr 8) and 15 / 15*255);
      TARGBArray(Dest^)[i].G := Round((TWordBuffer(Src^)[i] shr 4) and 15 / 15*255);
      TARGBArray(Dest^)[i].B := Round( TWordBuffer(Src^)[i] and 15 / 15*255);
    end;
    pfA8, pfL8: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := TByteBuffer(Src^)[i];
      TARGBArray(Dest^)[i].R := TByteBuffer(Src^)[i];
      TARGBArray(Dest^)[i].G := TByteBuffer(Src^)[i];
      TARGBArray(Dest^)[i].B := TByteBuffer(Src^)[i];
    end;
    pfP8: for i := 0 to Size-1 do with TARGBArray(Dest^)[i] do begin
      A := Palette^[TByteBuffer(Src^)[i]].A;
      R := Palette^[TByteBuffer(Src^)[i]].R;
      G := Palette^[TByteBuffer(Src^)[i]].G;
      B := Palette^[TByteBuffer(Src^)[i]].B;
    end;
    pfA8P8: for i := 0 to Size-1 do with TARGBArray(Dest^)[i] do begin
      A := TWordBuffer(Src^)[i] shr 8;
      R := Palette^[TWordBuffer(Src^)[i] and 255].R;
      G := Palette^[TWordBuffer(Src^)[i] and 255].G;
      B := Palette^[TWordBuffer(Src^)[i] and 255].B;
    end;
    pfA8L8: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := TWordBuffer(Src^)[i] shr 8;
      TARGBArray(Dest^)[i].R := TWordBuffer(Src^)[i] and 255;
      TARGBArray(Dest^)[i].G := TWordBuffer(Src^)[i] and 255;
      TARGBArray(Dest^)[i].B := TWordBuffer(Src^)[i] and 255;
    end;
    pfV8U8: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := 0;
      TARGBArray(Dest^)[i].R := 0;
      TARGBArray(Dest^)[i].G := TWordBuffer(Src^)[i] shr 8;
      TARGBArray(Dest^)[i].B := TWordBuffer(Src^)[i] and 255;
    end;
    pfA4L4: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := TByteBuffer(Src^)[i] and $F0;
      Temp := Round((TByteBuffer(Src^)[i] and 15)*17);
      TARGBArray(Dest^)[i].R := Temp;
      TARGBArray(Dest^)[i].G := Temp;
      TARGBArray(Dest^)[i].B := Temp;
    end;
//    pfL6V5U5:;
//    pfV16U16:;
//    pfW11V11U10:;
//    pfD32:;
    pfD16: for i := 0 to Size-1 do begin
      TARGBArray(Dest^)[i].A := Round(TWordBuffer(Src^)[i]/65535*255);
      TARGBArray(Dest^)[i].R := Round(TWordBuffer(Src^)[i]/65535*255);
      TARGBArray(Dest^)[i].G := Round(TWordBuffer(Src^)[i]/65535*255);
      TARGBArray(Dest^)[i].B := Round(TWordBuffer(Src^)[i]/65535*255);
    end;
    else Result := False;
  end;
end;

//procedure ConvertImage(SrcFormat, DestFormat: Cardinal; LineLength, Width, Height: Integer; Src: Pointer; PaletteSize: Integer; Palette: Basics.PPalette; Dest: Pointer);
function ConvertImage(SrcFormat, DestFormat, TotalPixels: Integer; Src: Pointer; PaletteSize: Integer; Palette: PPalette; Dest: Pointer): Boolean;
var Temp: Pointer;
begin
  Result := False;
  if (Src = nil) or (Dest = nil) then Exit;
  if SrcFormat = DestFormat then begin
    Result := True;
    Move(Src^, Dest^, TotalPixels * GetBytesPerPixel(SrcFormat));
  end else begin
    GetMem(Temp, TotalPixels*ProcessingFormatBpP);
    Result := ConvertToProcessing(SrcFormat, TotalPixels, Src, PaletteSize, Palette, Temp) and
              ConvertFromProcessing(DestFormat, TotalPixels, Temp, PaletteSize, Palette, Dest);
    FreeMem(Temp);
  end;
end;

function ResizeImage(Filter: TImageResizeFilter; FilterValue: Single; Format:Integer; Src: PImageBuffer; const SrcArea: BaseTypes.TRect; SrcLineLength: Integer; const Dest: PImageBuffer; const DestArea: BaseTypes.TRect; DestLineLength: Integer): Boolean;
var
  NeedConvert: Boolean;
  MarginX, MarginY: Integer;
  ow, oh, nw, nh: Integer;
  NSrc, NDest: Pointer;
  NSrcArea, NDestArea: BaseTypes.TRect;
  NSrcLineLength, NDestLineLength: Integer;
  Garbage: IRefcountedContainer;

  procedure CheckFormat;
  begin
    NeedConvert := (Format <> pfA8R8G8B8) and (Filter <> ifNone) and (Filter <> ifSimple2X);
    if NeedConvert then begin
      MarginX := Ceil(FilterValue * ow/nw);
      MarginY := Ceil(FilterValue * oh/nh);

      RectMove(SrcArea,  -SrcArea.Left,  -SrcArea.Top,  NSrcArea);
      RectMove(DestArea, -DestArea.Left, -DestArea.Top, NDestArea);

      NSrcLineLength  := NSrcArea.Right  - NSrcArea.Left;
      NDestLineLength := NDestArea.Right - NDestArea.Left;

      GetMem(NSrc,  ow*oh * ProcessingFormatBpP);
      GetMem(NDest, ow*oh * ProcessingFormatBpP);

      Garbage.AddPointers([NSrc, NDest]);

      BufferCutAsRGBA(Src, NSrc, SrcLineLength, NSrcLineLength, Format, SrcArea);
    end else begin
      NSrc  := Src;
      NDest := Dest;

      NSrcArea  := SrcArea;
      NDestArea := DestArea;

      NSrcLineLength  := SrcLineLength;
      NDestLineLength := DestLineLength;
    end;
  end;

var
  XRatio, YRatio: Integer;
  i, j, BpP, FillValue: Integer;

begin
  Result := False;

  Garbage := CreateRefcountedContainer;

  ow := SrcArea.Right   - SrcArea.Left;
  oh := SrcArea.Bottom  - SrcArea.Top;
  nw := DestArea.Right  - DestArea.Left;
  nh := DestArea.Bottom - DestArea.Top;
  if (ow <= 0) or (oh <= 0) or (nw <= 0) or (nh <= 0){ or ((nw = ow) and (nh = oh))} then Exit;

  CheckFormat;
  BpP := GetBytesPerPixel(Format);

  case Filter of
    ifNone: begin
      FillValue := Round(FilterValue);
      for i := 0 to Basics.MinI(nh-1, oh-1) do begin
        Move(PtrOffs(NSrc, i*ow * BpP)^, PtrOffs(NDest, i*nw * BpP)^, Basics.MinI(nw, ow)*BpP);
        if nw > ow then FillChar(PtrOffs(NDest, (i*nw+ow) * BpP)^, (nw - ow)*BpP, FillValue);
      end;
      if nh > oh then for i := oh to nh-1 do FillChar(PtrOffs(NDest, (i*nw) * BpP)^, nw*BpP, FillValue);
    end;
    ifSimple2X: begin
      XRatio := ow mod nw;
      YRatio := oh mod nh;
      if (XRatio <> 0) or (YRatio <> 0) then begin
        ErrorHandler(TInvalidArgument.Create('ResizeImage: ifSimple2X filter can be used only to shrink image by an integer factor'));
        Exit;
      end;
      XRatio := ow div nw;
      YRatio := oh div nh;

      case BpP of
        1: for j := 0 to nh-1 do for i := 0 to nw-1 do
             PByteBuffer(NDest)^[(j + DestArea.Top)*DestLineLength + DestArea.Left + i] :=
               PByteBuffer(NSrc)^[(j*YRatio + SrcArea.Top)*SrcLineLength + SrcArea.Left + i*XRatio];
        2: for j := 0 to nh-1 do for i := 0 to nw-1 do
             PWordBuffer(NDest)^[(j + DestArea.Top)*DestLineLength + DestArea.Left + i] :=
               PWordBuffer(NSrc)^[(j*YRatio + SrcArea.Top)*SrcLineLength + SrcArea.Left + i*XRatio];
        4: for j := 0 to nh-1 do for i := 0 to nw-1 do
             PImageBuffer(NDest)^[(j + DestArea.Top)*DestLineLength + DestArea.Left + i] :=
               PImageBuffer(NSrc)^[(j*YRatio + SrcArea.Top)*SrcLineLength + SrcArea.Left + i*XRatio];
        else begin
          ErrorHandler(TInvalidFormat.Create('Invalid pixel format'));
          Exit;
        end;
      end;
    end;
    ifBox:      StretchARGBImage(ImageBoxFilter,      FilterValue, NSrc, NSrcArea, NSrcLineLength, NDest, NDestArea, NDestLineLength);
    ifTriangle: StretchARGBImage(ImageTriangleFilter, FilterValue, NSrc, NSrcArea, NSrcLineLength, NDest, NDestArea, NDestLineLength);
    ifHermite:  StretchARGBImage(ImageHermiteFilter,  FilterValue, NSrc, NSrcArea, NSrcLineLength, NDest, NDestArea, NDestLineLength);
    ifBell:     StretchARGBImage(ImageBellFilter,     FilterValue, NSrc, NSrcArea, NSrcLineLength, NDest, NDestArea, NDestLineLength);
    ifSpline:   StretchARGBImage(ImageSplineFilter,   FilterValue, NSrc, NSrcArea, NSrcLineLength, NDest, NDestArea, NDestLineLength);
    ifLanczos:  StretchARGBImage(ImageLanczos3Filter, FilterValue, NSrc, NSrcArea, NSrcLineLength, NDest, NDestArea, NDestLineLength);
    ifMitchell: StretchARGBImage(ImageMitchellFilter, FilterValue, NSrc, NSrcArea, NSrcLineLength, NDest, NDestArea, NDestLineLength);
  end;

  if NeedConvert then begin
    BufferRGBAPaste(NDest, Dest, NDestLineLength, DestLineLength, Format, DestArea);
  end;

  Result := True;
end;

function CreateThumbnail(SrcFormat, SrcWidth: Integer; const SrcRect: BaseTypes.TRect; Src: Pointer; PaletteSize: Integer; Palette: PPalette; DestFormat, Width, Height: Integer; Dest: Pointer): Boolean;
var i, j, SrcBpP, DestBpP: Integer; CurX, CurY, StepX, StepY: Single; Temp: Longword;
begin
  Result := False;
  Assert((Width <> 0) and (Height <> 0));

  SrcBpP  := GetBytesPerPixel(SrcFormat);
  DestBpP := GetBytesPerPixel(DestFormat);

  if (SrcBpP = 0) or (DestBpP = 0) then Exit;

  StepX := (SrcRect.Right  - SrcRect.Left) / (Width);
  StepY := (SrcRect.Bottom - SrcRect.Top) / (Height);

  CurY := SrcRect.Top;
  for j := 0 to Height-1 do begin
    CurX := SrcRect.Left;
    for i := 0 to Width-1 do begin
      if not ConvertToProcessing(SrcFormat, 1, PtrOffs(Src, (Round(CurY) * SrcWidth + Round(CurX)) * SrcBpP), PaletteSize, Palette, @Temp) or
         not ConvertFromProcessing(DestFormat, 1, @Temp, PaletteSize, Palette, PtrOffs(Dest, (j*Width + i) * DestBpP)) then Exit;
      CurX := CurX + StepX;
//      if Odd(j) then pdwordbuffer(dest)^[j*Width+i] := $FFFFFF else pdwordbuffer(dest)^[j*Width+i] := 0;
    end;                                                                       
    CurY := CurY + StepY;
  end;

  Result := True;
end;

function ImageBoxFilter(Value: Single): Single;
begin
  if (Value > -0.5) and (Value <= 0.5) then Result := 1.0 else Result := 0.0;
end;

function ImageTriangleFilter(Value: Single): Single;
begin
  if Value < 0.0 then Value := -Value;
  if Value < 1.0 then Result := 1.0 - Value else Result := 0.0;
end;

function ImageHermiteFilter(Value: Single): Single;
begin
  if Value < 0.0 then
    Value := -Value;
  if Value < 1 then
    Result := (2 * Value - 3) * Sqr(Value) + 1
  else
    Result := 0;
end;

function ImageBellFilter(Value: Single): Single;
begin
  if Value < 0.0 then Value := -Value;
  if Value < 0.5 then Result := 0.75 - Sqr(Value) else if Value < 1.5 then begin
    Value := Value - 1.5;
    Result := 0.5 * Sqr(Value);
  end else Result := 0.0;
end;

function ImageSplineFilter(Value: Single): Single;
var Temp: Single;
begin
  if Value < 0.0 then Value := -Value;
  if Value < 1.0 then begin
    Temp := Sqr(Value);
    Result := 0.5 * Temp * Value - Temp + 2.0 / 3.0;
  end else if Value < 2.0 then begin
    Value := 2.0 - Value;
    Result := Sqr(Value) * Value / 6.0;
  end else Result := 0.0;
end;

//--------------------------------------------------------------------------------------------------

{function ImageLanczos3Filter(Value: Single): Single;

  function SinC(Value: Single): Single;
  begin
    if Value <> 0.0 then begin
      Value := Value * Pi;
      Result := System.Sin(Value) / Value;
    end else Result := 1.0;
  end;

begin
  if Value < 0.0 then Value := -Value;
  if Value < 3.0 then Result := SinC(Value) * SinC(Value / 3.0) else Result := 0.0;
end;}

function ImageLanczos3Filter(Value: Single): Single;
const Radius = 3.0;
begin
  Result := 1;
  if Value = 0 then Exit;
  if Value < 0.0 then Value := -Value;
  if Value < Radius then begin
    Value := Value * pi;
    Result := Radius * Sin(Value) * Sin(Value / Radius) / (Value * Value);
  end else Result := 0.0;
end;

//--------------------------------------------------------------------------------------------------

function ImageMitchellFilter(Value: Single): Single;
const B = 1.0 / 3.0; C = 1.0 / 3.0;
var Temp: Single;
begin
  if Value < 0.0 then Value := -Value;
  Temp := Sqr(Value);
  if Value < 1.0 then begin
    Value := (((12.0 - 9.0 * B - 6.0 * C) * (Value * Temp)) +
             ((-18.0 + 12.0 * B + 6.0 * C) * Temp) +
             (6.0 - 2.0 * B));
    Result := Value / 6.0;
  end else if Value < 2.0 then begin
    Value := (((-B - 6.0 * C) * (Value * Temp)) +
             ((6.0 * B + 30.0 * C) * Temp) +
             ((-12.0 * B - 48.0 * C) * Value) +
             (8.0 * B + 24.0 * C));
    Result := Value / 6.0;
  end else Result := 0.0;
end;

function IntToByte(Value: Integer): Byte;
begin
  Result := MaxI(0, MinI(255, Value));
end;

procedure StretchARGBImage(Filter: TImageFilterFunction; const Radius: Single; Src: PImageBuffer; const SrcArea: BaseTypes.TRect; SrcLineLength: Integer; const Dest: PImageBuffer; const DestArea: BaseTypes.TRect; DestLineLength: Integer);
var
  Temp: PImageBuffer; TempSize: Integer;
  SX1, SY1, SX2, SY2, DX1, DY1, DX2, DY2: Integer;
  XStep, YStep: Single;
  Width, Center: Single;
  i, j, k, n: Integer;
  Left, Right, Weight: Integer;
  ContributorList: TContributorList;

  function ApplyContributors(Mult, N: Integer; Contributors: TContributors; Buf: PImageBuffer): TARGB;
  var J: Integer; RGB: TARGBInt; Total, Weight: Integer; Pixel: Cardinal; Contr: ^TContributor;
  begin
    RGB.R := 0; RGB.G := 0; RGB.B := 0; RGB.A := 0; Total := 0;
    Contr := @Contributors[0];
    for J := 0 to N-1 do begin
      Weight := Contr^.Weight;
      Inc(Total, Weight);
      Pixel := Contr^.Pixel;
{      if not ((Buf <> Temp) or (Cardinal(K*Mult)+Pixel < TempSize)) then begin
        Assert((Buf <> Temp) or (Cardinal(K*Mult)+Pixel < TempSize));
      end;}
      Inc(RGB.R, TARGB(Buf^[Cardinal(K*Mult)+Pixel]).R * Weight);
      Inc(RGB.G, TARGB(Buf^[Cardinal(K*Mult)+Pixel]).G * Weight);
      Inc(RGB.B, TARGB(Buf^[Cardinal(K*Mult)+Pixel]).B * Weight);
      Inc(RGB.A, TARGB(Buf^[Cardinal(K*Mult)+Pixel]).A * Weight);
      Inc(Contr);
    end;
    if Total = 0 then begin
      Result.R := IntToByte(RGB.R shr 8); Result.G := IntToByte(RGB.G shr 8); Result.B := IntToByte(RGB.B shr 8); Result.A := IntToByte(RGB.A shr 8);
    end else begin
      Result.R := IntToByte(RGB.R div Total); Result.G := IntToByte(RGB.G div Total); Result.B := IntToByte(RGB.B div Total); Result.A := IntToByte(RGB.A div Total);
    end;
  end;

begin
  with SrcArea do begin
    SX1 := MinI(Left, Right); SY1 := MinI(Top, Bottom);
    SX2 := MaxI(Left, Right); SY2 := MaxI(Top, Bottom);
  end;
  with DestArea do begin
    DX1 := MinI(Left, Right); DY1 := MinI(Top, Bottom);
    DX2 := MaxI(Left, Right); DY2 := MaxI(Top, Bottom);
  end;

  TempSize := DestLineLength{  (DX2-DX1)} * MaxI(DY2-DY1, SY2-SY1);
  GetMem(Temp, TempSize * ProcessingFormatBpP);

  XStep := (DX2-DX1)/(SX2-SX1);
  if XStep < 1 then Width := Radius / XStep else Width := Radius;
  SetLength(ContributorList, DX2);
  for I := 0 to DX2 - 1 do begin
    ContributorList[I].N := 0;
    SetLength(ContributorList[I].Contributors, Trunc(2 * Width + 3));
    Center := I / XStep;
    Left  := MinI(Floor(Center - Width), SrcLineLength-1);
    Right := MinI(Ceil(Center + Width), SrcLineLength-1);
    for J := Left to Right do begin
      if XStep < 1 then Weight := Round(Filter((Center - J) * XStep) * XStep * 256) else Weight := Round(Filter(Center - J) * 256);
      if Weight <> 0 then begin
        if J < 0 then N := -J else if J >= SX2 then N := SX2 - J + SX2 - 1 else N := J; // ToFix: SX2
        N := N mod SX2;
        K := ContributorList[I].N;
        Inc(ContributorList[I].N);
        ContributorList[I].Contributors[K].Pixel := N;
        ContributorList[I].Contributors[K].Weight := Weight;
      end;
    end;
  end;
  for K := 0 to SY2 - 1 do for I := 0 to DX2 - 1 do with ContributorList[I] do
    TARGB(Temp^[K*DestLineLength+I]) := ApplyContributors(SrcLineLength, N, ContributorList[I].Contributors, Src);
  for I := 0 to DX2 - 1 do ContributorList[I].Contributors := nil;
  ContributorList := nil;

  YStep := (DY2-DY1)/(SY2-SY1);
  if YStep < 1 then Width := Radius / YStep else Width := Radius;
  SetLength(ContributorList, DY2);
  for I := 0 to DY2 - 1 do begin
    ContributorList[I].N := 0;
    SetLength(ContributorList[I].Contributors, Trunc(2 * Width + 3));
    Center := I / YStep;
    Left  := MinI(Floor(Center - Width), SY2-SY1);
    Right := MinI(Ceil(Center + Width), SY2-SY1);
    for J := Left to Right do begin
      if YStep < 1 then Weight := Round(Filter((Center - J) * YStep) * YStep * 256) else Weight := Round(Filter(Center - J) * 256);
      if Weight <> 0 then begin
        if J < 0 then N := -J else if J >= SY2 then N := SY2 - J + SY2 - 1 else N := J; // ToFix: SY2
        N := N mod SY2;
        K := ContributorList[I].N;
        Inc(ContributorList[I].N);
//        ContributorList[I].Contributors[K].Pixel  := N*DX2;     // ? DX2=>(DX2-DX1) ?
        ContributorList[I].Contributors[K].Pixel  := N*(DX2-DX1);
        ContributorList[I].Contributors[K].Weight := Weight;
      end;
    end;
  end;
  for K := 0 to DX2 - 1 do for I := 0 to DY2 - 1 do with ContributorList[I] do
    TARGB(Dest^[I*DestLineLength+K]) := ApplyContributors(1, N, ContributorList[I].Contributors, Temp);
  for I := 0 to DY2 - 1 do ContributorList[I].Contributors := nil;
  ContributorList := nil;
  FreeMem(Temp);
end;

function SaveIDF(const Stream: TStream; const IDFHeader: TIDFHeader; const Buffers: array of Pointer): Boolean;
var i, CurW, CurH, BpP: Integer;
begin
  Result := False;
  if not Stream.WriteCheck(IDFHeader, SizeOf(IDFHeader)) then Exit;
  CurW := IDFHeader.Width; CurH := IDFHeader.Height;
  BpP := GetBytesPerPixel(IDFHeader.PixelFormat);
  if BpP = 0 then begin
    ErrorHandler(TInvalidFormat.Create('Invalid pixel format'));
    Exit;                                                        // Unrecoverable
  end;
  for i := 0 to Length(Buffers)-1 do begin
    if not Stream.WriteCheck(Buffers[i]^, CurW*CurH*BpP) then Exit;
    CurW := MaxI(1, CurW div 2); CurH := MaxI(1, CurH div 2);
  end;
  Result := True;
end;

function LoadIDF(const Stream: TStream; var IDFHeader: TIDFHeader; var Buffer: Pointer; var TotalSize: Integer): Boolean;
var i, CurW, CurH, BpP: Integer;
begin
  Result := False;
  if not Stream.ReadCheck(IDFHeader, SizeOf(IDFHeader)) or (IDFHeader.Signature <> 'IDF') then Exit;
  CurW := IDFHeader.Width; CurH := IDFHeader.Height;
  BpP := GetBytesPerPixel(IDFHeader.PixelFormat);
  if BpP = 0 then begin
    ErrorHandler(TInvalidFormat.Create('Invalid pixel format'));
    Exit;                                                        // Unrecoverable
  end;
    TotalSize := 0;
  for i := 0 to IDFHeader.MipLevels do begin
    Inc(TotalSize, CurW*CurH);
    CurW := MaxI(1, CurW div 2);
    CurH := MaxI(1, CurH div 2);
  end;
  GetMem(Buffer, TotalSize*BpP);
  if not Stream.ReadCheck(Buffer^, TotalSize*BpP) then begin FreeMem(Buffer); TotalSize := 0; end else Result := True;
end;

function LoadIDFBuffers(const Stream: TStream; var IDFHeader: TIDFHeader; var Buffers: TPointerArray; var TotalSize: Integer): Boolean;
var i, j, CurW, CurH, BpP: Integer;
begin
  Result := False;
  if (not Stream.ReadCheck(IDFHeader, SizeOf(IDFHeader))) or (IDFHeader.Signature <> 'IDF') then Exit;
  CurW := IDFHeader.Width; CurH := IDFHeader.Height;
  BpP := GetBytesPerPixel(IDFHeader.PixelFormat);
  if BpP = 0 then begin
    ErrorHandler(TInvalidFormat.Create('Invalid pixel format'));
    Exit;                                                        // Unrecoverable
  end;
  TotalSize := 0;
  SetLength(Buffers, IDFHeader.MipLevels+1);
  for i := 0 to Length(Buffers)-1 do begin
    Inc(TotalSize, CurW*CurH);
    GetMem(Buffers[i], CurW*CurH*BpP);
    if not Stream.ReadCheck(Buffers[i]^, CurW*CurH*BpP) then begin
      for j := 0 to i do FreeMem(Buffers[i]);
      TotalSize := 0;
      Exit;
    end;
    CurW := MaxI(1, CurW div 2);
    CurH := MaxI(1, CurH div 2);
  end;
  Result := True;
end;

function LoadBitmapHeader(const Stream: TStream; out Header: TImageHeader): Boolean;
var
 FileHeader: TBITMAPFILEHEADER;
 InfoHeader: TBITMAPINFOHEADER;
begin
  Result := False;

  if not Stream.ReadCheck(FileHeader, SizeOf(FileHeader)) then Exit;
  if FileHeader.bfType <> Ord('M')*256 + Ord('B') then begin
    ErrorHandler(TInvalidFormat.Create('Not a .bmp file'));
    Exit;
  end;
  if not Stream.ReadCheck(InfoHeader, SizeOf(InfoHeader)) then Exit;

  Header.Width  := InfoHeader.biWidth;
  Header.Height := Abs(InfoHeader.biHeight);
  Header.BitsPerPixel := InfoHeader.biBitCount;
  Header.LineSize := Header.Width * Header.BitsPerPixel div 8;
  if InfoHeader.biHeight < 0 then Header.ImageOrigin := ioTopLeft else Header.ImageOrigin := ioBottomLeft;

  if Header.LineSize and 3 <> 0 then Header.LineSize := Header.LineSize + 4 - Header.LineSize and 3;
  case Header.BitsPerPixel of                                  // ToDo: Test with more .bmp files and fix if necessary
    1..8:   Header.Format := pfP8;
    15, 16: Header.Format := pfR5G6B5;
    24:     Header.Format := pfB8G8R8;
    32:     Header.Format := pfA8R8G8B8;
  end;

  Header.PaletteSize := InfoHeader.biClrUsed;
  if (InfoHeader.biBitCount <= 8) and (Header.PaletteSize = 0) then Header.PaletteSize := 256;
  Getmem(Header.Palette, Header.PaletteSize * SizeOf(TPaletteItem));
  if not Stream.ReadCheck(Header.Palette^, Header.PaletteSize * SizeOf(TPaletteItem)) then begin FreeMem(Header.Palette); Exit; end;
  Header.ImageSize := InfoHeader.biSizeImage;
  if Header.ImageSize = 0 then Header.ImageSize := Header.LineSize * Header.Height;
  Result := True;
end;

function LoadBitmap(const Stream: TStream; out LineSize: Integer; out Width: Integer; out Height: Integer; out BitsPerPixel: Integer; out PaletteSize: Cardinal; out Palette: PPalette; out Data: Pointer): Boolean;
var Header: TImageHeader;
begin
  Result := False;
  if not LoadBitmap(Stream, Header) then Exit;
  Width        := Header.Width;
  Height       := Header.Height;
  BitsPerPixel := Header.BitsPerPixel;
  LineSize     := Header.LineSize;
  PaletteSize  := Header.PaletteSize;
  Palette      := Header.Palette;
  Data         := Header.Data;

  Result := True;
end;

function LoadBitmap(const Stream: TStream; var Header: TImageHeader): Boolean;
var i, CurLine, Remainder, RemData: Integer;
begin
  Result := False;

  if not LoadBitmapHeader(Stream, Header) then Exit;

  // Convert header from .bmp to usual image
  Remainder := Header.LineSize - Header.Width * Header.BitsPerPixel div 8;
  Assert((Remainder >= 0) and (Remainder < 4));
  Header.LineSize  := Header.Width * Header.BitsPerPixel div 8;
  Header.ImageSize := Header.LineSize * Header.Height;
  // Get the actual pixel data
  GetMem(Header.Data, Header.ImageSize);

  if Header.ImageOrigin = ioTopLeft then CurLine := 0 else CurLine := Header.Height-1;

  for i := 0 to Header.Height-1 do begin
    if not Stream.ReadCheck(PtrOffs(Header.Data, CurLine*Header.LineSize)^, Header.LineSize) or
       not Stream.ReadCheck(RemData, Remainder) then begin
      FreeMem(Header.Data);
      Exit;
    end;
    if Header.ImageOrigin = ioTopLeft then Inc(CurLine) else Dec(CurLine);
  end;
  Result := True;
end;

procedure BufferCopy(const SBuf, DBuf: Pointer; const BufLineLength, BpP: Integer; const Rect: BaseTypes.TRect);
var j: Integer;
begin
  for j := Rect.Top to Rect.Bottom-1 do
    Move(PByteBuffer(SBuf)^[(j*BufLineLength+Rect.Left)*BpP],
         PByteBuffer(DBuf)^[(j*BufLineLength+Rect.Left)*BpP], (Rect.Right-Rect.Left)*BpP);
end;

procedure BufferCut(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, BpP: Integer; const Rect: BaseTypes.TRect);
var w, j: Integer;
begin
  w := Rect.Right-Rect.Left;
  for j := Rect.Top to Rect.Bottom-1 do
    Move(PByteBuffer(SBuf)^[(j*SrcLineLength+Rect.Left)*BpP], PByteBuffer(DBuf)^[(j-Rect.Top)*DestLineLength*BpP], w*BpP);
end;

procedure BufferPaste(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, BpP: Integer; const Rect: BaseTypes.TRect);
var w, j: Integer;
begin
  w := Rect.Right-Rect.Left;
  for j := Rect.Top to Rect.Bottom-1 do
    Move(PByteBuffer(SBuf)^[(j-Rect.Top)*SrcLineLength*BpP], PByteBuffer(DBuf)^[(j*DestLineLength+Rect.Left)*BpP], w*BpP);
end;

procedure BufferSwap(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, BpP: Integer; const Rect: BaseTypes.TRect);
const MaxLineSize = $FFFF*4;
var w, j: Integer; Temp: array[0..MaxLineSize] of Byte;
begin
  w := Rect.Right-Rect.Left;
  Assert(w*BpP <= MaxLineSize, 'BufferSwap: Line size is too big');
  for j := Rect.Top to Rect.Bottom-1 do begin
    Move(PByteBuffer(DBuf)^[(j-Rect.Top)*DestLineLength*BpP], Temp[0], w*BpP);
    Move(PByteBuffer(SBuf)^[(j*SrcLineLength+Rect.Left)*BpP], PByteBuffer(DBuf)^[(j-Rect.Top)*DestLineLength*BpP], w*BpP);
    Move(Temp[0], PByteBuffer(SBuf)^[(j*SrcLineLength+Rect.Left)*BpP], w*BpP);
  end;
end;

function BufferCutAsRGBA(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, SrcFormat: Integer; const Rect: BaseTypes.TRect): Boolean;
var w, j, BpP: Integer;
begin
  Result := False;
  w := Rect.Right-Rect.Left;
  BpP := GetBytesPerPixel(SrcFormat);
  for j := Rect.Top to Rect.Bottom-1 do
    if not ConvertToProcessing(SrcFormat, w, PtrOffs(SBuf, (j*SrcLineLength+Rect.Left)*BpP), 0, nil, PtrOffs(DBuf, (j-Rect.Top)*DestLineLength*ProcessingFormatBpP)) then Exit;
  Result := True;
end;

function BufferRGBAPaste(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, DestFormat: Integer; const Rect: BaseTypes.TRect): Boolean;
var w, j, BpP, tmp: Integer;
begin
  Result := False;
  w := Rect.Right-Rect.Left;
  BpP := GetBytesPerPixel(DestFormat);
  for j := Rect.Top to Rect.Bottom-1 do
    if not ConvertFromProcessing(DestFormat, w, PtrOffs(SBuf, (j-Rect.Top)*SrcLineLength*ProcessingFormatBpP), tmp, nil, PtrOffs(DBuf, (j*DestLineLength+Rect.Left)*BpP)) then Exit;
  Result := True;
end;

function BufferRGBACombine(const SBuf, DBuf: Pointer; const SrcLineLength, DestLineLength, DestFormat: Integer; const Rect: BaseTypes.TRect): Boolean;
const MaxLineLength = $FFFF;
var w, i, j, BpP, tmp: Integer; Temp: array[0..MaxLineLength] of TColor; Col: TColor;
begin                       
  Result := False;
  w := Rect.Right-Rect.Left;
  Assert(w <= MaxLineLength, 'Base2D.BufferRGBACombine: Line length is too big');
  BpP := GetBytesPerPixel(DestFormat);
  for j := Rect.Top to Rect.Bottom-1 do begin
    if not ConvertToProcessing(DestFormat, w, PtrOffs(DBuf, (j*DestLineLength+Rect.Left)*BpP), 0, nil, @Temp[0]) then Exit;
    for i := 0 to Rect.Right-Rect.Left-1 do begin
      Col := PColor(PtrOffs(SBuf, ((j-Rect.Top)*SrcLineLength+i)*ProcessingFormatBpP))^;
      Temp[i] := BlendColor(Temp[i], Col, Col.A/255);
    end;
    if not ConvertFromProcessing(DestFormat, w, @Temp[0], tmp, nil, PtrOffs(DBuf, (j*DestLineLength+Rect.Left)*BpP)) then Exit;
  end;
  Result := True;
end;

function BufferRGBABlend(const SBuf, DBuf, ABuf: Pointer; const SrcLineLength, DestLineLength, DestFormat: Integer; const Rect: BaseTypes.TRect): Boolean;
const MaxLineLength = $FFFF;
var w, i, j, BpP, tmp, Addr: Integer; Temp: array[0..MaxLineLength] of TColor; Col: TColor;
begin
  Result := False;
  w := Rect.Right-Rect.Left;
  Assert(w <= MaxLineLength, 'Base2D.BufferRGBABlend: Line length is too big');
  BpP := GetBytesPerPixel(DestFormat);
  for j := Rect.Top to Rect.Bottom-1 do begin
    if not ConvertToProcessing(DestFormat, w, PtrOffs(DBuf, (j*DestLineLength+Rect.Left)*BpP), 0, nil, @Temp[0]) then Exit;
    for i := 0 to Rect.Right-Rect.Left-1 do begin
      Addr := ((j-Rect.Top)*SrcLineLength+i);
      Col := PColor(PtrOffs(SBuf, Addr*ProcessingFormatBpP))^;
      Temp[i] := BlendColor(Temp[i], Col, PByteBuffer(ABuf)^[Addr]/255);
    end;
    if not ConvertFromProcessing(DestFormat, w, @Temp[0], tmp, nil, PtrOffs(DBuf, (j*DestLineLength+Rect.Left)*BpP)) then Exit;
  end;
  Result := True;
end;

{ TBaseImageSource }

function TBaseImageSource.GetBitsPerPixel: Integer;
begin
  Result := Basics.GetBitsPerPixel(FFormat);
end;

function TBaseImageSource.GetBytesPerPixel: Integer;
begin
  Result := Basics.GetBytesPerPixel(FFormat);
end;

constructor TBaseImageSource.Create(AFormat, AWidth, AHeight: Integer);
begin
  FFormat := AFormat;
  FWidth  := AWidth;
  FHeight := AHeight;
end;

function TBaseImageSource.LoadData(Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean;
begin
  Result := GetData(Rect, Dest, DestImageWidth);
end;

function TBaseImageSource.LoadDataAsRGBA(Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean;
var xo1, xo2, xn, yo1, yo2, yn, tmp: Integer;

  function GetLine(ATop, AHeight: Integer): Boolean;
    function GetCol(ALeft, AWidth: Integer): Boolean;
    var LRect: TRect;
    begin
      LRect := GetRectWH((ALeft + FWidth  * (xn+1)) mod FWidth,
                         (ATop  + FHeight * (yn+1)) mod FHeight,
                         AWidth, AHeight);
      Result := GetDataAsRGBA(LRect, PtrOffs(Dest, ((ATop - Rect.Top) * DestImageWidth + ALeft - Rect.Left) * ProcessingFormatBpP), DestImageWidth);
    end;
  var l, lxn: Integer;
  begin
    Result := False;

    l := Rect.Left;
    if xo1 > 0 then begin
      if not GetCol(l, xo1) then Exit;
      l := l + xo1;
      if l mod FWidth  <> 0 then begin
        Assert(l mod FWidth = 0);
      end;  
    end;
    lxn := xn;
    while lxn > 0 do begin
      if not GetCol(l, FWidth) then Exit;
      l := l + FWidth;
      Dec(lxn);
    end;
    if xo2 > 0 then begin
      if not GetCol(l, xo2) then Exit;
      l := l + xo2;
    end;
    Assert(l = Rect.Right);

    Result := True;
  end;

  var t: Integer;

//   _ ___ --- ___ __
//  xo1 w   w   w  xo2
begin
  Result := True;
  if (Rect.Right <= Rect.Left) or (Rect.Bottom <= Rect.Top) then Exit;
  Result := False;

  RectMove(Rect, MaxImageRepeatsHalf * FWidth, MaxImageRepeatsHalf * FHeight, Rect);

  xo1 := (FWidth - (Rect.Left mod FWidth)) mod FWidth;
  xo2 := Rect.Right mod FWidth;
  tmp := (Rect.Right - Rect.Left - xo1 - xo2);
  xn := tmp div FWidth;
  if tmp < 0 then begin
    xo2 := -FWidth + xo1 + xo2;
    xo1 := 0;
  end;

  yo1 := (FHeight - (Rect.Top mod FHeight)) mod FHeight;
  yo2 := Rect.Bottom mod FHeight;
  tmp :=(Rect.Bottom - Rect.Top - yo1 - yo2);
  yn := tmp div FHeight;
  if tmp < 0 then begin
    yo2 := -FHeight + yo1 + yo2;
    yo1 := 0;
  end;

  t := Rect.Top;
  if yo1 > 0 then begin
    if not GetLine(t, yo1) then Exit;
    t := t + yo1;
    Assert(t mod FHeight = 0);
  end;
  while yn > 0 do begin
    if not GetLine(t, FHeight) then Exit;
    t := t + FHeight;
    Dec(yn);
  end;
  if yo2 > 0 then begin
    if not GetLine(t, yo2) then Exit;
    t := t + yo2;
  end;
  Assert(t = Rect.Bottom);

  Result := True;
end;

{ TImageOperation }

procedure TImageOperation.DoApply;
begin
  Assert(Assigned(FImageData), 'TImageOperation.DoApply: Image data is undefined');
  BufferSwap(FImageData, FData, FImageLineLength, FRect.Right-FRect.Left, FImageBpP, FRect);
end;

constructor TImageOperation.Create(AImageData: Pointer; AImageLineLength, AImageFormat: Integer; const ARect: BaseTypes.TRect);
begin
  FImageData       := AImageData;
  FImageLineLength := AImageLineLength;
  FImageFormat     := AImageFormat;
  FImageBpP        := GetBytesPerPixel(FImageFormat);
  FRect            := ARect;
  GetMem(FData, (FRect.Bottom-FRect.Top) * (FRect.Right-FRect.Left) * FImageBpP);
//  FillChar(FData^, (FRect.Bottom-FRect.Top) * (FRect.Right-FRect.Left) * FImageBpP, 0);
end;

function CombineValues(OldValue, NewValue, Mask: Longword; ColorOp: TColorCombineOperation): BaseTypes.TColor;
begin
  NewValue := NewValue and Mask;
  case ColorOp of
    coSet: Result.C := Longword(OldValue and (not Mask)) + NewValue;
    coAdd: asm
      movd            MM0, OldValue
      movd            MM1, NewValue
      paddusb         MM0, MM1
      movd            Result, MM0
      emms
    end;
    coSub: asm
      movd            MM0, OldValue
      movd            MM1, NewValue
      psubusb         MM0, MM1
      movd            Result, MM0
      emms
    end;
    coMod: asm
      pxor            MM2, MM2
      movd            MM0, OldValue

      mov             EAX, NewValue
      mov             DX, AX
      shl             EAX, 16
      mov             AX, DX
//      movd            MM1, EAX
      psllq           MM1, 32
//      psllw           MM1, 8
      movd            MM3, EAX
      por             MM1, MM3

      punpcklbw       MM0, MM2
      pmullw          MM0, MM1
      psrlw           MM0, 8
      packuswb        MM0, MM2

      mov             EAX, Mask
      not             EAX
      and             OldValue, EAX

      movd            EAX, MM0
      and             EAX, Mask
      or              EAX, OldValue
//      mov             Result, EAX
      emms
    end;
  end;
end;

{ TImagePaintOp }

constructor TImagePaintOp.Create(X, Y: Integer; AImageData: Pointer; AImageLineLength, AImageFormat: Integer; ABrush: TBrush; const ARect: BaseTypes.TRect);
begin
  inherited Create(AImageData, AImageLineLength, AImageFormat, GetRectIntersect(GetRect(X, Y, X+ABrush.Width, Y+ABrush.Height), ARect));

  BufferCut(FImageData, FData, FImageLineLength, Rect.Right-Rect.Left, FImageBpP, Rect);
  BufferRGBABlend(PtrOffs(ABrush.PatternData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X)) * SizeOf(TColor)),
                  FData,
                  PtrOffs(ABrush.ShapeData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X))),
                  ABrush.Width, Rect.Right-Rect.Left, FImageFormat, GetRectMoved(Rect, -Rect.Left, -Rect.Top));
//  BufferRGBACombine(PtrOffs(ABrush.PatternData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X)) * SizeOf(TColor)),
//                  FData,
//                  ABrush.Width, Rect.Right-Rect.Left, FImageFormat, GetRectMove(Rect, -Rect.Left, -Rect.Top));
end;

{ TImageCloneOp }

constructor TImageCloneOp.Create(X, Y: Integer; AImageData: Pointer; AImageLineLength, AImageFormat: Integer; ABrush: TBrush;
                                 SrcX, SrcY: Integer; ASource: TBaseImageSource; const ARect: TRect);
begin
  if not Assigned(ASource) then begin
    ErrorHandler(TInvalidArgument.Create('TImageCloneOp.Create: Can''t create operation: invalid image source'));
    Exit;
  end;
  inherited Create(AImageData, AImageLineLength, AImageFormat, GetRectIntersect(GetRect(X, Y, X+ABrush.Width, Y+ABrush.Height), ARect));
//  ASource.GetData(GetRectWH(SrcX, SrcY, Rect.Right-Rect.Left, Rect.Bottom-Rect.Top), FData, Rect.Right-Rect.Left);
  BufferRGBABlend(PtrOffs(ABrush.PatternData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X)) * SizeOf(TColor)),
                  FData,
                  PtrOffs(ABrush.ShapeData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X))),
                  ABrush.Width, Rect.Right-Rect.Left, FImageFormat, GetRectMoved(Rect, -Rect.Left, -Rect.Top));

//  BufferRGBACombine(PtrOffs(ABrush.ShapeData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X)) * SizeOf(TColor)),
//                    FData, ABrush.Width, Rect.Right-Rect.Left, FImageFormat, GetRectMove(Rect, -Rect.Left, -Rect.Top));
end;

{ TBrush }

function TBrush.GetWidth: Integer;
begin
  Result := FShape.Width;
end;

function TBrush.GetHeight: Integer;
begin
  Result := FShape.Height;
end;

function TBrush.GetShapeData: Pointer;
begin
  Result := FShape.Data;
end;

function TBrush.GetPatternData: Pointer;
begin
  Result := FPattern.Data;
end;

constructor TBrush.Create;
begin
  FShape.Data   := nil;
  FPattern.Data := nil;
end;

destructor TBrush.Destroy;
begin
  if Assigned(FShape.Data)   then FreeMem(FShape.Data);
  if Assigned(FPattern.Data) then FreeMem(FPattern.Data);
  inherited;
end;

procedure TBrush.Init(AWidth, AHeight: Integer; AShape, APattern: Pointer; ABitmapFormat: Integer; AColor: TColor; AColorCombineOperation: TColorCombineOperation; ASource: TBaseImageSource);
begin
  FShape.Format       := pfA8;
  FShape.Width        := AWidth;
  FShape.Height       := AHeight;
  FShape.BitsPerPixel := GetBitsPerPixel(FShape.Format);
  FShape.PaletteSize  := 0;
  FShape.Palette      := nil;
  FShape.LineSize     := FShape.Width * FShape.BitsPerPixel div BitsInByte;
  FShape.ImageSize    := FShape.LineSize * FShape.Height;

  FPattern.Format       := pfA8R8G8B8;
  FPattern.Width        := AWidth;
  FPattern.Height       := AHeight;
  FPattern.BitsPerPixel := GetBitsPerPixel(FPattern.Format);
  FPattern.PaletteSize  := 0;
  FPattern.Palette      := nil;
  FPattern.LineSize     := FPattern.Width * FPattern.BitsPerPixel div BitsInByte;
  FPattern.ImageSize    := FPattern.LineSize * FPattern.Height;

  ReallocMem(FShape.Data, FShape.ImageSize);
//  ConvertImage(ABitmapFormat, FShape.Format, AWidth*AHeight, ABitmap, 0, nil, FShape.Data);
  ReallocMem(FPattern.Data, FPattern.ImageSize);

  if Assigned(AShape)   then Move(AShape^,   FShape.Data^,   FShape.ImageSize);
  if Assigned(APattern) then Move(APattern^, FPattern.Data^, FPattern.ImageSize);

  Color := AColor;
  ColorCombineOperation := AColorCombineOperation;

  FSource := ASource;

  Assert(IsValid);
end;

function TBrush.IsValid: Boolean;
begin
  Result := (FShape.Format <> pfUndefined) and (FShape.BitsPerPixel > 0) and
            (FShape.Width > 0) and (FShape.Height > 0) and
             Assigned(FShape.Data) and
            (FPattern.Format <> pfUndefined) and (FPattern.BitsPerPixel > 0) and
            (FPattern.Width > 0) and (FPattern.Height > 0) and
             Assigned(FPattern.Data)
end;

{ TImageSource }

function TImageSource.GetData(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean;
begin
  BufferCut(FBuf, Dest, FWidth, DestImageWidth, Basics.GetBytesPerPixel(FFormat), Rect);
  Result := True;
end;

function TImageSource.GetDataAsRGBA(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean;
begin
  Result := BufferCutAsRGBA(FBuf, Dest, FWidth, DestImageWidth, FFormat, Rect);
end;

constructor TImageSource.Create(const ABuf: Pointer; AFormat, AWidth, AHeight: Integer);
begin
  FFormat := AFormat;
  FWidth  := AWidth;
  FHeight := AHeight;
  FBuf    := ABuf;
end;

end.

