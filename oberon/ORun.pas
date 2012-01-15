(*
 Oberon virtual machine unit
 (C) 2004-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 The unit contains VM class
*)
{$DEFINE DEBUG}
unit ORun;

interface

uses
  SysUtils,
{$IFDEF DEBUG} Dialogs, Classes, {$ENDIF}
  OTypes, OScan, OBasics;

{$IFDEF DEBUG} var Debug: string; DItems: TStringList; {$ENDIF}

type
  TBinModuleSign = array[0..3] of Char;

  TStackItem = Integer;

  TOberonVM = class
    Data: TRTData;
    TotalStack, StackCapacity, StackCapacityStep, StackBase: Integer;
    Stack: array of TStackItem;                                  // Stack
//    Comp: TCompiler;
// Implementation specific
    MaxSet: Integer;
    El2Set: array of Longword;                                   // For set optimisation
    constructor Create;
    destructor Destroy; override;
{$IFDEF DEBUG}
    function ItemToStr(Index: Integer): string;   // Converts PIN item to string in debug purposes
    function GetVar(const Location, Offset, Index: Integer): Integer;
{$ENDIF}
    function Save(const Stream: TDStream): Integer;
    function Load(const Stream: TDStream): Integer;
    function SetExtVarAddr(const VarIndex: Integer; const Addr: Pointer): Boolean;
    procedure Run;
    function Compute: TStackItem;
  private
    procedure ExpandStack(const Amount: Integer);
    procedure Push(Item: TStackItem);
    procedure PushS(Item: Single);
    function Pop: TStackItem;
    function PopS: Single;
    procedure RunTimeError(ErrorNumber: Integer);

    function AddII(Value1, Value2: Integer): Integer;
    function AddRR(Value1, Value2: Single): Single;
    function AddIR(Value1: Integer; Value2: Single): Single;
    function AddRI(Value1: Single; Value2: Integer): Single;
    function AddSS(Value1, Value2: Integer): Integer;
    function AddStrStr(Value1, Value2: Integer): Integer;
    function SubII(Value1, Value2: Integer): Integer;
    function SubRR(Value1, Value2: Single): Single;
    function SubIR(Value1: Integer; Value2: Single): Single;
    function SubRI(Value1: Single; Value2: Integer): Single;
    function SubSS(Value1, Value2: Integer): Integer;
    function MulII(Value1, Value2: Integer): Integer;
    function MulRR(Value1, Value2: Single): Single;
    function MulIR(Value1: Integer; Value2: Single): Single;
    function MulRI(Value1: Single; Value2: Integer): Single;
    function MulSS(Value1, Value2: Integer): Integer;
    function DivII(Value1, Value2: Integer): Single;
    function DivRR(Value1, Value2: Single): Single;
    function DivIR(Value1: Integer; Value2: Single): Single;
    function DivRI(Value1: Single; Value2: Integer): Single;
    function DivSS(Value1, Value2: Integer): Integer;
    function OrII(Value1, Value2: Integer): Integer;
    function AndII(Value1, Value2: Integer): Integer;
    function IDivII(Value1, Value2: Integer): Integer;
    function ModII(Value1, Value2: Integer): Integer;
    function NegI(Value1: Integer): Integer;
    function NegR(Value1: Single): Single;
    function NegS(Value1: Integer): Integer;
    function InvI(Value1: Integer): Integer;
    function InvB(Value1: Integer): Integer;
    function Equal(Value1, Value2: Integer): Integer;
    function EqualRI(Value1: Single; Value2: Integer): Integer;
    function GreaterII(Value1, Value2: Integer): Integer;
    function GreaterIR(Value1: Integer; Value2: Single): Integer;
    function GreaterRI(Value1: Single; Value2: Integer): Integer;
    function GreaterRR(Value1, Value2: Single): Integer;
    function LessII(Value1, Value2: Integer): Integer;
    function LessIR(Value1: Integer; Value2: Single): Integer;
    function LessRI(Value1: Single; Value2: Integer): Integer;
    function LessRR(Value1, Value2: Single): Integer;
    function GreaterEqualII(Value1, Value2: Integer): Integer;
    function GreaterEqualIR(Value1: Integer; Value2: Single): Integer;
    function GreaterEqualRI(Value1: Single; Value2: Integer): Integer;
    function GreaterEqualRR(Value1, Value2: Single): Integer;
    function LessEqualII(Value1, Value2: Integer): Integer;
    function LessEqualIR(Value1: Integer; Value2: Single): Integer;
    function LessEqualRI(Value1: Single; Value2: Integer): Integer;
    function LessEqualRR(Value1, Value2: Single): Integer;
    function NotEqual(Value1, Value2: Integer): Integer;
    function NotEqualRI(Value1: Single; Value2: Integer): Integer;
    function GreaterEqual(Value1, Value2: Integer): Integer;
    function LessEqual(Value1, Value2: Integer): Integer;
    function TestIn(Value1, Value2: Integer): Integer;
    procedure DoAssign4(Value1, Value2: Integer);
    procedure DoStackAssign4(Value1, Value2: Integer);
    procedure DoGoto(var IP: Integer);
    procedure DoZeroJump(Value1: Integer; var IP: Integer);
    procedure DoCall(const Dest: Integer; var IP: Integer);
    procedure DoReturn(var IP: Integer);
    procedure DoExit(const Dest: Integer; var IP: Integer);
    function ConstructSet(const TotalElements: Integer): Integer;
