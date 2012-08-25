(*
  @Abstract(Template classes and algorithms test unit)
  (C) 2003-2012 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: Jan 21, 2012
  The unit contains tests for template classes and algorithms
  *)
{$Include GDefines.inc}
unit GenTestU;
interface

uses
  Tester, Logger, SysUtils, Template, BaseTypes, Basics;

type
  // Key type of test map class
  _MapKeyType = AnsiString;
  // Value type of test map class
  _MapValueType = AnsiString;

  // Base class for all template classes tests
  TTestTemplates = class(TTestSuite)
  end;

  // Generic sort algorithm test class
  TTestGenericSort = class(TTestTemplates)
  private
    arr, OArr, ind: TIndArray;
    strarr, strarr2: TAnsiStringArray;
  protected
    procedure InitSuite(); override;
    procedure InitTest(); override;
  public

    procedure PrepareArray;

    procedure testSortStr();
    procedure testOldSortStr();

    procedure testOldSortAcc();

    procedure testOldSortDsc();

  published
    procedure TestSortAcc();
    procedure TestSortDsc();
    procedure TestSortInd();
  end;

  TTestCollections = class(TTestTemplates)
  protected
    function ForCollEl(const e: Integer; Data: Pointer): Boolean;
  end;

  TTestHash = class(TTestCollections)
  private
    procedure ForPair(const Key: Integer; const Value: String; Data: Pointer);
  published
    procedure TestHasmMap();
  end;

  TTestVector = class(TTestCollections)
  published
    procedure TestVector();
  end;

  TTestLinkedList = class(TTestCollections)
  published
    procedure TestLinkedList();
  end;

  _HashMapKeyType = Integer;
  _HashMapValueType = String;
  {$MESSAGE 'Instantiating TIntStrHashMap interface'}
  {$I gen_coll_hashmap.inc}
  TIntStrHashMap = class(_GenHashMap) end;
  TIntStrHashMapKeyIterator = object(_GenHashMapKeyIterator) end;

  TKeyArray = array of _HashMapKeyType;

  _VectorValueType = Integer;
  {$MESSAGE 'Instantiating TIntVector interface'}
  {$I gen_coll_vector.inc}
  TIntVector = _GenVector;

  _LinkedListValueType = Integer;
  {$MESSAGE 'Instantiating TIntLinkedList interface'}
  {$I gen_coll_linkedlist.inc}
  TIntLinkedList = _GenLinkedList;

implementation

  {$MESSAGE 'Instantiating TIntStrHashMap'}
  {$I gen_coll_hashmap.inc}

  const _VectorOptions = [];
  {$MESSAGE 'Instantiating TIntVector'}
  {$I gen_coll_vector.inc}

  const _LinkedListOptions = [dsRangeCheck];
  {$MESSAGE 'Instantiating TIntLinkedList'}
  {$I gen_coll_linkedlist.inc}

var
  Rnd: TRandomGenerator;

const
  TESTCOUNT = 1024*8*4;//*256;//*1000*10;
  HashMapElCnt = 500;//1024*8;
  CollElCnt = 1024*8;
//type TestData = Integer;

procedure SortStr(const Count: Integer; const Data: TAnsiStringArray);
//  const _SortOptions = [soBadData];
  type _SortDataType = AnsiString;
  {$MESSAGE 'Instantiating sort algorithm <AnsiString>'}
  {$I gen_algo_sort.inc}
end;

procedure SortDsc(const Count: Integer; const Data: TIndArray);
  const _SortOptions = [soDescending];
  type _SortDataType = Integer; _SortValueType = Integer;
  function _SortGetValue2(const V: _SortDataType): _SortValueType; {$I inline.inc}
  begin
    Result := V;
  end;
  {.$DEFINE _SORTBADDATA}
  {.$DEFINE _SORTDESCENDING}
  {$MESSAGE 'Instantiating sort algorithm <Integer>'}
  {$I gen_algo_sort.inc}
end;

