(*
 Oberon compiler unit
 (C) 2004-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 The unit contains compiler main class
*)
{$DEFINE DEBUG}
unit OComp;

interface

uses SysUtils,
{$IFDEF DEBUG} Classes, {$ENDIF}
  OTypes, OScan, ORun, Dialogs;

const
  ConstMask  = 0 shl 24; VarMask = 1 shl 24; ProcMask = 2 shl 24;
  ArrayMask = 4 shl 24; COArrayMask = 8 shl 24; ResWordMask = 16 shl 24; 
  AllMask = 127 shl 24;

type
  TCompiledModule = record
  end;

  TTokenSet = set of TToken;

  TCompiler = class
    Scaner: TScaner;
    Error: Boolean;
    CError: TCompilationError;
    CurNamespace, Namespace: PNamespace;       // Current and global namespaces
    LastExpConstant: Boolean;
    LoopCount: Integer;
// Run-time data
    Data: TRTData;
    ExternalVars: array of record
      VarAddress: Pointer;
      VarName, VarType: string;
    end;
    constructor Create(AScaner: TScaner);
    destructor Destroy; override;
    procedure Reset;
    function Compile: Integer;

    function ImportExternalVar(AName, AType: string; Address: Pointer): Boolean;
    function GetExternalVarIndex(AName: string): Integer;

    function AddType(AName: TName): PType;
    procedure ClearType(AType: PType); virtual;

    function NewNamespace(AName: TName): PNamespace;
    procedure AddNamespace(AName: TName); virtual;
    procedure ClearNamespace(NS: PNamespace); virtual;

    function AllocateData(const DataSize, Value: Integer): Integer;
    function AllocateStack(const DataSize: Integer): Integer;

    function AddIdent(AKind: Int32; AName: TName; AType, AValue: Integer): Integer; overload;
    function AddIdentS(AKind: Int32; AName: TName; AType: Integer; AValue: Single): Integer; overload;
    function CheckIdent(AName: TName; NS: PNamespace; SearchToRoot: Boolean; var IdentKind: Integer): Int32;

    function SpecifyArray(TypeID: Integer; var Offset: Integer; var RuntimeOffs: Boolean): Integer;
    function SpecifyRecord(TypeID: Integer; var Offset: Integer; var RuntimeOffs: Boolean): Integer;
    function SpecifyVariable(AName: TName; TypeID: Integer; var Offset: Integer; var RuntimeOffs: Boolean): Integer;

    function CompileBlock(ReturnType: Integer): Integer;
    function ComputeExpression(StartPIN: Integer): Integer;
    function SetNValue(PINIndex: Integer; Buffer: string; SetType: Boolean): Integer;
    function SetSValue(PINIndex: Integer; Buffer: string): Integer;
    function isNumeric(AType: Integer): Boolean;
    function isInteger(AType: Integer): Boolean;
    function isReal(AType: Integer): Boolean;
  private
    LocalVM: TOberonVM;
    TotalNamesSpaces: Integer;
    procedure AddOperation(LastOp, OldType: Integer; var Res: Integer);
    function ControlTypes(var Operation: Integer; Type1, Type2: Integer): Integer;
    procedure SynError(ASource: string; AErrorNum: Integer; AErrorData: Integer);
    function CheckEnd(Buf: string): Integer;
    function CheckOperator(Buf: string): Integer;
    function GetOp1: Integer;
    function Exp1: Integer;
    function Exp2: Integer;
    function SimplifyExpression(Loc: Integer): Integer;
    function Expression: Integer;
    function ConstantExpression(var ExpResult: Integer): Integer;
    function GetOperator(Buf: string): Integer;
    procedure ParseAssign(IdentID, IdentOffset: Integer);
    procedure ParseLoop(ReturnType: Integer);
    procedure ParseWhile(ReturnType: Integer);
    procedure ParseRepeat(ReturnType: Integer);
    procedure ParseFor(ReturnType: Integer);
    procedure ParseIf(ReturnType: Integer);
    procedure ParseCall(const ProcID: Integer);
    procedure SetVarLocation(var AVar: TIdent; ALocation: Integer);
    function ParseVarSection: Integer;
    function ParseVar: Integer;
    procedure ParseConst;
    procedure ParseProc;
    function ParseTypeDef(TypeName: TName; AlwaysNew: Boolean): Integer;
    procedure ParseType;
    function GetDeclaration(Buf: string): Integer;
//    function GetTypeKind(TID: Integer): Integer;
    function GetType(Buf: string): Integer;
    function GetTypeSize(const TID: Integer): Integer;
    function GetConst(const Index: Integer): Integer;
    function Operators(ReturnType: Integer): Integer;
    function Declarations: Integer;
  end;

implementation

function TCompiler.SetNValue(PINIndex: Integer; Buffer: string; SetType: Boolean): Integer;            // ToFix: Check values range
var i: Integer; Temp: Extended; DecPos: Int32;

function HexStrToInt: Integer;
var i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Buffer)-1 do begin
    if Buffer[i] in ['0'..'9'] then
     Result := (Result shl 4) or (Ord(Buffer[i]) - Ord('0')) else
      if UpCase(Buffer[i]) in ['A'..'F'] then begin
        if i = 1 then SynError('HexStrToStr', eInvalidNumber, 0) else
        Result := (Result shl 4) or (Ord(UpCase(Buffer[i])) - Ord('A') + 10)
      end else SynError('HexStrToStr', eInvalidNumber, 0);
  end;
  if UpCase(Buffer[Length(Buffer)]) <> 'H' then SynError('HexStrToStr', eInvalidNumber, 0);
end;

begin
  Result := -1;
  DecPos := Pos('.', Buffer);
  if DecPos = 0 then begin
    Data.PIN[PINIndex+1] := StrToIntDef(Buffer, 0);
    for i := 1 to Length(Buffer) do if not (UpCase(Buffer[i]) in ['0'..'9']) then begin
      Data.PIN[PINIndex+1] := HexStrToInt;                     // Number in hex format
      Break;
    end;
    if Error then Exit;
    if SetType then Data.PIN[PINIndex] := GetVTypeInt(Data.PIN[PINIndex+1]);
  end else begin
    if Pos('.', Copy(Buffer, DecPos+1, Length(Buffer))) > 0 then begin
      SynError('SetNValue', eInvalidNumber, 0);
      Exit;
    end;
    for i := 1 to Length(Buffer) do if not (UpCase(Buffer[i]) in ['0'..'9', 'D', 'E', '.', '-', '+']) then begin
      SynError('SetNValue', eInvalidNumber, 0);
      Exit;
    end;
    Buffer[DecPos] := ',';
    DecPos := Length(Buffer)-DecPos;
    case DecPos of
      1..7: Data.PIN[PINIndex] := dtSingle;                         // ToFix: Wrong type checking
      8..15: Data.PIN[PINIndex] := dtDouble;
      else Data.PIN[PINIndex] := dtReal;
    end;
    Temp := StrToFloat(Buffer);
    Single((@Data.PIN[PINIndex+1])^) := Temp;
  end;
  Result := Data.PIN[PINIndex];
end;

function TCompiler.SetSValue(PINIndex: Integer; Buffer: string): Integer;
var Len: Nat16;
begin
  Result := -1;
  Data.PIN[PINIndex+1] := Data.DataLength;
  Data.PIN[PINIndex] := dtString;
  Len := Length(Buffer);
  Move(Len, Pointer(Int32(Data.Data)+Data.DataLength)^, 2);
  if Len > 0 then Move(Buffer[1], Pointer(Int32(Data.Data)+Data.DataLength+2)^, Len);
  Inc(Data.DataLength, Len+2);
  Result := Data.PIN[PINIndex];
end;

function TCompiler.AddType(AName: TName): PType;
begin
  Assert(CurNamespace <> nil, 'AddType: Current namespace is nil');
  New(Result);
  Inc(Data.TotalTypes); SetLength(Data.Types, Data.TotalTypes);
  Data.Types[Data.TotalTypes-1] := Result;

  Inc(CurNamespace.TotalTypes); SetLength(CurNamespace.Types, CurNamespace.TotalTypes);
  CurNamespace.Types[CurNamespace.TotalTypes-1] := Data.TotalTypes-1;

  Result.Name := AName;
  Result.ID := Data.TotalTypes-1;
  Result.Kind := 0;
  Result.Namespace := nil;
  Result.Size := SizeOf(TStackItem);
end;

function TCompiler.NewNamespace(AName: TName): PNamespace;
begin
  New(Result);
  Result.Name := AName;
  Result.TotalConstants := 0; SetLength(Result.Constants, 0);
  Result.TotalVariables := 0; SetLength(Result.Variables, 0);
  Result.TotalProcedures := 0; SetLength(Result.Procedures, 0);
  Result.TotalTypes := 0; SetLength(Result.Types, 0);
  Result.Parent := nil;
  Result.Kind := nskModule;
  Result.StackLength := 0;
  Result.ParamCount := 0; Result.ID := 0;
  Result.UID := TotalNamesSpaces;
  Inc(TotalNamesSpaces);
end;

procedure TCompiler.AddNamespace(AName: TName);
var NewNS: PNamespace;
begin
  NewNS := NewNamespace(AName);
  if CurNamespace = nil then Namespace := NewNS else begin
    Inc(CurNamespace.TotalProcedures); SetLength(CurNamespace.Procedures, CurNamespace.TotalProcedures);
    CurNamespace.Procedures[CurNamespace.TotalProcedures-1] := NewNS;
  end;
  NewNS.Parent := CurNamespace;
  CurNamespace := NewNS;
end;

procedure TCompiler.ClearType(AType: PType);
begin
  if AType.Namespace <> nil then ClearNamespace(AType.Namespace);
end;