// For scripting support
    procedure DoExtAssign4(Value1, Value2: Integer);
  end;

const
 BinModuleSign: TBinModuleSign = ('O', '2', 'B', 'M');

implementation

{$IFDEF DEBUG}
function TOberonVM.ItemToStr(Index: Integer): string;
var j: Integer; Len: Nat16; First: Boolean;

  function GetVarName(NS: PNamespace; Ofs: Integer): string;
  var i, ind, Bound: Integer;
  begin
    Result := 'Unknown';
    for i := 0 to NS.TotalVariables-1 do begin
      Bound := Data.Variables[NS.Variables[i]].Index + Data.Types[Data.Variables[NS.Variables[i]].TypeID].Size;
      if Bound > Ofs then begin
        ind := i;
  {    if Data.Variables[NS.Variables[i]].Index >= Ofs then begin
        if (Data.Variables[NS.Variables[i]].Index > Ofs) then begin
          ind := i-1;
          if ind < 0 then Exit;
        end else ind := i;}
        if Data.Types[Data.Variables[NS.Variables[ind]].TypeID].Kind = tkRecord then
         Result := Data.Variables[NS.Variables[ind]].Name+'.'+GetVarName(Data.Types[Data.Variables[NS.Variables[ind]].TypeID].Namespace,
                              Ofs-Data.Variables[NS.Variables[ind]].Index) else
          Result := Data.Variables[NS.Variables[ind]].Name;
        Exit;
      end;
    end;
  {  ind := NS.TotalVariables-1;
    Result := Data.Variables[NS.Variables[ind]].Name+'.'+GetVarName(Data.Types[Data.Variables[NS.Variables[ind]].TypeID].Namespace,
                              Ofs-Data.Variables[NS.Variables[ind]].Index);}
  end;

  function GetGlobalVarName(Ofs: Integer): string;
  begin
    Result := GetVarName(Data.Namespace, Ofs);
  end;

begin
//  Result := '';
  case Data.PIN[Index] and $FFFF of
    dtBoolean: if Boolean((@Data.PIN[Index+1])^) then Result := 'True' else Result := 'False';
    dtChar: Result := Char((@Data.PIN[Index+1])^);
    dtInt8, dtInt16, dtInt32, dtInt, dtNat8, dtNat16, dtNat32, dtNat: Result := IntToStr(Data.PIN[Index+1])+',';
    dtSingle, dtDouble, dtReal: Result := FloatToStr(Single((@Data.PIN[Index+1])^));
    dtString: begin
      Move(Pointer(Int32(Data.Data)+Data.PIN[Index+1])^, Len, 2);
      SetLength(Result, Len);
      if Len > 0 then Move(Pointer(Int32(Data.Data)+Data.PIN[Index+1]+2)^, Result[1], Len);
    end;
    dtSet: Result := 'SET of ' + IntToStr(Longword(Data.PIN[Index] shr 16)) + ' elements';
    aoNull: Result := ' Null ';
    aoAddII: Result := ' +(ii) ';
    aoAddIR: Result := ' +(ir) ';
    aoAddRI: Result := ' +(ri) ';
    aoAddRR: Result := ' +(rr) ';
    aoAddSS: Result := ' +(ss) ';
    aoSubII: Result := ' -(ii) ';
    aoSubIR: Result := ' -(ir) ';
    aoSubRI: Result := ' -(ri) ';
    aoSubRR: Result := ' -(rr) ';
    aoSubSS: Result := ' -(ss) ';
    aoMulII: Result := ' *(ii) ';
    aoMulIR: Result := ' *(ir) ';
    aoMulRI: Result := ' *(ri) ';
    aoMulRR: Result := ' *(rr) ';
    aoMulSS: Result := ' *(ss) ';
    aoDivII: Result := ' /(ii) ';
    aoDivIR: Result := ' /(ir) ';
    aoDivRI: Result := ' /(ri) ';
    aoDivRR: Result := ' /(rr) ';
    aoDivSS: Result := ' /(ss) ';
    aoOrII: Result := ' OR(ii) ';
    aoOrBB: Result := ' OR(bb) ';
    aoAndII: Result := ' &(ii) ';
    aoAndBB: Result := ' &(bb) ';
    aoIDivII: Result := ' DIV(ii) ';
    aoModII: Result := ' MOD(ii) ';
    aoNegI: Result := ' Neg(i) ';
    aoNegR: Result := ' Neg(r) ';
    aoNegS: Result := ' Neg(s) ';
    aoInvI: Result := ' ~(i) ';
    aoInvB: Result := ' ~(b) ';
    arEqualII: Result := ' =(ii) ';
    arEqualIR: Result := ' =(ir) ';
    arEqualRI: Result := ' =(ri) ';
    arEqualRR: Result := ' =(rr) ';
    arGreaterII: Result := ' >(ii) ';
    arGreaterIR: Result := ' >(ir) ';
    arGreaterRI: Result := ' >(ri) ';
    arGreaterRR: Result := ' >(rr) ';
    arLessII: Result := ' <(ii) ';
    arLessIR: Result := ' <(ir) ';
    arLessRI: Result := ' <(ri) ';
    arLessRR: Result := ' <(rr) ';
    arGreaterEqualII: Result := ' >=(ii) ';
    arGreaterEqualIR: Result := ' >=(ir) ';
    arGreaterEqualRI: Result := ' >=(ri) ';
    arGreaterEqualRR: Result := ' >=(rr) ';
    arLessEqualII: Result := ' <=(ii) ';
    arLessEqualIR: Result := ' <=(ir) ';
    arLessEqualRI: Result := ' <=(ri) ';
    arLessEqualRR: Result := ' <=(rr) ';
    arNotEqualII: Result := ' #(ii) ';
    arNotEqualIR: Result := ' #(ir) ';
    arNotEqualRI: Result := ' #(ri) ';
    arNotEqualRR: Result := ' #(rr) ';
    aoAssign1: Result := ' :=[1b] ';
    aoAssign2: Result := ' :=[2b] ';
    aoAssign4: Result := ' :=[4b] ';
    aoAssign4RI: Result := ' :=[r4b] ';
    aoAssignSize: Result := ' :=[?b] ';
    aoStackAssign4: Result := ' [s]:= ';
    aoStackAssign4RI: Result := ' [s]:=[r] ';
    aoStackAssignSize: Result := ' [s]:=[?b] ';
    aoGoto: Result := ' Goto ';
    aoJumpIfZero: Result := ' JumpIfZero ';
    aoCall: Result := ' Call ';
    aoReturnF: Result := ' Function return ';
    aoReturnP: Result := ' Procedure return ';
    dtVariable, dtVariableRef: Result := GetGlobalVarName(Data.PIN[Index+1]) + ' [' + IntToStr(Data.PIN[Index+1]) + ']';
    dtVariableByOfs: Result := 'ARR: '+GetGlobalVarName(Data.PIN[Index+1]) + ' [' + IntToStr(Data.PIN[Index+1]) + ']';
    dtStackVariable: Result := 'Local variable';//Data.Variables[Data.PIN[Index+1]].Name+'[s],';
    dtStackVariableByOfs: Result := 'Local array';//Data.Variables[Data.PIN[Index+1]].Name+'[s],';
    aoSetStackBase: Result := 'Set stack base (- ' + IntToStr(Data.PIN[Index+1])+' parameters)';
    aoExpandStack: Result := 'Expand stack by ' + IntToStr(Data.PIN[Index+1]);
  end;
