(*
 @Abstract(Compiler types unit)
 (C) 2006-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Started Jul 15, 2004
 The unit contains the compiler basic constants and types
*)
unit OTypes;

interface

uses BaseTypes, SysUtils;

type TToken = (tNone, tIdentifier, tOperator, tExpression, tRelation, tOperation, tEndToken);

const
//  // Types. Must be in size-accending order
  dtBoolean = 0; dtChar = 1;
  dtInt8 = 2; dtInt16 = 3; dtInt32 = 4; dtInt = 5;
  dtNat8 = 6; dtNat16 = 7; dtNat32 = 8; dtNat = 9;
  dtSingle = 10; dtReal = 11; dtDouble = 12;
  dtString = 13;
  dtSet = 14;
  dtArray = 16;
  dtRecord = 17;
  dtPointer = 18;
  dtProcedure = 19;

  dtConstant = 32;
  dtVariable = 33; dtVariableRef = 34; dtVariableByOfs = 35;
  dtStackVariable = 36; dtStackVariableByOfs = 37;
  dtExtVariable = 38; dtExtVariableRef = 39; dtExtVariableByOfs = 40;

// Result types
  rtModule = -2; rtProcedure = -1;

  TotalSTDTypes = 15;
  TypeStr: array[0..TotalSTDTypes-1] of string[8] =
           ('BOOLEAN', 'CHAR',
            'SHORTINT', 'SMALLINT', 'LONGINT', 'INTEGER',
            'SHORTINT', 'SMALLINT', 'LONGINT', 'INTEGER',
            'SINGLE', 'REAL', 'LONGREAL',
            'STRING', 'SET');
//  TypeKind: array[0..TotalSTDTypes-1] of Integer = (dtBoolean, dtChar, dtInt16, dtInt, dtInt32, dtSingle, dtReal, dtDouble, dtString, dtSet);

//  Operations
  oAdd = $80 + 1; oSub = $80 + 5; oMul = $80 + 9; oDiv = $80 + 13; oOr = $80 + 17; oAnd = $80 + 19; oIDiv = $80 + 21; oMod = $80 + 22; oNeg = $80 + 23; oInv = $80 + 26;
  rEqual = $80 + 28; rGreater = $80 + 32; rLess = $80 + 36; rGreaterEqual = $80 + 40; rLessEqual = $80 + 44; rNotEqual = $80 + 48; rIN = $80 + 52; rIS = $80 + 53;
// Operators
  oAssign = $80 + 54;
//  All actions
  aoNull = $80 + 0;
  aoAddII = $80 + 1; aoAddIR = $80 + 2; aoAddRI = $80 + 3; aoAddRR = $80 + 4; aoAddSS = $80 + 105;
  aoSubII = $80 + 5; aoSubIR = $80 + 6; aoSubRI = $80 + 7; aoSubRR = $80 + 8; aoSubSS = $80 + 109;
  aoMulII = $80 + 9;  aoMulIR = $80 + 10; aoMulRI = $80 + 11; aoMulRR = $80 + 12; aoMulSS = $80 + 113;
  aoDivII = $80 + 13; aoDivIR = $80 + 14; aoDivRI = $80 + 15; aoDivRR = $80 + 16; aoDivSS = $80 + 117;
  aoOrII = $80 + 17; aoOrBB = $80 + 18;
  aoAndII = $80 + 19; aoAndBB = $80 + 20;
  aoIDivII = $80 + 21; aoModII = $80 + 22;
  aoNegI = $80 + 23; aoNegR = $80 + 24; aoNegS = $80 + 125;
  aoInvI = $80 + 25; aoInvB = $80 + 26;
