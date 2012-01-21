{$I gdefines.inc}
program test;
{$APPTYPE CONSOLE}

//uses sysutils;
uses
  SysUtils, BaseDebug, Logger, BaseTypes, BaseStr, BaseRTTI;

type
  {$M+}
  TestClass = class(TObject)
  private
    fb: string;
    Fa: Integer;
    procedure Seta(const Value: Integer);
  published
    procedure Cmd();
    property a: Integer read Fa write Seta;
    property b: string read fb write fb;
  end;

{procedure VarDispDebugHandler(Result: PVariant; const Instance: Variant;
  CallDesc: PCallDesc; Params: Pointer); cdecl;
begin
  Writeln(PChar(Params));
  Result^ := 11;
end;}

{ TestClass }

procedure TestClass.Cmd;
begin
  Log('Cmd invoked');
end;

procedure TestClass.Seta(const Value: Integer);
begin
  Fa := Value;
end;

var
  i: Integer;
  Props: TRTTINames;
  testc: TestClass;

begin
//  a := IUnknown(TInterfacedObject.Create());
//  VarDispProc := @VarDispDebugHandler;
//  i := a.doSomething($20);

  //AddAppender(TFileAppender.Create('test.log', llFull));

  testc := TestClass.Create;

  Props := GetClassProperties(TestClass);
  for i := 0 to High(Props) do Log('Property: ' + Props[i]);
  InvokeCommand(testc, 'Cmd');

  Writeln('Finished OK');
end.

