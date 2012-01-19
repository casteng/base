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
    // Pointer to exception information
    PExceptionInfo = ^TExceptionInfo;
    // Exception information
    TExceptionInfo = record
      ExceptionObj: TObject;
      Msg: string;
      StackTrace: TBaseStackTrace;
      NestedExceptionAddresses: array of Pointer;
    end;

  { Returns TCodeLocation with additional source information for the specified by address location.
    An additional debug information (TD32, map file, etc) is required for the function to work. }
  function GetCodeLocation(Address: Pointer): TCodeLocation;

  // Returns array of TCodeLocation structures representing current stack trace, not including the call to GetStackTrace
  function GetStackTrace(LevelsIgnore: Integer = 0): TBaseStackTrace; overload;

  // Returns array of TCodeLocation structures representing stack trace of last exception occured
  function GetExceptionStackTrace(): TBaseStackTrace; overload;

  // Returns current stack trace as string, not including the call to GetStackTraceStr
  function GetStackTraceStr(const StackTrace: TBaseStackTrace): string;

  // Prevents compiler optimization to remove a variable which was passed to this function
  procedure Volatile(var v);

implementation

uses
  {$IFDEF USE_JCLDEBUG}
    JCLDebug,
  {$ENDIF}
  Logger,
  BaseStr,
  SysUtils;

const
  // Max number of stack trace entries
  MAX_STACK_ENTRIES = 1000;

var
  LastCodeLocation: TCodeLocation;

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

  AssertRestore();
end;

function _CodeLoc(): Boolean;
begin
  Result := not AssertHook(GetCodeLocAssert);  // Prevent assertion error if hook failed
end;

function LastCodeLoc(): TCodeLocation;
begin
  Result := LastCodeLocation;
end;

{$IFDEF FPC}
{ Parse FPC stack trace line to find out code location record.
  Stabs: $08048377  TMYAPPLICATION__RUN,  line 43 of testcallstack.lpr
  DWARF 1/2/3b: $08048377 line 43 of testcallstack.lpr }
function ParseCodeLocation(const s: ShortString; var Res: TCodeLocation): Boolean;
var
  CurPos, OldPos, LineLen: Integer;

begin
  Result := False;
  if s = '' then Exit;

//  Writeln('ParseCodeLocation: ', s);

  Res := GetCodeLoc('', '', '', 0, nil);

  CurPos := Pos('$', s);
  if CurPos > 0 then
    Res.Address := PtrOffs(nil, StrToIntDef(Copy(s, CurPos, 9), 0))
  else
    CurPos := 1;
//  Writeln('Addr: ', Copy(s, CurPos, 9), ' => $', IntToHex(Integer(Res.Address), 8));

  OldPos := CurPos+9;
  CurPos := Pos(',', s);
  if CurPos > 0 then
    Res.ProcedureName := Trim(Copy(s, OldPos, CurPos-OldPos))
  else
    CurPos := 1;

  CurPos := PosEx('line ', s, CurPos) + 5;
  while (CurPos <= Length(s)) and (s[CurPos] = ' ') do Inc(CurPos);
  LineLen := PosEx(' of ', s, CurPos) - CurPos;
//  Writeln('Line: ', CurPos, ' - ', CurPos + LineLen);

  Res.LineNumber := StrToIntDef(Copy(s, CurPos, LineLen), 0);

  Res.SourceFilename := Copy(s, CurPos + LineLen + 4, Length(s));

  Result := True;
end;
{$ENDIF}

function GetCodeLocation(Address: Pointer): TCodeLocation;
{$IFDEF USE_JCLDEBUG}
var LocInfo: TJclLocationInfo;
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
    // need debug information (Stabs, Dwarf, etc) to work
    ParseCodeLocation(BackTraceStrFunc(Address), Result);
  {$ENDIF}

  LastCodeLocation := Result;
end;

  procedure Add(var Result: TBaseStackTrace; Address: Pointer);
  begin
    SetLength(Result, Length(Result)+1);
    Result[High(Result)] := GetCodeLocation(Address);
  end;

function GetStackTrace(LevelsIgnore: Integer = 0): TBaseStackTrace;
var
  i: Integer;
  Address: Pointer;
  {$IFDEF FPC} BasePtr, LastPtr, CallerFrame: Pointer; {$ENDIF}