end;

function TOberonVM.GetVar(const Location, Offset, Index: Integer): Integer;
begin
  case Data.Types[Data.Variables[Index].TypeID].Size of
    1: Result := Data.BaseData[Data.Variables[Index].Index+Offset + Integer(Data.Data)];
    2: Result := Word((@Data.BaseData[Data.Variables[Index].Index+Offset + Integer(Data.Data)])^);
    4: case Location of
      ilGlobal: Result := Int32((@Data.BaseData[Data.Variables[Index].Index+Offset + Integer(Data.Data)])^);
      ilExternal: Result := Int32((@Data.BaseData[Data.Variables[Index].Index+Offset])^);
    end;
  end;
end;
{$ENDIF}

procedure TOberonVM.ExpandStack(const Amount: Integer);
begin
  Inc(TotalStack, Amount);
  if TotalStack > StackCapacity then begin
    Inc(StackCapacity, StackCapacityStep); SetLength(Stack, StackCapacity);
  end;
end;

procedure TOberonVM.Push(Item: TStackItem);
begin
  ExpandStack(1);
  Stack[TotalStack-1] := Item;
end;

procedure TOberonVM.PushS(Item: Single);
begin
  ExpandStack(1);
  Stack[TotalStack-1] := TStackItem((@Item)^);
end;

function TOberonVM.Pop: TStackItem;
begin
  if TotalStack = 0 then begin
    RunTimeError(rteStackEmpty); Exit; 
  end;
  Result := Stack[TotalStack-1];
  Dec(TotalStack);
end;

function TOberonVM.PopS: Single;
begin
  if TotalStack = 0 then Exit;
  Result := Single((@Stack[TotalStack-1])^);
  Dec(TotalStack);
end;

