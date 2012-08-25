(*
  @Abstract(Simple JSON parser unit)
  (C) 2003-2011 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: Jan 31, 2011
  The unit contains simple ansi JSON parser / generator implementation
*)
{$Include GDefines.inc}
unit json;

interface

uses BaseMsg, BaseTypes, BaseStr, Template;

type
  // Type to represent characters
  TJSONChar = AnsiChar;
  // Type to represent strings
  TJSONString = AnsiString;
  // Type to represent unmanaged strings
  TJSONPChar = PAnsiChar;

  // Possible JSON value types
  TJSONValueType = (jvString, jvNumber, jvBoolean, jvObject, jvArray);

const
  // JSON quote character
  JSON_QUOTE_CHAR = TJSONChar('"');
  // Not a number constant
  NAN: Double = 0.0 / 0.0;

type
  // Error which will be generated when a parsing error occurs
  TParseError = class(TError) end;

  TJSON = class;

  // Immutable JSON value instance
  TJSONValue = class(TObject)
  private
    fStart, fEnd: Integer;
    fSrc: TJSONString;
    fType: TJSONValueType;
    fNum: Double;
    fObject: TJSON;
    fArray: array of TJSONValue;
    function GetAsString: TJSONString;
    function GetAsBoolean: Boolean;
    function GetAsArray(index: Integer): TJSONValue;
    procedure skipSpace();
    procedure doParse();
    procedure parseToken();
    procedure parseStr();
    procedure parseNum;
    procedure parseObject;
  public
    // Construct the value instance from a JSON value string, starting from StartIndex character (WideChar element for unicode)
    constructor Create(const ASrc: TJSONString; StartIndex: Integer = 1);

    // Value type
    property ValueType: TJSONValueType read fType;
    // String value
    property asStr: TJSONString read GetAsString;
    // Numeric value if fType is jvNumber or NAN otherwise
    property asNum: Double read fNum;
    // Boolean value
    property asBool: Boolean read GetAsBoolean;
    // Object value
    property asObj: TJSON read fObject;
    // Array value if fType is jvArray or nil otherwise
    property asArray[index: Integer]: TJSONValue read GetAsArray; //default;
  end;

  // Name-value hash map type instantiation
  _HashMapKeyType = TJSONString;
  _HashMapValueType = TJSONValue;
  {$I gen_coll_hashmap.inc}
  TJSONNameValueHashMap = _GenHashMap;
  TJSONNamesIterator = _GenHashMapKeyIterator;

  // JSON method callback called when a new name/value pair just parsed for object Obj
  TJSONDataDelegate = procedure(const Obj: TJSON; const Name: TJSONString; Value: TJSONValue) of object;

  { @Abstract(JSON parser/generator class)
    The class will parse JSON data passed to constructor.
    TODO: modifyable values. Read of the Source property will cause reverse to parsing process if some value set was changed.
    The data can be then obtained with Names, Values and ValueTypes properties as well as through asProperties property.
  }
  TJSON = class(TObject)
  private
    fSrc: TJSONString;
    fPos: Integer;
    fDataMethod: TJSONDataDelegate;
    fValues: TJSONNameValueHashMap;
    fCount: Integer;

    function getThis: TJSON;
    function getValue(const name: TJSONString): TJSONValue;

    procedure skipSpace();
    function parseStr(): TJSONString;
    function checkChar(ch: TJSONChar; mandatory: Boolean): Boolean;
    procedure parsePair();
    procedure doParse();
    procedure ForEachDelegate(const key: _HashMapKeyType; const value: _HashMapValueType; Data: Pointer);

  protected
    // Default data delegate. May be overridden.
     procedure DefDataDelegate(const Obj: TJSON; const Name: TJSONString; Value: TJSONValue); virtual;
  public
    // Creates an instance of the class with aSrc JSON data.
    constructor Create(const aSrc: TJSONString; DataMethod: TJSONDataDelegate = nil);
    // Creates an instance of the class with JSON data starting from aStart character in aSrc.
    constructor CreateEx(const aSrc: TJSONString; aStart: Integer; DataMethod: TJSONDataDelegate);
    // Destroys an instance of the class
    destructor Destroy; override;
    // Sets global for the whole unit error handler
    class procedure setErrorHandler(AErrorHandler: TErrorHandler);
    // Returns True if the JSON contains name
    function Contains(const Name: TJSONString): Boolean;
    // Call the specified delegate for each name/value pair
    procedure ForEach(DataMethod: TJSONDataDelegate);
    // Returns iterator over all existing names
    function GetNamesIterator(): TJSONNamesIterator;

    // Instance reference
    property This: TJSON read getThis;
    // Number of values
    property Count: Integer read fCount;
    // Source JSON string
    property Source: TJSONString read fSrc;
    // Values
    property Values[const Name: TJSONString]: TJSONValue read GetValue; default;
  end;

