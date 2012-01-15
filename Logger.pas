(*
  @Abstract(Logger interface unit)
  (C) 2003-2012 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: Jan 13, 2012
  The unit contains main logger interface and several default appenders
*)
{$Include GDefines.inc}
unit Logger;

interface

uses BaseTypes;

type
  // Levels of importance of log messages
  TLogLevel = (// Detail debug information
               lkDebug,
               // General information events
               lkInfo,
               // Noticeable information events
               lkNotice,
               // Warnings
               lkWarning,
               // Errors
               lkError,
               // Unrecoverable errors
               lkFatalError,
               // Custom level 1
               lkCustom1,
               // Custom level 2
               lkCustom2,
               // Custom level 3
               lkCustom3);
  // Log level setting type
  TLogLevels = set of TLogLevel;

const
  // Set of all log levels
  llFull:     TLogLevels = [Low(TLogLevel)..High(TLogLevel)];
  // Set of all error log levels
  llErrors:   TLogLevels = [lkError, lkFatalError];
  // Set of all error and warning log levels
  llWarnings: TLogLevels = [lkWarning, lkError, lkFatalError];

  // Default level prefixes
  lkPrefix: array[TLogLevel] of string = (' (D)    ', ' (i)    ', ' (I)  ', '(WW)  ', '(EE)  ', '(!!)  ', ' (1)  ', ' (2)    ', ' (3)    ');

type
  // Method pointer which formats
  TLogFormatDelegate = function(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel): string of object;

  // Log appender metaclass
  CAppender = class of TAppender;
  // Abstract log appender
  TAppender = class(TObject)
  public
    // Creates the appender with the specified log levels
    constructor Create(ALevels: TLogLevels);
  protected
    // Should be overridden to actually append log
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel); virtual; abstract;
  private
    FFormatter: TLogFormatDelegate;
    FLogLevels: TLogLevels;
    function GetPreparedStr(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel): string;
    procedure SetLevels(Levels: TLogLevels);
  public
    // Set of levels which to include in the log
    property LogLevels: TLogLevels read FLogLevels write SetLevels;
    // String formatter delegate. It's recommended for descendant classes to use it.
    property Formatter: TLogFormatDelegate read FFormatter write FFormatter;
  end;

  // Calls all registered appenders to log the string
  procedure Log(const Str: string; Level: TLogLevel = lkInfo); overload;
  // Calls all registered appenders to log the string with source location information
  procedure Log(const Str: string; SrcLoc: TCodeLocation; Level: TLogLevel = lkInfo); overload;
  // Calls all registered appenders to log the fatal error
  procedure Fatal(const Str: string);
  // Calls all registered appenders to log the error
  procedure Error(const Str: string);
  // Calls all registered appenders to log the warning
  procedure Warning(const Str: string);
  // Calls all registered appenders to log the notice
  procedure Notice(const Str: string);

  { A special function-argument. Should be called ONLY as Assert() argument.
    Allows to log source file name and line number at calling location.
    Doesn't require any debug information to be included in binary module.
    The only requirement is inclusion of assertions code.
    Tested in Delphi 7+ and FPC 2.4.2+.

    Suggested usage:

    Assert(_Log(lkInfo), 'Log message');

    This call will log the message with source filename and Line number
    Always returns False. }
  function _Log(Level: TLogLevel = lkInfo): Boolean;

  // Adds an appender to list of registered appenders. All registered appenders will be destroyed on shutdown.
  procedure AddAppender(Appender: TAppender);
  // Removes an appender from list of registered appenders. Doesn't destroy the appender.
  procedure RemoveAppender(Appender: TAppender);
  // Returns a registered appender of the specified class
  function FindAppender(AppenderClass: CAppender): TAppender;

  { Initializes default appenders:
    TConsoleAppender if current application is a console application
    TWinDebugAppender for Delphi applications running under debugger in Windows OS
  }
  procedure AddDefaultAppenders();

  // Removes all appenders added by AddDefaultAppenders() if any
  procedure RemoveDefaultAppenders();

type
  // Appends log messages to a system console. Application should be a console application.
  TSysConsoleAppender = class(TAppender)
  protected
    // Prints the log string to a system console
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel); override;
  end;

  // Use OutputsDebugString() for loging. Works only in Windows.
  TWinDebugAppender = class(TAppender)
  protected
    // Prints the log string with OutputsDebugString()
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel); override;
  end;

  // Appends log messages to a file.
  TFileAppender = class(TAppender)
  public
    // Creates the appender with the specified file name and log levels
    constructor Create(const Filename: string; ALevels: TLogLevels);
  protected
    // Appends file with the log string
    procedure AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel); override;
  private
    LogFile: Text;
  end;


