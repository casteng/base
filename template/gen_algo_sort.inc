(*
  Generic quicksort algorithm implementation without recursion and constant memory consumption (64 * 2 * SizeOf(Integer) bytes)
  (C) George Bakhtadze
Usage:
--------------------------
  procedure/function <Name>(Count: Integer; Data: <any array of _SortDataType>);
  type
    _SortDataType = <Your type>;
    [_SortValueType = <any comparable with "<" type>]
  [<_SortGetValue() or _SortCompare() function>]
  [$DEFINE _SORTDESCENDING]
  [$DEFINE _SORTBADDATA]
  $I gen_algo_sort.inc}
--------------------------
  define _SORTDESCENDING to perform sort in descending order
  define _SORTBADDATA to use a random index for base element. This can be ~5% slower on usual data but good for quicksort-unfriendly data

  if _SortDataType is a type which can not be compared with "<" operation one of the following functions should be declared:

        function _SortCompare(const V1,V2: _SortDataType): <Some numeric type>;
        begin
          Result := V1 - V2;         // As usual
        end;
  or
        function _SortGetValue(const V: _SortDataType): _SortValueType;
        begin
          Result := <some numeric expression>;
        end;

  if _SortCompare() function is declared the algorithm will call it each time when a comparation of two data values is needed

  if _SortGetValue() function is declared the algorithm will call it each time when a comparable representation of data value is needed
*)

{$IF Declared(_SortCompare)}
  {$IFNDEF _SORTNOCOMPAREFUNC}
    {$DEFINE _SORTCOMPAREFUNC}
  {$ENDIF}
{$ELSE}
  {$UNDEF _SORTCOMPAREFUNC}
{$IFEND}

{$IF Declared(_SortGetValue)}
  {$IFNDEF _SORTNOCOMPUTEFUNC}
    {$DEFINE _SORTCOMPUTEFUNC}
  {$ENDIF}
{$ELSE}
  {$UNDEF _SORTCOMPUTEFUNC}
{$IFEND}

{$IF Declared(_SortOptions)}
  {$I gen_algo_sort_opt.inc}
{$IFEND}

{$IF not Declared(_SORT_INSERTION_THRESHOLD)}
  const _SORT_INSERTION_THRESHOLD = 30;
{$IFEND}

{$DEFINE CodeNav}

const
  {$IFDEF CPU64}
  StackSize = 64;     // Enough for 2^64 sort data size
  {$ELSE}
  StackSize = 32;     // Enough for 2^32 sort data size
  {$ENDIF}


var
  n1, n2, L, R: Integer;
  bv, t: _SortDataType;

  StackPTR: Integer;
  MaxStack: Integer;
  Stack: array[0..StackSize-1] of record
    l, r: Integer;
  end;
  {$IFDEF _SORTBADDATA}
  Seed: Cardinal;
  temp: Integer;
  {$ENDIF}
  {$IFDEF _SORTCOMPUTEFUNC}
    TempValue: _SortValueType;
  {$ENDIF}
  //Ptr, EndPtr: ^_SortDataType;