procedure TCompiler.ClearNamespace(NS: PNamespace);
var i: Integer;
begin
  NS.TotalConstants := 0; SetLength(NS.Constants, 0);
  NS.TotalVariables := 0; SetLength(NS.Variables, 0);
  NS.TotalTypes := 0; SetLength(NS.Types, 0);
  for i := 0 to NS.TotalProcedures-1 do begin
    ClearNamespace(NS.Procedures[i]);
    Dispose(NS.Procedures[i]);
  end;
  NS.TotalProcedures := 0; SetLength(NS.Procedures, 0);
end;

function TCompiler.AddIdent(AKind: Int32; AName: TName; AType, AValue: Integer): Integer;
// Adds constant, variable or procedure identifier
// In case of variable doesn't allocate data
// Returns index of the new identifier
var Offset, IdentKind: Integer;
begin
  Result := -1;
  case AKind of
    ikConstant: begin
      Inc(Data.TotalConstants); SetLength(Data.Constants, Data.TotalConstants);
      with Data.Constants[Data.TotalConstants-1] do begin
        Name := AName; TypeID := AType; Namespace := CurNamespace;
        Index := AllocateData(GetTypeSize(AType), AValue);
        Location := ilGlobal;
      end;
      Inc(CurNamespace.TotalConstants); SetLength(CurNamespace.Constants, CurNamespace.TotalConstants);
      CurNamespace.Constants[CurNamespace.TotalConstants-1] := Data.TotalConstants-1;
      Result := Data.TotalConstants-1;
    end;
    ikVariable: begin
      Offset := CheckIdent(AName, Namespace, False, IdentKind);
      if (CurNamespace <> NameSpace) or (Offset = -1) then begin
        Inc(Data.TotalVariables); SetLength(Data.Variables, Data.TotalVariables);
        with Data.Variables[Data.TotalVariables-1] do begin
          Name := AName; TypeID := AType; Namespace := CurNamespace;
//          if Data.Types[AType].Kind <> tkRecord then begin
//          end;
        end;
        Inc(CurNamespace.TotalVariables); SetLength(CurNamespace.Variables, CurNamespace.TotalVariables);
        CurNamespace.Variables[CurNamespace.TotalVariables-1] := Data.TotalVariables-1;
        Result := Data.TotalVariables-1;
      end else Result := Offset and not AllMask;
    end;
    ikProcedure: begin
      Inc(Data.TotalProcedures); SetLength(Data.Procedures, Data.TotalProcedures);
      with Data.Procedures[Data.TotalProcedures-1] do begin
        Name := AName; TypeID := AType; Namespace := CurNamespace;
        Index := AllocateData(4, AValue);
        Location := ilGlobal;
      end;
//      Inc(CurNamespace.TotalProcedures); SetLength(CurNamespace.Procedures, CurNamespace.TotalProcedures);
//      CurNamespace.Procedures[CurNamespace.TotalProcedures-1].Value := TotalProcedures-1;
      Result := Data.TotalProcedures-1
    end;
    ikType:;{ begin
      Inc(Data.TotalTypes); SetLength(Data.Types, Data.TotalTypes);
      with Data.Types[Data.TotalTypes-1] do begin
        Name := AName; Value := AValue; TypeID := AType; Namespace := CurNamespace;
      end;
    end;}
    else Assert(False, 'Invalid identifier kind');
  end;
end;

function TCompiler.AddIdentS(AKind: Int32; AName: TName; AType: Integer; AValue: Single): Integer;
begin
  Result := AddIdent(AKind, AName, AType, Integer((@AValue)^));
end;

procedure TCompiler.SynError(ASource: string; AErrorNum: Integer; AErrorData: Integer);
begin
  if Error then Exit;
  with CError do begin
    Source := ASource;
    Line := Scaner.CurLine;
    Position := Scaner.SourcePos;
    Number := AErrorNum;
    Data := AErrorData;
  end;
  Error := True;
end;

function TCompiler.CheckEnd(Buf: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to TotalEndTokens-1 do if Buf = EndTokenStr[i] then begin
    Result := i;
    Break;
  end;
end;

function TCompiler.CheckOperator(Buf: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to TotalOperators-1 do if Buf = OperatorStr[i] then begin
    Result := i;
    Break;
  end;
end;

function TCompiler.SpecifyArray(TypeID: Integer; var Offset: Integer; var RuntimeOffs: Boolean): Integer;
// Parses "["Exp"]"
var i, ExpStartPIN: Integer; ch: Char;
begin
//  Assert(Data.Types[TID].ID = TID, 'CheckIdent.SpecifyArray: Type ID mismatch');

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  if ch <> '[' then begin Result := TypeID; Scaner.ReturnChar(ch); Exit; end;

  ExpStartPIN := Data.PINItems;
  LastExpConstant := True;
  if not isInteger(Exp1) then begin
    SynError('SpecifyArray', eIntExpExpected, 0);
    Exit;
  end;
  if Error then Exit;

  if LastExpConstant then begin
    Offset := Offset + ComputeExpression(ExpStartPIN) * GetTypeSize(Data.Types[TypeID].ID);
    Data.PINItems := ExpStartPIN;
  end else begin
    Inc(Data.PINItems, 3); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-3] := dtInt;
    Data.PIN[Data.PINItems-2] := GetTypeSize(Data.Types[TypeID].ID);
    Data.PIN[Data.PINItems-1] := aoMulII;                              // Multiply expression by element size
    if RuntimeOffs then begin
      Inc(Data.PINItems, 1); SetLength(Data.PIN, Data.PINItems);
      Data.PIN[Data.PINItems-1] := aoAddII;                              // Add base variable address
    end;
    RuntimeOffs := True;
  end;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  if ch <> ']' then begin
    SynError('SpecifyArray', eRightBracketExpected, 0);
    Exit;
  end;

  case Data.Types[Data.Types[TypeID].ID].Kind of
    tkCommon: Result := Data.Types[TypeID].ID;
    tkRecord: Result := SpecifyRecord(Data.Types[TypeID].ID, Offset, RuntimeOffs);
    tkArray: Result := SpecifyArray(Data.Types[TypeID].ID, Offset, RuntimeOffs);
  end;
end;

function TCompiler.SpecifyRecord(TypeID: Integer; var Offset: Integer; var RuntimeOffs: Boolean): Integer;
// Parses "."ident
// Returns field index
var ch: Char; FieldIndex, TempIdentKind: Integer;
begin
  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  if ch <> '.' then begin Result := TypeID; Scaner.ReturnChar(ch); Exit; end;
  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf = '' then SynError('SpecifyRecord', eVariableExpected, 0) else

  FieldIndex := CheckIdent(Scaner.Buf, Data.Types[TypeID].Namespace, False, TempIdentKind);
  if FieldIndex = -1 then begin                                       // Not found
    SynError('SpecifyRecord', eUndeclaredIdentifier, 0); Exit;
  end;
  if (TempIdentKind and ResWordMask > 0) then begin                     // Found, but is reserved word
    SynError('SpecifyRecord', eUnexpectedResWord, 0); Exit;
  end;

  Offset := Offset + Data.Variables[FieldIndex].Index;

  case Data.Types[Data.Variables[FieldIndex].TypeID].Kind of
    tkCommon: Result := Data.Variables[FieldIndex].TypeID;
    tkRecord: Result := SpecifyRecord(Data.Variables[FieldIndex].TypeID, Offset, RuntimeOffs);
    tkArray: Result := SpecifyArray(Data.Variables[FieldIndex].TypeID, Offset, RuntimeOffs);
  end;
end;

function TCompiler.SpecifyVariable(AName: TName; TypeID: Integer; var Offset: Integer; var RuntimeOffs: Boolean): Integer;
// Calculates offset of specified field in record or array element of specified type
// Returns type ID of the element specified
// In offset returns offset of specified element
// In IdentKind returns identifier kind (constant offset or run-time calculated offset)
// Adds to PIN code to calculate runtime calculating offset
begin
  Result := TypeID;

  RuntimeOffs := False;

  case Data.Types[TypeID].Kind of
    tkRecord: Result := SpecifyRecord(TypeID, Offset, RuntimeOffs);
    tkArray: Result := SpecifyArray(TypeID, Offset, RuntimeOffs);
  end;

  if RuntimeOffs then begin
      Inc(Data.PINItems, 3); SetLength(Data.PIN, Data.PINItems);
      Data.PIN[Data.PINItems-3] := dtInt;
      Data.PIN[Data.PINItems-2] := Offset;
      Data.PIN[Data.PINItems-1] := aoAddII;                              // Add base variable address
    end;

{  if Result and ArrayMask > 0 then begin
    Inc(Data.PINItems, 3); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-3] := dtInt;
    Data.PIN[Data.PINItems-2] := Offset;
    Data.PIN[Data.PINItems-1] := aoAddII;                              // Add base variable address
  end;}

end;

function TCompiler.CheckIdent(AName: TName; NS: PNamespace; SearchToRoot: Boolean; var IdentKind: Integer): Int32;
// Searches identifier by name specified
// in current namespace and above namespaces if SearchToRoot is true.
// Returns index in Constants, Variables etc array
// In IdentKind returns kind of identifier (reserved word, constant, variable or procedure)
var i: Integer; ch: Char;
begin
  Result := -1;

  for i := 0 to TotalReservedWords-1 do if AName = ReservedWord[i] then begin
    Result := i; IdentKind := ResWordMask; Exit;
  end;

  while NS <> nil do begin
    for i := 0 to NS.TotalConstants-1 do if Data.Constants[NS.Constants[i]].Name = AName then begin
      Result := NS.Constants[i]; IdentKind := ConstMask; Exit;
    end;
    for i := 0 to NS.TotalVariables-1 do if Data.Variables[NS.Variables[i]].Name = AName then begin
      Result := NS.Variables[i]; IdentKind := VarMask; Exit;
    end;
    for i := 0 to NS.TotalProcedures-1 do if NS.Procedures[i].Name = AName then begin
      Result := NS.Procedures[i].ID; IdentKind := ProcMask; Exit;
    end;
    if SearchToRoot then NS := NS.Parent else NS := nil;
  end;
end;

