(*
 Quicksort algorithm template
 (C) Mirage (avagames@gmail.com)
Usage:
--------------------------
procedure/function <Name>(N: Integer; Values: TValues - any array of _QSValueType);
.type _QSDataType = <Your type>; [_QSValueType = <any comparable type>]
.[<_QSGetValue or _QSCompare function body>]
.[$DEFINE COMPARABLE | COMPUTABLE]
.[$DEFINE DESCENDING]
.$I basics_quicksort_cmp.inc}
--------------------------
! if DESCENDING defined the sorting will be performed in descending order
! if COMPARABLE defined:
. _QSDataType should be any type which can be compared with "<" operation
! if COMPUTABLE defined the following function should be defined:
.function _QSGetValue(const V: _QSDataType): _QSValueType;
.begin
.  result := <some numeric expression>;
.end;
! not COMPARABLE nor COMPUTABLE defined the following function should be defined:
.function _QSCompare(const V1,V2: _QSDataType): <Some numeric type>;
.begin
.  result := V1-V2;         // As usual
.end;
*)
{$DEFINE ForCodeNavigationWork}
const StackSize = 64*64*16;
var
  i, j, L, R: Integer;
  Temp, Temp2: _QSDataType;
  StackPTR: Integer;
  MaxStack: Integer;
  Stack: array[0..StackSize-1] of record
    l, r: Integer;
  end;

{$IFDEF COMPUTABLE}
  TempValue: _QSValueType;
{$ENDIF}
begin
  if N < 2 then Exit;

  MaxStack := 0;
//  SetLength(Stack, StackSize);
  StackPTR := 0; Stack[0].l := 0; Stack[0].r := N-1;
  repeat
    L := Stack[StackPTR].l;
    R := Stack[StackPTR].r;
    Dec(StackPTR);
    repeat
      i := L; j := R;
      Temp2 := Values[(R+L) div 2];
      {$IFDEF COMPUTABLE}
        TempValue := _QSGetValue(Temp2);
      {$ENDIF}
      repeat
{$IFNDEF DESCENDING}
  {$IFDEF COMPARABLE}
        while Values[i] < Temp2 do Inc(i);
        while Temp2 < Values[j] do Dec(j);
  {$ELSE}
    {$IFDEF COMPUTABLE}
        while _QSGetValue(Values[i]) < TempValue do Inc(i);
        while TempValue < _QSGetValue(Values[j]) do Dec(j);
    {$ELSE}
        while _QSCompare(Values[i], Temp2) < 0 do Inc(i);
        while _QSCompare(Temp2, Values[j]) < 0 do Dec(j);
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  {$IFDEF COMPARABLE}
        while Temp2 < Values[i] do Inc(i);
        while Values[j] < Temp2 do Dec(j);
  {$ELSE}
    {$IFDEF COMPUTABLE}
        while TempValue < _QSGetValue(Values[i]) do Inc(i);
        while _QSGetValue(Values[j]) < TempValue do Dec(j);
    {$ELSE}
        while _QSCompare(Temp2, Values[i]) < 0 do Inc(i);
        while _QSCompare(Values[j], Temp2) < 0 do Dec(j);
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
        if i <= j then begin
          Temp := Values[i];
          Values[i] := Values[j];
          Values[j] := Temp;
          Inc(i); Dec(j);
        end;
      until i > j;
      if i < R then begin
        Inc(StackPTR);
        if StackPTR > MaxStack then MaxStack := StackPTR;
        Stack[StackPTR].l := i;
        Stack[StackPTR].r := R;
      end;
      R := j;
    until L >= R;
  until StackPTR < 0;
//  Stack := nil;
end;

{$UNDEF COMPARABLE}
{$UNDEF COMPUTABLE}
{$UNDEF DESCENDING}