function TOberonVM.Save(const Stream: TDStream): Integer;
const InvalidUID: Integer = -1;

  function SaveNamespace(NS: PNamespace): Integer;
  var i: Integer;
  begin
    Result :=  feCannotWrite;
    if Stream.Write(NS.Name, SizeOf(NS.Name)) <> feOK then Exit;
    if Stream.Write(NS.UID, SizeOf(NS.UID)) <> feOK then Exit;
    if Stream.Write(NS.Kind, SizeOf(NS.Kind)) <> feOK then Exit;
    if Stream.Write(NS.ParamCount, SizeOf(NS.ParamCount)) <> feOK then Exit;
    if Stream.Write(NS.ID, SizeOf(NS.ID)) <> feOK then Exit;
    if Stream.Write(NS.StackLength, SizeOf(NS.StackLength)) <> feOK then Exit;
    if Stream.Write(NS.TotalConstants, SizeOf(NS.TotalConstants)) <> feOK then Exit;
    if NS.TotalConstants > 0 then if Stream.Write(NS.Constants[0], SizeOf(Longword)*NS.TotalConstants) <> feOK then Exit;
    if Stream.Write(NS.TotalVariables, SizeOf(NS.TotalVariables)) <> feOK then Exit;
    if NS.TotalVariables > 0 then if Stream.Write(NS.Variables[0], SizeOf(Longword)*NS.TotalVariables) <> feOK then Exit;
    if Stream.Write(NS.TotalTypes, SizeOf(NS.TotalTypes)) <> feOK then Exit;
    if NS.TotalTypes > 0 then if Stream.Write(NS.Types[0], SizeOf(Longword)*NS.TotalTypes) <> feOK then Exit;
    if Stream.Write(NS.TotalProcedures, SizeOf(NS.TotalProcedures)) <> feOK then Exit;
    for i := 0 to NS.TotalProcedures-1 do if SaveNamespace(NS.Procedures[i]) <> feOK then Exit;
    if NS.Parent <> nil then begin
      if Stream.Write(NS.Parent.ID, SizeOf(NS.Parent.ID)) <> feOK then Exit;
    end else begin
      if Stream.Write(InvalidUID, SizeOf(InvalidUID)) <> feOK then Exit;
    end;
    Result := feOK;
  end;

var i, Ind: Integer;
begin
  Result := feCannotWrite;
  if Stream.Write(BinModuleSign, SizeOf(TBinModuleSign)) <> feOK then Exit;
  if Stream.Write(Data.EntryPIN, SizeOf(Data.EntryPIN)) <> feOK then Exit;
  if Stream.Write(Data.PINItems, SizeOf(Data.PINItems)) <> feOK then Exit;
  if Stream.Write(Data.PIN[0], SizeOf(TPINItem)*Data.PINItems) <> feOK then Exit;
  if Stream.Write(Data.TotalExternalVariables, SizeOf(Data.TotalExternalVariables)) <> feOK then Exit;
  if Stream.Write(Data.ExternalVarsOfs, SizeOf(Data.ExternalVarsOfs)) <> feOK then Exit;

  if SaveNamespace(Data.Namespace) <> feOK then Exit;

  if Stream.Write(Data.BaseData, SizeOf(Data.BaseData)) <> feOK then Exit;
  if Stream.Write(Data.DataLength, SizeOf(Data.DataLength)) <> feOK then Exit;
  if Data.DataLength > 0 then
   if Stream.Write(Data.Data[0], Data.DataLength * SizeOf(Data.Data[0])) <> feOK then Exit;

  if Stream.Write(Data.TotalTypes, SizeOf(Data.TotalTypes)) <> feOK then Exit;
  for i := 0 to Data.TotalTypes-1 do begin
    if Stream.Write(Data.Types[i]^, SizeOf(Data.Types[i]^)-SizeOf(Data.Types[i].Namespace)) <> feOK then Exit;
    if Data.Types[i].Namespace <> nil then begin
      if Stream.Write(Data.Types[i].Namespace.UID, SizeOf(Data.Types[i].Namespace.UID)) <> feOK then Exit;
      if SaveNamespace(Data.Types[i].Namespace) <> feOK then Exit;
    end else begin
      if Stream.Write(InvalidUID, SizeOf(InvalidUID)) <> feOK then Exit;
    end;
  end;

  if Stream.Write(Data.TotalProcedures, SizeOf(Data.TotalProcedures)) <> feOK then Exit;
  for i := 0 to Data.TotalProcedures-1 do begin
    if Stream.Write(Data.Procedures[i], SizeOf(Data.Procedures[i])-SizeOf(Data.Procedures[i].Namespace)) <> feOK then Exit;
    if Stream.Write(Data.Procedures[i].Namespace.UID, SizeOf(Data.Procedures[i].Namespace.UID)) <> feOK then Exit;
  end;

  if Stream.Write(Data.TotalVariables, SizeOf(Data.TotalVariables)) <> feOK then Exit;
  for i := 0 to Data.TotalVariables-1 do begin
    if Stream.Write(Data.Variables[i], SizeOf(Data.Variables[i])-SizeOf(Data.Variables[i].Namespace){-SizeOf(Data.Variables[i].Index)}) <> feOK then Exit;
{    if (Data.Variables[i].Location = ilGlobal) and (Data.Variables[i].Namespace.Parent = nil) then
     Ind := Data.Variables[i].Index - Integer(Data.Data) else
      Ind := Data.Variables[i].Index;
    if Stream.Write(Ind, SizeOf(Ind)) <> feOK then Exit;}
    if Stream.Write(Data.Variables[i].Namespace.UID, SizeOf(Data.Variables[i].Namespace.UID)) <> feOK then Exit;
  end;

  if Stream.Write(Data.TotalConstants, SizeOf(Data.TotalConstants)) <> feOK then Exit;
  for i := 0 to Data.TotalConstants-1 do begin
    if Stream.Write(Data.Constants[i], SizeOf(Data.Constants[i])-SizeOf(Data.Constants[i].Namespace){-SizeOf(Data.Constants[i].Index)}) <> feOK then Exit;
