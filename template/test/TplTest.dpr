{$Include GDefines.inc}
program TplTest;

uses
  Tester,
  {$IFDEF FireMonkey}
    FMRunnerForm,         // Uncomment for FireMonkey based test runner in Delphi XE 2+
  {$ENDIF}
  GenTestU;

{$R *.res}

begin
  RunTests();
end.