begin
  {$IFDEF _SORTBADDATA}
  Seed := 1000;
  {$ENDIF}
    MaxStack := 0;
  StackPTR := 0;
  Stack[0].l := 0;
  Stack[0].r := Count-1;
  repeat
    L := Stack[StackPTR].l;
    R := Stack[StackPTR].r;
    Dec(StackPTR);

    // Insertion sort
    if R - L < _SORT_INSERTION_THRESHOLD then begin

      for n1 := L+1 to R do begin
        n2 := n1-1;
        bv := Data[n1];
        while (n2 > L) do begin
          {$IFNDEF _SORTDESCENDING}
            {$IFDEF _SORTCOMPUTEFUNC}
              if not (_SortGetValue(bv) < _SortGetValue(Data[n2])) then Break;
            {$ELSE}
              {$IFDEF _SORTCOMPAREFUNC}
                if not (_SortCompare(bv, Data[n2]) < 0) then Break;
              {$ELSE}
                if not (bv < Data[n2]) then Break;
              {$ENDIF}
            {$ENDIF}
          {$ELSE}
            {$IFDEF _SORTCOMPUTEFUNC}
              if not (_SortGetValue(Data[n2]) < _SortGetValue(bv)) then Break;
            {$ELSE}
              {$IFDEF _SORTCOMPAREFUNC}
                if not (_SortCompare(Data[n2], bv) < 0) then Break;
              {$ELSE}
                if not (Data[n2] < bv) then Break;
              {$ENDIF}
            {$ENDIF}
          {$ENDIF}
          Data[n2+1] := Data[n2];
          Dec(n2);
        end;
        if n1 <> n2 then Data[n2] := bv;
      end;

    end else while (L < R) do begin
      {$IFDEF _SORTBADDATA} {$Q-}
        Seed := 97781173 * Seed + 7;
        temp := R - L - 1;
        temp := temp or temp shr 1;
        temp := temp or temp shr 2;
        temp := temp or temp shr 4;
        temp := temp or temp shr 8;
        temp := temp or temp shr 16;
        {$IFDEF CPU64}
          temp := temp or temp shr 32;
        {$ENDIF}

        bv := Data[Cardinal(L) + Seed and (temp shr 1)];              // Separating element
      {$ELSE}
        bv := Data[(L+R) div 2];                            // Separating element
      {$ENDIF}

      {$IFDEF _SORTCOMPUTEFUNC}
        TempValue := _SortGetValue(bv);
      {$ENDIF}

      n1 := L;
      n2 := R;
      while n1 <= n2 do begin
        {$IFNDEF _SORTDESCENDING}
          {$IFDEF _SORTCOMPUTEFUNC}
            while True do if _SortGetValue(Data[n1]) < TempValue then Inc(n1) else Break;              // While conditions not inlined by some stupid reason
            while True do if TempValue < _SortGetValue(Data[n2]) then Dec(n2) else Break;
          {$ELSE}
            {$IFDEF _SORTCOMPAREFUNC}
              while True do if _SortCompare(Data[n1], bv) < 0 then Inc(n1) else Break;
              while True do if _SortCompare(bv, Data[n2]) < 0 then Dec(n2) else Break;
            {$ELSE}
              while Data[n1] < bv do Inc(n1);
              while bv < Data[n2] do Dec(n2);
//              while True do if Data[n1] < bv then Inc(n1) else Break;
//              while True do if bv < Data[n2] then Dec(n2) else Break;
            {$ENDIF}
          {$ENDIF}
        {$ELSE}
          {$IFDEF _SORTCOMPUTEFUNC}
            while True do if TempValue < _SortGetValue(Data[n1]) then Inc(n1) else Break;
            while True do if _SortGetValue(Data[n2]) < TempValue then Dec(n2) else Break;
          {$ELSE}
            {$IFDEF _SORTCOMPAREFUNC}
              while True do if _SortCompare(bv, Data[n1]) < 0 then Inc(n1) else Break;
              while True do if _SortCompare(Data[n2], bv) < 0 then Dec(n2) else Break;
            {$ELSE}
              while bv < Data[n1] do Inc(n1);
              while Data[n2] < bv do Dec(n2);
//              while True do if bv < Data[n1] then Inc(n1) else Break;
//              while True do if Data[n2] < bv then Dec(n2) else Break;
            {$ENDIF}
          {$ENDIF}
        {$ENDIF}
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
                Inc(StackPTR);
                Stack[StackPTR].l := L;
                Stack[StackPTR].r := n2;
                if StackPTR > MaxStack then MaxStack := StackPTR;
        end;
        L := n1;
      end else begin
        if n1 < R then begin
                Inc(StackPTR);
                Stack[StackPTR].l := n1;
                Stack[StackPTR].r := R;
                if StackPTR > MaxStack then MaxStack := StackPTR;
        end;
        R := n2;
      end;
    end;
  until StackPTR < 0;
  Writeln('New stack: ', MaxStack);

{$UNDEF _SORTCOMPAREFUNC}
{$UNDEF _SORTCOMPUTEFUNC}
{$UNDEF _SORTDESCENDING}
{$UNDEF _SORTBADDATA}
{$UNDEF _SORTNOCOMPAREFUNC}
{$UNDEF _SORTNOCOMPUTEFUNC}