//    Ind := Data.Constants[i].Index - Integer(Data.Data);
//    if Stream.Write(Ind, SizeOf(Ind)) <> feOK then Exit;
    if Stream.Write(Data.Constants[i].Namespace.UID, SizeOf(Data.Constants[i].Namespace.UID)) <> feOK then Exit;
  end;

  Result := feOK;
end;

function TOberonVM.Load(const Stream: TDStream): Integer;

function GetNamespace(ID: Integer): PNamespace;

function SearchID(FirstNS: PNamespace; ID: Integer): PNamespace;
var i: Integer;
begin
  Result := nil;
  if (ID < 0) or (FirstNS = nil) then Exit;
  if FirstNS.UID = ID then begin
    Result := FirstNS; Exit;
  end;
  for i := 0 to FirstNS.TotalProcedures-1 do begin
    Result := SearchID(FirstNS.Procedures[i], ID);
    if Result <> nil then Exit;
  end;
end;

var i: Integer;
begin
  for i := 0 to Data.TotalTypes-1 do begin
    Result := SearchID(Data.Types[i].Namespace, ID);
    if Result <> nil then Exit;
  end;
  Result := SearchID(Data.Namespace, ID);
end;

function LoadNamespace(var NS: PNamespace): Integer;
var i, ID: Integer;
begin
  Result :=  feCannotRead;
{  UID: Integer;
  Name: TName;
  Kind: Int32;                     // Procedure or record
  ParamCount: Int32;
  ID: Int32;                       // Index in Data.Procedures
  StackLength: Int32;              // Length of variables declared local and in child namespaces
  TotalConstants, TotalVariables, TotalProcedures, TotalTypes: Int32;
  Constants, Variables, Types: array of Longword;
  Procedures: array of PNameSpace;
  Parent: PNamespace;}
  New(NS);
  if Stream.Read(NS.Name, SizeOf(NS.Name)) <> feOK then Exit;
  if Stream.Read(NS.UID, SizeOf(NS.UID)) <> feOK then Exit;
  if Stream.Read(NS.Kind, SizeOf(NS.Kind)) <> feOK then Exit;
  if Stream.Read(NS.ParamCount, SizeOf(NS.ParamCount)) <> feOK then Exit;
  if Stream.Read(NS.ID, SizeOf(NS.ID)) <> feOK then Exit;
  if Stream.Read(NS.StackLength, SizeOf(NS.StackLength)) <> feOK then Exit;

  if Stream.Read(NS.TotalConstants, SizeOf(NS.TotalConstants)) <> feOK then Exit;
  SetLength(NS.Constants, NS.TotalConstants);
  if NS.TotalConstants > 0 then
   if Stream.Read(NS.Constants[0], SizeOf(Longword)*NS.TotalConstants) <> feOK then Exit;

  if Stream.Read(NS.TotalVariables, SizeOf(NS.TotalVariables)) <> feOK then Exit;
  SetLength(NS.Variables, NS.TotalVariables);
  if NS.TotalVariables > 0 then
   if Stream.Read(NS.Variables[0], SizeOf(Longword)*NS.TotalVariables) <> feOK then Exit;

  if Stream.Read(NS.TotalTypes, SizeOf(NS.TotalTypes)) <> feOK then Exit;
  SetLength(NS.Types, NS.TotalTypes);
  if NS.TotalTypes > 0 then
   if Stream.Read(NS.Types[0], SizeOf(Longword)*NS.TotalTypes) <> feOK then Exit;

  if Stream.Read(NS.TotalProcedures, SizeOf(NS.TotalProcedures)) <> feOK then Exit;
  SetLength(NS.Procedures, NS.TotalProcedures);
  for i := 0 to NS.TotalProcedures-1 do NS.Procedures[i] := nil;
  for i := 0 to NS.TotalProcedures-1 do if LoadNamespace(NS.Procedures[i]) <> feOK then Exit;
  if Stream.Read(ID, SizeOf(ID)) <> feOK then Exit;
  NS.Parent := GetNamespace(ID);
  Result := feOK;
end;

var i, ID, Ind: Integer; Sign: TBinModuleSign;
begin
  Result := feCannotRead;

