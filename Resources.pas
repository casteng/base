(*
 @Abstract(Basic resources unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains basic resource classes
*)
{$Include GDefines.inc}
unit Resources;

interface

uses SysUtils, OSUtils,
     {$IFDEF UNICODE} AnsiStrings, {$ENDIF}
     Logger,
     BaseTypes, Basics, BaseStr, BaseMsg, Base2D, Base3D, Props, BaseClasses;

const
  // Image mip levels policy enumeration string
  MipPolicyEnum = 'No mips' + StringDelimiter + 'Persistent' + StringDelimiter + 'Generated';
  // Image filters enumeration string
  ImageFilterEnums = 'None'    + StringDelimiter + 'Simple 2X' + StringDelimiter +
                     'Box'     + StringDelimiter + 'Triangle'  + StringDelimiter +
                     'Hermite' + StringDelimiter + 'Bell'      + StringDelimiter +
                     'Spline'  + StringDelimiter + 'Lanczos'   + StringDelimiter +
                     'Mitchell';
  // Minimum mega image block size
  MinBlockSize = 32;
  // A substring to separate URL type part in a resource URL
  URLTypeSeparator = '://';

type
  // Type for string resource 
  TResString = type AnsiString;

  // Variables of this type are resource type identifiers i.e. bitmap, .obj model, etc
  TResourceTypeID = TFileSignature;

  // This message is sent to a resource when it should reload its data
  TResourceReloadMsg = class(TMessage)
  end;

  // Mip (LOD) levels policy
  TMipPolicy = (// No mip levels used
                mpNoMips,
                // Mip levels are persistent and stored with original image
                mpPersistent,
                // Mip levels are generated and not stored with original image
                mpGenerated);
  // Base resource class)
  TResource = class(TItem)
  private
    FLoaded: Boolean;
    FExternal: Boolean;
    FFormat: Cardinal;
    FData: Pointer;
    FDataSize, DataOffsetInStream: Integer;
    FCarrierURL: string;
    FLastModified: TDateTime;
    function GetData: Pointer;
    function GetTotalElements: Integer;
    function SaveToCarrier: Boolean;
    function LoadFromCarrier(NewerOnly: Boolean): Boolean;
    procedure SetCarrierURL(const Value: string);
  protected
    // Returns number of bytes which should be allocated for the resource in a storage stream
    function GetDataSizeInStream: Integer; virtual;
    // Should perform actual conversion from old format to a new one and return True if the conversion is possible and successful
    function Convert(OldFormat, NewFormat: Cardinal): Boolean; virtual;
    // Calls Convert() and if it returns True sets the new format
    procedure SetFormat(const Value: Cardinal);
    // Read resource's data from the specified stream
    function LoadData(Stream: Basics.TStream): Boolean; virtual;
    // Not used yet
    procedure SetLoaded(Value: Boolean); virtual;
    // Not used yet
    procedure UnloadData; virtual;
  public
    constructor Create(AManager: TItemsManager); override;
    destructor Destroy; override;
    procedure Assign(ASource: TItem); override;
    class function IsAbstract: Boolean; override;

    function GetItemSize(CountChilds: Boolean): Integer; override;

    procedure HandleMessage(const Msg: TMessage); override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    // Allocates an empty data buffer or changes allocated size of an existing one
    procedure Allocate(ASize: Integer);
    // Sets already allocated and probably ready to use data
    procedure SetAllocated(ASize: Integer; AData: Pointer);
    // Returns size of each element in resource
    function GetElementSize: Integer; virtual;

    // Loads the resource from a stream
    function Load(Stream: Basics.TStream): Boolean; override;
    // Saves the resource to a stream
    function Save(Stream: Basics.TStream): Boolean; override;

    // Resource format
    property Format: Cardinal read FFormat write SetFormat;
    // Determines if the resource is loaded completely including its data
    property Loaded: Boolean read FLoaded write SetLoaded;
    // Data size in bytes
    property DataSize: Integer read FDataSize write Allocate;
    // Data size in bytes in general stream or zero if the resource's data is stored separately
    property DataSizeInStream: Integer read GetDataSizeInStream;
    // Pointer to the resource's data
    property Data: Pointer read GetData;
    // Number of elements in the resource
    property TotalElements: Integer read GetTotalElements;
    property CarrierURL: string read FCarrierURL write SetCarrierURL;
  end;

  // This message should be sent to core handler, resource which was modified and possibly broadcasted if data of a resource has been modified
  TResourceModifyMsg = class(TNotificationMessage)
    // Resource, containing the modified data
    Resource: TResource;
    // AResource - a resource, containing the modified data
    constructor Create(AResource: TResource);
  end;

  // Array of resource type IDs
  TResTypeList = array of TResourceTypeID;

  // Abstract class descendants of which should load and/or save resources of a certain class
  TResourceCarrier = class
  protected
    // List of types the carrier can save
    SavingTypes,
    // List of types the carrier can load
    LoadingTypes: TResTypeList;
    // Sets carrier URL for the specified resource without trying to load it immediately
    procedure SetCarrierURL(AResource: TResource; const ACarrierURL: string);
    // Should perform actual resource load
    function DoLoad(Stream: TStream; const AURL: string; var Resource: TItem): Boolean; virtual; abstract;
  public
    // Calls Init() and logs supported formats
    constructor Create; virtual;
    // Should fill SavingTypes and LoadingTypes
    procedure Init; virtual;
    // Returns True if the carrier can save resources of the specified type
    function CanSave(ResType: TResourceTypeID): Boolean;
    // Returns True if the carrier can load resources of the specified type
    function CanLoad(ResType: TResourceTypeID): Boolean;
    // Returns resource class which the carrier can handle
    function GetResourceClass: CItem; virtual; abstract;
    { Checks if class of the resource matches type of the data stream and calls DoLoad() to load the resource.
      If Resource is nil the function creates a new resource of appropriate class.
      Some streams can contain multiple resources and even other items (e.g. mesh file).
      Carriers which handles those kind of resources can create hierarchies of items.
      For this Resource.Manager should be assigned. Otherwise only Resource data will be loaded.
      Returns True on success. }
    function Load(Stream: TStream; const AURL: string; var Resource: TItem): Boolean;
  end;

  // Singleton class which registers and manages carriers classes for various resource types
  TResourceLinker = class
  private
    FCarriers: array of TResourceCarrier;
  public
    constructor Create;
    destructor Destroy; override;
    // Returns carrier class which can load resources of the specified type or nil if such a carrier was not registered
    function GetLoader(ResType: TResourceTypeID): TResourceCarrier;
    // Returns carrier class which can save resources of the specified type or nil if such a carrier was not registered
    function GetWriter(ResType: TResourceTypeID): TResourceCarrier;
    // Adds a registered carrier. The latter registered carriers will override previously registered ones if those can handle same resource types
    procedure RegisterCarrier(Carrier: TResourceCarrier);
  end;

  // Base class for all array-based resources
  TArrayResource = class(TResource)
    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;
  end;

  // @Abstract(Stores an image)
  TImageResource = class(TResource)
  private
    procedure SetMipPolicy(const Value: TMipPolicy); virtual;
    procedure ObtainFilter(OldWidth, OldHeight, NewWidth, NewHeight: Integer; out OFilter: TImageResizeFilter; out OFilterValue: Single);
    procedure SetMinFilter(const Value: TImageResizeFilter);
    procedure SetMagFilter(const Value: TImageResizeFilter);
    function GetActualLevels: Integer;
  protected
    // Image width
    FWidth,
    // Image height
    FHeight: Integer;
    // Information about mip levels
    FLevels: TImageLevels;
    // Number of mip levels requested (via properties). 0 to use FSuggestedLevels.
    FRequestedLevels,
    // Suggested number of mip levels based on dimensions
    FSuggestedLevels,
    // Number of bits per pixel
    FBitsPerPixel: Integer;

    // Mip levels policy
    FMipPolicy: TMipPolicy;
    // Filter used when the image size is decreased and for mipmaps calculation
    FMinFilter,
    // Filter used when the image size is increased. Image width have more priority than height when choosing filter.
    FMagFilter: TImageResizeFilter;
    // Parameter value for minification filter
    FMinFilterParameter,
    // Parameter value for magnification filter
    FMagFilterParameter: Single;

    // Images with generated mipmaps needs less space in storage stream
    function GetDataSizeInStream: Integer; override;
    // Returns information about specified mip level
    function GetLevelInfo(Index: Integer): TImageLevel;
    // Performs image conversion from one format to another
    function Convert(OldFormat, NewFormat: Cardinal): Boolean; override;
  public
    // Resource containing image's palette (for paletted image formats only).
    PaletteResource: TArrayResource;
    constructor Create(AManager: TItemsManager); override;
    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    function GetElementSize: Integer; override;

    function Save(Stream: Basics.TStream): Boolean; override;
    function Load(Stream: Basics.TStream): Boolean; override;

    // Creates an empty image with the specified dimensions
    procedure CreateEmpty(AWidth, AHeight: Integer); virtual;
    // Sets width and height of the image. Data should be initialized. deprecated: @Link(MinFilter)/@Link(MagFilter) will be used to resize.
    procedure SetDimensions(AWidth, AHeight: Integer); virtual;
    // Generates mip data
    procedure GenerateMipLevels(ARect: BaseTypes.TRect);

    // Image width
    property Width: Integer read FWidth;
    // Image height
    property Height: Integer read FHeight;
    // Mip levels policy
    property MipPolicy: TMipPolicy read FMipPolicy write SetMipPolicy;
    // Suggested mip levels
    property SuggestedLevels: Integer read FSuggestedLevels;
    // Actual number of mip levels
    property ActualLevels: Integer read GetActualLevels;
    // Mip levels information
    property LevelInfo[Index: Integer]: TImageLevel read GetLevelInfo;
    // Filter used when the image size is decreased and for mipmaps calculation
    property MinFilter: TImageResizeFilter read FMinFilter write SetMinFilter;
    // Filter used when the image size is increased. Image width have more priority than height when choosing filter.
    property MagFilter: TImageResizeFilter read FMagFilter write SetMagFilter;
    // Parameter value for minification filter
    property MinFilterParameter: Single read FMinFilterParameter write FMinFilterParameter;
    // Parameter value for magnification filter
    property MagFilterParameter: Single read FMagFilterParameter write FMagFilterParameter;
  end;

  // @Abstract(Stores a texture)
  TTextureResource = class(TImageResource)
  private
    FMipLevels: Integer;

    procedure SetMipLevels(const Value: Integer);
  public

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    function GetMipLevelData(ALevel: Integer): Pointer;

    // Number of mip-levels
    property MipLevels: Integer read FMipLevels write SetMipLevels;
  end;

  // @Abstract(Stores a sound)
  TAudioResource = class(TArrayResource)
  end;

  // @Abstract(Stores some text)
  TTextResource = class(TArrayResource)
  protected
    // Returns text stored by the resource
    function GetText: TResString; virtual;
    // Sets text stored by the resource
    procedure SetText(const NewText: TResString); virtual;
  public
    function GetElementSize: Integer; override;
    // Text stored by the resource
    property Text: TResString read GetText write SetText;
  end;

  { @Abstract(Stores a script)
    @Link(Text) property returns script's source text. @Link(Data) stores compiled version.
    When @Link(Source) property is changed a message of class <b>TDataModifyMsg</b> will be broadcasted to allow timely update of <b>data</b> property. }
  TScriptResource = class(TTextResource)
  protected
    // Script source text
    FSource: TResString;
    // Compiled code size. Zero value means that code size is same as the resource data size.
    FCodeSize: Integer;
    // Returns source text
    function GetText: TResString; override;
    // Sets source text
    procedure SetText(const NewText: TResString); override;
  public
    // Sets compiled code size if it has different value than resource data size (in case if some other information is stored within the resource)
    procedure SetCodeSize(ACodeSize: Integer);

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;
    // Source text
    property Source: TResString read FSource write SetText;
    // Compiled code size. Zero value means that code size is same as the resource data size.
    property CodeSize: Integer read FCodeSize;
  end;

  // @Abstract(Stores a path)
  TPathResource = class(TArrayResource)
  end;

  // @Abstract(Stores an UV-corrdinates mapping)
  TUVMapResource = class(TArrayResource)
    function GetElementSize: Integer; override;
  end;

  // @Abstract(Stores a characted mapping)
  TCharMapResource = class(TArrayResource)
    function GetElementSize: Integer; override;
  end;

  // @Abstract(Stores a palette)
  TPaletteResource = class(TArrayResource)
    function GetElementSize: Integer; override;
  end;

  // Data structure used for mega image caching
  TCahceRec = record
    Level, X, Y: Integer;
    Data: Pointer;
  end;

  { Stores an extra large image which can not be handled as usual due to its size. The image is stored in a stream
    divided into blocks. Some number of blocks are cached in memory.
    Optimal block size and cache size depending on how the mega image will be used and should be determined empirically. }
  TMegaImageResource = class(TImageResource)
  private
    FBlockWidth, FBlockHeight, ActualBlockWidth, ActualBlockHeight, FNumBlocksX, FNumBlocksY: Integer;
    FDataStream: TStream;
    FStoreFileName, FSourceFileName: TFileName;

    FCacheTotal, FCacheCurrent: Integer;
    FCacheData: array of array of array of Pointer;      // MipLevels * FNumBlocksX * FNumBlocksY
    FCacheStart, FCacheEnd: Integer;
    FCache: array of TCahceRec;
    procedure SetMipPolicy(const Value: TMipPolicy); override;
    // Stores in FDataStream the image divided in blocks of the specified size and retuns True if success
    function Prepare(AImageSource: TStream): Boolean;
    procedure DelCacheBlock;
    function AddCacheBlock(ALevel, AX, AY: Integer): Pointer;
    // Inits cache
    procedure InitCache(ACacheTotal: Integer);
    // Inits internal parameters. Returns True if all parameters are correct.
    function Init(ABlockWidth, ABlockHeight: Integer): Boolean;
    // Writes the specified cached data block to data stream and returns True if success.
    function SaveBlockData(ALevel, ABlockX, ABlockY: Integer): Boolean;
  public
    destructor Destroy; override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    procedure CreateEmpty(AWidth, AHeight: Integer); override;
    procedure SetDimensions(AWidth, AHeight: Integer); override;

    // Returns address of data of the specified block. Puts the block into cache if it was not here already.
    function GetBlockData(ALevel, ABlockX, ABlockY: Integer): Pointer;
    { Copies a sequence of ALength pixels starting at (AX, AY) from the specified mip level of the megaimage
      to an image with width DestImageWidth and data located in memory at Dest and returns True if success }
    function LoadSeq(AX, AY, ALength, ALevel: Integer; Dest: Pointer): Boolean;
    // Copies a rectangular area of the specified mip level of the megaimage to an image with width DestImageWidth and data located in memory at Dest and returns True if success
    function LoadRect(const Rect: TRect; ALevel: Integer; Dest: Pointer; DestImageWidth: Integer): Boolean;
    // Copies a rectangular area of the specified mip level of the megaimage to an RGBA image with width DestImageWidth and data located in memory at Dest and returns True if success
    function LoadRectAsRGBA(Rect: TRect; ALevel: Integer; Dest: Pointer; DestImageWidth: Integer): Boolean;
    { Copies a sequence of ALength pixels from an image with data located in memory at Src to
      a rectangular area on the specified mip level of the mega image starting at (AX, AY) from the specified mip level of the megaimage and returns True if success }
    function SaveSeq(AX, AY, ALength, ALevel: Integer; Src: Pointer): Boolean;
    { Copies a rectangular area from an image with width SrcImageWidth and data located in memory at Src
      to the specified mip level of the megaimage and returns True if success. Rebuilds all mipmaps lower than Level if BuildMips is True. }
    function SaveRect(Rect: TRect; ALevel: Integer; Src: Pointer; SrcImageWidth: Integer; BuildMips: Boolean): Boolean;
    // Data store stream
    property DataStream: TStream read FDataStream write FDataStream;
  end;

  // Image source impementation for mega images
  TMegaImageSource = class(TBaseImageSource)
  private
    FResource: TMegaImageResource;
    FLevel: Integer;
  protected  
    function GetData(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean; override;
    function GetDataAsRGBA(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean; override;
  public
    constructor Create(AResource: TMegaImageResource; ALevel: Integer);
  end;

  TMegaImagePaintOp = class(TImageOperation)
  private
    FTempData: Pointer;
    FResource: TMegaImageResource;
    FLevel: Integer;
  protected
    procedure DoApply; override;
  public
    constructor Create(X, Y: Integer; AResource: TMegaImageResource; ALevel: Integer; ABrush: TBrush; const ARect: BaseTypes.TRect);
    destructor Destroy; override;
  end;

  // Intermediate class for image resource carriers
  TImageCarrier = class(TResourceCarrier)
  public
    // Inits resource with the given parameters and returns True on success
    function InitResource(Image: TImageResource; const AURL: string; AWidth, AHeight: Integer; AFormat: TPixelFormat; ASize: Integer; AData: Pointer): Boolean;  
  end;

  // Resource carrier implementation for .bmp files
  TBitmapCarrier = class(TImageCarrier)
  protected
    function DoLoad(Stream: TStream; const AURL: string; var Resource: TItem): Boolean; override;
  public
    procedure Init; override;
    function GetResourceClass: CItem; override;
  end;

  // Returns list of classes introduced by the unit
  function GetUnitClassList: TClassArray;
  // Access to the TResourceLinker singleton class instance
  function ResourceLinker: TResourceLinker;
  // Builds TResourceTypeID from a file extension
  function GetResTypeFromExt(const ext: AnsiString): TResourceTypeID;
  // Builds resource types list
  function GetResTypeList(ResTypeArray: array of TResourceTypeID): TResTypeList;
  // Figures out and returns a resource type ID from resource URL string
  function GetResourceTypeID(const URL: AnsiString): TResourceTypeID;
  // Figures out stream class from resource URL string and creates, initializes and returns an instance of it. Application should take care of freeing the instance.
  function GetResourceStream(const URL: string; ShouldExists: Boolean): TStream;
  // Returns time of last data modification or "12/30/1899 12:00 am" (zero) if the time can not be retrieved
  function GetResourceModificationTime(const URL: string): TDateTime;


implementation


function GetUnitClassList: TClassArray;
begin
  Result := GetClassList([TResource, TImageResource, TMegaImageResource, TArrayResource, TCharMapResource, TUVMapResource, TAudioResource, TTextResource, TScriptResource]);
end;

var LResourceLinker: TResourceLinker;

function ResourceLinker: TResourceLinker;
begin
  Result := LResourceLinker;
end;

function GetResTypeFromExt(const ext: AnsiString): TResourceTypeID;
var i: Integer;
begin
  Result[0] := '.';
  for i := 1 to High(Result) do
    if i <= Length(ext) then
      Result[i] := UpperCase(Copy(ext, i, 1))[1]
    else
      Result[i] := ' ';
end;

function GetResTypeList(ResTypeArray: array of TResourceTypeID): TResTypeList;
var i: Integer;
begin
  SetLength(Result, Length(ResTypeArray));
  for i := 0 to High(Result) do Result[i] := ResTypeArray[i];
end;

function GetResourceTypeID(const URL: AnsiString): TResourceTypeID;
begin
  Result := GetResTypeFromExt(GetFileExt(URL));
end;

function GetFileNameFromURL(const URL: string): string;
var Ind: Integer;
begin
  Ind := Pos(URLTypeSeparator, URL);
  if Ind <> 0 then
    Result := Copy(URL, Ind+2, Length(URL))
  else
    Result := URL;
end;

function GetResourceStream(const URL: string; ShouldExists: Boolean): TStream;
var FileName: string;
begin
  FileName := GetFileNameFromURL(URL);
  if not ShouldExists or FileExists(FileName) then
    Result := TFileStream.Create(FileName)
  else
    Result := nil;
end;

function GetResourceModificationTime(const URL: string): TDateTime;
var FileName: string;
begin
  FileName := GetFileNameFromURL(URL);
  if FileExists(FileName) then
    Result := OSUtils.GetFileModifiedTime(FileName)
  else
    Result := 0;
end;

{ TResource }

function TResource.GetDataSizeInStream: Integer;
begin
  Result := FDataSize;
end;

function TResource.Convert(OldFormat, NewFormat: Cardinal): Boolean;
begin
  Result := not Assigned(Data);
//  Result := True;
end;

procedure TResource.SetFormat(const Value: Cardinal);
var Changed: Boolean; OldData: Pointer;
begin
  OldData := Data;
  {$IFDEF DEBUGMODE} FConsistent := False; {$ENDIF}      // The resource is not valid within the Convert() method because its contents is not compliant to Format variable
  Changed := (Value <> FFormat) and Convert(FFormat, Value);
  if Changed then FFormat := Value;
  {$IFDEF DEBUGMODE} FConsistent := True; {$ENDIF}
  if Assigned(FManager) then begin
    if (FData <> OldData) then SendMessage(TDataAdressChangeMsg.Create(OldData, FData, True), nil, [mfCore, mfBroadcast]);
    if Changed then SendMessage(TResourceModifyMsg.Create(Self), Self, [mfCore, mfRecipient]);
  end;
end;

function TResource.GetData: Pointer;
begin
//  Result := nil;
//  if not Loaded then if LoadData(Root.Core.DataStream) <> feOK then Exit;
  Result := FData;
end;

function TResource.LoadData(Stream: Basics.TStream): Boolean;
begin
  Result := False;

{.$IFDEF COMPATMODE}
  if (DataOffsetInStream = -1) or (Stream = nil) then begin
     Log('TResource.LoadData: Failed to load resource data', lkError); 
    Exit;
  end;
  if not Stream.Seek(DataOffsetInStream) then Exit;
{.$ENDIF}

  GetMem(FData, DataSize);
  if not Stream.ReadCheck(FData^, DataSize) then Exit;
  FLastModified := Now;

  Result  := True;
  FLoaded := True;
end;

constructor TResource.Create(AManager: TItemsManager);
begin
  inherited;
  FLoaded            := True;
  FData              := nil;
  FDataSize          :=  0;
  DataOffsetInStream := -1;
  FLastModified      := Now;
end;

destructor TResource.Destroy;
begin
  UnloadData;
  inherited;
end;

procedure TResource.Assign(ASource: TItem);
var OldData: Pointer;
begin
  inherited;
  // Copy resource data instead of just copying a pointer
  if ASource is TResource then begin
    OldData := FData;
    GetMem(FData, DataSize);
    Move(TResource(ASource).Data^, FData^, DataSize);
    FLastModified := TResource(ASource).FLastModified;
    if OldData <> nil then SendMessage(TDataAdressChangeMsg.Create(OldData, FData, FData <> nil), nil, [mfBroadcast, mfCore]);    
  end;
end;

class function TResource.IsAbstract: Boolean;
begin
  Result := Self = TResource;
end;

function TResource.GetItemSize(CountChilds: Boolean): Integer;
begin
  Result := inherited GetItemSize(CountChilds);
  if FLoaded then Inc(Result, FDataSize);
end;

procedure TResource.HandleMessage(const Msg: TMessage);
begin
  inherited;
  if Msg.ClassType = TResourceReloadMsg then
    LoadFromCarrier(True)
  else if Msg.ClassType = TResourceModifyMsg then
    FLastModified := Now;
end;

procedure TResource.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;
  Result.Add('Format'   ,     vtNat,     [poReadonly],           IntToStrA(Format),    '');
  Result.Add('Data size',     vtInt,     [poReadonly, poHidden], IntToStrA(FDataSize), '');
  Result.Add('Data loaded',   vtBoolean, [poReadonly],           OnOffStr[FLoaded],    '');
  Result.Add('Data external', vtBoolean, [],                     OnOffStr[FExternal],  '');

  if not FExternal then   
    Result.AddBinary('Data', [poReadonly, poHidden], FData, DataSizeInStream);

  Result.Add('Data carrier',  vtString,  [], FCarrierURL,     '');
  Result.Add('Data reload',   vtBoolean, [], OnOffStr[False], '');
end;

procedure TResource.SetProperties(Properties: Props.TProperties);
var Prop: PProperty; RealDataSize: Integer; LLoaded: Boolean; 
begin
  inherited;
  if Properties.Valid('Format')    then Format := StrToInt64Def(Properties['Format'], 0);

  LLoaded := False;
  if Properties.Valid('Data carrier') then begin
    FCarrierURL := Properties['Data carrier'];
    //if FCarrierURL <> '' then LLoaded := LoadFromCarrier(False);
  end;
  if Properties.Valid('Data reload') and (Properties.GetAsInteger('Data reload') > 0) then
    LLoaded := LoadFromCarrier(False);

  if not LLoaded and Properties.Valid('Data size') then begin
    if Properties.Valid('Data') then begin
      Prop := Properties.GetProperty('Data');
      Properties.AcquireData(Pointer(StrToInt64Def(Properties['Data'], 0)));
      RealDataSize := StrToIntDef(Prop.Enumeration, FDataSize);

      if RealDataSize = FDataSize then
        SetAllocated(StrToIntDef(Properties['Data size'], FDataSize), Pointer(StrToInt64Def(Properties['Data'], Integer(FData))))
      else begin
        SetAllocated(RealDataSize, Pointer(StrToInt64Def(Properties['Data'], Integer(FData))));
        Allocate(StrToIntDef(Properties['Data size'], FDataSize));
      end;
    end else Allocate(StrToIntDef(Properties['Data size'], FDataSize));
  end;
end;

procedure TResource.Allocate(ASize: Integer);
var OldData: Pointer;
begin
  if (ASize = FDataSize) and (FData <> nil) then Exit;
  OldData := FData;
  ReallocMem(FData, ASize);
  FDataSize := ASize;
  FLoaded := True;
  if Assigned(FManager) and (FData <> OldData) then SendMessage(TDataAdressChangeMsg.Create(OldData, FData, OldData <> nil), nil, [mfCore, mfBroadcast]);
end;

procedure TResource.SetAllocated(ASize: Integer; AData: Pointer);
var OldData: Pointer;
begin
  Assert((ASize = 0) or Assigned(AData));
  OldData := FData;
  FDataSize := ASize;
  if (FData <> AData) and (FData <> nil) then FreeMem(FData);
  FData     := AData;
  FLoaded   := True;
  FLastModified := Now;
  if Assigned(FManager) and (FData <> OldData)
     {$IFDEF DEBUGMODE} and FConsistent {$ENDIF} then SendMessage(TDataAdressChangeMsg.Create(OldData, FData, True), nil, [mfCore, mfBroadcast]);
end;

function TResource.GetElementSize: Integer;
begin
  Result := DataSize;
end;

function TResource.GetTotalElements: Integer;
begin
  Assert(FDataSize mod GetElementSize = 0, ClassName + '.GetTotalElements: Invalid data size');
  Result := FDataSize div GetElementSize;
end;

function TResource.SaveToCarrier: Boolean;
begin
//  FLastModified := 
  Result := False;
end;

function TResource.LoadFromCarrier(NewerOnly: Boolean): Boolean;
var Garbage: IRefcountedContainer; LCarrier: TResourceCarrier; Stream: TStream; CarrierModified: TDateTime;
begin
  Result := False;
  if FCarrierURL = '' then Exit;
  LCarrier := ResourceLinker.GetLoader(GetResourceTypeID(FCarrierURL));
  if not Assigned(LCarrier) then begin
    Log(ClassName + '.LoadFromCarrier: No appropriate loader found for URL: "' + FCarrierURL + '"', lkWarning);
    Exit;
  end;
  CarrierModified := GetResourceModificationTime(FCarrierURL);
  if NewerOnly and (CarrierModified <= FLastModified) then begin
    Log(' *** Resource: ' + DateTimeToStr(FLastModified) + ', carrier: ' + DateTimeToStr(CarrierModified), lkDebug);
    Exit;
  end;
  FLastModified := CarrierModified;

  Garbage := CreateRefcountedContainer();
  Stream := GetResourceStream(FCarrierURL, True);
  Garbage.AddObject(Stream);
  if not Assigned(Stream) then Exit;
  Result := LCarrier.Load(Stream, FCarrierURL, TItem(Self));
  if Result then SendMessage(TResourceModifyMsg.Create(Self), nil, [mfCore]);
end;

procedure TResource.SetCarrierURL(const Value: string);
begin
  SetProperty('Data carrier', Value);
end;

function TResource.Load(Stream: Basics.TStream): Boolean;
begin
//  {$IFNDEF COMPATMODE}
//  Result := feCannotRead;
//  if LoadData(Stream) <> feOK then Exit;
//  UnloadData;
  Result := inherited Load(Stream);
//  {$ELSE}
{  if not inherited Load(Stream) then Exit;
  DataOffsetInStream := Stream.Position;
  if not Stream.Seek(Stream.Position + Cardinal(DataSize)) then Exit;       // Move to the next
  UnloadData;
  LoadData(Stream);
  Result := True;}
//  {$ENDIF}
end;

function TResource.Save(Stream: Basics.TStream): Boolean;
begin
//  Result := feCannotRead;
//  if not Loaded and (LoadData(Stream) <> feOK) then Exit;         // Try to load data if it's not loaded
//  Result := feCannotWrite;
//  if Stream.Write(FData^, DataSize) <> feOK then Exit;
  Result := inherited Save(Stream);
end;

procedure TResource.UnloadData;
begin
  FLoaded := False;
  if FData <> nil then FreeMem(FData);  
  FData := nil;
  SendMessage(TResourceModifyMsg.Create(Self), nil, [mfCore]);
end;

procedure TResource.SetLoaded(Value: Boolean);
begin
  if FLoaded = Value then Exit;
  if Value then begin

  end else
    UnloadData();
end;

{ TResourceModifyMsg }

constructor TResourceModifyMsg.Create(AResource: TResource);
begin
  Resource := AResource;
end;

{ TTextResource }

function TTextResource.GetElementSize: Integer;
const s: TResString = 'A';
begin
  Result := SizeOf(s[1]);
end;

function TTextResource.GetText: TResString;
begin
  SetLength(Result, TotalElements);
  if FData <> nil then Move(FData^, Result[1], FDataSize);
end;

procedure TTextResource.SetText(const NewText: TResString);
begin
  Allocate(Length(NewText) * GetElementSize);
  if FData <> nil then Move(NewText[1], FData^, FDataSize);
end;

{ TArrayResource }

procedure TArrayResource.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;
  Result.Add('Total elements', vtInt, [poReadonly], IntToStrA(TotalElements), '');
end;

procedure TArrayResource.SetProperties(Properties: Props.TProperties);
begin
  inherited;
//  if Properties.Valid('Total elements') then TotalElements := Properties.GetAsInteger('Total elements');
end;

{ TImageResource }

procedure TImageResource.SetMipPolicy(const Value: TMipPolicy);
var NewSize, OldSize: Integer; NewData: Pointer; NeedGenerateMips: Boolean;
begin
  if (Value = FMipPolicy) then Exit;
  Assert(ActualLevels > 0);

  NeedGenerateMips := (FMipPolicy <> mpGenerated) and (Value = mpGenerated);

  OldSize := FLevels[ActualLevels-1].Offset + FLevels[ActualLevels-1].Size;// Width * Height * GetBytesPerPixel(FFormat);

  FMipPolicy := Value; // May change the value of ActualLevels

  if (FFormat = pfUndefined) or (GetBytesPerPixel(FFormat) = 0) or
     (FWidth = 0) or (FHeight = 0) or
     (DataSize = 0) or not Assigned(FData) then Exit;

  NewSize := FLevels[ActualLevels-1].Offset + FLevels[ActualLevels-1].Size;

//  if Value =  mpNoMips then NewSize := OldSize;
//  if (Value <> mpNoMips) and  then
//    NewSize := FLevels[SuggestedLevels-1].Offset + FLevels[SuggestedLevels-1].Size;

  if (NewSize <> DataSize) and
     (FFormat <> pfUndefined) and (GetBytesPerPixel(FFormat) <> 0) and
     (FWidth <> 0) and (FHeight <> 0) and
     (DataSize <> 0) and Assigned(FData) then begin
    {$IFDEF DEBUGMODE} Log('TImageResource.SetMipPolicy: Reallocating image "' + Name + '"'); {$ENDIF}
    GetMem(NewData, NewSize);
    if NewData = nil then begin
      Log('TImageResource.SetMipPolicy: Not enough memory', lkError);
      Exit;
    end;

    Move(FData^, NewData^, MinI(OldSize, NewSize));
    SetAllocated(NewSize, NewData);
  end;

  if NeedGenerateMips then GenerateMipLevels(GetRect(0, 0, Width, Height));
  SendMessage(TResourceModifyMsg.Create(Self), Self, [mfCore, mfRecipient]);
end;

procedure TImageResource.ObtainFilter(OldWidth, OldHeight, NewWidth, NewHeight: Integer; out OFilter: TImageResizeFilter; out OFilterValue: Single);
begin
  if 2*(NewWidth - OldWidth) + (NewHeight - OldHeight) > 0 then begin
    OFilter      := MagFilter;
    OFilterValue := MagFilterParameter;
  end else begin
    OFilter      := MinFilter;
    OFilterValue := MinFilterParameter;
  end;
end;

procedure TImageResource.SetMinFilter(const Value: TImageResizeFilter);
begin
  FMinFilter := Value;
  if DefaultResizeFilterValue[FMinFilter] <> 0 then FMinFilterParameter := DefaultResizeFilterValue[FMinFilter];
end;

procedure TImageResource.SetMagFilter(const Value: TImageResizeFilter);
begin
  FMagFilter := Value;
  if DefaultResizeFilterValue[FMagFilter] <> 0 then FMagFilterParameter := DefaultResizeFilterValue[FMagFilter];
end;

function TImageResource.GetActualLevels: Integer;
begin
  if MipPolicy = mpNoMips then
    Result := 1
  else if FRequestedLevels = 0 then
    Result := FSuggestedLevels
  else
    Result := FRequestedLevels;
end;

function TImageResource.Convert(OldFormat, NewFormat: Cardinal): Boolean;
var
  NewData: Pointer;
  NewSize: Integer;
  PaletteData: Pointer;
  PaletteElements: Integer;
begin
  Result := True;
  Assert(OldFormat <> NewFormat);
  if OldFormat = NewFormat then Exit;
  FBitsPerPixel := GetBitsPerPixel(NewFormat);
  if GetBytesPerPixel(NewFormat) = 0 then begin
    Log(SysUtils.Format('%S(%S).%S: Invalid image format: %D', [ClassName, GetFullName, 'Convert', NewFormat]), lkError);
    Result := False;
    Exit;
  end;

  if Assigned(PaletteResource) then begin
    PaletteElements := PaletteResource.TotalElements;
    PaletteData     := PaletteResource.FData;
  end else begin
    PaletteElements := 0; PaletteData := nil;
  end;

  NewData := nil;
  if (OldFormat <> pfUndefined) then begin
    NewSize := TotalElements * GetBytesPerPixel(NewFormat);
    GetMem(NewData, NewSize);
  end else
    NewSize := 0;

  if (OldFormat <> pfUndefined) and (FWidth <> 0) and (FHeight <> 0) then
    if ConvertImage(OldFormat, NewFormat, TotalElements, FData, PaletteElements, PaletteData, NewData) then begin
      FFormat := NewFormat;                            // To make the resource valid in SetAllocated
      {$IFDEF DEBUGMODE} FConsistent := True; {$ENDIF}
      SetAllocated(NewSize, NewData);
      FSuggestedLevels := GetSuggestedMipLevelsInfo(FWidth, FHeight, FFormat, FLevels);
      {$IFDEF DEBUGMODE} Log(SysUtils.Format('%S("%S").%S: Image format changed', [ClassName, GetFullName, 'Convert']), lkWarning); {$ENDIF}
    end else begin
       Log(SysUtils.Format('%S(%S).%S: Unsupported format conversion: %D to %D', [ClassName, GetFullName, 'Convert', OldFormat, NewFormat]), lkError); 
    end;
end;

function TImageResource.GetDataSizeInStream: Integer;
begin
  Result := FDataSize;
  if MipPolicy = mpGenerated then Result := Width * Height * GetBytesPerPixel(Format);
end;

function TImageResource.GetLevelInfo(Index: Integer): TImageLevel;
begin
  Result := FLevels[Index];
end;

constructor TImageResource.Create(AManager: TItemsManager);
begin
  inherited;
  MipPolicy     := mpNoMips;
  MinFilter     := ifLanczos;
  MagFilter     := ifLanczos;
end;

procedure TImageResource.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;
  Result.Add('Width',  vtInt, [], IntToStrA(FWidth),  '');
  Result.Add('Height', vtInt, [], IntToStrA(FHeight), '');
  Result.AddEnumerated('Format\Image', [], Format, PixelFormatsEnum);

  Result.AddEnumerated('Mip Policy', [], Ord(FMipPolicy), MipPolicyEnum);

  Result.Add('Mip levels',     vtInt, [], IntToStr(FRequestedLevels), '');
  Result.Add('Current levels', vtInt, [poReadOnly], IntToStr(ActualLevels), '');

  Result.AddEnumerated('Min filter', [], Ord(MinFilter), ImageFilterEnums);
  Result.AddEnumerated('Mag filter', [], Ord(MagFilter), ImageFilterEnums);

  Result.Add('Min filter value', vtSingle, [], FloatToStr(FMinFilterParameter), '');
  Result.Add('Mag filter value', vtSingle, [], FloatToStr(FMagFilterParameter), '');  

  Result.Add('Mip recalc', vtBoolean, [], OnOffStr[False], '');
  if not Assigned(Data) then Result.Add('Create empty', vtBoolean, [], OnOffStr[False], '');
end;

procedure TImageResource.SetProperties(Properties: Props.TProperties);
var NewWidth, NewHeight: Integer;
begin
  inherited;
  if Properties.Valid('Format\Image') then Format := Properties.GetAsInteger('Format\Image');
  if Properties.Valid('Width')  then NewWidth  := Properties.GetAsInteger('Width')  else NewWidth  := FWidth;
  if Properties.Valid('Height') then NewHeight := Properties.GetAsInteger('Height') else NewHeight := FHeight;

  if Properties.Valid('Min filter') then MinFilter := TImageResizeFilter(Properties.GetAsInteger('Min filter'));
  if Properties.Valid('Mag filter') then MagFilter := TImageResizeFilter(Properties.GetAsInteger('Mag filter'));

  if Properties.Valid('Min filter value') then FMinFilterParameter := StrToFloatDef(Properties['Min filter value'], 0);
  if Properties.Valid('Mag filter value') then FMagFilterParameter := StrToFloatDef(Properties['Mag filter value'], 0);

  if Properties.Valid('Mip levels') then begin
    FRequestedLevels := StrToIntDef(Properties['Mip levels'], 0);
    SendMessage(TResourceModifyMsg.Create(Self), nil, [mfCore]);
  end;

  if Properties.Valid('Mip Policy') then MipPolicy := TMipPolicy(Properties.GetAsInteger('Mip Policy'));

  if (NewWidth <> FWidth) or (NewHeight <> FHeight) then SetDimensions(NewWidth, NewHeight);

  if Properties.Valid('Create empty') and (Properties.GetAsInteger('Create empty') > 0) then
    CreateEmpty(NewWidth, NewHeight);

  if Properties.Valid('Mip recalc') and (Properties.GetAsInteger('Mip recalc') > 0) or
     Properties.Valid('Mip Policy') and (TMipPolicy(Properties.GetAsInteger('Mip Policy')) = mpGenerated) then
    GenerateMipLevels(GetRect(0, 0, Width, Height));  
end;

function TImageResource.GetElementSize: Integer;
begin
  Result := GetBytesPerPixel(Format);
  if Result = 0 then Result := DataSize;
end;

function TImageResource.Save(Stream: Basics.TStream): Boolean;
begin
  Result := inherited Save(Stream);
end;

function TImageResource.Load(Stream: Basics.TStream): Boolean;
begin
  Result := inherited Load(Stream);
end;

procedure TImageResource.CreateEmpty(AWidth, AHeight: Integer);
begin
  if (AWidth <> 0) and (AHeight <> 0) then begin
    FSuggestedLevels := GetSuggestedMipLevelsInfo(AWidth, AHeight, FFormat, FLevels);
    if (FFormat <> pfUndefined) and (GetBytesPerPixel(FFormat) <> 0) then
      Allocate(FLevels[ActualLevels-1].Offset + FLevels[ActualLevels-1].Size);
  end;

  FWidth  := AWidth;
  FHeight := AHeight;

  FSuggestedLevels := GetSuggestedMipLevelsInfo(FWidth, FHeight, FFormat, FLevels);

  SendMessage(TResourceModifyMsg.Create(Self), nil, [mfCore]);
end;

procedure TImageResource.SetDimensions(AWidth, AHeight: Integer);
var NewData: Pointer; NewSize: Integer;
begin
  if (FWidth = AWidth) and (FHeight = AHeight) then Exit;

  if (AWidth <> 0) and (AHeight <> 0) then begin
    FSuggestedLevels := GetSuggestedMipLevelsInfo(AWidth, AHeight, FFormat, FLevels);
    NewSize := FLevels[ActualLevels-1].Offset + FLevels[ActualLevels-1].Size;

    if Assigned(Data) and (FDataSize <> NewSize) and (FFormat <> pfUndefined) and (GetBytesPerPixel(FFormat) <> 0) then begin
      GetMem(NewData, NewSize);
      Move(Data^, NewData^, MinI(DataSize, NewSize));
//      ResizeImage(GetRect(0, 0, Width, Height), GetRect(0, 0, AWidth, AHeight), AWidth, NewData);
      SetAllocated(NewSize, NewData);
      {$IFDEF DEBUGMODE} Log(SysUtils.Format('%S("%S").%S: Image dimensions changed', [ClassName, Name, 'SetDimensions']), lkWarning); {$ENDIF}
    end;
  end;

  FWidth  := AWidth;
  FHeight := AHeight;

  FSuggestedLevels := GetSuggestedMipLevelsInfo(FWidth, FHeight, FFormat, FLevels);

  SendMessage(TResourceModifyMsg.Create(Self), Self, [mfCore, mfRecipient]);
end;

procedure TImageResource.GenerateMipLevels(ARect: BaseTypes.TRect);

  procedure CorrectRect(var LRect: BaseTypes.TRect; Level: Integer);
  begin
    LRect.Left   := LRect.Left - Ord(Odd(LRect.Left));
    LRect.Top    := LRect.Top  - Ord(Odd(LRect.Top));
    LRect.Right  := MinI(LevelInfo[Level].Width,  LRect.Right  + Ord(Odd(LRect.Right)));
    LRect.Bottom := MinI(LevelInfo[Level].Height, LRect.Bottom + Ord(Odd(LRect.Bottom)));
  end;

var k, w, h: Integer; ORect, LRect, LastRect: BaseTypes.TRect; Filter: TImageResizeFilter; FilterValue: Single;
begin
  if not Assigned(Data) or (FMipPolicy = mpNoMips) then Exit;

  ARect.Left   := ClampI(ARect.Left,   0, Width);
  ARect.Top    := ClampI(ARect.Top,    0, Height);
  ARect.Right  := ClampI(ARect.Right,  0, Width);
  ARect.Bottom := ClampI(ARect.Bottom, 0, Height);

  ORect := ARect;
  CorrectRect(ORect, 0);
  LRect := ARect;

  for k := 0 to ActualLevels-2 do begin
    CorrectRect(LRect, k);
    LastRect := LRect;
    LRect.Left   := LRect.Left   div 2;
    LRect.Top    := LRect.Top    div 2;
    LRect.Right  := LRect.Right  div 2;
    LRect.Bottom := LRect.Bottom div 2;

    w := LRect.Right  - LRect.Left;
    h := LRect.Bottom - LRect.Top;

    if (w = 0) and (h = 0) then Break;
    w := MaxI(1, w);
    h := MaxI(1, h);
    ObtainFilter(Width, Height, w, h, Filter, FilterValue);
    Base2D.ResizeImage(Filter, FilterValue, Format, PtrOffs(Data, LevelInfo[k].Offset),   LastRect, LevelInfo[k].Width,
                                                    PtrOffs(Data, LevelInfo[k+1].Offset), LRect,    LevelInfo[k+1].Width);
  end;

  {$IFDEF DEBUGMODE} Log('TImageResource.GenerateMipLevels: Image "' + Name + '"'); {$ENDIF}

  SendMessage(TResourceModifyMsg.Create(Self), Self, [mfCore, mfRecipient]);
end;

{ TTextureResource }

procedure TTextureResource.SetMipLevels(const Value: Integer);
begin
  FMipLevels := Value;
end;

procedure TTextureResource.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;
//  Result.Add('Auto generate mips', vtBoolean, [], OnOffStr[AutoGenerateMips], '');
  Result.Add('Mip levels',         vtInt,     [], IntToStr(Miplevels),        '');
end;

procedure TTextureResource.SetProperties(Properties: Props.TProperties);
begin
  inherited;
//  if Properties.Valid('Auto generate mips') then AutoGenerateMips := Properties.GetAsInteger('Auto generate mips') > 0;
  if Properties.Valid('Mip levels') then Miplevels := Properties.GetAsInteger('Mip levels');
end;

function TTextureResource.GetMipLevelData(ALevel: Integer): Pointer;
begin
  Result := Pointer(Integer(Data) + FLevels[ALevel].Offset);
end;

{ TUVMapResource }

function TUVMapResource.GetElementSize: Integer;
begin
  Result := SizeOf(TUV);
end;

{ TCharMapResource }

function TCharMapResource.GetElementSize: Integer;
begin
  Result := SizeOf(TCharMapItem);
end;

{ TPaletteResource }

function TPaletteResource.GetElementSize: Integer;
begin
  Result := SizeOf(TPaletteItem);
end;

{ TScriptResource }

function TScriptResource.GetText: TResString;
begin
  Result := FSource;
end;

procedure TScriptResource.SetText(const NewText: TResString);
begin
  FSource := NewText;

  SendMessage(TDataModifyMsg.Create(Self), nil, [mfCore, mfBroadcast]);
//  if FSource <> '' then
  SetAllocated(0, nil);                       // Invalidate existing compiled script
end;

procedure TScriptResource.SetCodeSize(ACodeSize: Integer);
begin
  FCodeSize := ACodeSize;
end;

procedure TScriptResource.AddProperties(const Result: TProperties);
begin
  inherited;
  if Assigned(Result) then begin
    Result.Add('Source', vtString, [], Source, '');
    Result.Add('Code size', vtInt, [poReadonly], IntToStr(FCodeSize), '');
  end;
end;

procedure TScriptResource.SetProperties(Properties: TProperties);
begin
  if Properties.Valid('Source') then Source := Properties['Source'];          // Source should be assigned prior to data to preserve the data while loading
  if Properties.Valid('Code size') then FCodeSize := StrToIntDef(Properties['Code size'], 0);
  inherited;
end;

{ TMegaImageResource }

procedure TMegaImageResource.SetMipPolicy(const Value: TMipPolicy);
begin
  inherited SetMipPolicy(mpPersistent);
end;

function TMegaImageResource.Prepare(AImageSource: TStream): Boolean;
const ReadPhaseW = 0.1; CMipPhaseW = 0.3; WritePhaseW = 0.6;
var
  i, j, k, m,
  SrcBpP, BpP,
  lw, lh, bw, bh: Integer;
  Buffer, Temp, CTemp: Pointer;
  Garbage: IRefcountedContainer;
  Header: TImageHeader;
begin
  Result := False;
  if not Assigned(FDataStream) or not Assigned(AImageSource) then Exit;

  if not LoadBitmapHeader(AImageSource, Header) then begin
    Header.Format       := Format;
    Header.Width        := Width;
    Header.Height       := Height;
    Header.BitsPerPixel := GetBitsPerPixel(Header.Format);
    Header.LineSize     := Header.Width * Header.BitsPerPixel div 8;
    Header.ImageSize    := Header.LineSize * Header.Height;
    Header.PaletteSize  := 0;
    Header.Palette      := nil;
  end;

  SrcBpP := GetBytesPerPixel(Header.Format);
  BpP    := GetBytesPerPixel(Format);

  if (Header.Width = 0) or (Header.Height = 0) or (SrcBpP = 0) then begin
    Log('TMegaImageResource.Prepare: Invalid source stream format', lkError);
    Exit;
  end;

  InitCache(FCacheTotal);                        // To clear cache

  SetDimensions(Header.Width, Header.Height);

  if not Init(FBlockWidth, FBlockHeight) then Exit;

  FDataStream.Size := LevelInfo[SuggestedLevels-1].Offset + LevelInfo[SuggestedLevels-1].Size;

  if AImageSource.Size - AImageSource.Position < Cardinal(Width * Height * GetBytesPerPixel(Header.Format)) then begin
    Log('TMegaImageResource.Prepare: Not enough data in stream', lkError);
    Exit;
  end;

  Garbage := CreateRefcountedContainer;
  GetMem(Buffer, FLevels[SuggestedLevels-1].Offset + FLevels[SuggestedLevels-1].Size);

  SetAllocated(Width * Height * BpP, Buffer);
  Garbage.AddPointer(Buffer);
  GetMem(Temp, Width * FBlockHeight * SrcBpP);
  Garbage.AddPointer(Temp);
  GetMem(CTemp, FBlockWidth * FBlockHeight * BpP);
  Garbage.AddPointer(CTemp);

  FDataStream.Seek(0);
  for k := 0 to FNumBlocksY - 1 do begin
    SendMessage(TProgressMsg.Create(ReadPhaseW * k / (FNumBlocksY - 1)), nil, [mfCore]);
    if not AImageSource.ReadCheck(Temp^, Width * FBlockHeight * SrcBpP) then begin
      Log('TMegaImageResource.Prepare: Error reading from stream', lkError);
      Exit;
    end;
    for i := 0 to FBlockHeight-1 do
      if not ConvertImage(Header.Format, Format, Width, PtrOffs(Temp, i*Width*SrcBpP), 0, nil,
                                                        PtrOffs(Buffer, ((FNumBlocksY-k) * FBlockHeight - i - 1) * Width * BpP)) then begin
        Log('TMegaImageResource.Prepare: Format conversion ' + PixelFormatToStr(Header.Format) + ' to ' + PixelFormatToStr(Format) + ' not supported', lkError);
        Exit;
      end;
  end;

  GenerateMipLevels(GetRect(0, 0, Width, Height));
  SendMessage(TProgressMsg.Create(CMipPhaseW), nil, [mfCore]);

  for m := 0 to ActualLevels-1 do begin
    lw := LevelInfo[m].Width;
    lh := LevelInfo[m].Height;
    bw := MinI(lw, FBlockWidth);
    bh := MinI(lh, FBlockHeight);
    for k := 0 to lh div bh - 1 do begin
      for j := 0 to lw div bw - 1 do begin
        BufferCut(PtrOffs(Buffer, LevelInfo[m].Offset), CTemp, lw, bw, BpP, GetRect(j * bw, k * bh, (j+1) * bw, (k+1) * bh));
        if not FDataStream.WriteCheck(CTemp^, bw*bh*BpP) then Exit;
      end;
    end;
    SendMessage(TProgressMsg.Create(CMipPhaseW + (1-CMipPhaseW) * m / MaxI(1, (ActualLevels-1))), nil, [mfCore]);
  end;

{  for k := 0 to FNumBlocksY - 1 do begin
    SendMessage(TProgressMsg.Create(k / (FNumBlocksY - 1)), nil, [mfCore]);
    if not AImageSource.ReadCheck(Src^, Width * FBlockHeight * SrcBpP) then Exit;
    for i := 0 to FNumBlocksX-1 do for j := 0 to FBlockHeight-1 do begin
      if not ConvertImage(Header.Format, Format, FBlockWidth, PtrOffs(Src, (j*Width + i*FBlockWidth) * SrcBpP), 0, nil,
                                                   PtrOffs(Temp, j*FBlockWidth*BpP)) or
         not FDataStream.WriteCheck(PtrOffs(Temp, j*FBlockWidth*BpP)^, FBlockWidth*BpP) then Exit;
    end;
  end;}

  FData := nil;                                 // To prevent freeing in SetAllocated()
  SetAllocated(0, nil);                      
  Result := True;
end;

procedure TMegaImageResource.DelCacheBlock;
begin
  FCacheData[FCache[FCacheStart].Level, FCache[FCacheStart].Y, FCache[FCacheStart].X] := nil;
  FCacheStart := (FCacheStart + 1) mod FCacheTotal;
  Dec(FCacheCurrent);
end;

function TMegaImageResource.AddCacheBlock(ALevel, AX, AY: Integer): Pointer;
begin
  Assert(FCacheCurrent <= FCacheTotal);
  if FCacheCurrent = FCacheTotal then DelCacheBlock;

  with FCache[(FCacheStart + FCacheCurrent) mod FCacheTotal] do begin
    Level := ALevel;
    X     := AX;
    Y     := AY;
    Result := Data;
  end;
  Inc(FCacheCurrent);
end;

procedure TMegaImageResource.InitCache(ACacheTotal: Integer);

  function CacheEmpty: Boolean;
  var i, j, k: Integer;
  begin
    Result := True;
    if FCacheTotal = 0 then Exit;
    for k := 0 to ActualLevels-1 do
      for j := 0 to FNumBlocksY-1 do for i := 0 to FNumBlocksX-1 do Result := Result and (FCacheData[k, j, i] = nil);
  end;

var i: Integer;
begin
  for i := 0 to FCacheCurrent-1 do DelCacheBlock;
  for i := 0 to FCacheTotal-1 do FreeMem(FCache[i].Data);

//  Assert(CacheEmpty);

  FCacheTotal := ACacheTotal;
  SetLength(FCache, FCacheTotal);
  for i := 0 to FCacheTotal-1 do GetMem(FCache[i].Data, ActualBlockWidth * ActualBlockHeight * FBitsPerPixel div 8);
  FCacheCurrent := 0;
  FCacheStart   := 0;
  FCacheEnd     := -1;

  SetLength(FCacheData, ActualLevels, FNumBlocksY, FNumBlocksX);
end;

function TMegaImageResource.Init(ABlockWidth, ABlockHeight: Integer): Boolean;
begin
  Result := False;
  if (ABlockWidth = 0) or (FBlockHeight = 0) or (Width mod ABlockWidth <> 0) or (Height mod ABlockHeight <> 0) then begin
    Log('TMegaImageResource.Prepare: Width/Height should be nonzero and divide by BlockWidth/BlockHeight', lkError);
    Exit;
  end;

  FBlockWidth  := ABlockWidth;
  FBlockHeight := ABlockHeight;

  FNumBlocksX := Width  div FBlockWidth;
  FNumBlocksY := Height div FBlockHeight;

  ActualBlockWidth  := FBlockWidth;
  ActualBlockHeight := FBlockHeight;

  InitCache(FCacheTotal);
  Result := True;
end;

function TMegaImageResource.SaveBlockData(ALevel, ABlockX, ABlockY: Integer): Boolean;
begin
  Result := False;
  if FCacheData[ALevel, ABlockY, ABlockX] = nil then Exit;
  if not FDataStream.Seek(LevelInfo[ALevel].Offset + ((FNumBlocksX div (1 shl ALevel)) * ABlockY + ABlockX) * ActualBlockWidth * ActualBlockHeight * FBitsPerPixel div 8) then begin
    ErrorHandler(TStreamError.Create('TMegaImageResource.SaveBlockData: Error seeking stream'));
    Exit;
  end else if not FDataStream.WriteCheck(FCacheData[ALevel, ABlockY, ABlockX]^, MinI(LevelInfo[ALevel].Width, ActualBlockWidth) * MinI(LevelInfo[ALevel].Height, ActualBlockHeight) * FBitsPerPixel div 8) then
    ErrorHandler(TStreamError.Create('TMegaImageResource.SaveBlockData: Error writing stream'));
  Result := True;
end;

destructor TMegaImageResource.Destroy;
begin
  FreeAndNil(FDataStream);
  InitCache(0);
  inherited;
end;

procedure TMegaImageResource.AddProperties(const Result: TProperties);
begin
  inherited;
  if Assigned(Result) then begin
    Result.Add('Store file',  vtString,  [], FStoreFileName, '');

    Result.Add('Reinit',              vtBoolean, [], OnOffStr[False], '');
    Result.Add('Reinit\Source file',  vtString,  [], FSourceFileName, '');
    Result.Add('Reinit\Block width',  vtInt,     [], IntToStr(FBlockWidth),  '');
    Result.Add('Reinit\Block height', vtInt,     [], IntToStr(FBlockHeight), '');

    Result.Add('Cache\Number of blocks', vtInt, [],           IntToStr(FCacheTotal),   '');
    Result.Add('Cache\Current blocks',   vtInt, [poReadonly], IntToStr(FCacheCurrent), '');
  end;
end;

procedure TMegaImageResource.CreateEmpty(AWidth, AHeight: Integer);
begin
  // Do nothing
end;

procedure TMegaImageResource.SetDimensions(AWidth, AHeight: Integer);
begin
  FWidth  := AWidth;
  FHeight := AHeight;
  FSuggestedLevels := GetSuggestedMipLevelsInfo(FWidth, FHeight, FFormat, FLevels);
  Init(FBlockWidth, FBlockHeight);
end;

procedure TMegaImageResource.SetProperties(Properties: TProperties);
var Stream: TStream;
begin
  inherited;
  if Properties.Valid('Store file') then begin
    FStoreFileName := Properties['Store file'];
//    if not Assigned(DataStream) then
    FDataStream := TFileStream.Create(FStoreFileName);
  end;

  if Properties.Valid('Reinit\Source file')  then FSourceFileName := Properties['Reinit\Source file'];

  if Properties.Valid('Reinit\Block width') or Properties.Valid('Reinit\Block height') then begin
    if Properties.Valid('Reinit\Block width')  then FBlockWidth  := StrToIntDef(Properties['Reinit\Block width'],  0);
    if Properties.Valid('Reinit\Block height') then FBlockHeight := StrToIntDef(Properties['Reinit\Block height'], 0);
    Init(FBlockWidth, FBlockHeight);
  end;

  if Properties.Valid('Cache\Number of blocks') then InitCache(MaxI(1, StrToIntDef(Properties['Cache\Number of blocks'], 1)));

  if Properties.Valid('Reinit') and (Properties.GetAsInteger('Reinit') > 0) then begin
    Stream := TFileStream.Create(FSourceFileName);
    if not Prepare(Stream) then Log('TMegaImageResource: Reinit failed', lkError);
    FreeAndNil(Stream);
  end else Log('TMegaImageResource.SetProperties: Reinit may be needed after properties change');
end;

function TMegaImageResource.GetBlockData(ALevel, ABlockX, ABlockY: Integer): Pointer;
begin
  Result := nil;
  if FCacheData[ALevel, ABlockY, ABlockX] = nil then begin
    FCacheData[ALevel, ABlockY, ABlockX] := AddCacheBlock(ALevel, ABlockX, ABlockY);
    if (FCacheData[ALevel, ABlockY, ABlockX] = nil) then Exit;
    if not FDataStream.Seek(LevelInfo[ALevel].Offset + ((FNumBlocksX div (1 shl ALevel)) * ABlockY + ABlockX) * ActualBlockWidth * ActualBlockHeight * FBitsPerPixel div 8) then begin
      Log('TMegaImageResource.GetBlockData: Error seeking stream', lkError);
      Exit;
    end else if not FDataStream.ReadCheck(FCacheData[ALevel, ABlockY, ABlockX]^, MinI(LevelInfo[ALevel].Width, ActualBlockWidth) * MinI(LevelInfo[ALevel].Height, ActualBlockHeight) * FBitsPerPixel div 8) then
      Log('TMegaImageResource.GetBlockData: Error reading stream', lkError)
  end;
  Result := FCacheData[ALevel, ABlockY, ABlockX];
end;

function TMegaImageResource.LoadSeq(AX, AY, ALength, ALevel: Integer; Dest: Pointer): Boolean;
var BlockX, BlockY, BlockXOfs, BlockYOfs, BpP, Len, abw: Integer; Temp: Pointer;
begin
  Result := False;
  if (ActualBlockWidth < MinBlockSize) or (ActualBlockHeight < MinBlockSize) then Exit;

  BpP := GetBytesPerPixel(Format);

  BlockX := AX div ActualBlockWidth;
  BlockY := AY div ActualBlockHeight;
  BlockXOfs := AX - BlockX * ActualBlockWidth;
  BlockYOfs := AY - BlockY * ActualBlockHeight;

  abw := MinI(LevelInfo[ALevel].Width, ActualBlockWidth);

//  Log(SysUtils.Format('*** (%D, %D), Bl (%D, %D) ', [AX, AY, BlockX, BlockY]));

  while ALength > 0 do begin
    Temp := GetBlockData(ALevel, BlockX, BlockY);
    if Temp = nil then Exit;
    Len := MinI(abw - BlockXOfs, ALength);
    Move(PtrOffs(Temp, (BlockYOfs * abw + BlockXOfs)*BpP)^, Dest^, Len*BpP);
    Dec(ALength, Len);
    Dest := PtrOffs(Dest, Len * BpP);
    BlockXOfs := 0;
    Inc(BlockX);
  end;

  Result := True;
end;

function TMegaImageResource.LoadRect(const Rect: TRect; ALevel: Integer; Dest: Pointer; DestImageWidth: Integer): Boolean;
var i, Left, Top, Right, Bottom: Integer;
begin
  Result := False;
  Left   := ClampI(Rect.Left,   0, LevelInfo[ALevel].Width);
  Right  := ClampI(Rect.Right,  0, LevelInfo[ALevel].Width);
  Top    := ClampI(Rect.Top,    0, LevelInfo[ALevel].Height);
  Bottom := ClampI(Rect.Bottom, 0, LevelInfo[ALevel].Height);
  {$IFDEF DEBUGMODE}
  for i := Rect.Top to Top-1 do
    FillChar(PtrOffs(Dest, (i-Rect.Top)*DestImageWidth*FBitsPerPixel div 8)^, 0, (Rect.Right - Rect.Left)*FBitsPerPixel div 8);
  for i := Bottom to Rect.Bottom-1 do
    FillChar(PtrOffs(Dest, (i-Rect.Top)*DestImageWidth*FBitsPerPixel div 8)^, 0, (Rect.Right - Rect.Left)*FBitsPerPixel div 8);
  {$ENDIF}
  for i := Top to Bottom-1 do begin
    {$IFDEF DEBUGMODE} FillChar(PtrOffs(Dest, (i-Rect.Top)*DestImageWidth*FBitsPerPixel div 8)^, 0, (Left - Rect.Left)*FBitsPerPixel div 8);{$ENDIF}
    if not LoadSeq(Left, i, Right-Left, ALevel, PtrOffs(Dest, ((i-Rect.Top)*DestImageWidth+Left - Rect.Left)*FBitsPerPixel div 8)) then Exit;
    {$IFDEF DEBUGMODE} FillChar(PtrOffs(Dest, ((i-Rect.Top)*DestImageWidth+Right - Rect.Left)*FBitsPerPixel div 8)^, 0, (Rect.Right - Right)*FBitsPerPixel div 8);{$ENDIF}
  end;
  Result := True;
end;

function TMegaImageResource.LoadRectAsRGBA(Rect: TRect; ALevel: Integer; Dest: Pointer; DestImageWidth: Integer): Boolean;
const MaxLineLength = $FFFF;
var i, w: Integer; Temp: array[0..MaxLineLength-1] of TColor;
begin
  Result := False;
  Dest := PtrOffs(Dest, MaxI(0, -Rect.Left * ProcessingFormatBpP));
  Rect.Left   := ClampI(Rect.Left,   0, LevelInfo[ALevel].Width);
  Rect.Right  := ClampI(Rect.Right,  0, LevelInfo[ALevel].Width);
  Rect.Top    := ClampI(Rect.Top,    0, LevelInfo[ALevel].Height);
  Rect.Bottom := ClampI(Rect.Bottom, 0, LevelInfo[ALevel].Height);
  w := Rect.Right-Rect.Left;
  Assert(w <= MaxLineLength, 'TMegaImageResource.LoadRectAsRGBA: Line length is too big');

  for i := Rect.Top to Rect.Bottom-1 do
    if not LoadSeq(Rect.Left, i, w, ALevel, @Temp) or
       not ConvertToProcessing(Format, w, @Temp[0], 0, nil, PtrOffs(Dest, ((i-Rect.Top)*DestImageWidth)*ProcessingFormatBpP)) then Exit;
  Result := True;
end;

function TMegaImageResource.SaveSeq(AX, AY, ALength, ALevel: Integer; Src: Pointer): Boolean;
var BlockX, BlockY, BlockXOfs, BlockYOfs, BpP, Len, abw: Integer; Temp: Pointer;
begin
  Result := False;
  if (ActualBlockWidth < MinBlockSize) or (ActualBlockHeight < MinBlockSize) then Exit;

  BpP := GetBytesPerPixel(Format);

  BlockX := AX div ActualBlockWidth;
  BlockY := AY div ActualBlockHeight;
  BlockXOfs := AX - BlockX * ActualBlockWidth;
  BlockYOfs := AY - BlockY * ActualBlockHeight;

  abw := MinI(LevelInfo[ALevel].Width, ActualBlockWidth);

//  Log(SysUtils.Format('*** (%D, %D), Bl (%D, %D) ', [AX, AY, BlockX, BlockY]));

  while ALength > 0 do begin
    Temp := GetBlockData(ALevel, BlockX, BlockY);
    if Temp = nil then Exit;
    Len := MinI(abw - BlockXOfs, ALength);
    Move(Src^, PtrOffs(Temp, (BlockYOfs * abw + BlockXOfs)*BpP)^, Len*BpP);
    SaveBlockData(ALevel, BlockX, BlockY);
    Dec(ALength, Len);
    Src := PtrOffs(Src, Len * BpP);
    BlockXOfs := 0;
    Inc(BlockX);
  end;

  Result := True;
end;

function TMegaImageResource.SaveRect(Rect: TRect; ALevel: Integer; Src: Pointer; SrcImageWidth: Integer; BuildMips: Boolean): Boolean;
var i, ow, oh, nw, nh: Integer; Temp, Temp2: Pointer; NewRect: TRect;
begin
  Result := False;
  Rect.Left   := ClampI(Rect.Left,   0, LevelInfo[ALevel].Width);
  Rect.Right  := ClampI(Rect.Right,  0, LevelInfo[ALevel].Width);
  Rect.Top    := ClampI(Rect.Top,    0, LevelInfo[ALevel].Height);
  Rect.Bottom := ClampI(Rect.Bottom, 0, LevelInfo[ALevel].Height);
  for i := Rect.Top to Rect.Bottom-1 do
    if not SaveSeq(Rect.Left, i, Rect.Right-Rect.Left, ALevel, PtrOffs(Src, ((i-Rect.Top)*SrcImageWidth+Rect.Left - Rect.Left)*FBitsPerPixel div 8)) then Exit;

  if BuildMips and (ALevel < ActualLevels-1) then begin
    Rect := GetRectIntersect(GetRectExpanded(Rect, Ceil(MinFilterParameter), Ceil(MinFilterParameter)), GetRect(0, 0, LevelInfo[ALevel].Width, LevelInfo[ALevel].Height));
    ow := Rect.Right  - Rect.Left;
    oh := Rect.Bottom - Rect.Top;
    GetMem(Temp, ow*oh * FBitsPerPixel div 8);
    LoadRect(Rect, ALevel, Temp, ow);

    RectScale(Rect, 0.5, 0.5, NewRect);
    nw := NewRect.Right  - NewRect.Left;
    nh := NewRect.Bottom - NewRect.Top;
    GetMem(Temp2, nw*nh * FBitsPerPixel div 8);

    Base2D.ResizeImage(MinFilter, MinFilterParameter, Format, Temp,  GetRect(0, 0, ow, oh), ow,
                                                              Temp2, GetRect(0, 0, nw, nh), nw);
    SaveRect(NewRect, ALevel+1, Temp2, nw, True);

    FreeMem(Temp2); FreeMem(Temp);
  end;

  Result := True;
end;

{ TMegaImagePaintOp }

procedure TMegaImagePaintOp.DoApply;
begin
  FResource.LoadRect(FRect, FLevel, FTempData, FRect.Right-FRect.Left);
  FResource.SaveRect(FRect, FLevel, FData, FRect.Right-FRect.Left, True);
  Move(FTempData^, FData^, (FRect.Bottom-FRect.Top) * (FRect.Right-FRect.Left) * FImageBpP);
end;

constructor TMegaImagePaintOp.Create(X, Y: Integer; AResource: TMegaImageResource; ALevel: Integer; ABrush: TBrush; const ARect: BaseTypes.TRect);
begin
  Assert(Assigned(AResource), 'TMegaImagePaintOp.Create: Resource is undefined');
  inherited Create(nil, AResource.Width, AResource.Format, GetRectIntersect(GetRect(X, Y, X+ABrush.Width, Y+ABrush.Height), ARect));
  FResource := AResource;
  FLevel    := ALevel;
  GetMem(FTempData, (FRect.Bottom-FRect.Top) * (FRect.Right-FRect.Left) * FImageBpP);

  FResource.LoadRect(Rect, FLevel, FData, FRect.Right-FRect.Left);
  BufferRGBABlend(PtrOffs(ABrush.PatternData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X)) * SizeOf(TColor)),
                  FData,
                  PtrOffs(ABrush.ShapeData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X))),
                  ABrush.Width, Rect.Right-Rect.Left, FImageFormat, GetRectMoved(Rect, -Rect.Left, -Rect.Top));