implementation

uses
  {$IFDEF MULTITHREADLOG}
    SyncObjs,
  {$ENDIF}
  {$IFDEF WINDOWS}{$IFDEF DELPHI}
    Windows,
  {$ENDIF}{$ENDIF}
  SysUtils;

{ TAppender }

constructor TAppender.Create(ALevels: TLogLevels);
begin
  LogLevels  := ALevels;
  FFormatter := GetPreparedStr;
end;

function TAppender.GetPreparedStr(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel): string;
begin
  Result := FormatDateTime('dd"/"mm"/"yyyy hh":"nn":"ss"."zzz  ', Now()) + lkPrefix[Level] + Str;
  if (CodeLoc <> nil) then
    Result := Concat(Result, ' --- ', CodeLocToStr(CodeLoc^));
end;

procedure TAppender.SetLevels(Levels: TLogLevels);
begin
  FLogLevels := Levels;
end;

{ Logger }

var
  FAppenders: array of TAppender;
  {$IFDEF MULTITHREADLOG}
    CriticalSection: TCriticalSection;
  {$ENDIF}
  LogLevelCount: array[TLogLevel] of Integer;

procedure Lock();
begin
  {$IFDEF MULTITHREADLOG}
    CriticalSection.Enter();
  {$ENDIF}
end;

procedure UnLock();
begin
  {$IFDEF MULTITHREADLOG}
    CriticalSection.Leave();
  {$ENDIF}
end;

procedure Log(const Str: string; Level: TLogLevel = lkInfo);
{$IFDEF LOGGING} var i: Integer; Time: TDateTime; {$ENDIF}
begin
  {$IFDEF LOGGING}
  Lock();

  Time := Now;

  for i := 0 to High(FAppenders) do
    if Level in FAppenders[i].LogLevels then
      FAppenders[i].AppendLog(Time, Str, nil, Level);

  UnLock();

  Inc(LogLevelCount[Level]);
  {$ENDIF}
end;

procedure Log(const Str: string; SrcLoc: TCodeLocation; Level: TLogLevel = lkInfo); overload;
{$IFDEF LOGGING} var i: Integer; Time: TDateTime; {$ENDIF}
begin
  {$IFDEF LOGGING}
  Lock();

  Time := Now;

  for i := 0 to High(FAppenders) do
    if Level in FAppenders[i].LogLevels then
      FAppenders[i].AppendLog(Time, Str, @SrcLoc, Level);

  UnLock();

  Inc(LogLevelCount[Level]);
  {$ENDIF}
end;

procedure Fatal(const Str: string);
begin
  {$IFDEF LOGGING} Log(Str, lkFatalError); {$ENDIF}
end;

procedure Error(const Str: string);
begin
  {$IFDEF LOGGING} Log(Str, lkError); {$ENDIF}
end;

procedure Warning(const Str: string);
begin
  {$IFDEF LOGGING} Log(Str, lkWarning); {$ENDIF}
end;

procedure Notice(const Str: string);
begin
  {$IFDEF LOGGING} Log(Str, lkNotice); {$ENDIF}
end;

var
  StoredAssertProc: TAssertErrorProc = nil;
  AssertLogLevel: TLogLevel;

{$IFDEF FPC}
  procedure LogAssert(const Message, Filename: ShortString; LineNumber: LongInt; ErrorAddr: Pointer);
{$ELSE}
  procedure LogAssert(const Message, Filename: string; LineNumber: Integer; ErrorAddr: Pointer);
{$ENDIF}
var CodeLocation: TCodeLocation;
begin
  AssertErrorProc := StoredAssertProc;
  StoredAssertProc := nil;
  AssertUnlock();

  CodeLocation := GetCodeLoc(Filename, '', '', LineNumber, ErrorAddr);

  Log(Message, CodeLocation, AssertLogLevel);
end;

function _Log(Level: TLogLevel = lkInfo): Boolean;
begin
  Assert(@StoredAssertProc = nil, '_Log() can be used only as Assert() argument');

  AssertLock();
  AssertLogLevel   := Level;
  StoredAssertProc := AssertErrorProc;
  AssertErrorProc  := @LogAssert;
  Result := False;
end;

procedure AddAppender(Appender: TAppender);
begin
  if not Assigned(Appender) then Exit;
  Lock();
  SetLength(FAppenders, Length(FAppenders)+1);
  // Set default formatter
  if @Appender.Formatter = nil then Appender.Formatter := Appender.GetPreparedStr;
  FAppenders[High(FAppenders)] := Appender;
  Unlock();
