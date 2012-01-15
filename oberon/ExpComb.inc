procedure TOberonVM.RunTimeError(ErrorNumber: Integer);
var s: string;
begin
  s := 'Runtime error #' + IntToStr(ErrorNumber)+#13;
  case ErrorNumber of
    rteRangeError: MessageDlg(s+'Range check error', mtError, [mbOK], 0);
    rteStackEmpty: MessageDlg(s+'Stack is empty', mtError, [mbOK], 0);
  end;
end;

function TOberonVM.AddII(Value1, Value2: Integer): Integer;
begin {$Q-} Result := Value1 + Value2; end;

function TOberonVM.AddRR(Value1, Value2: Single): Single;
begin Result := Value1 + Value2; end;

function TOberonVM.AddIR(Value1: Integer; Value2: Single): Single;
begin Result := Value1 + Value2; end;

function TOberonVM.AddRI(Value1: Single; Value2: Integer): Single;
begin Result := Value1 + Value2; end;

function TOberonVM.AddSS(Value1, Value2: Integer): Integer;
begin Result := Value1 or Value2; end;

function TOberonVM.AddStrStr(Value1, Value2: Integer): Integer;
begin
{  Move(Pointer(Int32(Comp.Data)+Value1)^, Len1, 2);
  Move(Pointer(Int32(Comp.Data)+Value2)^, Len2, 2);
  SetLength(Buf, Len1+Len2);
  if Len1 > 0 then Move(Pointer(Int32(Comp.Data)+Item1.Value+2)^, Buf[1], Len1);
  if Len2 > 0 then Move(Pointer(Int32(Comp.Data)+Item2.Value+2)^, Buf[1+Len1], Len2);
  Comp.SetSValue(Result, Buf);}
  Result := -1;
end;

function TOberonVM.SubII(Value1, Value2: Integer): Integer;
begin {$Q-} Result := Value1 - Value2; end;

function TOberonVM.SubRR(Value1, Value2: Single): Single;
begin Result := Value1 - Value2; end;

function TOberonVM.SubIR(Value1: Integer; Value2: Single): Single;
begin Result := Value1 - Value2; end;

function TOberonVM.SubRI(Value1: Single; Value2: Integer): Single;
begin Result := Value1 - Value2; end;

function TOberonVM.SubSS(Value1, Value2: Integer): Integer;
begin Result := Value1 and not Value2; end;

function TOberonVM.MulII(Value1, Value2: Integer): Integer;
begin {$Q-} Result := Value1 * Value2; end;

function TOberonVM.MulRR(Value1, Value2: Single): Single;
begin Result := Value1 * Value2; end;

function TOberonVM.MulIR(Value1: Integer; Value2: Single): Single;
begin Result := Value1 * Value2; end;

function TOberonVM.MulRI(Value1: Single; Value2: Integer): Single;
begin Result := Value1 * Value2; end;

function TOberonVM.MulSS(Value1, Value2: Integer): Integer;
begin Result := Value1 and Value2; end;

function TOberonVM.DivII(Value1, Value2: Integer): Single;
begin Result := Value1 / Value2; end;

function TOberonVM.DivRR(Value1, Value2: Single): Single;
begin Result := Value1 / Value2; end;

function TOberonVM.DivIR(Value1: Integer; Value2: Single): Single;
begin Result := Value1 / Value2; end;

function TOberonVM.DivRI(Value1: Single; Value2: Integer): Single;
begin Result := Value1 / Value2; end;

function TOberonVM.DivSS(Value1, Value2: Integer): Integer;
begin Result := Value1 xor Value2; end;

function TOberonVM.OrII(Value1, Value2: Integer): Integer;
begin Result := Value1 or Value2; end;

function TOberonVM.AndII(Value1, Value2: Integer): Integer;
begin Result := Value1 and Value2; end;

function TOberonVM.IDivII(Value1, Value2: Integer): Integer;
begin Result := Value1 div Value2; end;

function TOberonVM.ModII(Value1, Value2: Integer): Integer;
begin Result := Value1 mod Value2; end;

function TOberonVM.NegI(Value1: Integer): Integer;
begin Result := -Value1; end;

function TOberonVM.NegR(Value1: Single): Single;
begin Result := -Value1; end;

function TOberonVM.NegS(Value1: Integer): Integer;
begin Result := not Value1; end;

function TOberonVM.InvI(Value1: Integer): Integer;
begin Result := not Value1; end;

function TOberonVM.InvB(Value1: Integer): Integer;
begin Result := Integer(not Boolean(Value1)); end;

function TOberonVM.Equal(Value1, Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 = Value2)); end;

function TOberonVM.EqualRI(Value1: Single; Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 = Value2)); end;

function TOberonVM.GreaterII(Value1, Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 > Value2)); end;

function TOberonVM.GreaterIR(Value1: Integer; Value2: Single): Integer;
begin Result := Integer(Boolean(Value1 > Value2)); end;

function TOberonVM.GreaterRI(Value1: Single; Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 > Value2)); end;

function TOberonVM.GreaterRR(Value1, Value2: Single): Integer;
begin Result := Integer(Boolean(Value1 > Value2)); end;

