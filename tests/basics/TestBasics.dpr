{$I gdefines.inc}
program TestBasics;
{$APPTYPE CONSOLE}

uses
  Logger, Tester, BaseTypes, Basics;

type
  {$M+}
  // Binary routines tests
  TBinary = class(TTestSuite)
  private
    function GetCTZ(x: Integer): Integer;
  published
    procedure TestCTZ();
  end;

{ TestClass }

function TBinary.GetCTZ(x: Integer): Integer;
var i: Integer;
begin
  Result := 0;
  while (Result < 32) and (((x shr Result) and 1) = 0) do Inc(Result);
end;

procedure TBinary.TestCTZ;
var i: Cardinal;
begin
//  Log('TestClass.Test2 invoked');
  Writeln(Basics.CountTrailingZeros(0), ' = ', GetCTZ(0));
  for i := 0 to $7FFFFFFF do begin
    Assert(_Check(Basics.CountTrailingZeros(i) = GetCTZ(i)), 'CTZ(' + IntToStr(i) + ')');
    if i and $FFFFFF = 0 then  Write('.');
  end;
end;

begin
  SetRunner(TLogTestRunner.Create);
  RunTests([TBinary]);

  Writeln('Finished OK');
  readln;
end.