//  BufferRGBACombine(PtrOffs(ABrush.ShapeData, (MaxI(0, -Y) * ABrush.Width + MaxI(0, -X)) * SizeOf(TColor)),
//                    FData, ABrush.Width, Rect.Right-Rect.Left, FImageFormat, GetRectMove(Rect, -Rect.Left, -Rect.Top));

end;

destructor TMegaImagePaintOp.Destroy;
begin
  FreeMem(FTempData);
  inherited;
end;

{ TMegaImageSource }

function TMegaImageSource.GetData(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean;
begin
  Result := FResource.LoadRect(Rect, FLevel, Dest, DestImageWidth);
end;

function TMegaImageSource.GetDataAsRGBA(const Rect: TRect; Dest: Pointer; DestImageWidth: Integer): Boolean;
begin
  Result := FResource.LoadRectAsRGBA(Rect, FLevel, Dest, DestImageWidth);
end;

constructor TMegaImageSource.Create(AResource: TMegaImageResource; ALevel: Integer);
begin
  Assert(Assigned(AResource));
  inherited Create(AResource.Format, AResource.LevelInfo[ALevel].Width, AResource.LevelInfo[ALevel].Height);
  FResource := AResource;
  FLevel    := ALevel;
end;

{ TResourceLinker }

constructor TResourceLinker.Create;
begin
  Assert(not Assigned(LResourceLinker), 'Only one instance of TResourceLinker allowed');
  RegisterCarrier(TBitmapCarrier.Create);
end;

destructor TResourceLinker.Destroy;
var i: Integer;
begin
  for i := 0 to High(FCarriers) do
    if Assigned(FCarriers[i]) then FCarriers[i].Free;
  inherited;
end;

function TResourceLinker.GetLoader(ResType: TResourceTypeID): TResourceCarrier;
var i: Integer;
begin
  i := High(FCarriers);
  while (i >= 0) and not FCarriers[i].CanLoad(ResType) do Dec(i);

  if i >= 0 then
    Result := FCarriers[i]
  else
    Result := nil;
end;

function TResourceLinker.GetWriter(ResType: TResourceTypeID): TResourceCarrier;
var i: Integer;
begin
  i := High(FCarriers);
  while (i >= 0) and not FCarriers[i].CanSave(ResType) do Dec(i);

  if i >= 0 then
    Result := FCarriers[i]
  else
    Result := nil;
end;

procedure TResourceLinker.RegisterCarrier(Carrier: TResourceCarrier);
begin
  SetLength(FCarriers, Length(FCarriers)+1);
  FCarriers[High(FCarriers)] := Carrier;
end;

{ TImageCarrier }

function TImageCarrier.InitResource(Image: TImageResource; const AURL: string; AWidth, AHeight: Integer; AFormat: TPixelFormat; ASize: Integer; AData: Pointer): Boolean;
var OldMipPolicy: TMipPolicy; OldFormat: TPixelFormat;
begin
  Result := False;
  if not Assigned(Image) or (AFormat = pfUndefined) or (AData = nil) then Exit;

  if IsPalettedFormat(AFormat) and not Assigned(Image.PaletteResource) then begin
    Log(ClassName + '.InitResource: No palette found for a paletted image format', lkError);
    Exit;
  end;

  {$IFDEF DEBUGMODE} Image.FConsistent := False; {$ENDIF}                            // Not consistent during init

  OldMipPolicy := Image.MipPolicy;
  Image.FMipPolicy := mpNoMips;                           // Save mip policy

  OldFormat := Image.FFormat;

  Image.FFormat := AFormat;
  Image.FWidth  := AWidth;
  Image.FHeight := AHeight;
  Image.FSuggestedLevels := GetSuggestedMipLevelsInfo(Image.FWidth, Image.FHeight, Image.FFormat, Image.FLevels);

  Image.SetAllocated(ASize, AData);

  {$IFDEF DEBUGMODE} Image.FConsistent := True; {$ENDIF}

  if OldFormat <> pfUndefined then Image.Format := OldFormat;
  Image.MipPolicy := OldMipPolicy;                        // Restore mip policy
  Image.FCarrierURL := AURL;
  Result := True;
end;

{ TBitmapCarrier }

function TBitmapCarrier.DoLoad(Stream: TStream; const AURL: string; var Resource: TItem): Boolean;
var BMPHeader: TImageHeader;
begin
  Assert(Assigned(Resource));
  Result := False;
  if LoadBitmap(Stream, BMPHeader) then
    Result := InitResource(Resource as TImageResource, AURL, BMPHeader.Width, BMPHeader.Height, BMPHeader.Format, BMPHeader.ImageSize, BMPHeader.Data);
end;

procedure TBitmapCarrier.Init;
begin
  inherited;
  LoadingTypes := GetResTypeList([GetResTypeFromExt('bmp')]);
end;

function TBitmapCarrier.GetResourceClass: CItem;
begin
  Result := TImageResource;
end;

{ TResourceCarrier }

constructor TResourceCarrier.Create;
var i: Integer; s: string;
begin
  Init();
  Log('Resource carrier of class "' + ClassName + '"');

  s := '';
  Log('  Loading supported for:');
  for i := 0 to High(LoadingTypes) do
    s := s + '  <' + LoadingTypes[i] + '>';
  Log(s);

  s := '';
  Log('  Saving supported for:');
  for i := 0 to High(SavingTypes) do
    s := s + '  <' + SavingTypes[i] + '>';
  Log(s);  
end;

procedure TResourceCarrier.Init;
begin
  SavingTypes  := nil;
  LoadingTypes := nil;
end;

function TResourceCarrier.CanSave(ResType: TResourceTypeID): Boolean;
var i: Integer;
begin
  i := High(SavingTypes);
  while (i >= 0) and (SavingTypes[i] <> ResType) do Dec(i);
  Result := i >= 0;
end;

function TResourceCarrier.CanLoad(ResType: TResourceTypeID): Boolean;
var i: Integer;
begin
  i := High(LoadingTypes);
  while (i >= 0) and (LoadingTypes[i] <> ResType) do Dec(i);
  Result := i >= 0;
end;

function TResourceCarrier.Load(Stream: TStream; const AURL: string; var Resource: TItem): Boolean;
begin
  Result := False;
  if not Assigned(Resource) then begin
    Resource := GetResourceClass.Create(nil) as TResource;
    Resource.Name := GetFileName(GetFileNameFromURL(AURL));
  end;
  if not (Resource is GetResourceClass) then begin
    Log(Format('%S.%S: incompatible classes "%s" and "%s"', [ClassName, 'Load', Resource.ClassName, GetResourceClass.ClassName]), lkError);
    Exit;
  end;
  Result := DoLoad(Stream, AURL, Resource);
end;

procedure TResourceCarrier.SetCarrierURL(AResource: TResource; const ACarrierURL: string);
begin
  if Assigned(AResource) then AResource.FCarrierURL := ACarrierURL;
end;

initialization
  LResourceLinker := TResourceLinker.Create;
  GlobalClassList.Add('Resources', GetUnitClassList);
finalization
  FreeAndNil(LResourceLinker);
end.