function TOberonVM.LessII(Value1, Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 < Value2)); end;

function TOberonVM.LessIR(Value1: Integer; Value2: Single): Integer;
begin Result := Integer(Boolean(Value1 < Value2)); end;

function TOberonVM.LessRI(Value1: Single; Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 < Value2)); end;

function TOberonVM.LessRR(Value1, Value2: Single): Integer;
begin Result := Integer(Boolean(Value1 < Value2)); end;

function TOberonVM.GreaterEqualII(Value1, Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 >= Value2)); end;

function TOberonVM.GreaterEqualIR(Value1: Integer; Value2: Single): Integer;
begin Result := Integer(Boolean(Value1 >= Value2)); end;

function TOberonVM.GreaterEqualRI(Value1: Single; Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 >= Value2)); end;

function TOberonVM.GreaterEqualRR(Value1, Value2: Single): Integer;
begin Result := Integer(Boolean(Value1 >= Value2)); end;

function TOberonVM.LessEqualII(Value1, Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 <= Value2)); end;

function TOberonVM.LessEqualIR(Value1: Integer; Value2: Single): Integer;
begin Result := Integer(Boolean(Value1 <= Value2)); end;

function TOberonVM.LessEqualRI(Value1: Single; Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 <= Value2)); end;

function TOberonVM.LessEqualRR(Value1, Value2: Single): Integer;
begin Result := Integer(Boolean(Value1 <= Value2)); end;

function TOberonVM.NotEqual(Value1, Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 <> Value2)); end;

function TOberonVM.NotEqualRI(Value1: Single; Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 <> Value2)); end;

function TOberonVM.GreaterEqual(Value1, Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 >= Value2)); end;

function TOberonVM.LessEqual(Value1, Value2: Integer): Integer;
begin Result := Integer(Boolean(Value1 <= Value2)); end;

function TOberonVM.TestIn(Value1, Value2: Integer): Integer;
begin Result := Integer((El2Set[Value1] and Value2) > 0); end;

procedure TOberonVM.DoAssign4(Value1, Value2: Integer);
begin
  {dtBoolean = 0; dtChar = 1;
  dtInt8 = 2; dtInt16 = 3; dtInt32 = 4; dtInt = 5;
  dtNat8 = 6; dtNat16 = 7; dtNat32 = 8; dtNat = 9;
  dtSingle = 10; dtReal = 11; dtDouble = 12;
  dtString = 13;
  dtSet = 14;
  dtArray = 16;
  dtRecord = 17;
  dtPointer = 18;
  dtProcedure = 19;}
{  case Data.Variables[Value1].VType of
    dtBoolean, dtChar, dtInt8, dtNat8: elSize := 1;
    dtInt16, dtNat16: elSize := 2;
    dtInt32, dtInt, dtNat32, dtNat, dtSingle, dtReal, dtSet, dtPointer, dtProcedure: elSize := 4;
    dtDouble: elSize := 8;
    dtString:;
  end;
  case elSize of
    1: TByteArray(Data.Data)[Data.Variables[Value1].Index] := Value2;
    2: Word((@TByteArray(Data.Data)[Data.Variables[Value1].Index])^) := Value2;
    4: Int32((@TByteArray(Data.Data)[Data.Variables[Value1].Index])^) := Value2;
    else Int32((@TByteArray(Data.Data)[Data.Variables[Value1].Index])^) := Value2;
  end;}
  Int32((@Data.Data[Value1])^) := Value2;
end;

procedure TOberonVM.DoExtAssign4(Value1, Value2: Integer);
begin
  Int32((@Data.BaseData[Value1])^) := Value2;
end;

procedure TOberonVM.DoStackAssign4(Value1, Value2: Integer);
begin
  Stack[StackBase+Value1] := Value2;
end;

procedure TOberonVM.DoGoto(var IP: Integer);
begin
  IP := Data.PIN[IP+1];
end;

procedure TOberonVM.DoZeroJump(Value1: Integer; var IP: Integer);
begin
  Inc(IP);
  if Value1 = 0 then IP := Data.PIN[IP];
end;

procedure TOberonVM.DoCall(const Dest: Integer; var IP: Integer);
begin
  Push(IP);
  IP := Dest;
end;

procedure TOberonVM.DoReturn(var IP: Integer);
var Temp: Integer;
begin
  Inc(IP);
  Temp := Data.PIN[IP];
  Dec(TotalStack, Data.PIN[IP+1]-Temp);             // Pop all local variables
  StackBase := Pop;                                 // Pop old stack base
  IP := Pop;                                        // Pop return address
  Dec(TotalStack, Temp);                            // Pop parameters
end;

procedure TOberonVM.DoExit(const Dest: Integer; var IP: Integer);
begin
  IP := Dest;
end;

function TOberonVM.ConstructSet(const TotalElements: Integer): Integer;
var i: Integer; El: Longword;
begin
  Result := 0;
  if TotalElements = -1 then Result := Pop else for i := 0 to TotalElements-1 do begin
    El := Pop;
    if El > MaxSet then RunTimeError(rteRangeError) else Result := Result or Integer(El2Set[El]);
  end;
end;