//  Relations
  arEqualII = $80 + 28; arEqualIR = $80 + 29; arEqualRI = $80 + 30; arEqualRR = $80 + 31;
  arGreaterII = $80 + 32; arGreaterIR = $80 + 33; arGreaterRI = $80 + 34; arGreaterRR = $80 + 35;
  arLessII = $80 + 36; arLessIR = $80 + 37; arLessRI = $80 + 38; arLessRR = $80 + 39;
  arGreaterEqualII = $80 + 40; arGreaterEqualIR = $80 + 41; arGreaterEqualRI = $80 + 42; arGreaterEqualRR = $80 + 43;
  arLessEqualII = $80 + 44; arLessEqualIR = $80 + 45; arLessEqualRI = $80 + 46; arLessEqualRR = $80 + 47;
  arNotEqualII = $80 + 48; arNotEqualIR = $80 + 49; arNotEqualRI = $80 + 50; arNotEqualRR = $80 + 51;
  arIn = $80 + 52; arIS = $80 + 53;
//  Operators
  aoAssign1 = $80 + 54;
  aoAssign2 = $80 + 55;
  aoAssign4 = $80 + 56; aoAssign4RI = $80 + 57;
  aoAssignSize = $80 + 58;
  aoStackAssign4 = $80 + 59; aoStackAssign4RI = $80 + 60;
  aoStackAssignSize = $80 + 61;
  aoGoto = $80 + 62; aoJumpIfZero = $80 + 63;
  aoCall = $80 + 64; aoReturnF = $80 + 65; aoReturnP = $80 + 66;
  aoExit = $80 + 67;
  aoSetStackBase = $80 + 69;
  aoExpandStack = $80 + 70;
// Operations with external variables for scripting only
  aoExtAssign1 = $80 +  71;
  aoExtAssign2 = $80 +  72;
  aoExtAssign4 = $80 +  73;
  aoExtAssign4RI = $80 + 74;
  aoExtAssignSize = $80 + 75;
// Standard functions
  sfSin = $80 + 76;
  sfCos = $80 + 77;
  sfTan = $80 + 78;
  sfArcTan = $80 + 79;
  sfSqrt = $80 + 80;
  sfInvSqrt = $80 + 81;
  sfRnd = $80 + 82;
  sfEntier = $80 + 83;
  sfLn = $80+84;
  sfBlend = $80+85;

//  aoIndex

