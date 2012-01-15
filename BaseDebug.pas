(*
  @Abstract(Base debug unit)
  (C) 2003-2012 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: Jan 10, 2012
  The unit provides debug functionality such as stack traces.
*)
{$Include GDefines.inc}
unit BaseDebug;

interface

uses BaseTypes;

  { A special function-argument. Should be called ONLY as Assert() argument.
    Allows to obtain a source file name and line number by calling Assert() procedure with this function as an argument.
    Doesn't require any debug information to be included in binary module.
    The only requirement is inclusion of assertions code.
    Tested in Delphi 7+ and FPC 2.4.2+.

    Suggested usage:

    Assert(GetCodeLoc);

    This call will fill SourceFilename and LineNumber fields of TCodeLocation structure
    which can be obtained by calling LastCodeLoc():

    Log('File name: ' + LastCodeLoc().SourceFilename + ', line: ' + IntToStr(LastCodeLoc().LineNumber));
    Always returns False. }
  function _CodeLoc(): Boolean;

  // Returns last obtained code location
  function LastCodeLoc(): TCodeLocation;

  type
    // Stack trace
    TBaseStackTrace = array of TCodeLocation;

  { Returns TCodeLocation with additional source information for the specified by address location.
    An additional debug information (TD32, map file, etc) is required for the function to work. }
  function GetCodeLocation(Address: Pointer): TCodeLocation;

  // Returns array of TCodeLocation structures representing current stack trace, not including the call to GetStackTrace
  function GetStackTrace(LevelsIgnore: Integer = 0): TBaseStackTrace;

  // Returns current stack trace, not including the call to GetStackTrace as string
  function GetStackTraceStr(LevelsIgnore: Integer = 0): string;

  // Prevents compiler optimization to remove a variable which was passed to this function
  procedure Volatile(var v);

implementation

uses
  {$IFDEF USE_JCLDEBUG}
    JCLDebug,
  {$ENDIF}
  SysUtils;

const
  // New line character sequence
  NEW_LINE_SEQ = {$IFDEF WINDOWS}#13#10{$ELSE}#10{$ENDIF};
  // Max number of stack trace entries
  MAX_STACK_ENTRIES = 1000;

var
  LastCodeLocation: TCodeLocation;
  StoredAssertProc: TAssertErrorProc = nil;

const SRC_UNKNOWN: string = 'Unknown';

// Assert error procedure which stores source location info and restores original assert handler
{$IFDEF FPC}
  procedure GetCodeLocAssert(const Message, Filename: ShortString; LineNumber: LongInt; ErrorAddr: Pointer);
{$ELSE}
  procedure GetCodeLocAssert(const Message, Filename: string; LineNumber: Integer; ErrorAddr: Pointer);
{$ENDIF}
begin
  LastCodeLocation.Address        := ErrorAddr;
  LastCodeLocation.SourceFilename := Filename;
  LastCodeLocation.UnitName       := '';
  LastCodeLocation.ProcedureName  := '';
  LastCodeLocation.LineNumber     := LineNumber;

  AssertErrorProc := StoredAssertProc;
  StoredAssertProc := nil;
  AssertUnlock();
end;

function _CodeLoc(): Boolean;
begin
  Assert(@StoredAssertProc = nil, 'GetCodeLoc() should be used only as Assert() argument');

  AssertLock();
  StoredAssertProc := AssertErrorProc;
  AssertErrorProc := @GetCodeLocAssert;
  Result := False;
end;

function LastCodeLoc(): TCodeLocation;
begin
  Result := LastCodeLocation;
end;

function GetCodeLocation(Address: Pointer): TCodeLocation;
{$IFDEF USE_JCLDEBUG}
var LocInfo: TJclLocationInfo;
{$ENDIF}
{$IFDEF FPC}
var
  LSourceName, LProcedureName: ShortString;
  LLineNumber: LongInt;
{$ENDIF}
begin
  Result.Address := Address;
  // Stub implementation
  Result.SourceFilename := SRC_UNKNOWN;
  Result.UnitName       := SRC_UNKNOWN;
  Result.ProcedureName  := SRC_UNKNOWN;
  Result.LineNumber     := 0;

  {$IFDEF USE_JCLDEBUG}
    // need some kind of additional debug information such as TD32 or map file
    LocInfo := GetLocationInfo(Address);
    Result.SourceFilename := LocInfo.SourceName;
    Result.UnitName       := LocInfo.UnitName;
    Result.ProcedureName  := LocInfo.ProcedureName;
    Result.LineNumber     := LocInfo.LineNumber;
  {$ENDIF}
  {$IFDEF FPC}
    // need -gd and -gl options to work
{    if getLineInfo(PtrUInt(Address), LProcedureName, LSourceName, LLineNumber) then begin
      Result.SourceFilename := LSourceName;
      Result.ProcedureName  := LProcedureName;
      Result.LineNumber     := LLineNumber;
    end;}
  {$ENDIF}

  LastCodeLocation := Result;
end;

function GetStackTrace(LevelsIgnore: Integer = 0): TBaseStackTrace;
var
  i: Integer;
  Address: Pointer;
begin
  i := 0;
  {$IFDEF USE_JCLDEBUG} Address := Caller(i+LevelsIgnore+1); {$ELSE} Address := nil; {$ENDIF}
  while (Address <> nil) and (i < MAX_STACK_ENTRIES) do begin
    SetLength(Result, i+1);
    Result[i] := GetCodeLocation(Address);
    Inc(i);
    {$IFDEF USE_JCLDEBUG} Address := Caller(i+LevelsIgnore+1); {$ELSE} Address := nil; {$ENDIF}
  end;
end;

function GetStackTraceStr(LevelsIgnore: Integer = 0): string;
var
  CodeLoc: TCodeLocation;
  i: Integer;
  Address: Pointer;
begin
  Result := '';
  i := 0;
  {$IFDEF USE_JCLDEBUG} Address := Caller(i+LevelsIgnore+1); {$ELSE} Address := nil; {$ENDIF}
  while (Address <> nil) and (i < MAX_STACK_ENTRIES) do begin
    CodeLoc := GetCodeLocation(Address);
    if i > 0 then Result := Result + NEW_LINE_SEQ;
    Result := Result + ' --- ' + CodeLocToStr(CodeLoc);
    Inc(i);
    {$IFDEF USE_JCLDEBUG} Address := Caller(i+LevelsIgnore+1); {$ELSE} Address := nil; {$ENDIF}
  end;

end;

procedure Volatile(var v);
begin
end;

initialization
  LastCodeLocation.Address := nil;
end.

