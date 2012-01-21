{$I gdefines.inc}
program test;
{$APPTYPE CONSOLE}

//uses sysutils;
uses 
  SysUtils, BaseDebug, Logger, BaseTypes, BaseStr;

{procedure VarDispDebugHandler(Result: PVariant; const Instance: Variant;
  CallDesc: PCallDesc; Params: Pointer); cdecl;
begin
  Writeln(PChar(Params));
  Result^ := 11;
end;}

procedure Test3;
begin
  Assert(_Log(lkNotice), 'Test 3');
  raise Exception.Create('My exception');
end;


procedure Test2;
var 
  func, source: shortstring; line: longint;
  cl: TCodeLocation;
begin
  try
    Test3;
  except
    on E: Exception do begin
      raise Exception.Create('My exception');
    end;
  end;

//  Assert(_CodeLoc); cl := LastCodeLoc;
  
  cl.Address := ExceptAddr;
  Assert(_Log(lkWarning), 'Logging with line number info');
//  Assert(False, 'true assert');
end;

//var a: Variant;  i: Integer;

begin
//  a := IUnknown(TInterfacedObject.Create());
//  VarDispProc := @VarDispDebugHandler;
//  i := a.doSomething($20);
  
  AddAppender(TFileAppender.Create('test.log', llFull));

  try
    Test2();
  except
    on E: Exception do begin
      Fatal('Stack trace: '+NEW_LINE_SEQ+GetStackTraceStr(GetExceptionStackTrace()));
    end;
  end;
  
  Writeln('Finished OK');
end.

