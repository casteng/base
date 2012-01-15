(*
 @Abstract(Application Initialization Unit)
 (C) 2003-2007 George "Mirage" Bakhtadze
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains abstract application initialization and maintenance classes
*)
{$Include GDefines.inc}
unit AppsInit;

interface

uses
  Logger,
  BaseTypes, Basics, BaseMsg, OSUtils;

type
  // Possible application option flags
  TStarterOption = ({ Without this option the starter will create a working directory for the application in current user's documents directory (usally within "my documents" folder")
                      If the option is included the directory with the application's .exe file will be used as working directory. Not recommended under Windows Vista. }
                    soSingleUser,
                    // If this option is included current directory will be not changed by the starter, else it will be changed to working directory
                    soPreserveDir);
  // Application option flag set
  TStarterOptions = set of TStarterOption;
  // Window handle type
  TWindowHandle = Cardinal;

  { Application starter base class
    The class manages application startup process, creates window, forwards windows messages, etc }
  TAppStarter = class
  private
    FTerminated, FActive: Boolean;
  protected
    // Application name
    FProgramName,
    // Application .exe file name
    FProgramExeName,
    // Application .exe directory
    FProgramExeDir,
    // Application working directory
    FProgramWorkDir: string;
    // Application version string
    FProgramVersionStr: string[16];
    // Application window handle
    FWindowHandle: TWindowHandle;

    // Returns <b>True</b> if the application is terminated
    function GetTerminated: Boolean; virtual;
    // Windows message handler
    function ProcessMessage(Msg: Longword; wParam: Integer; lParam: Integer): Integer; virtual;
    // This method should be overridden to do command line parameters parsing
    procedure ParseParamStr; virtual;
    // This method should be overridden for variables custom initialization
    procedure Init; virtual;
  public
    // Determines if message handling is needed. <b>True</b> by default.
    HandleMessages: Boolean;
    // Determines if a default window message handler should be called
    CallDefaultMsgHandler: Boolean;
    // A message handler to forward Window messages to
    MessageHandler: TMessageHandler;
    // Time to sleep in milliseconds when the application is not active (60 default)
    InactiveSleepAmount: Integer;
    // Create and setup an application with the given name. If <b>AWindowProc</b> is <b>nil</b> a default procedure will be used.
    constructor Create(const AProgramName: string; Options: TStarterOptions);
    // Immediate termination
    destructor Destroy; override;
    // Set <b>Terminated</b> flag. Normally the application will be terminated as soon as possible.
    procedure Terminate; virtual;
    // Returns <b>True</b> if another instance of the application is already rinning. If <b>ActivateExisting</b> is <b>True</b> the other instance will be activated.
    function isAlreadyRunning(ActivateExisting: Boolean): Boolean; virtual; abstract;
    // Should be called each application cycle. Usally overridden to perform message processing. Returns negate value of @Link(Terminated) property.
    function Process: Boolean; virtual; abstract;
    // Prints an error information
    procedure PrintError(const Msg: string; ErrorType: TLogLevel); virtual; abstract;

    // Application name
    property ProgramName: string read FProgramName;
    // Application .exe file name
    property ProgramExeName: string read FProgramExeName;
    // Application .exe directory including trailing path delimiter
    property ProgramExeDir: string read FProgramExeDir;
    // Application working directory including trailing path delimiter
    property ProgramWorkDir: string read FProgramWorkDir;
    // <b>True</b> if the application's window is currently active
    property Active: Boolean read FActive write FActive;
    // <b>True</b> if the application is terminated
    property Terminated: Boolean read GetTerminated write FTerminated;
    // Application window handle
    property WindowHandle: TWindowHandle read FWindowHandle;
  end;

implementation

uses SysUtils;

{ TAppStarter }

function TAppStarter.GetTerminated: Boolean;
begin
  Result := FTerminated;
end;

function TAppStarter.ProcessMessage(Msg: Longword; wParam, lParam: Integer): Integer;
begin
  if Assigned(MessageHandler) then MessageHandler(WMToMessage(Msg, wParam, lParam));
  Result := 1;
end;

procedure TAppStarter.ParseParamStr;
begin
end;

procedure TAppStarter.Init;
begin
end;

constructor TAppStarter.Create(const AProgramName: string; Options: TStarterOptions);
var ExeExt: string;
begin
  FWindowHandle := 0;                                     // No window yet
  FProgramName := AProgramName;
  ExeExt := ExtractFileExt(ParamStr(0));
  FProgramExeName := LowerCase(ExtractFileName(ParamStr(0)));
  if ExeExt <> '' then FProgramExeName := Copy(ProgramExeName, 1, Length(ProgramExeName) - Length(ExeExt));

  FProgramExeDir := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));

  FProgramWorkDir := '';
  if not (soSingleUser in Options) then begin
    FProgramWorkDir := IncludeTrailingPathDelimiter(GetSysFolder(sfPersonal)) + ProgramExeName;
    if not DirectoryExists(ProgramWorkDir) then
      if not CreateDir(ProgramWorkDir) then begin
        Log(ClassName + '.Create: Can''t create directory "' + ProgramWorkDir + '"', lkError);
        FProgramWorkDir := '';
      end;
  end;
  if ProgramWorkDir = '' then FProgramWorkDir := FProgramExeDir;

  if not (soPreserveDir in Options) then SetCurrentDir(ProgramWorkDir);

  Init;

  Terminated := False;
  if isAlreadyRunning(True) then begin
    Log(ClassName + '.Create: Application instance is already running', lkError);
    Terminated := True;
  end;

  InactiveSleepAmount := 60;
end;

destructor TAppStarter.Destroy;
begin
  Terminate;
  inherited;
end;

procedure TAppStarter.Terminate;
begin
  FTerminated := True;
end;

end.
