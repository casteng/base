{$I gdefines.inc}
program test;
{$APPTYPE CONSOLE}

//uses sysutils;
uses 
  SysUtils, BaseDebug, Logger, BaseTypes;

{procedure VarDispDebugHandler(Result: PVariant; const Instance: Variant;
  CallDesc: PCallDesc; Params: Pointer); cdecl;
begin
  Writeln(PChar(Params));
  Result^ := 11;
end;}


procedure Test2;
var func, source: shortstring; line: longint;
begin
  try
    raise Exception.Create('My exception');
  except
    on E: Exception do Writeln(E.Message);
  end;

  Assert(_CodeLoc);
  Log('Assert at ' + CodeLocToStr(LastCodeLoc));
  LastCodeLoc.Address := ExceptAddr;
  Assert(_Log(lkWarning), 'Logging with line number info');
//  Assert(False, 'true assert');
  if getLineInfo(ptruint(LastCodeLoc.Address),  func, source, line) then
    Writeln('File name: ' + Source + ', line: ', Line)
  else
    Writeln('No source info for ', HexStr(ptruint(LastCodeLoc.Address), 8));

end;

//var a: Variant;  i: Integer;

begin
//  a := IUnknown(TInterfacedObject.Create());
//  VarDispProc := @VarDispDebugHandler;
//  i := a.doSomething($20);
  AddAppender(TFileAppender.Create('test.log', llFull));
  Test2();
  Writeln('Finished OK');
end.