implementation

uses SysUtils;

{$MESSAGE 'Instantiating TJSONNameValueHashMap implementation'}
{$I gen_coll_hashmap.inc}

var
  // Error handler to call when an error occur
  ErrorHandler: TErrorHandler;

function IsNanDouble(const AValue: Double): Boolean;
begin
  Result := ((PInt64(@AValue)^ and $7FF0000000000000)  = $7FF0000000000000) and
            ((PInt64(@AValue)^ and $000FFFFFFFFFFFFF) <> $0000000000000000);
end;

{ TJSONValue }

function TJSONValue.GetAsString: TJSONString;
begin
  Result := Copy(fSrc, fStart, fEnd-fStart);
end;

function TJSONValue.GetAsBoolean: Boolean;
begin
  Result := fNum = 1.0;
end;

function TJSONValue.GetAsArray(index: Integer): TJSONValue;
begin
  Result := nil;
end;

procedure TJSONValue.skipSpace;
begin
  while (fStart <= length(fSrc)) and (fSrc[fStart] = ' ') do inc(fStart);
end;

// token = "true" | "false" | "null".
procedure TJSONValue.parseToken();
begin
  while (fEnd <= length(fSrc))
    and CharInSet(UpCase(fSrc[fEnd]), ['T', 'R', 'U', 'E', 'F', 'A', 'L', 'S', 'N'])
  do
    inc(fEnd);
end;

// str = """text""".
procedure TJSONValue.parseStr();
begin
  fType := jvString;
  if fSrc[fEnd] = JSON_QUOTE_CHAR then begin
    Inc(fStart);
    Inc(fEnd);
    while (fEnd <= length(fSrc)) and (fSrc[fEnd] <> JSON_QUOTE_CHAR) do inc(fEnd);
    if fEnd > length(fSrc) then
      if Assigned(ErrorHandler) then errorHandler(TError.Create('unclosed string constant at ' + intToStr(fStart)));
  end else
    if Assigned(ErrorHandler) then errorHandler(TError.Create('string expected at ' + intToStr(fEnd)));
end;

// num = {digit} [.{digit}].
procedure TJSONValue.parseNum();
begin
  while (fEnd <= length(fSrc))
    and CharInSet(fSrc[fEnd], ['0'..'9', '.', '+', '-', 'e', 'E'])
  do
    inc(fEnd);

  fNum := StrToRealDef(Copy(fSrc, fStart, fEnd-fStart), NAN);
  if IsNanDouble(fNum) then
    if Assigned(ErrorHandler) then errorHandler(TParseError.Create('Invalid numeric constant at ' + intToStr(fStart)));
end;

procedure TJSONValue.parseObject();
begin
  fObject := TJSON.CreateEx(fSrc, fStart, nil);
  fType   := jvObject;
  fEnd    := fObject.fPos;
end;

// val = str | num | "true" | "false" | "null" | rec | arr.
procedure TJSONValue.doParse;
begin
  fEnd := fStart;
  case UpCase(fSrc[fStart]) of
    JSON_QUOTE_CHAR: parseStr();
    'T': begin
      parseToken();
      if UpperCase(GetAsString()) = 'TRUE' then begin
        fNum := 1.0;
        fType := jvBoolean;
      end else
        if Assigned(ErrorHandler) then errorHandler(TParseError.Create('"true" expected at ' + intToStr(fStart)));
    end;
    'F': begin
      parseToken();
      if UpperCase(GetAsString()) = 'FALSE' then begin
        fNum := 0.0;
        fType := jvBoolean;
      end else
        if Assigned(ErrorHandler) then errorHandler(TParseError.Create('"false" expected at ' + intToStr(fStart)));
    end;
    'N': begin
      parseToken();
      if UpperCase(GetAsString()) = 'NULL' then begin
        fObject := nil;
        fType := jvObject;
      end else
        if Assigned(ErrorHandler) then errorHandler(TParseError.Create('"null" expected at ' + intToStr(fStart)));
    end;
    '{': parseObject();
    '[': ;
    else begin
      parseNum();
      fType := jvNumber;
    end;
  end;
end;

constructor TJSONValue.Create(const ASrc: TJSONString; StartIndex: Integer);
begin
  fSrc   := ASrc;
  fStart := StartIndex;
  fType  := jvString;
  fNum   := NAN;
  skipSpace();
  if fEnd <= length(fSrc) then doParse();
