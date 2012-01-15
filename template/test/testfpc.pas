(*
  Generic collections and algorithms tests
*)
{$Include GDefines.inc}
program testfpc;

uses BaseTypes, Timer, Generic;

const 
  TESTCOUNT = 1024*8*4*256;//*1000*10;
  _SORT_INSERTION_THRESHOLD = 44;

type
  TIndArray = array of Integer;

var
  arr, arr2: TIndArray;
  tmr: TTimer; tm: TTimeMark;

// Initialize array and fill it with random values
procedure ShuffleArray(data: TIndArray); overload;
var i: Integer;
begin
  Randomize;
  for i := 0 to TESTCOUNT-1 do data[i] := Random(TESTCOUNT);
end;

procedure PrepareArray;
begin
  arr := Copy(arr2, 0, Length(arr2));
end;

procedure SetUp;
begin
  if Length(arr2) <> TESTCOUNT then SetLength(arr2, TESTCOUNT);
  ShuffleArray(arr2);
end;

// Check if the array is sorted in ascending order
function isArraySortedAcc(arr: TIndArray): boolean;
var i: Integer;
begin
  i := Length(arr)-2;
  while (i >= 0) and (arr[i] <= arr[i+1]) do Dec(i);
  Result := i < 0;
end;

procedure Sort(const Count: Integer; const Data: TIndArray);
  const _SortOptions2 = [soDescending];
  type _SortDataType = Integer;
  function _SortCompare2(const V1, V2: _SortDataType): Integer; {$I inline.inc}
  begin
    Result := -(V1 - V2);         // As usual
  end;
  {$MESSAGE 'Instantiating sort algorithm <Integer>'}
  {$I gen_algo_sort.inc}
end;

begin
  tmr := TTimer.Create(nil);
  SetUp();
  PrepareArray;
  tmr.GetInterval(tm, True);
  Sort(TESTCOUNT, arr);
  Writeln('Sort: ', tmr.GetInterval(tm, True):3:3);
  if isArraySortedAcc(arr) then writeln('Sort correct') else writeln('Sort failed');
end.