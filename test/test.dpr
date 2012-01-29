{$I gdefines.inc}
program test;
{$APPTYPE CONSOLE}

//uses sysutils;
uses
  SysUtils, BaseDebug, Logger, BaseTypes, BaseStr, BaseRTTI, Tester;

type
  {$M+}
  CTestClass = class of TestClass;
  TestClass = class(TTestSuite)
  private
    fb: string;
    Fa: Integer;
    procedure Seta(const Value: Integer);
  published
    procedure Test1();
    procedure Test2();
  end;

  TestClass2 = class(TestClass)
  published
    procedure Test1();
  end;


{procedure VarDispDebugHandler(Result: PVariant; const Instance: Variant;
  CallDesc: PCallDesc; Params: Pointer); cdecl;
begin
  Writeln(PChar(Params));
  Result^ := 11;
end;}

{ TestClass }

procedure TestClass.Seta(const Value: Integer);
begin
  Fa := Value;
end;

var
  i: Integer;
  Props, Methods: TRTTINames;
  testc: TestClass;
  testcr: CTestClass;

procedure TestClass.Test1;
begin
  Log('TestClass.Test1 invoked');
end;

procedure TestClass.Test2;
begin
  Log('TestClass.Test2 invoked');
  Assert(_Check(False), 'Test2');
end;

{ TestClass2 }

procedure TestClass2.Test1;
begin
  Log('TestClass2.Test1 invoked');
  raise Exception.Create('Exception!');
end;

begin
//  a := IUnknown(TInterfacedObject.Create());
//  VarDispProc := @VarDispDebugHandler;
//  i := a.doSomething($20);

  //AddAppender(TFileAppender.Create('test.log', llFull));

{  testc := TestClass2.Create;

  testcr := TestClass2;

  Props := GetClassProperties(TestClass2);
  for i := 0 to High(Props) do Log('Property: ' + Props[i]);
  //Methods := GetInstanceMethods(TObject(testcr));
  Methods := GetClassMethods(testc.ClassType, True);
  for i := 0 to High(Methods) do Log('Method: ' + Methods[i]);

  InvokeCommand(testc, 'Cmd');}

  SetRunner(TLogTestRunner.Create);
  RunTests([TestClass2, TestClass]);

  Writeln('Finished OK');
  readln;
end.