end;

{ TJSON }

        (* rec  = "{" [pair] [{"," pair}] "}".
         * pair = ["""]text["""] ":" val.
         * str  = """text""".
         * val = str | num | "true" | "false" | "null" | rec | arr.
         * num  = {digit} [.{digit}].
         * arr  = "[" [val] [{, val}] "]".
         *)

function TJSON.getThis: TJSON;
begin
  Result := Self;
end;

function TJSON.getValue(const name: TJSONString): TJSONValue;
begin
  Result := fValues[name];
end;

procedure TJSON.skipSpace();
begin
  while (fPos <= length(fSrc)) and (fSrc[fPos] = ' ') do inc(fPos);
end;

function TJSON.checkChar(ch: TJSONChar; mandatory: Boolean): Boolean;
begin
  skipSpace();
  if (fPos <= length(fSrc)) and (fSrc[fPos] = ch) then begin
    inc(fPos);
    result := True;
  end else begin
    if mandatory and Assigned(ErrorHandler) then errorHandler(TError.Create('"' + ch + '" expected at ' + intToStr(fPos)));
    result := False;
  end;
end;

// str = ["""]text["""].
function TJSON.parseStr(): TJSONString;
var
  startPos: Integer;
  termChar: TJSONChar;
begin
  result := '';
  skipSpace();
  if fSrc[fPos] = JSON_QUOTE_CHAR then begin
    termChar := JSON_QUOTE_CHAR;
    inc(fPos);
  end else
    termChar := ':';

  startPos := fPos;
  while (fPos <= length(fSrc)) and (fSrc[fPos] <> termChar) do inc(fPos);

  if (fPos <= length(fSrc)) then begin
    result := copy(fSrc, startPos, fPos-startPos);
    if termChar = JSON_QUOTE_CHAR then Inc(fPos);                          // Skip closing quote
  end else
    if (termChar = JSON_QUOTE_CHAR) and Assigned(ErrorHandler) then
      errorHandler(TParseError.Create('unclosed string constant at ' + intToStr(fPos)));
end;

//pair = str ":" val.
procedure TJSON.parsePair();
var
  Name: TJSONString;
  Val: TJSONValue;
begin
  Name := parseStr();
  if checkChar(':', true) then begin
    Val := TJSONValue.Create(fSrc, fPos);
    fValues[Name] := Val;
    fPos := Val.fEnd + Ord(fSrc[Val.fEnd] = JSON_QUOTE_CHAR);

    if @fDataMethod <> nil then
      fDataMethod(Self, Name, fValues[Name]);

    Inc(fCount);
  end;
end;

//rec  = "{" [pair] [{"," pair}] "}".
procedure TJSON.doParse();
begin
  if not checkChar('{', true) then Exit;
  parsePair();
  while checkChar(',', false) do parsePair();
  checkChar('}', true);
end;


procedure TJSON.DefDataDelegate(const Obj: TJSON; const Name: TJSONString; Value: TJSONValue);
begin
end;

procedure TJSON.ForEachDelegate(const key: _HashMapKeyType; const value: _HashMapValueType; Data: Pointer);
begin
  TJSONDataDelegate(Data^)(Self, key, value);
end;

constructor TJSON.Create(const aSrc: TJSONString; DataMethod: TJSONDataDelegate = nil);
begin
  CreateEx(aSrc, 1, DataMethod);
end;

constructor TJSON.CreateEx(const aSrc: TJSONString; aStart: Integer; DataMethod: TJSONDataDelegate);
begin
  fSrc := aSrc;
  fPos := aStart;

  if @DataMethod = nil then
    fDataMethod := DataMethod
  else
    fDataMethod := DefDataDelegate;

  fValues := TJSONNameValueHashMap.Create();

  doParse();
end;

destructor TJSON.Destroy;
begin
  FreeAndNil(fValues);
  inherited;
end;

function TJSON.GetNamesIterator: TJSONNamesIterator;
begin
  Result := fValues.GetKeyIterator();
end;

function TJSON.Contains(const Name: TJSONString): Boolean;
begin
  Result := fValues.ContainsKey(Name);
end;

procedure TJSON.ForEach(DataMethod: TJSONDataDelegate);
begin
  if @DataMethod = nil then Exit;
  fValues.ForEach(ForEachDelegate, @@DataMethod);
end;

class procedure TJSON.setErrorHandler(AErrorHandler: TErrorHandler);
begin
  ErrorHandler := AErrorHandler;
end;

end.