{$IFDEF DEBUG}
  DItems.Clear;
{$ENDIF}
  StackCapacity := 256; SetLength(Stack, StackCapacity);

  if Stream.Read(Sign, SizeOf(TBinModuleSign)) <> feOK then Exit;
  if Sign <> BinModuleSign then begin
    Result := feInvalidFileFormat; Exit;
  end;

  if Stream.Read(Data.EntryPIN, SizeOf(Data.EntryPIN)) <> feOK then Exit;
  if Stream.Read(Data.PINItems, SizeOf(Data.PINItems)) <> feOK then Exit;
  SetLength(Data.PIN, Data.PINItems);
  if Data.PINItems > 0 then
   if Stream.Read(Data.PIN[0], SizeOf(TPINItem)*Data.PINItems) <> feOK then Exit;
  if Stream.Read(Data.TotalExternalVariables, SizeOf(Data.TotalExternalVariables)) <> feOK then Exit;
  if Stream.Read(Data.ExternalVarsOfs, SizeOf(Data.ExternalVarsOfs)) <> feOK then Exit;

  if LoadNamespace(Data.Namespace) <> feOK then Exit;

  if Stream.Read(Data.BaseData, SizeOf(Data.BaseData)) <> feOK then Exit;

  if Stream.Read(Data.DataLength, SizeOf(Data.DataLength)) <> feOK then Exit;
  SetLength(Data.Data, Data.DataLength);
  if Data.DataLength > 0 then
   if Stream.Read(Data.Data[0], Data.DataLength * SizeOf(Data.Data[0])) <> feOK then Exit;

  if Stream.Read(Data.TotalTypes, SizeOf(Data.TotalTypes)) <> feOK then Exit;
  SetLength(Data.Types, Data.TotalTypes);
  for i := 0 to Data.TotalTypes-1 do begin
    New(Data.Types[i]);
    Data.Types[i].Namespace := nil;
  end;
  for i := 0 to Data.TotalTypes-1 do begin
    if Stream.Read(Data.Types[i]^, SizeOf(Data.Types[i]^)-SizeOf(Data.Types[i].Namespace)) <> feOK then Exit;
    if Stream.Read(ID, SizeOf(ID)) <> feOK then Exit;
    if ID <> -1 then LoadNamespace(Data.Types[i].Namespace);
  end;

  if Stream.Read(Data.TotalProcedures, SizeOf(Data.TotalProcedures)) <> feOK then Exit;
  SetLength(Data.Procedures, Data.TotalProcedures);
  for i := 0 to Data.TotalProcedures-1 do begin
    if Stream.Read(Data.Procedures[i], SizeOf(Data.Procedures[i])-SizeOf(Data.Procedures[i].Namespace)) <> feOK then Exit;
    if Stream.Read(ID, SizeOf(ID)) <> feOK then Exit;
    Data.Procedures[i].Namespace := GetNamespace(ID);
  end;

  if Stream.Read(Data.TotalVariables, SizeOf(Data.TotalVariables)) <> feOK then Exit;
  SetLength(Data.Variables, Data.TotalVariables);
  for i := 0 to Data.TotalVariables-1 do begin
    if Stream.Read(Data.Variables[i], SizeOf(Data.Variables[i])-SizeOf(Data.Variables[i].Namespace){-SizeOf(Data.Variables[i].Index)}) <> feOK then Exit;
//    if Stream.Read(Ind, SizeOf(Ind)) <> feOK then Exit;
//    Data.Variables[i].Index := Ind;
    if Stream.Read(ID, SizeOf(ID)) <> feOK then Exit;
    Data.Variables[i].Namespace := GetNamespace(ID);
  end;

  if Stream.Read(Data.TotalConstants, SizeOf(Data.TotalConstants)) <> feOK then Exit;
  SetLength(Data.Constants, Data.TotalConstants);
  for i := 0 to Data.TotalConstants-1 do begin
    if Stream.Read(Data.Constants[i], SizeOf(Data.Constants[i])-SizeOf(Data.Constants[i].Namespace)) <> feOK then Exit;
//    if Stream.Read(Ind, SizeOf(Ind)) <> feOK then Exit;
//    Data.Constants[i].Index := Ind + Integer(Data.Data);
    if Stream.Read(ID, SizeOf(ID)) <> feOK then Exit;
    Data.Constants[i].Namespace := GetNamespace(ID);
  end;

  Result := feOK;
end;

function TOberonVM.SetExtVarAddr(const VarIndex: Integer; const Addr: Pointer): Boolean;
begin
  Result := False;
  if (VarIndex < 0) or (VarIndex >= Data.TotalExternalVariables) then Exit;
  Data.Variables[Data.ExternalVarsOfs + VarIndex].Index := Integer(Addr);
  Result := True;
end;

{$I ExpComb.inc}

procedure TOberonVM.Run;
var IP, i1, i2: Integer; r1, r2: Single;
begin
  StackBase := 0; TotalStack := 0;
  IP := Data.EntryPIN;
  while IP < Data.PINItems do begin
    case Data.PIN[IP] and $FF of
      dtBoolean..dtString, dtVariableRef: begin Inc(IP); Push(Data.PIN[IP]); end;
      dtSet: Push(ConstructSet(Data.PIN[IP] shr 16));
      dtVariable: begin
        Inc(IP); Push(TStackItem((@Data.BaseData[Integer(Data.Data) + Data.PIN[IP]])^));
      end;
      dtVariableByOfs: begin
        Push(TStackItem((@Data.BaseData[Integer(Data.Data) + Pop])^));
      end;
      dtStackVariable: begin
        Inc(IP); Push(TStackItem((@Stack[StackBase+Data.PIN[IP]])^));
      end;
      dtStackVariableByOfs: begin
        Push(TStackItem((@Stack[StackBase+Pop])^));
      end;
      dtExtVariable: begin
        Inc(IP); Push(TStackItem( (@Data.BaseData[Data.PIN[IP]])^));
