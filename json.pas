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

uses BaseMsg, BaseTypes, BaseStr, Props;

const
  // Minimum capacity of JSON data structures
  minJSONCapacity = 16;

type
  // Type to represent characters
  TJSONChar = AnsiChar;
  // Type to represent strings
  TJSONString = AnsiString;
  // Type to represent unmanaged strings
  TJSONPChar = PAnsiChar;


  TJSONArray = Pointer;

  // Possible JSON value types
  TJSONValueType = (jvString, jvNumber, jvBoolean, jvObject, jvArray);

  { @Abstract(JSON parser/generator class)
    The class will parse JSON data from Source property which can be initially set by passing a value to constructor.
    The Source property can be changed at any time which will cause parsing of the property value.
    Read of the Source property will cause reverse to parsing process if some value set was changed.
    The data can be then obtained with Names, Values and ValueTypes properties as well as through asProperties property.
  }
  TJSONAnsi = class
  private
    fSrc: TJSONString;
    fPos: Integer;
    fErrorHandler: TErrorHandler;
    fNames, fValues: array of TJSONString;
    fValueTypes: array of TJSONValueType;
    fProperties: TProperties;
    fCount, fCapacity: Integer;
    procedure setCapacity(aCapacity: Integer);
    procedure skipSpace();
    function checkChar(ch: TJSONChar; mandatory: Boolean): Boolean;
    function parseNum(): TJSONString;
    function parseToken(): TJSONString;
    function parseStr(): TJSONString;
    function parseVal(): Boolean;
    function parsePair(): Boolean;
    procedure doParse;
    function getName(index: Integer): TJSONString; {$I inline.inc}
    function getValueByIndex(index: Integer): TJSONString;
    function getValueTypeByIndex(index: Integer): TJSONValueType;
    procedure setSource(const Value: TJSONString);
  public
    // Creates an instance of the class. With aSrc initial JSON data can be specified.
    constructor Create(const aSrc: TJSONString; aErrorHandler: TErrorHandler = nil);
    // Destroys an instance of the class
    destructor Destroy; override;
    // Returns index corresponding to the name
    function getNameIndex(const name: TJSONString): Integer;

    { Current JSON representation of data. Setting this property will cause parsing of its contents.
      If the property is read JSON representation of the data conained by the class will be generated. }
    property Source: TJSONString read fSrc write setSource;
    // error handler to call when an error occures
    property errorHandler: TErrorHandler read fErrorHandler;
    // List of names of values
    property Names[index: Integer]: TJSONString read getName;
    // List of values accessible by index
    property ValuesByIndex[index: Integer]: TJSONString read getValueByIndex;
    // List of value types accessible by index
    property ValueTypesByIndex[index: Integer]: TJSONValueType read getValueTypeByIndex;
  end;

implementation

uses SysUtils;

