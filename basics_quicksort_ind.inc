(*
 Quicksort algorithm template (indexed data)
Usage:
--------------------------
.type _QSDataType = <Your type>; [_QSValueType = <any comparable type>]
.[<_QSGetValue or _QSCompare function body>]
.[$DEFINE COMPARABLE | COMPUTABLE]
.$I basics_quicksort_cmp.inc}
--------------------------
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
*)const MinStack = 64;
{$DEFINE ForCodeNavigationWork}
var
  i, j, L, R, Temp: Integer;
  Temp2: _QSDataType;
  StackPTR: Integer;
  StackSize: Integer;
  Stack: array[0..MinStack-1] of record
    l, r: Integer;
  end;
begin
  for i := 0 to N-1 do Inds[i] := i;

  if N < 2 then Exit;

  StackSize := MinStack;
//  SetLength(Stack, StackSize);
  StackPTR := 0; Stack[0].l := 0; Stack[0].r := N-1;
  repeat
    L := Stack[StackPTR].l;
    R := Stack[StackPTR].r;
    Dec(StackPTR);
    repeat
      i := L; j := R;
      Temp2 := Values[Inds[(L + R) shr 1]];
      repeat
        if Acc then begin
          while Temp2 > Values[Inds[i]] do Inc(i);
          while Temp2 < Values[Inds[j]] do Dec(j);
        end else begin
          while Temp2 < Values[Inds[i]] do Inc(i);
          while Temp2 > Values[Inds[j]] do Dec(j);
        end;
        if i <= j then begin
          Temp := Inds[i];
          Inds[i] := Inds[j];
          Inds[j] := Temp;
          Inc(i); Dec(j);
        end;
      until i > j;
      if i < R then begin
        Inc(StackPTR);
        if StackPTR >= StackSize then begin
          Inc(StackSize, MinStack);
//          SetLength(Stack, StackSize);
        end;
        Stack[StackPTR].l := i;
        Stack[StackPTR].r := R;
      end;
      R := j;
    until L >= R;
  until StackPTR < 0;
//  Stack := nil;
end;