// Comments

  TotalComments = 2;
  CommentStr: array[0..TotalComments-1] of record Open, Close: string[10]; end = ((Open: '(*'; Close: '*)'), (Open: '//'; Close: #10));

//  Type modifiers
  tmInt = 0; tmSingle = 256;

  TotalReservedWords = 34;
  ReservedWord: array[0..TotalReservedWords-1] of string[9] = (
   'ARRAY', 'BEGIN', 'BY', 'CASE', 'CONST',
   'DIV', 'DO', 'ELSE', 'ELSEIF', 'END',
   'EXIT', 'FOR', 'IF', 'IMPORT', 'IN',
   'IS', 'LOOP', 'MOD', 'MODULE', 'NIL',
   'OF', 'OR', 'POINTER', 'PROCEDURE', 'RECORD',
   'REPEAT', 'RETURN', 'THEN', 'TO', 'TYPE',
   'UNTIL', 'VAR', 'WHILE', 'WITH' );

  TotalStandardProcedures = 10;
  StandardProcedureCommandIDs: array[0..TotalStandardProcedures-1] of Integer = (
    sfSin, sfCos, sfTan, sfArcTan, sfSqrt, sfInvSqrt, sfRnd, sfEntier, sfLn, sfBlend
  );

  TotalOperations1 = 3;
  Op1Str: array[0..TotalOperations1-1] of string[3] = ('+', '-', 'OR');
  Op1ID: array[0..TotalOperations1-1] of Cardinal = (oAdd, oSub, oOr);

  TotalOperations2 = 5;
  Op2Str: array[0..TotalOperations2-1] of string[3] = ('*', '/', '&', 'DIV', 'MOD');
  Op2ID: array[0..TotalOperations2-1] of Cardinal = (oMul, oDiv, oAnd, oIDiv, oMod);

  TotalUnarOperations = 2;
  UnarOpStr: array[0..TotalUnarOperations-1] of string[3] = ('-', '~');
  UnarOpID: array[0..TotalUnarOperations-1] of Cardinal = (oNeg, oInv);

  TotalRelations = 8;
  RelationStr: array[0..TotalRelations-1] of string[2] = ('=', '>', '<', '>=', '<=', '#', 'IN', 'IS');
  RelationID: array[0..TotalRelations-1] of Cardinal = (rEqual, rGreater, rLess, rGreaterEqual, rLessEqual, rNotEqual, rIN, rIS);

  TotalEndTokens = 9;
  EndTokenStr: array[0..TotalEndTokens-1] of string[5] = ('END', 'DO', 'UNTIL', 'TO', 'EXIT', 'THEN', 'ELSIF', 'ELSE', 'OF');
  etEnd = 0; etDo = 1; etUntil = 2; etTo = 3; etExit = 4; etThen = 5; etElseIf = 6; etElse = 7;

  TotalOperators = 8;
  OperatorStr: array[0..TotalOperators-1] of string[6] = (':=', 'LOOP', 'WHILE', 'REPEAT', 'FOR', 'IF', 'EXIT', 'RETURN');
  opAssign = 0; opLopp = 1; opWhile = 2; opRepeat = 3; opFor = 4; opIf = 5; opExit = 6; opReturn = 7;

  TotalDeclarations = 4;
  DeclarationStr: array[0..TotalDeclarations-1] of string[9] = ('VAR', 'CONST', 'TYPE', 'PROCEDURE');
  dVar = 0; dConst = 1; dType = 2; dProc = 3;

  eeSum = 1; exExpression = 2; exOperation = 3; exRelation = 4;
// Compile errors
  eUnexpectedOperation = 1; eUnexpectedExpression = 2; eUnexpectedNumber = 3;
  eUnexpectedExpEnd = 4; eUnexpectedSimbol = 5; eUnexpectedOperator = 6;
  eUnexpectedIdentifier = 7;
  eUndeclaredIdentifier = 8;
  eIncompatibleTypes = 9;
  eIncomparableTypes = 10;
  eCannotAssign = 11;
  eUnexpectedSequenceEnd = 12;
  eSequenceEndNotFound = 13;
  eVariableExpected = 14;
  eAssignationExpected = 15;
  eUntilExpected = 16;
  eDoExpected = 17;
  eToExpected = 18;
  eEndExpected = 19;
  eThenExpected = 20;
  eBooleanExpExpected = 21;
  eUnexpectedBreak = 22;
  eIdentRedeclared = 23;
  eUnknownType = 24;
  eColonExpected = 25;
  eSemicolonExpected = 26;
  eEqualExpected = 27;
  eBeginExpected = 28;
  eOperationExpected = 29;
  eRightParenthesisExpected = 30;
  eRightBraceExpected = 31;
  eProcNameMismatch = 32;
  eNotEnoughParameters = 33;
  eTooManyParameters = 34;
  eMustBeFunction = 35;
  eMustBeProcedure = 36;
  eUnexpectedReturn = 37;
  eReturnExpected = 38;
  eConstExpExpected = 39;
  eInternalError = 40;
  eIntExpExpected = 41;
  ePositiveIntExpExpected = 42;
  eOfExpected = 43;
  eRightBracketExpected = 44;
  eUnexpectedResWord = 45;
  eExternalVarUnknownType = 46;
  eInvalidNumber = 47;
  TotalErrors = 47;
// Runtime errors
  rteRangeError = 1; rteStackEmpty = 2;

  ikConstant = 0; ikVariable = 1; ikProcedure = 2; ikType = 3;
  
  TypeToStr: array[1..15] of string[10] = ('Boolean', 'Char', 'Int8', 'Int16', 'Int32', 'Int',
    'Nat8', 'Nat16', 'Nat32', 'Nat', 'Single', 'Double', 'Real', 'String', 'Set');

// Namespace kind
  nskModule = 0; nskProcedure = 1; nskRecord = 2;
// Type kind
  tkCommon = 0; tkArray = 1; tkRecord = 2; tkPointer = 3; tkProcedure = 4;
// Ident location
  ilGlobal = 0; ilStack = 1; ilExternal = 2;

type
  Int8  = ShortInt; Int16 = SmallInt; Int32 = LongInt;  Int = Integer;
  Nat8  = Byte;     Nat16 = Word;     Nat32 = LongWord; Nat = Cardinal;
  TName = string[32];

  TPINItem = Integer;
  TPIN = array of TPINItem;

  PNamespace = ^TNamespace;
  PType = ^TType;

  TNamespace = record
    Name: TName;                     // Name of module, record or procedure
    UID: Integer;                    // Unique namespace ID (for saving/loading namespaces)
    Kind: Int32;                     // Module, procedure or record
    ParamCount: Int32;               // Only for procedures: number of parameters
    ID: Int32;                       // Index in Data.Procedures
    StackLength: Int32;              // Length of variables declared local and in all child namespaces
    TotalConstants, TotalVariables, TotalProcedures, TotalTypes: Int32;
    Constants, Variables, Types: array of Longword;
    Procedures: array of PNameSpace;
    Parent: PNamespace;
  end;

  TType = record
    Name: TName;
    Kind: Int32;                     // Type kind
    ID: Int32;                       // Index of arrays base type, or index in Types[] in case of simple type 
    Dimension, Size: Int32;          // Dimension of array (if the type is array) and size of the entire type
    Namespace: PNamespace;           // In case of record type record's namespace
  end;

  TIdent = packed record
    Name: TName;
    TypeID, Location, ExportMode, Index: Int32;
    Namespace: PNamespace;           // Namespace where identifier is declared
  case StdProcedure: Boolean of
    True: (CommandID: Integer);
    False: (Size: Integer);
  end;
  TIdents = array of TIdent;

  TCompilationError = record
    Source: string;
    Number, Line, Position: Integer;
    Data: Integer;
  end;

  TDataPool = array[0..MaxInt-1] of Byte;
  PDataPool = ^TDataPool;

  TRTData = class
    PIN: TPIN; PINItems: Integer;
    EntryPIN: Integer;                                      // First command index
    Namespace: PNamespace;                                  // Root namespace
    BaseData: PDataPool;
    Data: array of Byte;                                    // Dynamic data pool
    DataLength: Int32;                                      // Dynamic data pool size
    Constants, Variables, Procedures: TIdents;
    Types: array of PType;
    TotalConstants, TotalVariables, TotalProcedures, TotalTypes: Int32;
    TotalExternalVariables, ExternalVarsOfs: Int32;
    destructor Destroy; override;
  end;

  function GetVTypeInt(Value: Int32): Int32;

implementation

function GetVTypeInt(Value: Int32): Int32;
begin
  case Value of
//    0..$FF: Result := etNat8;
//    $FF+1..$FFFF: Result := etNat16;
//    $FFFF+1..$80000000-1: Result := etNat32;
    -$80..$80-1: Result := dtInt8;
    -$8000..-$81, $80..$8000-1: Result := dtInt16;
    else {if (Value < -$8000) or (Value >= $8000) then} Result := dtInt32;
  end;
end;

{ TRTData }

destructor TRTData.Destroy;

  procedure FreeNamespace(var Namespace: PNamespace);
  var i: Integer;
  begin
    if Namespace = nil then Exit;
    NameSpace^.Name := '';
    Namespace^.Constants := nil;
    Namespace^.Variables := nil;
    Namespace^.Types     := nil;
    for i := 0 to High(Procedures) do FreeNamespace(Namespace^.Procedures[i]);
    Dispose(Namespace);
    Namespace := nil;
  end;

var i: Integer;
begin
  PIN := nil;
  FreeNamespace(Namespace);
  FreeMem(BaseData);
  Data := nil;
  for i := 0 to TotalConstants-1 do FreeNamespace(Constants[i].Namespace);
  Constants := nil;
  for i := 0 to TotalVariables-1 do FreeNamespace(Variables[i].Namespace);
  Variables := nil;
  for i := 0 to TotalProcedures-1 do FreeNamespace(Procedures[i].Namespace);
  Procedures := nil;
  for i := 0 to TotalTypes-1 do FreeNamespace(Types[i]^.Namespace);
  Types := nil;
  inherited;
end;

end.