const
  JSONToPropertyType: array[TJSONValueType] of Integer=(vtString, vtDouble, vtBoolean, vtNone, vtNone);

        (* rec  = "{" [pair] [{"," pair}] "}".
         * pair = str ":" val.
         * str  = """text""".
         * val = str | num | "true" | "false" | "null" | rec | arr.
         * num  = {digit} [.{digit}].
         * arr  = "[" [val] [{, val}] "]".
         *)

  procedure TJSONAnsi.setCapacity(aCapacity: Integer);
  begin
    fCapacity := aCapacity;
    if fCapacity < minJSONCapacity then fCapacity := minJSONCapacity;
    SetLength(fNames,      fCapacity);
    SetLength(fValues,     fCapacity);
    SetLength(fValueTypes, fCapacity);
  end;

  procedure TJSONAnsi.skipSpace();
  begin
    while (fPos <= length(fSrc)) and (fSrc[fPos] = ' ') do inc(fPos);
  end;

  function TJSONAnsi.checkChar(ch: AnsiChar; mandatory: Boolean): Boolean;
  begin
    skipSpace();
    if (fPos <= length(fSrc)) and (fSrc[fPos] = ch) then begin
      inc(fPos);
      result := True;
    end else begin
      if mandatory and Assigned(ErrorHandler) then errorHandler(TError.Create('"' + ch + '" expected at ' + intToStrA(fPos)));
      result := False;
    end;
  end;

  // num = {digit} [.{digit}].
  function TJSONAnsi.parseNum(): AnsiString;
  var startPos: Integer;
  begin
    startPos := fPos;
    while (fPos <= length(fSrc)) and (fSrc[fPos] in ['0'..'9', '.', '+', '-', 'e', 'E']) do inc(fPos);
    Result := Copy(fSrc, startPos, fPos-startPos);
  end;

  // token = "true" | "false" | "null".
  function TJSONAnsi.parseToken(): AnsiString;
  var startPos: Integer;
  begin
    Result := '';
    startPos := fPos;
    while (fPos <= length(fSrc)) and (fSrc[fPos] in ['t', 'r', 'u', 'e', 'f', 'a', 'l', 's', 'n']) do inc(fPos);
    Result := copy(fSrc, startPos, fPos-startPos);
  end;

  // str = """text""".
  function TJSONAnsi.parseStr(): AnsiString;
  var startPos: Integer;
  begin
    result := '';
    if checkChar('"', true) then begin
      startPos := fPos;
      while (fPos <= length(fSrc)) and (fSrc[fPos] <> '"') do inc(fPos);
      if (fPos <= length(fSrc)) then begin
        result := copy(fSrc, startPos, fPos-startPos);
        Inc(fPos);                          // Skip closing '"'
      end else
        if Assigned(ErrorHandler) then errorHandler(TError.Create('unclosed string constant at ' + intToStrA(fPos)));
    end else
      if Assigned(ErrorHandler) then errorHandler(TError.Create('string expected at ' + intToStrA(fPos)));
  end;

  // val = str | num | "true" | "false" | "null" | rec | arr.
  function TJSONAnsi.parseVal(): Boolean;
  begin
    Result := True;
    skipSpace();
    if (fPos <= length(fSrc)) then begin
      case UpCase(fSrc[fPos]) of
        '"': begin
          fValues[fCount] := parseStr();
          fValueTypes[fCount] := jvString;
        end;
        'T': begin
          fValues[fCount] := parseToken();
          if UpperCase(fValues[fCount]) <> 'TRUE' then
            if Assigned(ErrorHandler) then errorHandler(TError.Create('"true" expected at ' + intToStrA(fPos)));
          fValueTypes[fCount] := jvBoolean;
        end;
        'F': begin
          fValues[fCount] := parseToken();
          if UpperCase(fValues[fCount]) <> 'FALSE' then
            if Assigned(ErrorHandler) then errorHandler(TError.Create('"false" expected at ' + intToStrA(fPos)));
          fValueTypes[fCount] := jvBoolean;
        end;
        'N': begin
          fValues[fCount] := parseToken();
          if UpperCase(fValues[fCount]) <> 'NULL' then
            if Assigned(ErrorHandler) then errorHandler(TError.Create('"null" expected at ' + intToStrA(fPos)));
          fValues[fCount] := '';                                                   // set to "null" value
          fValueTypes[fCount] := jvObject;
        end;
        '{': ;
        '[': ;
        else begin
          fValues[fCount] := parseNum();
          fValueTypes[fCount] := jvNumber;
        end;
      end;
    end else begin
      if Assigned(ErrorHandler) then errorHandler(TError.Create('value expected at ' + intToStrA(fPos)));
    end;
  end;

  //pair = str ":" val.
  function TJSONAnsi.parsePair(): Boolean;
  begin
    if fCount >= fCapacity  then SetCapacity(fCapacity * 2);
    fNames[fCount] := parseStr();
    if checkChar(':', true) then
      Result := parseVal()
    else
      Result := false;

    fProperties.Add(fNames[fCount], JSONToPropertyType[fValueTypes[fCount]], [], fValues[fCount], '');

    Inc(fCount);
  end;

  //rec  = "{" [pair] [{"," pair}] "}".
  procedure TJSONAnsi.doParse();
  begin
    fPos := 1;
    if not checkChar('{', true) then Exit;
    parsePair();
    while checkChar(',', false) do parsePair();
    checkChar('}', true);
  end;

  constructor TJSONAnsi.Create(const aSrc: TJSONString; aErrorHandler: TErrorHandler);
  begin
    fProperties := TProperties.Create();
    fSrc := aSrc;
    doParse();
  end;

  destructor TJSONAnsi.Destroy;
  begin
    FreeAndNil(fProperties);
    inherited;
  end;

  function TJSONAnsi.getName(index: Integer): TJSONString;
  begin
    Result := fNames[index];
  end;

  function TJSONAnsi.getNameIndex(const name: TJSONString): Integer;
  begin
    Result := fCount-1;
    while (Result >= 0) and (fNames[Result] <> name) do Dec(Result);
  end;

function TJSONAnsi.getValueByIndex(index: Integer): TJSONString;
begin
  Result := fValues[index];
end;

function TJSONAnsi.getValueTypeByIndex(index: Integer): TJSONValueType;
begin
  Result := fValueTypes[index];
end;

procedure TJSONAnsi.setSource(const Value: TJSONString);
begin
  fSrc := Value;
end;

end.
