{$Include GDefines.inc}
program TplTest;

uses
  Tester,
  {$IFDEF Delphi}
    FMRunnerForm,         // Uncomment for FireMonkey based test runner
  {$ENDIF}
  GenTestU;

{$R *.res}

begin
  RunTests();
end.