//        Inc(IP); Push(TStackItem( (@Data.BaseData[Data.Variables[Data.PIN[IP]].Index])^));
      end;
      dtExtVariableByOfs: begin
        Push(TStackItem((@Data.BaseData[Pop])^));
//        Inc(IP); Push(TStackItem( (@Data.BaseData[Data.PIN[IP] + Pop])^));
      end;
      aoAddII: begin i2 := Pop; i1 := Pop; Push(AddII(i1, i2)); end;
      aoAddIR: begin r2 := PopS; i1 := Pop; PushS(AddIR(i1, r2)); end;
      aoAddRI: begin i2 := Pop; r1 := PopS; PushS(AddRI(r1, i2)); end;
      aoAddRR: begin r2 := PopS; r1 := PopS; PushS(AddRR(r1, r2)); end;
      aoAddSS: begin i2 := Pop; i1 := Pop; Push(AddSS(i1, i2)); end;
      aoSubII: begin i2 := Pop; i1 := Pop; Push(SubII(i1, i2)); end;
      aoSubIR: begin r2 := PopS; i1 := Pop; PushS(SubIR(i1, r2)); end;
      aoSubRI: begin i2 := Pop; r1 := PopS; PushS(SubRI(r1, i2)); end;
      aoSubRR: begin r2 := PopS; r1 := PopS; PushS(SubRR(r1, r2)); end;
      aoSubSS: begin i2 := Pop; i1 := Pop; Push(SubSS(i1, i2)); end;
      aoMulII: begin i2 := Pop; i1 := Pop; Push(MulII(i1, i2)); end;
      aoMulIR: begin r2 := PopS; i1 := Pop; PushS(MulIR(i1, r2)); end;
      aoMulRI: begin i2 := Pop; r1 := PopS; PushS(MulRI(r1, i2)); end;
      aoMulRR: begin r2 := PopS; r1 := PopS; PushS(MulRR(r1, r2)); end;
      aoMulSS: begin i2 := Pop; i1 := Pop; Push(MulSS(i1, i2)); end;
      aoDivII: begin i2 := Pop; i1 := Pop; PushS(DivII(i1, i2)); end;
      aoDivIR: begin r2 := PopS; i1 := Pop; PushS(DivIR(i1, r2)); end;
      aoDivRI: begin i2 := Pop; r1 := PopS; PushS(DivRI(r1, i2)); end;
      aoDivRR: begin r2 := PopS; r1 := PopS; PushS(DivRR(r1, r2)); end;
      aoDivSS: begin i2 := Pop; i1 := Pop; Push(DivSS(i1, i2)); end;
      aoOrII, aoOrBB: Push(OrII(Pop, Pop));
      aoAndII, aoAndBB: Push(AndII(Pop, Pop));
      aoIDivII: Push(IDivII(Pop, Pop));
      aoModII: Push(ModII(Pop, Pop));
      aoNegI: Push(NegI(Pop));
      aoNegR: PushS(NegR(PopS));
      aoNegS: Push(NegS(Pop));
      aoInvI: Push(InvI(Pop));
      aoInvB: Push(InvB(Pop));
      arEqualII, arEqualRR: begin i2 := Pop; i1 := Pop; Push(Equal(i1, i2)); end;
      arEqualIR: begin r1 := PopS; i2 := Pop; Push(EqualRI(r1, i2)); end;
      arEqualRI: begin i1 := Pop; r2 := PopS; Push(EqualRI(r2, i1)); end;
      arGreaterII: begin i2 := Pop; i1 := Pop; Push(GreaterII(i1, i2)); end;
      arGreaterIR: begin r2 := PopS; i1 := Pop; Push(GreaterIR(i1, r2)); end;
      arGreaterRI: begin i2 := Pop; r1 := PopS; Push(GreaterRI(r1, i2)); end;
      arGreaterRR: begin r2 := PopS; r1 := PopS; Push(GreaterRR(r1, r2)); end;
      arLessII: begin i2 := Pop; i1 := Pop; Push(LessII(i1, i2)); end;
      arLessIR: begin r2 := PopS; i1 := Pop; Push(LessIR(i1, r2)); end;
      arLessRI: begin i2 := Pop; r1 := PopS; Push(LessRI(r1, i2)); end;
      arLessRR: begin r2 := PopS; r1 := PopS; Push(LessRR(r1, r2)); end;
      arGreaterEqualII: begin i2 := Pop; i1 := Pop; Push(GreaterEqualII(i1, i2)); end;
      arGreaterEqualIR: begin r2 := PopS; i1 := Pop; Push(GreaterEqualIR(i1, r2)); end;
      arGreaterEqualRI: begin i2 := Pop; r1 := PopS; Push(GreaterEqualRI(r1, i2)); end;
      arGreaterEqualRR: begin r2 := PopS; r1 := PopS; Push(GreaterEqualRR(r1, r2)); end;
      arLessEqualII: begin i2 := Pop; i1 := Pop; Push(LessEqualII(i1, i2)); end;
      arLessEqualIR: begin r2 := PopS; i1 := Pop; Push(LessEqualIR(i1, r2)); end;
      arLessEqualRI: begin i2 := Pop; r1 := PopS; Push(LessEqualRI(r1, i2)); end;
      arLessEqualRR: begin r2 := PopS; r1 := PopS; Push(LessEqualRR(r1, r2)); end;
      arNotEqualII, arNotEqualRR: begin i2 := Pop; i1 := Pop; Push(NotEqual(i1, i2)); end;
      arNotEqualIR: begin i2 := Pop; i1 := Pop; Push(NotEqualRI(i1, i2)); end;
      arNotEqualRI: begin i2 := Pop; i1 := Pop; Push(NotEqualRI(i2, i1)); end;
      arIn: begin i2 := Pop; i1 := Pop; Push(TestIn(i1, i2)); end;

      aoAssign1: ;//begin i2 := Pop; i1 := Pop; DoAssign4(i1, i2); end;
      aoAssign2: ;
      aoAssign4: begin i2 := Pop; i1 := Pop; DoAssign4(i1, i2); end;
      aoAssign4RI: begin r2 := Pop; i1 := Pop; DoAssign4(i1, Integer((@r2)^)); end;
      aoAssignSize: ;
      aoStackAssign4: begin i2 := Pop; i1 := Pop; DoStackAssign4(i1, i2); end;
      aoStackAssign4RI: begin r2 := Pop; i1 := Pop; DoStackAssign4(i1, Integer((@r2)^)); end;
      aoStackAssignSize: ;
      aoExtAssign4: begin i2 := Pop; i1 := Pop; DoExtAssign4(i1, i2); end;
      aoExtAssign4RI: begin r2 := Pop; i1 := Pop; DoExtAssign4(i1, Integer((@r2)^)); end;

      aoGoto: DoGoto(IP);
      aoJumpIfZero: DoZeroJump(Pop, IP);
      aoCall: begin DoCall(Pop, IP); Dec(IP); end;
      aoReturnF: begin
        i1 := Pop; DoReturn(IP); Push(i1);             // function only
      end;
      aoReturnP: DoReturn(IP);                         // procedure only
      aoExit: begin DoExit(Pop, IP); end;
      aoSetStackBase: begin Inc(IP); Push(StackBase); StackBase := TotalStack-Data.PIN[IP]-2; end;
      aoExpandStack: begin Inc(IP); ExpandStack(Data.PIN[IP]); end;
{        eoAdd, eoSub: Push(AddItems(Pop, Pop, Data.PIN[i].Value = eoSub));
      eoOr: Push(OrItems(Pop, Pop));
      eoAnd: Push(AndItems(Pop, Pop));
      eoMul: Push(MulItems(Pop, Pop));
      eoDiv: Push(DivItems(Pop, Pop));
      eoIDiv: Push(IDivItems(Pop, Pop));
      eoMod: Push(ModItems(Pop, Pop));
      rEqual, rNotEqual: Push(TestEqual(Pop, Pop, Data.PIN[i].Value = rNotEqual));
      rGreater, rLessEqual: Push(TestGreater(Pop, Pop, Data.PIN[i].Value = rLessEqual));
      rLess, rGreaterEqual: Push(TestLess(Pop, Pop, Data.PIN[i].Value = rGreaterEqual));}