procedure TCompiler.AddOperation(LastOp, OldType: Integer; var Res: Integer);
begin
  if LastOp <> aoNull then begin
    Res := ControlTypes(LastOp, OldType, Res);
    Inc(Data.PINItems, 1); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-1] := LastOp;
  end;
end;

function TCompiler.GetOp1: Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to TotalOperations1-1 do if Scaner.Buf = Op1Str[i] then begin
    Result := Op1ID[i]; Break;
  end;
end;

function TCompiler.Exp1: Integer;
var ch: Char; LastOp, OldType: Integer;
begin
// Exp1 = ['-' | '+'] Exp2 { ['-' | '+', 'OR'] Exp2}
// Result - expression type
  Result := -1; OldType := -1;
  LastOp := aoNull;
{  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  if ch = '-' then NegOp := oNeg else if ch <> '+' then Scaner.ReturnChar(ch);}

  Result := Exp2;                                               //

  Scaner.SkipDelims;
  while not Error and Scaner.ReadChar(ch) and (ch <> ';') do begin
    Scaner.Buf := ch;

    if Scaner.isAlpha(ch) then Scaner.GetIdent(ch);

    if (ch = ',') or (ch = ')') or (ch = '}') or (ch = ']') or Scaner.isRelation(ch) or
       (CheckEnd(Scaner.Buf) <> -1) or (CheckOperator(Scaner.Buf) <> -1) or (Scaner.Buf = RelationStr[6]) or (Scaner.Buf = RelationStr[7])  then begin
      Scaner.ReturnBuf(Scaner.Buf); Break;
    end;

    LastOp := GetOp1;
    if LastOp = -1 then begin
      SynError('Exp1', eOperationExpected, 0);
      Break;
    end;
    OldType := Result; Result := Exp2;
    if Error then Break;
    AddOperation(LastOp, OldType, Result);
  end;
  if ch = ';' then Scaner.ReturnBuf(ch);
end;

function TCompiler.Exp2: Integer;
var ch: Char; LastOp, IdentIndex, IdentKind: Int32; OldType: Integer;

function GetOp2: Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to TotalOperations2-1 do if Scaner.Buf = Op2Str[i] then begin
    Result := Op2ID[i]; Break;
  end;
end;

function ParseSetConstructor: Integer;
var TotalElements: Integer; ch: Char;
// Set = "{" [El {, El}] "}"
// El = Exp [..Exp]
begin
  Result := -1;
  TotalElements := 0;
// First element if exists
  Scaner.SkipDelims; Scaner.ReadChar(ch);
  Scaner.ReturnChar(ch);
  if ch <> '}' then
   if isInteger(Exp1) then Inc(TotalElements) else
    SynError('ParseSetConstructor', eIncompatibleTypes, 0);
// Rest of elements
  while Scaner.ReadChar(ch) and (ch = ',') and not Error do begin
    if not isInteger(Exp1) then begin SynError('ParseSetConstructor', eIncompatibleTypes, 0); Break; end;
    Inc(TotalElements);
    Scaner.SkipDelims;
  end;
  if Error then Exit;
  Inc(Data.PINItems); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-1] := dtSet + TotalElements shl 16;
  Result := dtSet;
end;

function ParseStdFunction: Integer;
// STDPROC
var i, Op, ExpType: Integer;
begin
{  Result := StandardFunctions[IdentIndex].ResultType;
  Op := oAssign;
  ExpType := Expression;
  if Error then Exit;
  if ControlTypes(Op, dtReal, ExpType) = -1 then Exit;
  Inc(Data.PINItems, 1); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-1] := StandardFunctions[IdentIndex].OperationID;}
end;

function ParseMultiplier: Integer;
var InvOp, NegOp, VarOfs, VarLoc: Integer; RTOffs: Boolean;
// Mult = ~Mult | Const | Ident | (Expression)
// Result - multiplier's type

begin
  Result := -1;
  Scaner.SkipDelims; Scaner.ReadChar(ch);
  if ch = '-' then begin
    NegOp := oNeg;
    Result := ControlTypes(NegOp, ParseMultiplier, 0);
    if Result = -1 then Exit;
    Inc(Data.PINItems); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-1] := NegOp;
  end else if ch='~' then begin
    InvOp := oInv;
    Result := ControlTypes(InvOp, ParseMultiplier, 0);
    if Result = -1 then Exit;
    Inc(Data.PINItems); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-1] := InvOp;
    Exit;
  end else if Scaner.isNumber(ch) then begin
    Scaner.GetNumber(ch);
    Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
//    OldType := Result;
    Result := SetNValue(Data.PINItems-2, Scaner.Buf, True);
//    AddOperation(LastOp, OldType, Result);
    Exit;
  end else if Scaner.isAlpha(ch) then begin
    Scaner.GetIdent(ch);
//    if CheckOp1 then begin Scaner.ReturnBuf(Scaner.Buf); Break; end;
    IdentIndex := CheckIdent(Scaner.Buf, CurNamespace, True, IdentKind);
    if IdentIndex >= 0 then begin
      case IdentKind of
        VarMask: begin                                // Variable

          if (IdentKind and VarMask <> 0) then begin                                // Variable
            VarOfs := Data.Variables[IdentIndex].Index;
            Result := SpecifyVariable(Scaner.Buf, Data.Variables[IdentIndex].TypeID, VarOfs, RTOffs);
            VarLoc := Data.Variables[IdentIndex].Location;

            if RTOffs then begin
              Inc(Data.PINItems);
//              if VarLoc = ilExternal then Inc(Data.PINItems);
              SetLength(Data.PIN, Data.PINItems);
              case VarLoc of
                ilStack: Data.PIN[Data.PINItems-1] := dtStackVariableByOfs;
                ilGlobal: Data.PIN[Data.PINItems-1] := dtVariableByOfs;
                ilExternal: Data.PIN[Data.PINItems-1] := dtExtVariableByOfs;
              end;