end;

procedure RemoveAppender(Appender: TAppender);
var i: Integer;
begin
  // Find appender
  i := 0;
  while (i <= High(FAppenders)) and (FAppenders[i] <> Appender) do Inc(i);

  // if found, replace it with last and resize array
  if i <= High(FAppenders) then begin
    Lock();
    FAppenders[i] := FAppenders[High(FAppenders)];
    SetLength(FAppenders, Length(FAppenders)-1);
    Unlock();
  end;
end;

function FindAppender(AppenderClass: CAppender): TAppender;
var i: Integer;
begin
  i := High(FAppenders);
  while (i >= 0) and (FAppenders[i].ClassType <> AppenderClass) do Dec(i);

  if i >= 0 then
    Result := FAppenders[i]
  else
    Result := nil;
end;

procedure AddDefaultAppenders();
begin
  {$IFDEF WINDOWS}{$IFDEF DELPHI}
    if DebugHook > 0 then
      AddAppender(TWinDebugAppender.Create(llFull));
  {$ENDIF}{$ENDIF}

  if IsConsole then begin
    if Length(FAppenders) = 0 then
      AddAppender(TSysConsoleAppender.Create(llFull))
    else
      AddAppender(TSysConsoleAppender.Create([lkWarning, lkError, lkFatalError]))
  end;
end;

procedure RemoveDefaultAppenders();
begin
  if IsConsole then
    RemoveAppender(FindAppender(TSysConsoleAppender));

  {$IFDEF WINDOWS}{$IFDEF DELPHI}
    if DebugHook > 0 then
      RemoveAppender(FindAppender(TWinDebugAppender));
  {$ENDIF}{$ENDIF}
end;

procedure DestroyAppenders();
var i: Integer;
begin
  Lock();
  for i := 0 to High(FAppenders) do begin
    FAppenders[i].Free;
  end;
  SetLength(FAppenders, 0);
  Unlock();
end;

{ TConsoleAppender }

procedure TSysConsoleAppender.AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel);
begin
  if IsConsole then
    Writeln(Formatter(Time, Str, CodeLoc, Level));
end;

{ TWinDebugAppender }

procedure TWinDebugAppender.AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel);
begin
  {$IFDEF WINDOWS}{$IFDEF DELPHI}
    if DebugHook > 0 then
      {$IFDEF UNICODE}
        OutputDebugString(PWideChar(Formatter(Time, Str, CodeLoc, Level)));
      {$ELSE}
        OutputDebugStringA(PAnsiChar(Formatter(Time, Str, CodeLoc, Level)));
      {$ENDIF}
  {$ENDIF}{$ENDIF}
end;

{ TFileAppender }

constructor TFileAppender.Create(const Filename: string; ALevels: TLogLevels);
begin
  LogLevels  := ALevels;
  FFormatter := GetPreparedStr;

  if (Pos(':', Filename) > 0) or (Pos('/', Filename) = 1) then
    AssignFile(LogFile, Filename)
  else
    AssignFile(LogFile, ExtractFilePath(ParamStr(0)) + Filename);

  {$I-}
  Rewrite(LogFile);
  CloseFile(LogFile);
  //if IOResult <> 0 then LogLevels := [];
end;

procedure TFileAppender.AppendLog(const Time: TDateTime; const Str: string; CodeLoc: PCodeLocation; Level: TLogLevel);
begin
  {$I-}
  Append(LogFile);
  if IOResult <> 0 then Exit;
  WriteLn(LogFile, Formatter(Time, Str, CodeLoc, Level));
  Flush(LogFile);
  CloseFile(LogFile);
end;

initialization
  {$IFDEF MULTITHREADLOG}
    CriticalSection := TCriticalSection.Create();
  {$ENDIF}
  FillChar(LogLevelCount, SizeOf(LogLevelCount), 0);
  AddDefaultAppenders();
finalization
  Notice('Log session shutdown');
  Log('Logged fatal errors: ' + IntToStr(LogLevelCount[lkFatalError])
    + ', errors: ' + IntToStr(LogLevelCount[lkError])
    + ', warnings: ' + IntToStr(LogLevelCount[lkWarning])
    + ', titles: ' + IntToStr(LogLevelCount[lkNotice])
    + ', infos: ' + IntToStr(LogLevelCount[lkInfo])
    + ', debug info: ' + IntToStr(LogLevelCount[lkDebug]) );
  DestroyAppenders();
  {$IFDEF MULTITHREADLOG}
    CriticalSection.Free();
  {$ENDIF}
end.

