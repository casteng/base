{$I gdefines.inc}
program TestBasics;
{$APPTYPE CONSOLE}

uses
  Logger, Tester, BaseTypes, Basics, json, Props;

type
  {$M+}
  // Binary routines tests
  TBinary = class(TTestSuite)
  private
    function GetCTZ(x: Integer): Integer;
  protected
    procedure InitSuite(); override;
  published
    procedure TestCTZ();
  end;

  // JSON routines tests
  TJsonTest = class(TTestSuite)
    procedure TestJSONValue();
    procedure TestCreate();
    procedure TestProps;
  end;

{ TestClass }

function TBinary.GetCTZ(x: Integer): Integer;
var i: Integer;
begin
  Result := 0;
  while (Result < 32) and (((x shr Result) and 1) = 0) do Inc(Result);
end;

procedure TBinary.InitSuite();
begin
  Randomize;
end;

procedure TBinary.TestCTZ();
var
  i: Cardinal;
  v: Integer;
begin
  Log('TBinary.TestCTZ invoked');
  for i := 0 to 10000000 do begin
    v := Random($80000000);
    Assert(_Check(Basics.CountTrailingZeros(v) = GetCTZ(v)), 'CTZ(' + IntToStr(v) + ')');
  end;
end;

{ TJson }

procedure TJsonTest.TestJSONValue;
const TEST_VALUE: Double = 23.8;
begin
  with TJSONValue.Create('True') do begin
    Assert(_Check(ValueType = jvBoolean), 'Wrong type 1');
    Assert(_Check(asNum = 1.0), 'Wrong value 1');
    Free;
  end;
  with TJSONValue.Create('23.8') do begin
    Assert(_Check(ValueType = jvNumber), 'Wrong type 2');
    Assert(_Check(not IsNan(asNum) and (asNum = TEST_VALUE)), 'Wrong value 2');
    Free;
  end;
  with TJSONValue.Create('Null') do begin
    Assert(_Check(ValueType = jvObject), 'Wrong type 3');
    Assert(_Check(asObj = nil), 'Wrong value 3');
    Free;
  end;
  with TJSONValue.Create('"String"') do begin
    Assert(_Check(ValueType = jvString), 'Wrong type 4');
    Assert(_Check(asStr = 'String'), 'Wrong value 4');
    Free;
  end;
end;

procedure TJsonTest.TestCreate;
var js: TJSON;
begin
  Log('TJsonTest.TestCreate invoked');
  js := TJSON.Create('{'
                       + '  "Name": "Test",'
                       + '  "Number": 2,'
                       + 'Nested: { n1: "nested 1", "n2": 34}'
                       + '}'
                        );
  Assert(_Check(js['Name'].asStr   = 'Test'), 'Wrong value 1');
  Assert(_Check(js['Number'].asNum = 2),    'Wrong value 2');
  Assert(_Check(js['Nested'].asObj['n1'].asStr = 'nested 1'),    'Wrong value 3');
  Assert(_Check(js.Count = 3), 'Wrong fields count: ' + IntToStr(js.Count));
end;

procedure TJsonTest.TestProps;
var props: TProperties;
begin
  Exit;
  Log('TJsonTest.TestProps invoked');
  props := TProperties.Create('{'
                            + '  "Name": "Test",'
                            + '  "Number": 2'
                            + '}'
                              );
  Assert(_Check(props['Name']   = 'Test'), 'Wrong value');
  Assert(_Check(props['Number'] = '2'),    'Wrong value');
  Assert(_Check(props.TotalProperties = 2), 'Wrong fields count: ' + IntToStr(props.TotalProperties));
end;

begin
  Logger.AddAppender(Logger.TSysConsoleAppender.Create([LLFull]));
  SetRunner(TLogTestRunner.Create);

  if RunTests([TBinary, TJsonTest]) then
    Writeln('Finished OK')
  else
    Writeln('Finished with errors');

  Readln;
end.