procedure SortRec(Count: Integer; Data: TIndArray);
type _DataType = Integer;
{$DEFINE COMPARABLE}
{$MESSAGE 'Instantiating sort algorithm <Integer>'}
{$I gen_algo_sort_rec.inc}
{$IFNDEF ForCodeNavigationWork} begin end; {$ENDIF}

// Initialize array and fill it with random values
procedure ShuffleArray(data: TIndArray); overload;
var i: Integer;
begin
  Randomize;
  for i := 0 to TESTCOUNT-1 do data[i] := Random(TESTCOUNT);
//  for i := 0 to TESTCOUNT-1 do data[i] := Round(Sin(i/TESTCOUNT*pi*3.234)*TESTCOUNT);
(*  v := TESTCOUNT div 2;
  vi := Random(2)*2-1;
  for i := 0 to TESTCOUNT-1 do begin

    data[i] := v;
    v := v + vi;
    if i mod (TESTCOUNT div 50) = 0 then vi := Random(2)*2-1;

  end;*)
end;

// Initialize array and fill it with random values
procedure ShuffleArray(data: TAnsiStringArray); overload;
var i, j: Integer;
begin
  Randomize;
  for i := 0 to TESTCOUNT-1 do begin
    SetLength(data[i], 3 + Random(10));
    for j := 1 to Length(data[i]) do data[i] := AnsiChar(Ord('0') + Random(Ord('z')-Ord('0')));
  end;
end;

// Checks if the array is sorted in ascending order
function isArraySortedAcc(arr: TIndArray): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  while (i >= 0) and (arr[i] <= arr[i+1]) do Dec(i);
  Result := i < 0;
end;

// Checks if the indexed array is sorted in ascending order
function isIndArraySortedAcc(arr, oarr, ind: TIndArray): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  if arr[i+1] = OArr[i+1] then
    while (i >= 0) and (arr[ind[i]] <= arr[ind[i+1]])
      and (arr[i] = OArr[i]) do Dec(i);
  Result := i < 0;
end;

// Checks if the array is sorted in ascending order
function isArraySortedStr(arr: TAnsiStringArray): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  while (i >= 0) and (arr[i] <= arr[i+1]) do Dec(i);
  Result := i < 0;
end;

// Checks if the array is sorted in descending order
function isArraySortedDsc(arr: TIndArray): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  while (i >= 0) and (arr[i] >= arr[i+1]) do Dec(i);
  Result := i < 0;
end;

{ TTestGenericSort }

procedure TTestGenericSort.InitSuite();
var i: Integer;
begin
  if Length(OArr) <> TESTCOUNT then SetLength(OArr, TESTCOUNT);
  ShuffleArray(OArr);
  if Length(ind) <> TESTCOUNT then SetLength(ind, TESTCOUNT);
  for i := 0 to High(ind) do ind[i] := i;
//  if Length(strarr2) <> TESTCOUNT then SetLength(strarr2, TESTCOUNT);
//  ShuffleArray(strarr2);
end;

procedure TTestGenericSort.InitTest;
begin
  PrepareArray();
end;

procedure TTestGenericSort.PrepareArray;
begin
  arr := Copy(OArr, 0, Length(OArr));
  strarr := Copy(strarr2, 0, Length(strarr2));
end;

procedure TTestGenericSort.testSortAcc;

  procedure Sort(const Count: Integer; const Data: TIndArray);
  //  const _SortOptions = [soBadData];
    type _SortDataType = Integer;
    function _SortCompare(const V1, V2: _SortDataType): Integer; {$I inline.inc}
    begin
      Result := (V1 - V2);         // As usual
    end;
    {$MESSAGE 'Instantiating sort algorithm <Integer>'}
    {$I gen_algo_sort.inc}
  end;

begin
  Sort(TESTCOUNT, arr);
  Assert(_Check(isArraySortedAcc(arr)), GetName + ':Sort failed');
end;

procedure TTestGenericSort.testSortInd;

  procedure Sort(const Count: Integer; var Data: TIndArray; var Index: array of Integer);
  //  const _SortOptions = [soBadData];
    type _SortDataType = Integer;
    {$MESSAGE 'Instantiating sort algorithm <Integer> indexed'}
    {$I gen_algo_sort.inc}
  end;