//              if VarLoc = ilExternal then Data.PIN[Data.PINItems-1] := VarOfs;
            end else begin
              Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
              case VarLoc of
                ilStack: Data.PIN[Data.PINItems-2] := dtStackVariable;
                ilGlobal: Data.PIN[Data.PINItems-2] := dtVariable;
                ilExternal: Data.PIN[Data.PINItems-2] := dtExtVariable;
              end;
              Data.PIN[Data.PINItems-1] := VarOfs;
            end;
            LastExpConstant := False;
          end else begin
            SynError('ParseAssign', eCannotAssign, 0); Exit;
          end;

          LastExpConstant := False;
        end;
        ConstMask: begin                              // Constant
          Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
          Data.PIN[Data.PINItems-2] := Data.Constants[IdentIndex].TypeID;
          Data.PIN[Data.PINItems-1] := GetConst(IdentIndex);
          Result := Data.Constants[IdentIndex].TypeID;
        end;
        ProcMask: begin                               // Procedure-function
          if Data.Procedures[IdentIndex].TypeID = -1 then begin
            SynError('ParseMultiplier', eMustBeFunction, 0);
            Exit;
          end;
          ParseCall(IdentIndex);
          Result := Data.Procedures[IdentIndex].TypeID;
          LastExpConstant := False;                       // ToFix: Take in account compile-time computable functions
        end;
        ResWordMask: begin
          SynError('ParseMultiplier', eUnexpectedResWord, 0); Exit;
        end;
        else begin
          MessageDlg('Unknown identifier type', mtError, [mbOK], 0);
          SynError('ParseMultiplier', eUndeclaredIdentifier, 0); Exit;
        end;
      end;
    end else begin SynError('ParseMultiplier', eUndeclaredIdentifier, 0); Exit; end;
  end else if (ch='''') or (ch='"') then begin
    Scaner.GetString(ch);
    Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
//    OldType := Result;
    Result := SetSValue(Data.PINItems-2, Scaner.Buf);
//    AddOperation(LastOp, OldType, Result);
  end else if (ch='{') then Result := ParseSetConstructor else if (ch='(') then begin
    Result := Expression;
    Scaner.SkipDelims; Scaner.ReadChar(ch);
    if ch <> ')' then SynError('ParseMultiplier', eRightParenthesisExpected, 0);
  end;
end;

begin
// Exp2 =  Mult { "*" | "/" | DIV | MOD | "&"  Mult }
  Result := -1; OldType := -1;
  LastOp := aoNull;
  Result := ParseMultiplier;
  if Result = -1 then Exit;
  Scaner.SkipDelims;
  while not Error and Scaner.ReadChar(ch) do begin
    if (ch = ';') or (ch = ',') or (ch = ')') or (ch = '}') or (ch = ']') or Scaner.isRelation(ch) then begin Scaner.ReturnChar(ch); Break; end;
    if Scaner.isOperation(ch) then Scaner.GetOperation(ch) else
     if Scaner.isAlpha(ch) then Scaner.GetIdent(ch);
    if (GetOp1 <> -1) or (CheckEnd(Scaner.Buf) <> -1) or (Scaner.Buf = RelationStr[6]) or (Scaner.Buf = RelationStr[7]) then begin
      Scaner.ReturnBuf(Scaner.Buf);
      Break;
    end;
    LastOp := GetOp2;
    if LastOp = -1 then begin
      SynError('Exp2', eOperationExpected, 0);
    end else begin
      OldType := Result;
      Result := ParseMultiplier;
      AddOperation(LastOp, OldType, Result);
      Scaner.SkipDelims;
    end;
  end;
end;

function TCompiler.SimplifyExpression(Loc: Integer): Integer;
var IP, i1, i2: Integer; r1, r2: Single;
type TStackItem = Integer;
const StackCapacityStep = 32;
var
  Stack: array of TStackItem;
  TotalStack, StackCapacity: Integer;

procedure Push(Item: TStackItem);
begin
  Inc(TotalStack);
  if TotalStack > StackCapacity then begin
    Inc(StackCapacity, StackCapacityStep); SetLength(Stack, StackCapacity);
  end;
  Stack[TotalStack-1] := Item;
end;

procedure PushS(Item: Single); 
begin
  Inc(TotalStack);
  if TotalStack > StackCapacity then begin
    Inc(StackCapacity, StackCapacityStep); SetLength(Stack, StackCapacity);
  end;
  Stack[TotalStack-1] := TStackItem((@Item)^);
end;

function Pop: TStackItem;
begin
  if TotalStack = 0 then Exit;
  Result := Stack[TotalStack-1];
  Dec(TotalStack);
end;

function PopS: Single;
begin
  if TotalStack = 0 then Exit;
  Result := Single((@Stack[TotalStack-1])^);
  Dec(TotalStack);
end;

// 2, 3, * 7, x, * 8 * + x, 2 * 3 * x * + 2, 4, * 1, 2, x, * + * + ( 2*3+7*x*8+x*2*3*x+2*4*(1+2*x) )
// x, 2, 4, * x, 2, x * + * + ( x+2*4*(x+2*x) )
begin
end;

function TCompiler.Expression: Integer;
var i: Integer; ch: Char; LastOp, OldType: Integer;
begin
// Exp1 [rel Exp1]
  LastExpConstant := True;
  Result := -1; OldType := -1;
  LastOp := aoNull;
  Scaner.SkipDelims;
  Result := Exp1;
  if (Result = -1) then begin
    if not Error then SynError('Expression', eUnexpectedExpEnd, Ord(ch));
    Exit;
  end;

  Scaner.SkipDelims;
  if not Scaner.ReadChar(ch) then Exit;
  if Scaner.isRelation(ch) then Scaner.GetRelation(ch) else if Scaner.isAlpha(ch) then Scaner.GetIdent(ch) else begin
    Scaner.ReturnChar(ch); Exit;
  end;
  for i := 0 to TotalRelations-1 do if Scaner.Buf = RelationStr[i] then begin
    LastOp := RelationID[i];
    Break;
  end;
  if LastOp = aoNull then begin Scaner.ReturnBuf(Scaner.Buf); Exit; end;

  Scaner.SkipDelims;
  OldType := Result;
  Result := Exp1;
  if (Result = -1) and not Error then begin SynError('Expression', eUnexpectedExpEnd, Ord(ch)); Exit; end;
  AddOperation(LastOp, OldType, Result);
end;

function TCompiler.ConstantExpression(var ExpResult: Integer): Integer;
// Parses expression, compute it and return result in ExpResult
// Returns type of expression
var i, ExpStartPIN: Integer;
begin
  ExpStartPIN := Data.PINItems;
  Result := Expression;
  if Error then Exit;
  if not LastExpConstant then SynError('ConstantExpression', eConstExpExpected, 0);
  ExpResult := ComputeExpression(ExpStartPIN);
  Data.PINItems := ExpStartPIN;
end;

constructor TCompiler.Create(AScaner: TScaner);
begin
  Scaner := AScaner;
  Data   := TRTData.Create;
  Reset;
end;

procedure TCompiler.Reset;
var i: Integer;
begin
  Data.EntryPIN := -1;
  CError.Number := 0;
  Scaner.Create(Scaner.Source);
//  Constants := nil; Variables := nil; Procedures := nil;
  Data.TotalConstants := 0; Data.TotalVariables := 0; Data.TotalProcedures := 0;
  for i := 0 to Data.TotalTypes-1 do begin
    ClearType(Data.Types[i]);
    Dispose(Data.Types[i]);
  end;
  Data.TotalTypes := 0;
//  Data.PIN := nil;
  Data.PINItems := 0;
//  if Assigned(Data) then FreeMem(Data);
//  Data.DataLength := 0;
  if Namespace <> nil then begin
    ClearNamespace(Namespace);
    Dispose(Namespace);
  end;
  Namespace := nil;
  CurNamespace := nil;
  TotalNamesSpaces := 0;

  Data.DataLength := 0; SetLength(Data.Data, Data.DataLength);
  Data.BaseData := nil;

  ExternalVars := nil; Data.TotalExternalVariables := 0; 
end;

function TCompiler.GetOperator(Buf: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to TotalOperators-1 do if Buf = OperatorStr[i] then begin
    Result := i; Exit;
  end;
end;

procedure TCompiler.ParseAssign(IdentID, IdentOffset: Integer);
var Op: Integer; ch: Char; AssignType, ExpType, IdentKind, VarLoc: Integer; RTOffs: Boolean;
begin
  IdentKind := VarMask;
  if IdentID = -1 then begin
    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    if Scaner.isAlpha(ch) then Scaner.GetIdent(ch) else begin SynError('ParseAssign', eVariableExpected, 0); Exit; end;
    IdentID := CheckIdent(Scaner.Buf, CurNamespace, True, IdentKind);
    if IdentID = -1 then begin SynError('ParseAssign', eUndeclaredIdentifier, 0); Exit; end;
  end;

  if (IdentKind and VarMask > 0) then begin                                // Variable
    IdentOffset := Data.Variables[IdentID].Index;
    AssignType := SpecifyVariable(Scaner.Buf, Data.Variables[IdentID].TypeID, IdentOffset, RTOffs);
    VarLoc := Data.Variables[IdentID].Location;
    if RTOffs then begin
{      Inc(Data.PINItems);
      if VarLoc = ilExternal then Inc(Data.PINItems);
      SetLength(Data.PIN, Data.PINItems);
      case VarLoc of
        ilStack: Data.PIN[Data.PINItems-1] := dtStackVariableByOfs;
        ilGlobal: Data.PIN[Data.PINItems-1] := dtVariableByOfs;
        ilExternal: Data.PIN[Data.PINItems-2] := dtExtVariableByOfs;
      end;
      if VarLoc = ilExternal then Data.PIN[Data.PINItems-1] := VarOfs;}
    end else begin
      if (IdentID and ArrayMask = 0) then begin
        Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
        Data.PIN[Data.PINItems-2] := dtVariableRef;
        Data.PIN[Data.PINItems-1] := IdentOffset;
      end;
    end;
    LastExpConstant := False;
  end else begin
    SynError('ParseAssign', eCannotAssign, 0); Exit;
  end;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetOperator(ch);
  if Scaner.Buf <> ':=' then begin
    SynError('ParseAssign', eAssignationExpected, 0);
    Exit;
  end;
  Op := oAssign;
  ExpType := ControlTypes(Op, AssignType, Expression);
  if Exptype = -1 then Exit;

  if Data.Variables[IdentID and not AllMask].Location = ilStack then case Op of
    aoAssign1, aoAssign2, aoAssign4: Op := aoStackAssign4;
    aoAssignSize: Op := aoStackAssignSize;
    aoAssign4RI: Op := aoStackAssign4RI;
  end else if Data.Variables[IdentID and not AllMask].Location = ilExternal then case Op of
    aoAssign1, aoAssign2, aoAssign4: Op := aoExtAssign4;
    aoAssignSize: Op := aoExtAssignSize;
    aoAssign4RI: Op := aoExtAssign4RI;
  end;

  Inc(Data.PINItems, 1); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-1] := Op;
end;

procedure TCompiler.ParseLoop(ReturnType: Integer);
var ch: Char; BegIP, ExitPIN: Integer;
begin
// LOOP ops; END;
  Inc(LoopCount);
  Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-2] := dtInt; ExitPIN := Data.PINItems-1;

  BegIP := Data.PINItems-1;

  Operators(ReturnType);

  if Error then Exit;
  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf <> EndTokenStr[etEnd] then begin
    SynError('OpLoop', eEndExpected, 0); Exit;
  end;

  Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-2] := aoGoto; Data.PIN[Data.PINItems-1] := BegIP;
  if ExitPIN <> -1 then Data.PIN[ExitPIN] := Data.PINItems-1;
  Dec(LoopCount);
end;

procedure TCompiler.ParseWhile(ReturnType: Integer);
var ch: Char; BegIP, JumpPIN, ExitPIN: Integer;
begin
// WHILE Expr DO Ops; END
  Inc(LoopCount);
  Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-2] := dtInt; ExitPIN := Data.PINItems-1;

  BegIP := Data.PINItems-1;

  Scaner.SkipDelims;
  if Expression <> dtBoolean then begin
    SynError('OpWhile', eBooleanExpExpected, 0); Exit;
  end;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf <> EndTokenStr[etDo] then begin
    SynError('OpWhile', eDoExpected, 0); Exit;
  end;

  Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-2] := aoJumpIfZero; JumpPIN := Data.PINItems-1;

  if Operators(ReturnType) = -1 then begin
  end;
  if Error then Exit;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf <> EndTokenStr[etEnd] then begin
    SynError('OpWhile', eEndExpected, 0); Exit;
  end;

  Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-2] := aoGoto; Data.PIN[Data.PINItems-1] := BegIP;
  Data.PIN[JumpPin] := Data.PINItems-1;
  if ExitPIN <> -1 then Data.PIN[ExitPIN] := Data.PINItems-1;
  Dec(LoopCount);
end;

procedure TCompiler.ParseRepeat(ReturnType: Integer);
var ch: Char; BegIP, ExitPIN: Integer;
begin
// REPEAT ops; UNTIL Expr;
  ExitPIN := -1;
  BegIP := Data.PINItems-1;
  if Operators(ReturnType) = -1 then begin
    Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-2] := aoGoto; ExitPIN := Data.PINItems-1;
  end;
  if Error then Exit;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf <> EndTokenStr[etUntil] then begin
    SynError('OpRepeat', eUntilExpected, 0); Exit;
  end;
  Scaner.SkipDelims;
  if Expression <> dtBoolean then begin
    SynError('OpRepeat', eBooleanExpExpected, 0); Exit;
  end;

  Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-2] := aoJumpIfZero; Data.PIN[Data.PINItems-1] := BegIP;
  if ExitPIN <> -1 then Data.PIN[ExitPIN] := Data.PINItems-1;
end;

procedure TCompiler.ParseFor(ReturnType: Integer);
var ch: Char; BegIP, JumpPIN, ExitPIN, VarRef, VarOfs, IdentKind: Integer;
begin
// FOR Ident := Expr TO Expr [BY ConstExpr] DO Ops END
  ExitPIN := -1;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  if Scaner.isAlpha(ch) then Scaner.GetIdent(ch) else begin SynError('OpFor', eVariableExpected, 0); Exit; end;
  VarOfs := 0;
  VarRef := CheckIdent(Scaner.Buf, CurNamespace, True, IdentKind);
  if VarRef = -1 then begin SynError('OpAssign', eUndeclaredIdentifier, 0); Exit; end;
  if (IdentKind and VarMask = 0) then begin SynError('OpAssign', eCannotAssign, 0); Exit; end;
  ParseAssign(VarRef, VarOfs);
  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf <> EndTokenStr[etTo] then begin
    SynError('OpFor', eToExpected, 0); Exit;
  end;

  BegIP := Data.PINItems-1;

  Expression;
  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf <> EndTokenStr[etDo] then begin
    SynError('OpFor', eDoExpected, 0); Exit;
  end;

  Inc(Data.PINItems, 5); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-5] := dtVariable; Data.PIN[Data.PINItems-4] := Data.Variables[VarRef].Index;
  Data.PIN[Data.PINItems-3] := arGreaterEqualII;  
  Data.PIN[Data.PINItems-2] := aoJumpIfZero; JumpPIN := Data.PINItems-1;

  if Operators(ReturnType) = -1 then begin
    Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-2] := aoGoto; ExitPIN := Data.PINItems-1;
  end;
  if Error then Exit;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  if ch = ';' then begin
    while ch = ';' do Scaner.ReadChar(ch);
    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
  end;
  Scaner.GetIdent(ch);
  if Scaner.Buf <> EndTokenStr[etEnd] then begin
    SynError('OpFor', eEndExpected, 0); Exit;
  end;

  Inc(Data.PINItems, 10); SetLength(Data.PIN, Data.PINItems);                         //ToFix: BY support

  Data.PIN[Data.PINItems-10] := dtVariableRef; Data.PIN[Data.PINItems-9] := Data.Variables[VarRef].Index;
  Data.PIN[Data.PINItems-8] := dtVariable; Data.PIN[Data.PINItems-7] := Data.Variables[VarRef].Index;
  Data.PIN[Data.PINItems-6] := dtInt; Data.PIN[Data.PINItems-5] := 1;
  Data.PIN[Data.PINItems-4] := aoAddII; Data.PIN[Data.PINItems-3] := aoAssign4;

  Data.PIN[Data.PINItems-2] := aoGoto; Data.PIN[Data.PINItems-1] := BegIP;
  Data.PIN[JumpPin] := Data.PINItems-1;
  if ExitPIN <> -1 then Data.PIN[ExitPIN] := Data.PINItems-1;
end;

procedure TCompiler.ParseIf(ReturnType: Integer);
var i, JumpPIN: Integer; ch: Char; ExitPINs: array of Integer; TotalExitPINs: Integer;

procedure ProcessIf;
begin
  if JumpPIN <> -1 then begin
    Inc(TotalExitPINs); SetLength(ExitPINs, TotalExitPINs);
    Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-2] := aoGoto; ExitPINs[TotalExitPINs-1] := Data.PINItems-1;
  end;

  Scaner.SkipDelims;
  if Expression <> dtBoolean then begin
    SynError('ProcessIf', eBooleanExpExpected, 0); Exit;
  end;

  Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-2] := aoJumpIfZero; JumpPIN := Data.PINItems-1;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf <> EndTokenStr[etThen] then begin
    SynError('ProcessIf', eThenExpected, 0); Exit;
  end;

  if Operators(ReturnType) = -1 then SynError('ProcessIf', eUnexpectedBreak, 0);
  if Error then Exit;

{  Inc(TotalExitPINs); SetLength(ExitPINs, TotalExitPINs);
  Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
  Data.PIN[Data.PINItems-2] := aoGoto; ExitPINs[TotalExitPINs-1] := Data.PINItems-1;}

  Data.PIN[JumpPIN] := Data.PINItems+1;

  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  if Scaner.Buf = EndTokenStr[etElseIf] then ProcessIf;
end;

begin
// IF expr THEN ops {ELSEIF expr THEN ops }[ELSE os ]END
  TotalExitPINs := 0; JumpPIN := -1;
  ProcessIf;
  if Error then Exit;
  if Scaner.Buf = EndTokenStr[etElse] then begin
    Inc(TotalExitPINs); SetLength(ExitPINs, TotalExitPINs);
    Inc(Data.PINItems, 2); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-2] := aoGoto; ExitPINs[TotalExitPINs-1] := Data.PINItems-1;
    if Operators(ReturnType) = -1 then SynError('ParseIf', eUnexpectedBreak, 0);
    if not Error then begin
      Scaner.SkipDelims;
      Scaner.ReadChar(ch);
      Scaner.GetIdent(ch);
      if Scaner.Buf = EndTokenStr[etElseIf] then ProcessIf;
//      Inc(TotalExitPINs);
    end;
  end else Dec(Data.PIN[JumpPIN], 2);
  if not Error and (Scaner.Buf <> EndTokenStr[etEnd]) then SynError('ParseIf', eEndExpected, 0);
  if TotalExitPINs >= 1 then for i := 0 to TotalExitPINs-1 do Data.PIN[ExitPINs[i]] := Data.PINItems-1;
  SetLength(ExitPins, 0);
end;

procedure TCompiler.ParseCall(const ProcID: Integer);
var LastParameter: Boolean; CurPar, Op, ExpType: Integer; ch: Char;
begin
// Procname [([Arg] {, Arg} )];
  Scaner.SkipDelims; Scaner.ReadChar(ch);
  CurPar := 0;
  if ch = '(' then begin
    Scaner.SkipDelims; Scaner.ReadChar(ch);
    if ch <> ')' then begin
      Scaner.ReturnChar(ch);
      repeat
        if CurPar >= Data.Procedures[ProcID].Namespace.ParamCount then begin
          SynError('ParseCall', eTooManyParameters, 0);
          Exit;
        end;
        LastParameter := True;

        Op := oAssign;
        ExpType := Expression;
        if Error then Exit;
        if ControlTypes(Op, Data.Variables[Data.Procedures[ProcID].Namespace.Variables[Curpar]].TypeID, ExpType) = -1 then Exit;
        Scaner.SkipDelims; Scaner.ReadChar(ch);
        if ch = ',' then begin
          LastParameter := False;
//          Scaner.SkipDelims; Scaner.ReadChar(ch);
        end else if ch <> ')' then begin
          SynError('ParseCall', eRightParenthesisExpected, 0);
          Exit;
        end;
        Inc(CurPar);
      until LastParameter or Scaner.EOS;
    end;
  end else Scaner.ReturnChar(ch);                        // ToFix: return procedure reference in this case

  if CurPar <> Data.Procedures[ProcID].Namespace.ParamCount then begin
    SynError('ParseCall', eNotEnoughParameters, 0);
    Exit;
  end;

  if ProcID < TotalStandardProcedures then begin
    Inc(Data.PINItems, 1); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-1] := Data.Procedures[ProcID].CommandID;
  end else begin
    Inc(Data.PINItems, 3); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-3] := dtInt; Data.PIN[Data.PINItems-2] := Data.Procedures[ProcID].Index;
    Data.PIN[Data.PINItems-1] := aoCall;
  end;
end;

function TCompiler.Operators(ReturnType: Integer): Integer;
var i, Op, Operation, IdentID, IdentOfs, ExpType, ReturnOp, IdentKind: Integer; ch: Char;
begin
  Result := 0;
  Scaner.SkipDelims;
  while (not Error) and Scaner.ReadChar(ch) do begin
    if ch = ';' then begin Scaner.SkipDelims; Continue; end;
    if Scaner.isAlpha(ch) then begin
      Scaner.GetIdent(ch);
      Op := GetOperator(Scaner.Buf);
      if Op >= 0 then begin
        case Op of
          1: ParseLoop(ReturnType);
          2: ParseWhile(ReturnType);
          3: ParseRepeat(ReturnType);
          4: ParseFor(ReturnType);
          5: ParseIf(ReturnType);
          6: if LoopCount > 0 then begin                       // Exit operator
            Inc(Data.PINItems); SetLength(Data.PIN, Data.PINItems);
            Data.PIN[Data.PINItems-1] := aoExit;
          end else SynError('Operators', eUnexpectedBreak, 0);
          7: if ReturnType = rtModule then SynError('Operators', eUnexpectedReturn, 0) else begin
            Scaner.SkipDelims;
            if ReturnType <> rtProcedure then begin
              Operation := oAssign;
              ExpType := Expression;
              if Error then Exit;
              if ControlTypes(Operation, ReturnType, ExpType) = -1 then Exit;
              ReturnOp := aoReturnF;
            end else ReturnOp := aoReturnP;
            Inc(Data.PINItems, 3); SetLength(Data.PIN, Data.PINItems);
            Data.PIN[Data.PINItems-3] := ReturnOp;
            Data.PIN[Data.PINItems-2] := CurNamespace.ParamCount;          // Number of parameters
            Data.PIN[Data.PINItems-1] := CurNamespace.StackLength div 4;   // Size of all local data
          end;
        end;
      end else if CheckEnd(Scaner.Buf) <> -1 then begin
        Scaner.ReturnBuf(Scaner.Buf);
        Break;
      end else begin
        IdentID := CheckIdent(Scaner.Buf, CurNamespace, True, IdentKind);
        if (IdentID <> -1) then begin
          if (IdentKind and ProcMask > 0) then begin
            if Data.Procedures[IdentID and not AllMask].TypeID <> -1 then begin
              SynError('Operators', eMustBeProcedure, 0);
              Exit;
            end;
            ParseCall(IdentID);
          end else if (IdentKind and ResWordMask > 0) then begin
            SynError('Operators', eUnexpectedResWord, 0); Exit;
          end else if (IdentKind and VarMask > 0) then ParseAssign(IdentID, IdentOfs);
        end else begin
          SynError('Operators', eUndeclaredIdentifier, 0); Exit;
        end;
      end;
    end else begin Scaner.ReturnChar(ch); ParseAssign(-1, 0); end;               // ?
    Scaner.SkipDelims;
  end;
end;

function TCompiler.GetDeclaration(Buf: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to TotalDeclarations-1 do if Buf = DeclarationStr[i] then begin
    Result := i; Exit;
  end;
end;

{function TCompiler.GetTypeKind(TID: Integer): Integer;
begin
  Result := -1;
  if TID = -1 then Exit;
  if TID < TotalSTDTypes then Result := TypeKind[TID] else begin
    case Data.Types[TID].Kind of
      tkCommon: Result := GetTypeKind(Data.Types[TID].ID);
      tkArray: Result := dtArray;
      tkRecord: Result := dtRecord;
      tkPointer: Result := dtPointer;
      tkProcedure: Result := dtProcedure;
    end;
  end;
end;}

function TCompiler.GetType(Buf: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to Data.TotalTypes-1 do if Buf = Data.Types[i].Name then begin
    Result := i; Exit;
  end;
end;

function TCompiler.ParseTypeDef(TypeName: TName; AlwaysNew: Boolean): Integer;
// Returns type ID of existing or just created type
// TypeDef = Ident | ARRAY [n] OF Type | RECORD ... END | POINTER TO TYPE | ProcDef
var ch: Char; OldNS, NS: PNamespace; T: PType;

  function ParseArray: Integer;
  // Parses ARRAY [Len {, Len}] OF Type
  var
    Dims: array of Integer; TotalDims: Integer; ch: Char; TID: Integer;
    T: PType;
  begin
    T := AddType(TypeName);
    Result := Data.TotalTypes-1;

    TotalDims := 1; SetLength(Dims, TotalDims);
    if not isInteger(ConstantExpression(Dims[TotalDims-1])) then SynError('ParseArray', eIntExpExpected, 0);
    if Dims[TotalDims-1] < 0 then SynError('ParseArray', ePositiveIntExpExpected, 0);
    if Error then Exit;
    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    Scaner.GetIdent(ch);
    if Scaner.Buf <> 'OF' then begin
      SynError('ParseArray', eOfExpected, 0);
      Exit;
    end;
    TID := ParseTypeDef('$internal$', False);
    if TID = -1 then begin SynError('ParseArray', eUnknownType, TID); Exit; end;

    T.Kind := tkArray;
    T.Dimension := Dims[TotalDims-1];
    T.Size := T.Dimension * Data.Types[TID].Size;
    T.ID := TID;
  end;

  function ParseRecord: Integer;
  // Returns size of record
  // Parses: RECORD ["(" Base type ")"] Fields {";" [Fields]} END
  var ch: Char;
  begin
    T := AddType(TypeName);
    Result := Data.TotalTypes-1;
    NS := NewNamespace(TypeName);
    T.Namespace := NS;
    T.Kind := tkRecord;
    NS.Kind := nskRecord;
    if CurNamespace.Kind = nskRecord then NS.Parent := CurNamespace;
    OldNS := CurNamespace;
    CurNamespace := NS;

    T.Size := ParseVar;
    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    while (ch = ';') or Scaner.isDelim(ch) do Scaner.ReadChar(ch);
    Scaner.GetIdent(ch);
    if Scaner.Buf <> 'END' then SynError('ParseRecord', eEndExpected, 0);

    CurNamespace := OldNS;
  end;

  function ParsePointer: Integer;
  var ch: Char;
  // TO <array or record type>
  begin
    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    Scaner.GetIdent(ch);
  //  if Scaner.Buf
  end;

  function ParseProcType: Integer;
  begin
  end;

begin
  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  Result := GetType(Scaner.Buf);
  if Result <> -1 then begin
    if AlwaysNew then begin
      T := AddType(TypeName);
      T.Kind := tkCommon;
      T.ID := Result;
    end;
  end else if Scaner.Buf = 'ARRAY' then begin
    Result := ParseArray;
  end else if Scaner.Buf = 'RECORD' then begin
    Result := ParseRecord;
  end else if Scaner.Buf = 'POINTER' then ParsePointer
   else if Scaner.Buf = 'PROCEDURE' then ParseProcType
    else SynError('ParseTypeDef', eUnknownType, 0);
end;

procedure TCompiler.ParseType;
// TYPE {Ident = TypeDef}
// TypeDef = Ident | ARRAY [n] OF Type | RECORD ... END | POINTER TO TYPE | ProcDef
var
  TypeEnd: Boolean; ch: Char;
  i, Ident, IdentOfs, TID, IdentKind: Integer; TypeName: TName;
begin
  repeat
    TypeEnd := True;

    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    Scaner.GetIdent(ch);
    IdentOfs := 0;
    Ident := CheckIdent(Scaner.Buf, CurNamespace, False, IdentKind);
    if Ident <> -1 then begin
      SynError('ParseType', eIdentRedeclared, Ident);
      Break;
    end;
    TypeName := Scaner.Buf;

    Scaner.SkipDelims;
    Scaner.ReadChar(ch);

    if (ch <> '=') then SynError('ParseType', eEqualExpected, 0) else begin
      TID := ParseTypeDef(TypeName, True);
    end;

    AddIdent(ikType, TypeName, TID, 0);

    if Error then Exit;

    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    if ch <> ';' then SynError('ParseType', eSemicolonExpected, 0);
    while ch = ';' do Scaner.ReadChar(ch);
    Scaner.ReturnChar(ch);

    if not Error then begin
      Scaner.SkipDelims;
      Scaner.ReadChar(ch);
      if Scaner.isAlpha(ch) then begin
        Scaner.GetIdent(ch);
        if (Scaner.Buf <> 'BEGIN') and (Scaner.Buf <> 'END') and (GetDeclaration(Scaner.Buf) = -1) then TypeEnd := False;
        Scaner.ReturnBuf(Scaner.Buf);
      end else SynError('ParseType', eUnexpectedSimbol, Ord(ch));
    end;
  until TypeEnd or Scaner.EOS or Error;
end;

function TCompiler.ParseVarSection: Integer;
// Parses variable section and returns size of all declared variables
// ident1, ident2, ... : Type;
var ch: Char; ListEnd: Boolean;
var i, j, Ident, IdentOfs, OldTotalVars, NSOldTotalVars, VarCount, TID, IdentKind: Integer;
begin
  Result := 0;
  OldTotalVars := Data.TotalVariables;
  NSOldTotalVars := CurNamespace.TotalVariables;
  VarCount := 0;
  repeat
    ListEnd := True;
    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    Scaner.GetIdent(ch);
    IdentOfs := 0;
    Ident := CheckIdent(Scaner.Buf, CurNamespace, False, IdentKind);
    if Ident <> -1 then begin
      SynError('ParseVarSection', eIdentRedeclared, Ident);
      Break;
    end;

    AddIdent(ikVariable, Scaner.Buf, 0, 0);

    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    if ch = ',' then ListEnd := False;
    Inc(VarCount);
  until ListEnd or Scaner.EOS or Error;

  if not Error and (ch <> ':') then SynError('ParseVarSection', eColonExpected, 0);
  if not Error then begin
    TID := ParseTypeDef('$internal$', False);
    if TID = -1 then begin SynError('ParseVarSection', eUnknownType, TID); Exit; end;
  end;

  if Error then begin
    Data.TotalVariables := OldTotalVars;
    CurNamespace.TotalVariables := NSOldTotalVars;
    SetLength(Data.Variables, Data.TotalVariables);
    Exit;
  end;

  for i := OldTotalVars to OldTotalVars+VarCount-1 do begin
    Inc(Result, GetTypeSize(TID));
    if (CurNamespace.Kind = nskModule) or (CurNamespace.Kind = nskRecord) then begin
      if GetExternalVarIndex(Data.Variables[i].Name) <> -1 then
       Data.Variables[i].Index := AllocateData(0, 0) else begin
         Data.Variables[i].Index := AllocateData(GetTypeSize(TID), 0);
         SetVarLocation(Data.Variables[i], ilGlobal);
       end;
    end else begin
      Data.Variables[i].Index := AllocateStack(GetTypeSize(TID));
      SetVarLocation(Data.Variables[i], ilStack);
    end;
    Data.Variables[i].TypeID := TID;
  end;
end;

function TCompiler.ParseVar: Integer;
// Parses: {ident { , ident}: Type ;}
// Returns size of all declared variables
var VarEnd: Boolean; ch: Char;
begin
  Result := 0;
  repeat
    VarEnd := True;

    Inc(Result, ParseVarSection);

    if Error then Exit;

    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    if ch <> ';' then SynError('ParseVar', eSemicolonExpected, 0);
    while ch = ';' do Scaner.ReadChar(ch);
    Scaner.ReturnChar(ch);

    if not Error then begin
      Scaner.SkipDelims;
      Scaner.ReadChar(ch);
      if Scaner.isAlpha(ch) then begin
        Scaner.GetIdent(ch);
        if (Scaner.Buf <> 'BEGIN') and (Scaner.Buf <> 'END') and (GetDeclaration(Scaner.Buf) = -1) then VarEnd := False;
        Scaner.ReturnBuf(Scaner.Buf);
      end else SynError('ParseVar', eUnexpectedSimbol, Ord(ch));
    end;
  until VarEnd or Scaner.EOS or Error;
end;

procedure TCompiler.ParseConst;
var
  ConstEnd: Boolean; ch: Char;
  i, Ident, IdentOfs, TID, ExpStartPIN, ExpResult, IdentKind: Integer; ConstName: TName;
begin
// CONST {ident = Expression}
  repeat
    ConstEnd := True;

    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    Scaner.GetIdent(ch);
    IdentOfs := 0;
    Ident := CheckIdent(Scaner.Buf, CurNamespace, False, IdentKind);
    if Ident <> -1 then begin
      SynError('ParseConst', eIdentRedeclared, Ident);
      Break;
    end;
    ConstName := Scaner.Buf;

    Scaner.SkipDelims;
    Scaner.ReadChar(ch);

    if (ch = '=') then TID := ConstantExpression(ExpResult) else SynError('ParseConst', eEqualExpected, 0);

    if Error then Exit;

    AddIdent(ikConstant, ConstName, TID, ExpResult);

    Scaner.SkipDelims;
    Scaner.ReadChar(ch);
    if ch <> ';' then SynError('ParseConst', eSemicolonExpected, 0);
    while ch = ';' do Scaner.ReadChar(ch);
    Scaner.ReturnChar(ch);

    if not Error then begin
      Scaner.SkipDelims;
      Scaner.ReadChar(ch);
      if Scaner.isAlpha(ch) then begin
        Scaner.GetIdent(ch);
        if (Scaner.Buf <> 'BEGIN') and (Scaner.Buf <> 'END') and (GetDeclaration(Scaner.Buf) = -1) then ConstEnd := False;
        Scaner.ReturnBuf(Scaner.Buf);
      end else SynError('ParseConst', eUnexpectedSimbol, Ord(ch));
    end;
  until ConstEnd or Scaner.EOS or Error;
end;

procedure TCompiler.ParseProc;
var ch: Char; Ident, IdentOfs, FuncType, IdentKind: Integer; ProcName: string[128];
// PROCEDURE ident [ "(" [[var] Vars {";" [var] Vars}] ")" [":" Type] ] ";"
// Declarations BEGIN ops END ident

function ParseFormalPars: Integer;
// "(" [[var] Vars {";" [var] Vars}] ")" [":" Type]
var LastParameter: Boolean;
begin
  Result := rtProcedure;
  Scaner.SkipDelims; Scaner.ReadChar(ch);
  if ch = '(' then begin
    Scaner.SkipDelims; Scaner.ReadChar(ch);
    if ch <> ')' then repeat
      LastParameter := True;
      if not Scaner.isAlpha(ch) then begin
        SynError('ParseFormalPars', eUnexpectedSimbol, 0);
        Exit;
      end;
      Scaner.GetIdent(ch);
      if Scaner.Buf = 'VAR' then  else Scaner.ReturnBuf(Scaner.Buf);
      ParseVarSection;
      Scaner.SkipDelims; Scaner.ReadChar(ch);
      if ch = ';' then begin
        LastParameter := False;
        Scaner.SkipDelims; Scaner.ReadChar(ch);
      end;
    until LastParameter;
  end else Scaner.ReturnChar(ch);
  Scaner.SkipDelims; Scaner.ReadChar(ch);
  if ch = ':' then begin
    Result := ParseTypeDef('$internal$', False);
    if Result = -1 then SynError('ParseFormalPars', eUnknownType, Result);
  end else Scaner.ReturnChar(ch);
end;

begin
// Procedure header
  Scaner.SkipDelims;
  Scaner.ReadChar(ch);
  Scaner.GetIdent(ch);
  IdentOfs := 0;
  Ident := CheckIdent(Scaner.Buf, CurNamespace, False, IdentKind);
  if Ident <> -1 then begin
    SynError('ParseProc', eIdentRedeclared, Ident);
    Exit;
  end;
  ProcName := Scaner.Buf;
  AddNameSpace(ProcName);
  CurNamespace.Kind := nskProcedure;

  CurNamespace.Parent.Procedures[CurNamespace.Parent.TotalProcedures-1].ID := Data.TotalProcedures;

  AddIdent(ikProcedure, ProcName, 0, Data.PINItems);                   // Procedure identifier

  FuncType := ParseFormalPars;                                    // Procedure result type
  Data.Procedures[Data.TotalProcedures-1].TypeID := FuncType;
  CurNamespace.ParamCount := CurNamespace.TotalVariables;              // Parameters count
  if Error then Exit;
  Scaner.SkipDelims; Scaner.ReadChar(ch);
  if ch <> ';' then begin SynError('ParseProc', eSemicolonExpected, 0); Exit; end;
// Procedure body
  Inc(CurNamespace.StackLength, 2*SizeOf(TStackItem));
  CompileBlock(FuncType); if Error then Exit;

  if (FuncType = rtProcedure) and (Data.PINItems >= 3) and (Data.PIN[Data.PINItems-3] <> aoReturnP) then begin
    Inc(Data.PINItems, 3); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-3] := aoReturnP;
    Data.PIN[Data.PINItems-2] := CurNamespace.ParamCount;           // Number of parameters
    Data.PIN[Data.PINItems-1] := CurNamespace.StackLength div 4;    // Length of all local data
  end else
   if (Data.PINItems >= 3) and (Data.PIN[Data.PINItems-3] <> aoReturnF) and (FuncType <> -1) then Synerror('ParseProc', eReturnExpected, 0);

  Scaner.SkipDelims; Scaner.ReadChar(ch); Scaner.GetIdent(ch);
  if Scaner.Buf <> ProcName then SynError('ParseProc', eProcNameMismatch, 0);

//  Inc(CurNamespace.Parent.StackLength, CurNamespace.StackLength);
  CurNamespace := CurNamespace.Parent;
end;

function TCompiler.Declarations: Integer;
var i, D: Integer; ch: Char;
begin
// { CONST {ÎáúÿâëÊîíñò ";" } | TYPE {ÎáúÿâëÒèïà ";" } | VAR {ÎáúÿâëÏåðåì ";" }} {ÎáúÿâëÏðîö ";" | ÎïåðåæàþùååÎáúÿâ";"}.
  Result := 0;
  Scaner.SkipDelims;
  while (not Error) and Scaner.ReadChar(ch) do begin
    if ch = ';' then begin Scaner.SkipDelims; Continue; end;
    if Scaner.isAlpha(ch) then begin
      Scaner.GetIdent(ch);
      D := GetDeclaration(Scaner.Buf);
      case D of
        dVar: ParseVar;
        dConst: ParseConst;
        dType: ParseType;
        dProc: ParseProc;
        else if (Scaner.Buf = 'BEGIN') or (CheckEnd(Scaner.Buf) <> -1) then begin
          Scaner.ReturnBuf(Scaner.Buf);
          Break;
        end else SynError('Declarations', eBeginExpected, Ord(ch));
      end;
    end else SynError('Declarations', eBeginExpected, Ord(ch));
    Scaner.SkipDelims;
  end;
end;

function TCompiler.isNumeric(AType: Integer): Boolean;
begin
  Result := AType in [dtInt8..dtReal];
end;

function TCompiler.isInteger(AType: Integer): Boolean;
begin
  Result := AType in [dtInt8..dtNat];
end;

function TCompiler.isReal(AType: Integer): Boolean;
begin
  Result := AType in [dtSingle..dtReal];
end;

function TCompiler.ControlTypes(var Operation: Integer; Type1, Type2: Integer): Integer;
begin
  Result := -1;
  case Operation of
    oAdd, oSub, oMul: begin
      if (Type1 = dtSet) and (Type2 = dtSet) then begin
        Result := dtSet; Operation := Operation + 104;
      end else if not (isNumeric(Type1) and isNumeric(Type2)) then SynError('ControlTypes', eIncompatibleTypes, Type1+Type2 shl 8) else begin
        if isInteger(Type1) and isInteger(Type2) then Result := dtInt else Result := dtReal;
        Inc(Operation, Byte(isReal(Type1))*2+Byte(isReal(Type2)));
      end;
    end;
    oDiv: begin
      if (Type1 = dtSet) and (Type2 = dtSet) then begin
        Result := dtSet; Operation := Operation + 104;
      end else if (isNumeric(Type1) and isNumeric(Type2)) then begin
        Result := dtReal;
        Inc(Operation, Byte(isReal(Type1))*2+Byte(isReal(Type2)));
      end else
       SynError('ControlTypes', eIncompatibleTypes, Type1+Type2 shl 8);
    end;
    oIDiv, oMod: if (isInteger(Type1) and isInteger(Type2)) then Result := dtInt else
                    SynError('ControlTypes', eIncompatibleTypes, Type1+Type2 shl 8);
    oOr, oAnd: begin
      if (isInteger(Type1) and isInteger(Type2)) then Result := dtInt else
       if (Type1 = dtBoolean) and (Type2 = dtBoolean) then begin Result := dtBoolean; Inc(Operation); end else
        SynError('ControlTypes', eIncompatibleTypes, Type1+Type2 shl 8);
    end;
    oInv: if IsInteger(Type1) then begin
      Result := dtInt; Operation := aoInvI;
    end else if Type1 = dtBoolean then begin
      Result := dtBoolean; Operation := aoInvB;
    end else SynError('ControlTypes', eIncompatibleTypes, Type1);
    oNeg: if Type1 = dtSet then begin
        Result := dtSet; Operation := Operation + 102;
      end else if IsNumeric(Type1) then begin
      if isReal(Type1) then begin Result := dtReal; Inc(Operation); end else Result := dtInt; 
    end else SynError('ControlTypes', eIncompatibleTypes, Type1);
    rEqual, rNotEqual: begin
      if (isNumeric(Type1) and isNumeric(Type2)) or (Type1 = Type2) then begin
        Result := dtBoolean;
        Inc(Operation, Byte(isReal(Type1))*2+Byte(isReal(Type2)));
      end else SynError('ControlTypes', eIncompatibleTypes, Type1+Type2 shl 8);
    end;
    rGreater..rLessEqual: begin
      if (isNumeric(Type1) and isNumeric(Type2)) or (Type1 = dtChar) and (Type2 = dtChar) or
         (Type1 = dtString) and (Type2 = dtString) then begin
        Result := dtBoolean;
        Inc(Operation, Byte(isReal(Type1))*2+Byte(isReal(Type2)));
      end else SynError('ControlTypes', eIncomparableTypes, Type1+Type2 shl 8);
    end;
    rIN: if isInteger(Type1) and (Type2 = dtSet) then begin
      Result := dtBoolean;
    end else SynError('ControlTypes', eIncomparableTypes, Type1+Type2 shl 8);
    oAssign: begin
      if (Type1 = Type2) or
         isInteger(Type1) and isInteger(Type2) and (Type1 >= Type2) or
         isReal(Type1) and isReal(Type2) and (Type1 >= Type2) then begin
           Result := Type1;
           case Data.Types[Type1].Size of
             1: Operation := aoAssign1;
             2: Operation := aoAssign2;
             4: Operation := aoAssign4;
             else Operation := aoAssignSize;
           end;
         end else if isReal(Type1) and isInteger(Type2) then begin
           case Data.Types[Type1].Size of
             4: Operation := aoAssign4RI;
             else Operation := aoAssignSize;
           end;
           Result := Type1;
         end else SynError('ControlTypes', eIncompatibleTypes, Type1+Type2 shl 8);
    end;
  end;
end;

function TCompiler.CompileBlock(ReturnType: Integer): Integer;
var ch: Char; i, ProcIndex, TID, ExtIndex: Integer;   // Index of current procedure
begin
  Result := -1;
  ProcIndex := Data.TotalProcedures-1;
  Declarations; if Error then Exit;

// Initialize external variables
  Data.ExternalVarsOfs := Data.TotalVariables;
  if CurNamespace.Kind = nskModule then for i := 0 to Data.TotalExternalVariables-1 do begin
    TID := GetType(ExternalVars[i].VarType);
    if TID = -1 then begin
      SynError('Compile', eExternalVarUnknownType, 0);
      Exit;
    end;
    ExtIndex := AddIdent(ikVariable, ExternalVars[i].VarName, TID, 0);
    if ExtIndex <> -1 then begin
      Data.Variables[ExtIndex].Index := Integer(ExternalVars[i].VarAddress);
      SetVarLocation(Data.Variables[ExtIndex], ilExternal);
    end;  
  end;

  Scaner.SkipDelims; Scaner.ReadChar(ch); Scaner.GetIdent(ch);
  if Scaner.Buf = 'END' then Exit;
  if Scaner.Buf <> 'BEGIN' then begin SynError('Compile', eBeginExpected, 0); Exit; end;
  if CurNamespace.Parent = nil then Data.EntryPIN := Data.PINItems else begin
    Data.Procedures[ProcIndex].Index := Data.PINItems;

    Inc(Data.PINItems, 4); SetLength(Data.PIN, Data.PINItems);
    Data.PIN[Data.PINItems-4] := aoSetStackBase;
    Data.PIN[Data.PINItems-3] := Data.Procedures[ProcIndex].Namespace.ParamCount;   
    Data.PIN[Data.PINItems-2] := aoExpandStack;
    Data.PIN[Data.PINItems-1] := Data.Procedures[ProcIndex].Namespace.StackLength div 4-Data.Procedures[ProcIndex].Namespace.ParamCount;

{    SetLength(Data.PIN, Data.PINItems+(Data.Procedures[ProcIndex].Namespace.ParamCount)*3);
    for i := 0 to Data.Procedures[ProcIndex].Namespace.ParamCount - 1 do begin
      Data.PIN[Data.PINItems] := aoParamLoad;
      Data.PIN[Data.PINItems + 1] := Data.Procedures[ProcIndex].Namespace.Variables[i];
      Data.PIN[Data.PINItems + 2] := Data.Procedures[ProcIndex].Namespace.ParamCount-1-i;
      Inc(Data.PINItems, 3);
    end;}
  end;

  if Operators(ReturnType) = -1 then SynError('Compile', eUnexpectedBreak, 0);
  if Error then Exit;
  Scaner.SkipDelims; Scaner.ReadChar(ch); Scaner.GetIdent(ch);
  if Scaner.Buf <> 'END' then SynError('Compile', eEndExpected, 0);
end;

function TCompiler.Compile: Integer;
var i: Integer; OldScaner, TempScaner: TScaner;
begin
  Error := False;
  AddNamespace('Module');
  Data.Namespace := CurNamespace;

  // Add standard procedure to the namespace
  for i := 0 to TotalSTDTypes - 1 do AddType(TypeStr[i]);
  TempScaner := TScaner.Create(
    'PROCEDURE SIN(Angle: REAL): REAL; BEGIN RETURN 0; END SIN;' +
    'PROCEDURE COS(Angle: REAL): REAL; BEGIN RETURN 0; END COS;' +
    'PROCEDURE TAN(Angle: REAL): REAL; BEGIN RETURN 0; END TAN;' +
    'PROCEDURE ARCTAN(X: REAL): REAL; BEGIN RETURN 0; END ARCTAN;' +
    'PROCEDURE SQRT(X: REAL): REAL; BEGIN RETURN 0; END SQRT;' +
    'PROCEDURE INVSQRT(X: REAL): REAL; BEGIN RETURN 0; END INVSQRT;' +
    'PROCEDURE RND: REAL; BEGIN RETURN 0; END RND;' +
    'PROCEDURE ENTIER(X: REAL): INTEGER; BEGIN RETURN 0; END ENTIER;' +
    'PROCEDURE LN(X: REAL): REAL; BEGIN RETURN 0; END LN;' +
    'PROCEDURE BLEND(Color1, Coor2: INTEGER; K: REAL): INTEGER; BEGIN RETURN 0; END BLEND;'
  );
  OldScaner := Scaner;
  Scaner := TempScaner;
  Declarations;
  Scaner := OldScaner;
  TempScaner.Free;

  if Error then Exit;

  for i := 0 to TotalStandardProcedures-1 do
   Data.Procedures[CurNamespace.Procedures[i].ID].CommandID := StandardProcedureCommandIDs[i];
//  Assert(not Error, 'TCompiler.Compile: Error in standard procedures initialization');

{  AddIdent(ikConstant, 'one', dtInt, 1);
  AddIdent(ikConstant, 'TRUE', dtBoolean, 1);
  AddIdent(ikConstant, 'FALSE', dtBoolean, 0);
  AddIdent(ikVariable, 'z', dtBoolean, 1);
  AddIdentS(ikVariable, 'y', dtReal, 2.5);
  AddIdent(ikVariable, 'x', dtInt, 0);
  AddIdent(ikVariable, 'set1', dtSET, $FFFF);
  AddIdent(ikVariable, 'set2', dtSET, $FFFF00);}

  CompileBlock(rtModule);
//  Result := Expression;
end;

function TCompiler.ComputeExpression(StartPIN: Integer): Integer;
// Computes expression located between StartPIN and Data.PINItems
// Returns expression result value
var i: Integer;
begin
  LocalVM := TOberonVM.Create;                             // ToFix: Copy from VM data, strings, etc...
  LocalVM.Data.Constants := Data.Constants;
  LocalVM.Data.TotalConstants := Data.TotalConstants;
  LocalVM.Data.PINItems := Data.PINItems - StartPIN;
  SetLength(LocalVM.Data.PIN, LocalVM.Data.PINItems);
  for i := StartPIN to Data.PINItems-1 do LocalVM.Data.PIN[i-StartPIN] := Data.PIN[i];
  Result := LocalVM.Compute;
  LocalVM.Free;
end;

function TCompiler.AllocateData(const DataSize, Value: Integer): Integer;
begin
  Result := Data.DataLength;
  Inc(Data.DataLength, DataSize); SetLength(Data.Data, Data.DataLength);
  if DataSize >= SizeOf(Value) then Int32((@Data.Data[Result])^) := Value;
  Result := Result;
end;

function TCompiler.AllocateStack(const DataSize: Integer): Integer;
begin
  Result := CurNamespace^.StackLength;
  Inc(CurNamespace^.StackLength, DataSize);
end;

function TCompiler.GetTypeSize(const TID: Integer): Integer;
begin
  Result := Data.Types[TID].Size;
{  case Data.Types[TID].Kind of
    dtBoolean, dtChar, dtInt8, dtNat8: Result := 1;
    dtInt16, dtNat16: Result := 2;
    dtInt32, dtInt, dtNat32, dtNat, dtSingle, dtReal, dtSet, dtPointer, dtProcedure: Result := 4;
    dtDouble: Result := 8;
    dtString:;
  end;}
end;

function TCompiler.GetConst(const Index: Integer): Integer;
begin
  case Data.Types[Data.Constants[Index].TypeID].Size of
    1: Result := Data.Data[Data.Constants[Index].Index];
    2: Result := Word((@Data.Data[Data.Constants[Index].Index])^);
    4: Result := Int32((@Data.Data[Data.Constants[Index].Index])^);
  end;
end;

procedure TCompiler.SetVarLocation(var AVar: TIdent; ALocation: Integer);
var i: Integer;
begin
  AVar.Location := ALocation;
  if Data.Types[AVar.TypeID].Namespace <> nil then
    for i := 0 to Data.Types[AVar.TypeID].Namespace.TotalVariables-1 do
      SetVarLocation(Data.Variables[Data.Types[AVar.TypeID].Namespace.Variables[i]], ALocation);
end;

function TCompiler.ImportExternalVar(AName, AType: string; Address: Pointer): Boolean;
begin
  Result := False;
  if GetExternalVarIndex(AName) <> -1 then Exit;
  Inc(Data.TotalExternalVariables); SetLength(ExternalVars, Data.TotalExternalVariables);
  ExternalVars[Data.TotalExternalVariables-1].VarAddress := Address;
  ExternalVars[Data.TotalExternalVariables-1].VarName := AName;
  ExternalVars[Data.TotalExternalVariables-1].VarType := AType;
  Result := True;
end;

function TCompiler.GetExternalVarIndex(AName: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to Data.TotalExternalVariables-1 do if ExternalVars[i].VarName = AName then begin
    Result := i;
    Break;
  end;
end;

destructor TCompiler.Destroy;
// Destroy all, except RTData
begin
  ExternalVars := nil;
  if Namespace <> nil then begin
    ClearNamespace(Namespace);
    Dispose(Namespace);
  end;
  Namespace := nil;
  CurNamespace := nil;
  FreeAndNil(LocalVM);
  FreeAndNil(Data);
  FreeAndNil(Scaner);
  inherited;
end;

end.
