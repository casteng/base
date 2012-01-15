(*
  Generic hash table collection
  (C) George Bakhtadze
Usage - once per unit:
  type
    _HashMapKeyType = <some type>;
    _HashMapValueType = <some type>;
    $I gen_coll_hashmap.inc}

    T<xxx><yyy>HashMap = class(_GenHashMap)
    end;

  implementation

   [ function _HashMapHashFunc(const Key: _HashMapKeyType): __CollectionIndexType;
     begin
       Result := Ord(@Key);
     end;]

   [ function _HashMapKeyEquals(const Key1, Key2: _HashMapKeyType): Boolean;
     begin
       Result := Key1 = Key2;
     end;]

   [ function _HashMapValueEquals(const Value1, Value2: _HashMapValueType): Boolean;
     begin
       Result := Value1 = Value2;
     end;]

    $I gen_coll_hashmap.inc}

  a compiler message with explanation which type is being instantiated would be very helpful:
  $MESSAGE 'Instantiating TStringIntegerHashMap'
  $I gen_coll_hashmap.inc}
*)

{$IFNDEF _HASHMAPIMPL}     // Interface

  {$IF not Declared(__CollectionIndexType)}
    __CollectionIndexType = Integer;
  {$IFEND}

  // Hash map key location data structure
  _HashMapKeyLoc = packed record Index1, Index2: __CollectionIndexType; end;

  // Hash map key-value pair
  _HashMapPair = packed record Key: _HashMapKeyType; Value: _HashMapValueType; end;

  // Hash  map for each delegate
  _HashMapDelegate = function(const key: _HashMapKeyType; const value: _HashMapValueType; Data: Pointer): Boolean of object;

  // Data structure to store values of hash map
  _HashMapValueRec = packed record Count: __CollectionIndexType; Data: array of _HashMapPair; end;

  // Hash map keys collection type
  _HashMapKeys = array of _HashMapValueRec;

  _GenHashMap = class
  protected
    FValues: _HashMapKeys;
    // Capacity of the hash map. Should be a power of 2.
    FCapacity,
    // Capacity mask
    FMask: __CollectionIndexType;
    // Grow step of bucket array
    FBucketGrowStep: __CollectionIndexType;
    // Number of entries
    FCount: __CollectionIndexType;
    function GetIndexInBucket(const Key: _HashMapKeyType; out BucketIndex: __CollectionIndexType): __CollectionIndexType; {$I inline.inc}
    function GetValue(const Key: _HashMapKeyType): _HashMapValueType; {$I inline.inc}
    procedure SetValue(const Key: _HashMapKeyType; const Value: _HashMapValueType); {$I inline.inc}
    procedure SetCapacity(ACapacity: __CollectionIndexType);
  public
    constructor Create(); overload;
    constructor Create(Capacity: __CollectionIndexType); overload;
    destructor Destroy(); override;

    // Returns True if the hash map contains the key
    function ContainsKey(const Key: _HashMapKeyType): Boolean; {$I inline.inc}
    // Returns True if the hash map contains the value
    function ContainsValue(const Value: _HashMapValueType): Boolean; {$I inline.inc}

    // Calls a delegate for each value stored in the map
    procedure ForEach(Delegate: _HashMapDelegate; Data: Pointer);

    // Returns True if the collection contains no elements
    function IsEmpty(): Boolean; {$I inline.inc}
    // Removes all elements from the collection
    procedure Clear(); {$I inline.inc}

    // Values retrieved by pointer key
    property Values[const Key: _HashMapKeyType]: _HashMapValueType read GetValue write SetValue; default;
    // Determines hash function values range which is currently used.
    property Capacity: __CollectionIndexType read FCapacity;
    // Grow step of bucket array
    property BucketGrowStep: __CollectionIndexType read FBucketGrowStep write FBucketGrowStep;
    // Number of entries
    property Count: __CollectionIndexType read FCount write FCount;
    // Keys collection
    property Keys: _HashMapKeys read FValues;
  end;

  {$DEFINE _HASHMAPIMPL}
{$ELSE}                    // Implementation

  {$IF Declared(_HashMapOptions)}
    {$I gen_coll_hashmap_opt.inc}
  {$IFEND}


  {$IF not Declared(_HashMapDefaultCapacity)}
    const _HashMapDefaultCapacity = 16;
  {$IFEND}


  {$IF not Declared(_HashMapHashFunc)}
    function _HashMapHashFunc(Key: _HashMapKeyType): NativeUInt; {$I inline.inc}
    const K = 0.6180339887; // (Sqrt(5) - 1) / 2
    begin
      Result := Trunc(maxint * (Frac(__CollectionIndexType(Key) * K)));
    end;
  {$IFEND}


  function _GenHashMap.GetIndexInBucket(const Key: _HashMapKeyType; out BucketIndex: __CollectionIndexType): __CollectionIndexType;
  begin
    BucketIndex := _HashMapHashFunc(Key) and FMask;
    Result := 0;
    while (Result < FValues[BucketIndex].Count) do
      {$IF Declared(_HashMapKeyEquals)}
        if _HashMapKeyEquals(FValues[BucketIndex].Data[Result].Key, Key) then Break else Inc(Result);
      {$ELSE}
        if (FValues[BucketIndex].Data[Result].Key = Key) then Break else Inc(Result);
      {$IFEND}
  end;

  function _GenHashMap.GetValue(const Key: _HashMapKeyType): _HashMapValueType;
  var Index, i: __CollectionIndexType;
  begin
    i := GetIndexInBucket(Key, index);

    if i < FValues[Index].Count then
      Result := FValues[Index].Data[i].Value
    else
      {$IFDEF _HashMapTypeNullable}
        Result := nil;
      {$ELSE}
        Assert(False, 'Key not found');
      {$ENDIF}
  end;

  procedure _GenHashMap.SetValue(const Key: _HashMapKeyType; const Value: _HashMapValueType);
  var Index, i: __CollectionIndexType;
  begin
    i := GetIndexInBucket(Key, index);

    if i = FValues[Index].Count then begin
      if Length(FValues[Index].Data) <= i then
        SetLength(FValues[Index].Data, Length(FValues[Index].Data) + FBucketGrowStep);
      FValues[Index].Data[i].Key := Key;
      FValues[Index].Count := i+1;
      Inc(FCount);
    end;

    FValues[Index].Data[i].Value := Value;
  end;

  procedure _GenHashMap.SetCapacity(ACapacity: __CollectionIndexType);
  begin
    Assert((ACapacity > 0) and (ACapacity and (ACapacity-1) = 0), 'Capacity should be greater then zero and a power of 2');
    FCapacity := ACapacity;
    SetLength(FValues, FCapacity);
    FMask := FCapacity-1;
  end;

  constructor _GenHashMap.Create();
  begin
    Create(_HashMapDefaultCapacity);
  end;

  constructor _GenHashMap.Create(Capacity: __CollectionIndexType);
  begin
    inherited Create();
    FBucketGrowStep := 1;
    SetCapacity(Capacity);
  end;

  destructor _GenHashMap.Destroy();
  begin
    Clear;
    inherited;
  end;

  function _GenHashMap.ContainsKey(const Key: _HashMapKeyType): Boolean;
  var Index: __CollectionIndexType;
  begin
    Result := GetIndexInBucket(Key, index) < FValues[Index].Count;
  end;

  function _GenHashMap.ContainsValue(const Value: _HashMapValueType): Boolean;
  var i, j: __CollectionIndexType;
  begin
    Result := True;
    for i := 0 to High(FValues) do
      for j := 0 to FValues[i].Count-1 do
        {$IF Declared(_HashMapValueEquals)}
          if _HashMapValueEquals(FValues[i].Data[j].Value, Value) then Exit;
        {$ELSE}
          if (FValues[i].Data[j].Value = Value) then Exit;
        {$IFEND}
    Result := False;
  end;

  procedure _GenHashMap.ForEach(Delegate: _HashMapDelegate; Data: Pointer);
  var i, j: __CollectionIndexType;
  begin
    for i := 0 to High(FValues) do
      for j := 0 to FValues[i].Count-1 do
        Delegate(FValues[i].Data[j].Key, FValues[i].Data[j].Value, Data);
  end;

  function _GenHashMap.IsEmpty(): Boolean;
  begin
    Result := FCount = 0;
  end;

  procedure _GenHashMap.Clear();
  var i: __CollectionIndexType;
  begin
    FCount := 0;
    for i := 0 to High(FValues) do begin
      SetLength(FValues[i].Data, 0);
      FValues[i].Count := 0;
    end;
    SetLength(FValues, 0);
  end;

  {$UNDEF _HASHMAPIMPL}
{$ENDIF}