begin
  Sort(TESTCOUNT, arr, ind);
  Assert(_Check(isIndArraySortedAcc(arr, OArr, ind)), GetName + ':Sort failed');
end;

procedure TTestGenericSort.testSortStr;
begin
  SortStr(TESTCOUNT, strarr);
  Assert(_Check(isArraySortedStr(strarr)), GetName + ':Sort failed');
end;

procedure TTestGenericSort.testOldSortAcc;
begin
  Basics.QuickSortInt(TESTCOUNT, arr);
  Assert(_Check(isArraySortedAcc(arr)), 'Sort failed');
end;

procedure TTestGenericSort.testOldSortStr;
begin
  Basics.QuickSortStr(TESTCOUNT, strarr);
  Assert(_Check(isArraySortedStr(strarr)), 'Sort failed');
end;

procedure TTestGenericSort.testOldSortDsc;
begin
  Basics.QuickSortIntDsc(TESTCOUNT, arr);
  Assert(_Check(isArraySortedDsc(arr)), 'Sort failed');
end;

procedure TTestGenericSort.testSortDsc;
begin
  SortDsc(TESTCOUNT, arr);
  Assert(_Check(isArraySortedDsc(arr)), GetName + ':Sort failed');
end;

{ TTestCollections }

function TTestCollections.ForCollEl(const e: Integer; Data: Pointer): Boolean;
begin
  Assert(_Check(e = Rnd.RndI(CollElCnt)), 'Value check in for each fail');
  Result := True;
end;

{ TTestHash }

procedure TTestHash.ForPair(const Key: Integer; const Value: String; Data: Pointer);
begin
//  Writeln(Key, ' = ', Value);
  Assert(_Check((Key) = StrToInt(Value)), 'Value check in for each fail');
  //SetLength(TKeyArray(Data^), Length(TKeyArray(Data^))+1);
  //TKeyArray(Data^)[High(TKeyArray(Data^))] := Key;
end;

procedure TTestHash.TestHasmMap;
var
  i, cnt, t: NativeInt;
  Map: TIntStrHashMap;
  Iter: _GenHashMapKeyIterator;
  Keys: TArray<Integer>;
begin
  Map := TIntStrHashMap.Create(1);

  cnt := 0;
  for i := 0 to HashMapElCnt-1 do begin
    t := Random(HashMapElCnt);

    if not Map.ContainsKey(t) then Inc(cnt);

    Map[t] := IntToStr(t);
    Assert(_Check(Map.ContainsKey(t) and Map.ContainsValue(IntToStr(t))));
  end;

  Map.ForEach(ForPair, @Keys);

  Assert(_Check(Map.Count = cnt));

  Iter := Map.GetKeyIterator();

  Log('Iterator count: ' + IntToStr(Map.Count));

  for i := 0 to Map.Count-1 do begin
    Assert(_Check(Iter.HasNext), 'iterator HasNext() failed');
    t := Iter.Next;
    Assert(_Check(Map.ContainsKey(t)), 'iterator value not found');
    Log('Iterator next: ' + IntToStr(t));
  end;

  Assert(_Check(not Iter.HasNext), 'iterator HasNext() false positive');

  Map.Clear;
  Assert(_Check(Map.IsEmpty));

  Map[t] := IntToStr(t);
  Assert(_Check(Map.ContainsKey(t) and Map.ContainsValue(IntToStr(t))));

  Map.Free;
end;

{ TTestVector }

procedure TTestVector.TestVector;
var Coll: TIntVector; i, cnt, t: Integer;
begin
  Coll := TIntVector.Create();
  {$I TestList.inc}
end;

{ TTestLinkedList }

procedure TTestLinkedList.TestLinkedList;
var Coll: TIntLinkedList; i, cnt, t: Integer;
begin
  Coll := TIntLinkedList.Create();
  {$I TestList.inc}
end;

initialization
  Rnd := TRandomGenerator.Create();
  RegisterSuites([TTestGenericSort, TTestCollections, TTestHash, TTestVector, TTestLinkedList]);

finalization
  Rnd.Free();
end.

