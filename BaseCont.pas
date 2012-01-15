(*
 @Abstract(Basic containers unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Created May 30, 2006 <br>
 Unit contains basic container classes
*)
{$Include GDefines.inc}
unit BaseCont;

interface

uses BaseTypes, Basics, BaseStr, 
     Props;

const
  // Default capacity for hash map containers
  DefaultHashmapCapacity = 16;

type
  // Class of items which can be contained only in a one TUniqueItemCollection container without duplicates in other containers
  TBaseUniqueItem = class
  private
    // Index in a containing collection
    Index: Integer;
  public
    constructor Create; virtual;
    function IsInContainer: Boolean;
  end;

  // Container for @Link(TBaseUniqueItem)
  TUniqueItemCollection = class
  protected
    FTotalItems: Integer;
  public
    GrowStep: Integer;                             // Memory usage grow step
    Ordered: Boolean;                              // Set to True to preserve item's order
    Items: array of TBaseUniqueItem;
    constructor Create;
    destructor Destroy; override;
    function Add(AItem: TBaseUniqueItem): TBaseUniqueItem;
    function Exists(AItem: TBaseUniqueItem): Boolean; {$I inline.inc}
    function Remove(AItem: TBaseUniqueItem): Boolean;
    procedure Clear;

    property TotalItems: Integer read FTotalItems;
  end;

  // Class of items with reference counting and universal equivalence checking
  TReferencedItem = class
  public
    constructor Create;
    // Increase and return reference counter
    function IncRef: Integer; {$I inline.inc}
    // Decrease and return reference counter. If it becomes zero destructor is called
    function DecRef: Integer; {$I inline.inc}
    // Returns @True if the item has the same class and parameters as <b>AItem</b>
    function IsSameItem(AItem: TReferencedItem): Boolean; virtual;
    { Fills <b>Parameters</b> with a pointer to public or internal (depending on value of <b>Internal</b>) parameters and
      returns size of the parameters in 32-bit dwords.
      Descendant classes should override this method to introduce their own parameters }
    function RetrieveParameters(out Parameters: Pointer; Internal: Boolean): Integer; virtual;
  private
    FRefCount: Integer;
//    NextItem: TReferencedItem;                   // For grouping by class
  public
    // Reference counter
    property RefCount: Integer read FRefCount;
  end;

  CReferencedItem = class of TReferencedItem;

  // Class which manages reference-counted items
  TReferencedItemManager = class
    // Memory usage grow step
    GrowStep: Integer;
    // Items
    Items: array of TReferencedItem;
    constructor Create;
    destructor Destroy; override;
    // Returns an item with the same class and parameter set as the specified one. If not found returns nil.
    function FindSameItem(AItem: TReferencedItem): TReferencedItem;
    // If the same as the given item is present in manager returns it, otherwise adds the given item and returns it
    function AddItem(Item: TReferencedItem): TReferencedItem;
    // Clears and release all contained items
    procedure Clear;
  private
    // Total items in manager
    FTotalItems: Integer;
  public
    // Total items in manager
    property TotalItems: Integer read FTotalItems;
  end;

  // Hash map key location data structure
  TKeyLocation  = packed record Index1, Index2: Integer; end;

  // Pointer-to-pointer map key type
  KeyType = Pointer;
  // Pointer-to-pointer map value type
  ValueType = Pointer;

  // Hash function delegate
  TPointerHashFunction = function(Key: KeyType): Integer of object;
  // Hash map action delegate
  TPointerPointerDoFunction = function(Key: KeyType; Value: ValueType): Boolean of object;

  // Hash map key-value pair
  TKeyValuePair = packed record Key: KeyType; Value: ValueType; end;

  // Data structure to store values of hash map
  TValueStore   = packed record Count: Integer; Data: array of TKeyValuePair; end;

  { @Abstract(Pointer to pointer hash map)
    A data structure which maps a pointer to another pointer in constant time (O(1)) }
  TPointerPointerMap = class
  private
    FValues: array of TValueStore;
    FCapacity, GrowStep: Integer;
    function LocateKey(const Key: KeyType; out KeyLocation: TKeyLocation; Add: Boolean): Boolean;
    function GetValue(const Key: KeyType): ValueType; {$I inline.inc}
    procedure SetValue(const Key: KeyType; const Value: ValueType); {$I inline.inc}
    procedure SetCapacity(ACapacity: Integer);
    function DefaultHash(Key: KeyType): Integer; virtual;
  public
    // Current hash function
    HashFunction: TPointerHashFunction;
    constructor Create; overload;
    constructor Create(Capacity: Integer); overload;
    // Calls a delegate for each value stored in the map
    procedure DoForEach(DoFunction: TPointerPointerDoFunction);

    // Values retrieved by pointer key
    property Values[const Key: KeyType]: ValueType read GetValue write SetValue; default;
    // Determines hash function values range which is currently used.
    property Capacity: Integer read FCapacity;
  end;

  // Container for untyped temporary data
  TTempContainer = class
    TotalDataChains, MaxDataChains: Integer;
    function AddData(Src: Pointer; Size: Integer): Integer; virtual;
    procedure RemoveData(ID: Integer); virtual;
    function GetData(ID: Integer): Pointer; virtual;
    function GetDataSize(ID: Integer): Integer; virtual;
    function ExtractData(ID: Integer): Pointer; virtual;
    destructor Destroy; override;
  protected
    Data: Pointer;
    DataSize: Integer;
    DataChains: array of Pointer;
    DataSizes: array of Integer;
  end;

  TQueue = class
    TotalElements: Integer;
    ElementSize, Capacity, CapacityStep: Cardinal;
    constructor Create;
    procedure Allocate(NewCapacity: Cardinal); virtual;
    function Copy: TQueue; virtual;
    procedure Delete(Index: Cardinal); virtual;
    procedure Remove(Index, Count: Cardinal); virtual;
    procedure MakeEmpty; virtual;
    procedure Clear; virtual;
    function Save(const Stream: Basics.TStream): Boolean; virtual;
    function Load(const Stream: Basics.TStream): Boolean; virtual;
    destructor Destroy; override;
  protected
    FData: Pointer;
  end;

  // Data structure represented with samples. Values between samples are calculated with some interpolation algorithm.
  TSampledData = class
  private
    // [1..TotalSamples]
    function GetIndex(AX: Single): Integer; {$I inline.inc}
    // Finds and places into NewIndex an index for the given X value and returns True if the index is found or False if it is a new value
    function FindIndex(AX: Single): Integer;
    function GetSampleX(Index: Integer): Single; {$I inline.inc}
    procedure SetSamplesX(Index: Integer; const Value: Single); {$I inline.inc}

    procedure SetTotalSamples(const Value: Integer); virtual;
    procedure SetMaxX(const Value: Single);
    procedure SetMinX(const Value: Single);
  protected
    FSampleX: array of Single;
    FThreshold: Single;
    FMinX, FMaxX: Single;
    FTotalSamples: Integer;
    PropertyValueType: TPropertyValueType;
    function GetDataSize: Integer; virtual; abstract;
    procedure DataExport(Dest: Pointer); virtual; abstract;
    procedure DataImport(Src: Pointer); virtual; abstract;
    // Should be implemented in descendants and move a sample value from SrcIndex to DestIndex to maintain sorted order
    procedure MoveSample(SrcIndex, DestIndex: Integer); virtual; abstract;
  public
    Enabled: Boolean;
    constructor Create; virtual;

    procedure Reset; virtual;

    // Adds a property which represents all samples
    procedure AddAsProperty(Properties: Props.TProperties; const AName: string); virtual;
    // Reads samples from properties
    procedure SetFromProperty(Properties: Props.TProperties; const AName: string); virtual;

    // Deletes the specified sample
    procedure Delete(Index: Integer);

    property TotalSamples: Integer read FTotalSamples write SetTotalSamples;
    property MinX: Single read FMinX write SetMinX;
    property MaxX: Single read FMaxX write SetMaxX;
    property SampleX[Index: Integer]: Single read GetSampleX write SetSamplesX;
  end;

  // Sampled single precision floats
  TSampledFloats = class(TSampledData)
  private
    FSamples: array of Single;
    FMinY, FMaxY: Single;
    FRange, FRangeInv: Single;
    function GetSampleValue(Index: Integer): Single; {$I inline.inc}
    procedure SetSampleValue(Index: Integer; const Value: Single); {$I inline.inc}
    function GetValue(X: Single): Single;
    procedure SetTotalSamples(const Value: Integer); override;
    procedure SetMaxY(const Value: Single);
    procedure SetMinY(const Value: Single);
  protected
    function GetDataSize: Integer; override;
    procedure DataExport(Dest: Pointer); override;
    procedure DataImport(Src: Pointer); override;
    procedure MoveSample(SrcIndex, DestIndex: Integer); override;
  public
    // Value used as default while resetting
    DefaultValue: Single;
    
    constructor Create; override;
    // Reset all to default value
    procedure Reset; override;

    // Creates a property hierarchy with the given name in the specified property collection
    procedure AddAsProperty(Properties: Props.TProperties; const AName: string); override;
    // Applies property
    procedure SetFromProperty(Properties: Props.TProperties; const AName: string); override;

    // Insert sample
    procedure Insert(AX, AY: Single); {$I inline.inc}

    // Value range (MaxY - MinY)
    property Range: Single read FRange;
    // 1/Range
    property RangeInv: Single read FRangeInv;
    // Minimal sample value
    property MinY: Single read FMinY write SetMinY;
    // Maximal sample value
    property MaxY: Single read FMaxY write SetMaxY;
    // Value of sample specified by index
    property SampleValue[Index: Integer]: Single read GetSampleValue write SetSampleValue;
    // Interpolated value
    property Value[X: Single]: Single read GetValue;

  end;

  // Color gradient represented with color samples and interpolation between the samples
  TSampledGradient = class(TSampledData)
  private
    FSamples: array of TColor;
    function GetSampleValue(Index: Integer): TColor; {$I inline.inc}
    procedure SetSampleValue(Index: Integer; const Value: TColor); {$I inline.inc}
    function GetValue(X: Single): TColor;
    procedure SetTotalSamples(const Value: Integer); override;
  protected
    function GetDataSize: Integer; override;
    procedure DataExport(Dest: Pointer); override;
    procedure DataImport(Src: Pointer); override;
    procedure MoveSample(SrcIndex, DestIndex: Integer); override;
  public
    constructor Create; override;
    procedure Reset; override;

    procedure Insert(AX: Single; AColor: TColor); {$I inline.inc}
    property SampleValue[Index: Integer]: TColor read GetSampleValue write SetSampleValue;
    property Value[X: Single]: TColor read GetValue;
  end;

  function CreateSampledFloats(MinValue, MaxValue, DefValue: Single): TSampledFloats;

implementation

{ TBaseUniqueItem }

constructor TBaseUniqueItem.Create;
begin
  Index := -1;
end;

function TBaseUniqueItem.IsInContainer: Boolean;
begin
  Result := Index <> -1;
end;

{ TUniqueItemCollection }

constructor TUniqueItemCollection.Create;
begin
  GrowStep := 1;
end;

destructor TUniqueItemCollection.Destroy;
begin
  Items := nil;
  inherited;
end;

function TUniqueItemCollection.Add(AItem: TBaseUniqueItem): TBaseUniqueItem;
begin
  Result := nil;
  if Exists(AItem) then Exit;

  Inc(FTotalItems);
  if Length(Items) < FTotalItems then SetLength(Items, Length(Items) + GrowStep);

  Items[FTotalItems-1] := AItem;
  Items[FTotalItems-1].Index := FTotalItems-1;
end;

function TUniqueItemCollection.Exists(AItem: TBaseUniqueItem): Boolean;
begin
  Result := False;
  if AItem = nil then Exit;
  Result := (AItem.Index >= 0) and (AItem.Index < FTotalItems) and (Items[AItem.Index] = AItem);
//  for i := 0 to FTotalItems-1 do if Items[i] = AItem then Exit;
end;

function TUniqueItemCollection.Remove(AItem: TBaseUniqueItem): Boolean;
var Index: Integer;
begin
  Result := False;
  if AItem = nil then Exit;
  if Exists(AItem) then begin
    Index := AItem.Index;
    AItem.Index := -1;
    if Ordered then begin
      while Index < FTotalItems-1 do begin
        Items[Index] := Items[Index+1];
        Items[Index].Index := Index;
        Inc(Index);
      end;
    end else begin
      Items[Index] := Items[FTotalItems-1];
      Items[Index].Index := Index;
    end;
    Dec(FTotalItems);
    Result := True;
  end;// else Assert(False, 'TUniqueItemCollection.Remove: Item not found');
end;

procedure TUniqueItemCollection.Clear;
begin
  FTotalItems := 0; SetLength(Items, 0);
end;

{ TReferencedItem }

constructor TReferencedItem.Create;
begin
  FRefCount := 1;
//  NextItem  := nil;
end;

function TReferencedItem.IncRef: Integer;
begin
  Inc(FRefCount); Result := FRefCount;
end;

function TReferencedItem.DecRef: Integer;
begin
  Dec(FRefCount);
  Result := FRefCount;
  if FRefCount <= 0 then Free;
end;

function TReferencedItem.IsSameItem(AItem: TReferencedItem): Boolean;
var Par1Num, Par2Num: Integer; Par1, Par2: Pointer;
begin
  Result := False;
{  if ClassType <> AItem.ClassType then Exit;

  Par1Num := RetrieveParameters(Par1, True);
  Par2Num := AItem.RetrieveParameters(Par2, True);
  if Par1Num <> Par2Num then Exit;                                 // Unlikely case

  if not CmpMem(Par1, Par2, Par1Num*4) then Exit;                  // Exit if some parameters not match

  Result := True;}
end;

function TReferencedItem.RetrieveParameters(out Parameters: Pointer; Internal: Boolean): Integer;
begin
  Parameters := nil; Result := 0;
end;

{ TReferencedItemManager }

constructor TReferencedItemManager.Create;
begin
  GrowStep := 1;
end;

function TReferencedItemManager.FindSameItem(AItem: TReferencedItem): TReferencedItem;
var i: Integer;
begin
  Result := nil; 
  i := FTotalItems-1;
  while (i >= 0) and (not Items[i].IsSameItem(AItem)) do Dec(i);
  if i >= 0 then Result := Items[i]
end;

function TReferencedItemManager.AddItem(Item: TReferencedItem): TReferencedItem;
begin
  Result := FindSameItem(Item);
  if Result <> nil then Exit;
  Result := Item;
// Add an item
  if Length(Items) <= FTotalItems then SetLength(Items, Length(Items) + GrowStep);
  Items[FTotalItems] := Item;
  Inc(FTotalItems);
end;

procedure TReferencedItemManager.Clear;
var i: Integer;
begin
  for i := 0 to TotalItems-1 do Items[i].Free;
  Items := nil;
  FTotalItems := 0;
end;

destructor TReferencedItemManager.Destroy;
begin
  Clear;
  inherited;
end;

{ TQueue }

constructor TQueue.Create;
begin
  CapacityStep := 256;
  Clear;
end;

procedure TQueue.Allocate(NewCapacity: Cardinal);
begin
  Capacity := NewCapacity;
end;

function TQueue.Copy: TQueue;
begin
  Result := ClassType.Create as TQueue;
  Result.ElementSize := ElementSize;
  Result.CapacityStep := CapacityStep;
  Result.Allocate(Capacity);
  Result.TotalElements := TotalElements;

  if TotalElements > 0 then Move(FData^, Result.FData^, Cardinal(TotalElements) * ElementSize);
end;

function TQueue.Save(const Stream: Basics.TStream): Boolean;
begin
  Result := False;
  if not Stream.WriteCheck(TotalElements, SizeOf(TotalElements)) then Exit;
  if TotalElements > 0 then if not Stream.WriteCheck(FData^, ElementSize * Cardinal(TotalElements)) then Exit;
  Result := True;
end;

function TQueue.Load(const Stream: Basics.TStream): Boolean;
begin
  Result := False;
  if not Stream.ReadCheck(TotalElements, SizeOf(TotalElements)) then Exit;
  Allocate(TotalElements);
  if TotalElements > 0 then if not Stream.ReadCheck(FData^, ElementSize * Cardinal(TotalElements)) then Exit;
  Result := True;
end;

procedure TQueue.Delete(Index: Cardinal);
begin
  Dec(TotalElements);
  if Index < Cardinal(TotalElements) then
   Move(Pointer(Cardinal(FData) + Cardinal(TotalElements) * ElementSize)^, Pointer(Cardinal(FData) + Index * ElementSize)^, ElementSize);
end;

procedure TQueue.Clear;
begin
  TotalElements := 0; Capacity := 0; FData := nil;
end;

procedure TQueue.MakeEmpty;
begin
  TotalElements := 0;
end;

procedure TQueue.Remove(Index, Count: Cardinal);
begin
  if Count = 0 then Exit;
  Assert((TotalElements >= 0) and (Index+Count-1 < Cardinal(TotalElements)), 'CommandQueue.Remove: Index out of bounds');
  Move(Pointer(Cardinal(FData) + (Index + Count) * ElementSize)^, Pointer(Cardinal(FData) + Index * ElementSize)^, Cardinal(MaxI(0, Cardinal(TotalElements) - Index - Count)) * ElementSize);
  Dec(TotalElements, Count);
end;

destructor TQueue.Destroy;
begin
  Clear;
  inherited;
end;

{ TTempContainer }

function TTempContainer.AddData(Src: Pointer; Size: Integer): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to Length(DataChains)-1 do if DataChains[i] = nil then begin    // Try to find an unused ID
    Result := i; Break;
  end;
  if Result = -1 then begin
    Result := MaxDataChains;
    Inc(MaxDataChains);
    SetLength(DataChains, MaxDataChains);
    SetLength(DataSizes, MaxDataChains);
  end;
  GetMem(DataChains[Result], Size);
  Move(Src^, DataChains[Result]^, Size);
  DataSizes[Result] := Size;
  Inc(TotalDataChains);
end;

function TTempContainer.GetData(ID: Integer): Pointer;
begin
  Result := nil;
  if (ID < 0) or (ID >= MaxDataChains) then Exit;
  Result := DataChains[ID];
end;

function TTempContainer.GetDataSize(ID: Integer): Integer;
begin
  Result := 0;
  if (ID < 0) or (ID >= MaxDataChains) then Exit;
  Result := DataSizes[ID];
end;

procedure TTempContainer.RemoveData(ID: Integer);
begin
  if (ID < 0) or (ID >= MaxDataChains) or (DataChains[ID] = nil) then Exit;
  FreeMem(DataChains[ID], DataSizes[ID]);
  DataChains[ID] := nil;
  Dec(TotalDataChains);
  Assert(TotalDataChains >= 0, 'TempData: TotalDataChains < 0');
end;

function TTempContainer.ExtractData(ID: Integer): Pointer;
begin
  Result := GetData(ID);
  RemoveData(ID);
end;

destructor TTempContainer.Destroy;
var i: Integer;
begin
  for i := 0 to MaxDataChains-1 do RemoveData(i);
  SetLength(DataChains, 0);
  TotalDataChains := 0; MaxDataChains := 0;
  inherited;
end;

{ TPointerPointerMap }

constructor TPointerPointerMap.Create;
begin
  Create(DefaultHashmapCapacity);
end;

constructor TPointerPointerMap.Create(Capacity: Integer);
begin
  inherited Create;
  HashFunction := {$IFDEF OBJFPCEnable}@{$ENDIF}DefaultHash;
  GrowStep := Capacity;
  SetCapacity(Capacity);
end;

procedure TPointerPointerMap.DoForEach(DoFunction: TPointerPointerDoFunction);
var i, j: Integer;
begin
  if @DoFunction = nil then Exit;
  for i := 0 to Capacity-1 do for j := 0 to FValues[i].Count-1 do if DoFunction(FValues[i].Data[j].Key, FValues[i].Data[j].Value) then Exit;
end;

procedure TPointerPointerMap.SetCapacity(ACapacity: Integer);
begin
  FCapacity := ACapacity;
  SetLength(FValues, FCapacity);
end;

function TPointerPointerMap.LocateKey(const Key: KeyType; out KeyLocation: TKeyLocation; Add: Boolean): Boolean;
var i: Integer;
begin
  Result := True;
  KeyLocation.Index1 := HashFunction(Key);
  for i := 0 to FValues[KeyLocation.Index1].Count-1 do
    if FValues[KeyLocation.Index1].Data[i].Key = Key then begin
      KeyLocation.Index2 := i;
      Exit;
    end;

  Result := Add;

  if Add then begin
    KeyLocation.Index2 := FValues[KeyLocation.Index1].Count;
    if Length(FValues[KeyLocation.Index1].Data) <= FValues[KeyLocation.Index1].Count then
     SetLength(FValues[KeyLocation.Index1].Data, Length(FValues[KeyLocation.Index1].Data) + GrowStep);
    FValues[KeyLocation.Index1].Data[KeyLocation.Index2].Key := Key;
    Inc(FValues[KeyLocation.Index1].Count);
  end;
end;

function TPointerPointerMap.GetValue(const Key: KeyType): ValueType;
var  KeyLoc: TKeyLocation;
begin
  Result := nil;
  if not LocateKey(Key, KeyLoc, False) then Exit;
  Result := FValues[KeyLoc.Index1].Data[KeyLoc.Index2].Value;
end;

procedure TPointerPointerMap.SetValue(const Key: KeyType; const Value: ValueType);
var  KeyLoc: TKeyLocation;
begin
  if not LocateKey(Key, KeyLoc, True) then Exit;
  FValues[KeyLoc.Index1].Data[KeyLoc.Index2].Value := Value;
end;

function TPointerPointerMap.DefaultHash(Key: KeyType): Integer;
const K = 0.6180339887; // (Sqrt(5) - 1) / 2
begin
  Result := Trunc(FCapacity * (Frac(Cardinal(Key) * K)));
end;

{ TSampledData }

function TSampledData.GetIndex(AX: Single): Integer;
begin
  Result := FTotalSamples;
  while (Result > 0) and (AX < FSampleX[Result-1]) do Dec(Result);
end;

function TSampledData.FindIndex(AX: Single): Integer;
var i: Integer; Found: Boolean;
begin
  AX := ClampS(AX, MinX, MaxX);
  Result := GetIndex(AX);

  Found := (Result > 0) and (Abs(AX - FSampleX[Result-1]) < FThreshold);
  if Found then
    Result := Result-1
  else
    Found := (Result < FTotalSamples) and (Abs(AX - FSampleX[Result]) < FThreshold);

  if not Found then begin
    // Grow points array if needed
    TotalSamples := TotalSamples + 1;
    // Shift Samples array
    for i := FTotalSamples - 1 downto Result+1 do begin
      FSampleX[i] := FSampleX[i-1];
      MoveSample(i-1, i);           // Do the same move for values
    end;
    if (FTotalSamples <= 2) then FSampleX[Result] := AX;
  end;

  if (Result > 0) and (Result < FTotalSamples-1) then FSampleX[Result] := AX;
end;

function TSampledData.GetSampleX(Index: Integer): Single;
begin
  Result := FSampleX[ClampI(Index, 0, FTotalSamples-1)];
end;

procedure TSampledData.SetSamplesX(Index: Integer; const Value: Single);
begin
  if (Index > 0) and (Index < TotalSamples-1) then
    FSampleX[Index] := ClampS(Value, FSampleX[Index-1] + FThreshold, FSampleX[Index+1] - FThreshold);
end;

procedure TSampledData.SetTotalSamples(const Value: Integer);
const ArrayGrowStep = 16;                  // Grow points array by ArrayGrowStep elements at once for better performance
begin
  FTotalSamples := Value;
  if Length(FSampleX) < FTotalSamples then
    SetLength(FSampleX, FTotalSamples + ArrayGrowStep);
end;

procedure TSampledData.SetMinX(const Value: Single);
begin
  FMinX := Value;
  FSampleX[0] := FMinX;
end;

procedure TSampledData.SetMaxX(const Value: Single);
begin
  FMaxX := Value;
  FSampleX[FTotalSamples-1] := FMaxX;
end;

procedure TSampledData.Reset;
begin
  TotalSamples := 2;
  MinX := MinX;
  MaxX := MaxX;
end;

constructor TSampledData.Create;
begin
  PropertyValueType := vtSingleSample;
  FThreshold := 0.02;
  TotalSamples := 2;
  MinX := 0;
  MaxX := 1;
  Enabled := False;
  Reset;
end;

procedure TSampledData.AddAsProperty(Properties: Props.TProperties; const AName: string);
var Data: Pointer;
begin
  if not Assigned(Properties) then Exit;

  if TotalSamples > 0 then begin
    Data := Properties.TempCopy(nil, TotalSamples * (SizeOf(Single) + GetDataSize()));    // Data valid as long as Properties not freed
//    GetMem(Data, TotalSamples * (SizeOf(Single) + GetDataSize()));
    Move(FSampleX[0], Data^, TotalSamples * SizeOf(Single));
    DataExport(PtrOffs(Data, TotalSamples * SizeOf(Single)));
  end else Data := nil;
  Properties.Add(AName, PropertyValueType, [], IntToStrA(Cardinal(Data)), IntToStrA(TotalSamples * (SizeOf(Single) + GetDataSize())), '');
  Properties.Add(AName + '\$Reset',   vtBoolean, [], OnOffStr[False], '');

  Properties.Add(AName + '\$Enabled', vtBoolean, [], OnOffStr[Enabled], '');
  Properties.Add(AName + '\$Min X', vtSingle, [], FloatToStrA(FMinX), '');
  Properties.Add(AName + '\$Max X', vtSingle, [], FloatToStrA(FMaxX), '');
end;

procedure TSampledData.SetFromProperty(Properties: Props.TProperties; const AName: string);
var Buf: Pointer;
begin
  if not Assigned(Properties) then Exit;

  if Properties.Valid(AName) then begin
    TotalSamples := Properties.GetBinPropertySize(AName, SizeOf(Single) + GetDataSize());
//    SetLength(FSampleX, FTotalSamples);
    if Assigned(FSampleX) then begin
      GetMem(Buf, TotalSamples * (SizeOf(Single) + GetDataSize()));
      Properties.RetrieveBinPropertyData(AName, Buf);
      Move(Buf^, FSampleX[0], TotalSamples * SizeOf(Single));
      DataImport(PtrOffs(Buf, TotalSamples * SizeOf(Single)));
      FreeMem(Buf);
    end;
  end;
  if (TotalSamples < 2) or
     Properties.Valid(AName + '\$Reset') and (Properties.GetAsInteger(AName + '\$Reset') > 0) then Reset();

  if Properties.Valid(AName + '\$Enabled') then Enabled := Properties.GetAsInteger(AName + '\$Enabled') > 0;
  if Properties.Valid(AName + '\$Min X') then MinX := StrToFloatDefA(Properties[AName + '\$Min X'], 0);
  if Properties.Valid(AName + '\$Max X') then MaxX := StrToFloatDefA(Properties[AName + '\$Max X'], 0);
end;

procedure TSampledData.Delete(Index: Integer);
var i: Integer;
begin
  if (Index > 0) and (Index < TotalSamples-1) then begin
    for i := Index to TotalSamples - 2 do begin
      MoveSample(i+1, i);
      FSampleX[i] := FSampleX[i+1];
    end;
    TotalSamples := TotalSamples - 1;
  end;  
end;

{ TSampledFloats }

function CreateSampledFloats(MinValue, MaxValue, DefValue: Single): TSampledFloats;
begin
  Result := TSampledFloats.Create;
  Result.MaxY := MaxValue;
  Result.MinY := MinValue;
  Result.DefaultValue := DefValue;
  Result.Reset();
end;

function TSampledFloats.GetSampleValue(Index: Integer): Single;
begin
  Result := FSamples[ClampI(Index, 0, FTotalSamples-1)];
end;

procedure TSampledFloats.SetSampleValue(Index: Integer; const Value: Single);
begin
  if (Index >= 0) and (Index < TotalSamples) then
    FSamples[Index] := ClampS(Value, MinY, MaxY);
end;

function TSampledFloats.GetValue(X: Single): Single;
var Ind1, Ind2: Integer; K: Single;
begin
  Result := DefaultValue;

  Ind1 := GetIndex(X)-1;
  if (Ind1 < 0) or (Ind1 >= FTotalSamples) then Exit;

  Ind2 := MinI(Ind1+1, FTotalSamples-1);

  if abs(FSampleX[Ind1] - FSampleX[Ind2]) < epsilon then
    K := 1
  else
    K := (FSampleX[Ind2] - X) / (FSampleX[Ind2] - FSampleX[Ind1]);

  Result := FSamples[Ind1] * K + FSamples[Ind2] * (1-K);

//  Result := FMinY + Result * (FMaxY - FMinY);
end;

procedure TSampledFloats.SetMaxY(const Value: Single);
begin
  FMaxY := Value;
  FRange := FMaxY - FMinY;
  if FRange > epsilon then FRangeInv := 1/FRange else FRangeInv := 0;
end;

procedure TSampledFloats.SetMinY(const Value: Single);
begin
  FMinY := Value;
  FRange := FMaxY - FMinY;
  if FRange > epsilon then FRangeInv := 1/FRange else FRangeInv := 0;
end;

procedure TSampledFloats.SetTotalSamples(const Value: Integer);
begin
  inherited;
  SetLength(FSamples, Length(FSampleX));
end;

function TSampledFloats.GetDataSize: Integer;
begin
  Result := SizeOf(Single);
end;

procedure TSampledFloats.DataExport(Dest: Pointer);
begin
  if TotalSamples > 0 then Move(FSamples[0], Dest^, TotalSamples*GetDataSize());
end;

procedure TSampledFloats.DataImport(Src: Pointer);
begin
  Assert(Length(FSamples) = Length(FSampleX));
  if TotalSamples > 0 then Move(Src^, FSamples[0], TotalSamples*GetDataSize());
end;

procedure TSampledFloats.MoveSample(SrcIndex, DestIndex: Integer);
begin
  FSamples[DestIndex] := FSamples[SrcIndex];
end;

constructor TSampledFloats.Create;
begin
  DefaultValue := 0.5;
  inherited;
  MinY := 0;
  MaxY := 1;
end;

procedure TSampledFloats.Reset;
begin
  inherited;
  FSamples[0] := DefaultValue;
  FSamples[FTotalSamples-1] := DefaultValue;
end;

procedure TSampledFloats.AddAsProperty(Properties: Props.TProperties; const AName: string);
begin
  inherited;
  Properties.Add(AName + '\$Min Y', vtSingle, [], FloatToStrA(FMinY), '');
  Properties.Add(AName + '\$Max Y', vtSingle, [], FloatToStrA(FMaxY), '');
  Properties.Add(AName + '\$DefaultValue', vtSingle, [], FloatToStrA(DefaultValue), '');
end;

procedure TSampledFloats.SetFromProperty(Properties: Props.TProperties; const AName: string);
begin
  inherited;
  if Properties.Valid(AName + '\$Min Y') then MinY := StrToFloatDefA(Properties[AName + '\$Min Y'], 0);
  if Properties.Valid(AName + '\$Max Y') then MaxY := StrToFloatDefA(Properties[AName + '\$Max Y'], 0);
  if Properties.Valid(AName + '\$DefaultValue') then DefaultValue := StrToFloatDefA(Properties[AName + '\$DefaultValue'], 0);
end;

procedure TSampledFloats.Insert(AX, AY: Single);
begin
  FSamples[FindIndex(AX)] := ClampS(AY, MinY, MaxY);
end;

{ TSampledGradient }

function TSampledGradient.GetSampleValue(Index: Integer): TColor;
begin
  Result := FSamples[ClampI(Index, 0, FTotalSamples-1)];
end;

procedure TSampledGradient.SetSampleValue(Index: Integer; const Value: TColor);
begin
  if (Index >= 0) and (Index < TotalSamples) then
    FSamples[Index] := Value;
end;

function TSampledGradient.GetValue(X: Single): TColor;
var Ind1, Ind2: Integer; K: Single;
begin
  Result.C := $808080FF;

  Ind1 := GetIndex(X)-1;
  if (Ind1 < 0) or (Ind1 >= FTotalSamples) then Exit;

  Ind2 := MinI(Ind1+1, FTotalSamples-1);

  if abs(FSampleX[Ind1] - FSampleX[Ind2]) < epsilon then
    K := 1
  else
    K := (X - FSampleX[Ind1]) / (FSampleX[Ind2] - FSampleX[Ind1]);


  Result := BlendColor(FSamples[Ind1], FSamples[Ind2], K)
end;

procedure TSampledGradient.SetTotalSamples(const Value: Integer);
begin
  inherited;
  SetLength(FSamples, Length(FSampleX));
end;

function TSampledGradient.GetDataSize: Integer;
begin
  Result := SizeOf(TColor);
end;

constructor TSampledGradient.Create;
begin
  inherited;
  PropertyValueType := vtGradientSample;
end;

procedure TSampledGradient.DataExport(Dest: Pointer);
begin
  if TotalSamples > 0 then Move(FSamples[0], Dest^, TotalSamples*GetDataSize());
end;

procedure TSampledGradient.DataImport(Src: Pointer);
begin
  if TotalSamples > 0 then Move(Src^, FSamples[0], TotalSamples*GetDataSize());
end;

procedure TSampledGradient.MoveSample(SrcIndex, DestIndex: Integer);
begin
  FSamples[DestIndex] := FSamples[SrcIndex];
end;

procedure TSampledGradient.Reset;
begin
  inherited;
  FSamples[0].C := $FF000000;
  FSamples[FTotalSamples-1].C := $FFFFFFFF;
end;

procedure TSampledGradient.Insert(AX: Single; AColor: TColor);
begin
  FSamples[FindIndex(AX)] := AColor;
end;

end.