begin
  i := 0;
  try
  {$IFDEF FPC}
    BasePtr := get_frame;
    if BasePtr <> nil then begin
      LastPtr := PtrOffs(BasePtr, -1);
      while (BasePtr > LastPtr) and (i < MAX_STACK_ENTRIES) do begin
        Address := get_caller_addr(BasePtr);
        CallerFrame := get_caller_frame(BasePtr);
        if (Address = nil) or (CallerFrame = nil) then Break;
        if (i >= LevelsIgnore) then Add(Result, Address);
        Inc(i);
        LastPtr := BasePtr;
        BasePtr := CallerFrame;
      end;
    end;
  {$ELSE}
    {$IFDEF USE_JCLDEBUG}
      Address := Caller(i + LevelsIgnore + 1);
      while (Address <> nil) and (i < MAX_STACK_ENTRIES) do begin
        Add(Result, Address);
        Inc(i);
        Address := Caller(i + LevelsIgnore + 1);
      end;
    {$ENDIF}
  {$ENDIF}
  except
    Log('Exception in GetStackTrace', lkError);
  end;
end;

function GetExceptionStackTrace(): TBaseStackTrace;
var
  i: Integer;
  {$IFDEF FPC} Frames: PPointer; {$ENDIF}
  {$IFDEF USE_JCLDEBUG}
    StackInfo: TJclStackInfoList;
  {$ENDIF}
begin
  {$IFDEF FPC}
    Add(Result, ExceptAddr);
    Frames := ExceptFrames;
    for i := 0 to ExceptFrameCount - 1 do
      Add(Result, Frames[i]);
  {$ELSE}
    {$IFDEF USE_JCLDEBUG}
      StackInfo := JclLastExceptStackList();
      if StackInfo <> nil then
        for i := 0 to StackInfo.Count-1 do
          Add(Result, StackInfo.Items[i].CallerAddr);
    {$ENDIF}
  {$ENDIF}
end;

function GetStackTraceStr(const StackTrace: TBaseStackTrace): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(StackTrace) do begin
    if i > 0 then Result := Result + BaseStr.NEW_LINE_SEQ;
    Result := Result + ' --- ' + IntToStr(i) + '. ' + CodeLocToStr(StackTrace[i]);
  end;
end;

procedure Volatile(var v);
begin
  // NOP
end;
{$IFDEF DELPHI2009}{$IFDEF USE_JCLDEBUG}
  function GetExceptionStackInfoProc(P: PExceptionRecord): Pointer;
  var
    i: Integer;
    EI: PExceptionInfo;
    Nested: PExceptionRecord;
  begin
    New(EI);
    EI.ExceptionObj := P^.ExceptObject;
    if EI^.ExceptionObj is Exception then
      EI.Msg := Exception(EI^.ExceptionObj).Message
    else
      EI.Msg := '';

    EI^.StackTrace := GetExceptionStackTrace();

    Nested := P^.ExceptionRecord;
    i := 0;
    while (Nested <> nil) and (i < MAX_STACK_ENTRIES) do begin
      Inc(i);
      SetLength(EI^.NestedExceptionAddresses, i);
      EI^.NestedExceptionAddresses[i-1] := Nested^.ExceptionAddress;
      Nested := Nested^.ExceptionRecord;
    end;

    Result := EI;
  end;

  function GetStackInfoStringProc(Info: Pointer): string;
  var
    i: Integer;
    EI: PExceptionInfo;
  begin
    EI := Info;
    Result := 'Exception class "' + EI^.ExceptionObj.ClassName + '" with message "' + EI^.Msg + '", stack trace:' + NEW_LINE_SEQ;
    Result := Result + GetStackTraceStr(EI^.StackTrace);
    for i := 0 to High(EI^.NestedExceptionAddresses) do
      Result := Result + NEW_LINE_SEQ + ' -- Nested: ' + CodeLocToStr(GetCodeLocation(EI^.NestedExceptionAddresses[i]));
  end;
{$ENDIF}{$ENDIF}

procedure CleanUpStackInfoProc(Info: Pointer);
var EI: PExceptionInfo;
begin
  EI := Info;
  SetLength(EI^.StackTrace, 0);
  SetLength(EI^.NestedExceptionAddresses, 0);
  Dispose(EI);
end;

initialization
  LastCodeLocation.Address := nil;
  {$IFDEF USE_JCLDEBUG}
    Include(JclStackTrackingOptions, stTraceAllExceptions);
    Include(JclStackTrackingOptions, stRawMode);
    JclStartExceptionTracking;
  {$ENDIF}
  {$IFDEF DELPHI2009}{$IFDEF USE_JCLDEBUG}
    Exception.GetExceptionStackInfoProc := GetExceptionStackInfoProc;
    Exception.GetStackInfoStringProc    := GetStackInfoStringProc;
    Exception.CleanUpStackInfoProc      := CleanUpStackInfoProc;
  {$ENDIF}{$ENDIF}
finalization
  {$IFDEF DELPHI2009}{$IFDEF USE_JCLDEBUG}
    Exception.GetExceptionStackInfoProc := nil;
    Exception.GetStackInfoStringProc    := nil;
    Exception.CleanUpStackInfoProc      := nil;
  {$ENDIF}{$ENDIF}
  {$IFDEF USE_JCLDEBUG}
    JclStopExceptionTracking;
  {$ENDIF}
end.