// Standard functions
      sfSin: Pushs(Sin(PopS));
      sfCos: Pushs(Cos(PopS));
      sfTan: begin r1 := PopS; PushS(Sin(r1)/Cos(r1)); end;
      sfArcTan: PushS(ArcTan(PopS));
      sfSqrt: PushS(Sqrt(PopS));
      sfInvSqrt: PushS(InvSqrt(PopS));
      sfRnd: PushS(Random);
      sfEntier: Push(Round(PopS));
      sfLn: Pushs(Ln(PopS));
      sfBlend: begin
        r1 := PopS; i1 := Pop; i2 := Pop;
        Push(Integer(BlendColor(Cardinal(i2), Cardinal(i1), r1)));
      end;
    end;
    Inc(IP);
  end;
end;

function TOberonVM.Compute: TStackItem;
begin
  Run;
  Result := Pop;
end;

constructor TOberonVM.Create;
var i: Integer;
begin
{$IFDEF DEBUG}
  DItems := TStringList.Create;
{$ENDIF}
  Data  := TRTData.Create;
  StackCapacityStep := 256; StackCapacity := 256; SetLength(Stack, StackCapacity);
  MaxSet := 31;
  SetLength(El2Set, MaxSet);
  for i := 0 to MaxSet-1 do El2Set[i] := 1 shl i;
  Data.Namespace := nil;
end;

destructor TOberonVM.Destroy;
begin
  StackCapacity := 0; SetLength(Stack, StackCapacity);
  SetLength(El2Set, 0);
end;

end.
