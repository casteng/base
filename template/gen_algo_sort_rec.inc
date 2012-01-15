(*
 Quicksort generic algorithm
 (C) George Bakhtadze
Usage:
--------------------------
procedure/function <Name>(Count: Integer; Data: <any array of _ValueType>);
.type _DataType = <Your type>; [_ValueType = <any comparable type>]
.[<_SortGetValue or _Compare function body>]
.[$DEFINE COMPARABLE | COMPUTABLE]
.[$DEFINE DESCENDING]
.$I algo_sort.inc}
--------------------------
! if DESCENDING defined the sorting will be performed in descending order
! if COMPARABLE defined:
. _DataType should be any type which can be compared with "<" operation or
! if COMPUTABLE defined the following function should be defined:
.function _QSGetValue(const V: _QSDataType): _QSValueType;
.begin
.  result := <some numeric expression>;
.end;
! not COMPARABLE nor COMPUTABLE defined the following function should be defined:
.function _Compare(const V1,V2: _DataType): <Some numeric type>;
.begin
.  result := V1-V2;         // As usual
.end;
*)
{$DEFINE ForCodeNavigationWork}

var
  StackPTR: Integer;
  MaxStack: Integer;

  procedure QS(L, R: Integer);
  var
    n1, n2: Integer;
    bv, t: _DataType;
  begin
    Inc(StackPTR);
    if StackPTR > MaxStack then MaxStack := StackPTR;
    while (L < R) do begin
      bv := Data[(R + L) div 2];                    // separating element

      n1 := L;
      n2 := R;
      while n1 <= n2 do begin
        while Data[n1] < bv do Inc(n1);
        // { Data[n] < bv n=[si..n1-1] AND Data[n1] >= bv }
        while bv < Data[n2] do Dec(n2);
        // { Data[n] > bv n=[n2+1..fi] AND Data[n2] <= bv }
        if n1 <= n2 then begin
          t := Data[n1];
          Data[n1] := Data[n2];
          Data[n2] := t;
          Inc(n1);
          Dec(n2);
        end;
      end;
      // { Data[si..n1<bi] < Data[bi] AND Data[bi<n2..fi] > Data[bi] }

      if (n2-L) > (R-n1) then begin
        if L < n2 then begin
          Qs(L, n2);
        end;
        L := n1;
      end else begin
        if n1 < R then begin
          Qs(n1, R);
        end;
        R := n2;
      end;
    end;
    Dec(StackPTR);
  end;

begin
  MaxStack := 0;
  StackPTR := 0;
  QS(0, Count-1);
  Writeln('Rec stack: ', MaxStack);
end;

