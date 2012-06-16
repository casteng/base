(*
 @Abstract(Application Initialization Unit)
 (C) 2003-2011 George "Mirage" Bakhtadze
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains Windows platform specific application and window initialization and maintenance classes
*)
{$Include GDefines.inc}
unit AppsInitWin;

interface

uses
  Logger,
  BaseTypes, Basics, BaseMsg, OSUtils, AppsInit,
  Windows, Messages, ShellAPI;

const
  WM_NOTIFYTRAYICON = WM_USER + 1;

type
  // Windows message handling callback
  TWndProc = function (WHandle: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

  TWin32BaseAppStarter = class(TAppStarter)
  private
    FWindowProc: TWndProc;
    // Application window style
    FWindowStyle: Cardinal;
  public
    // Sets window callback
    procedure SetWndProc(AWindowProc: TWndProc);
    constructor Create(const AProgramName: string; Options: TStarterOptions);
    // Application window style
    property WindowStyle: Cardinal read FWindowStyle;
  end;

  // Screen saver specific implementation of @Link(TAppStarter)
  TScreenSaverStarter = class(TWin32BaseAppStarter)
  private
    MutexWindowHandle: hWnd;
    Rect: TRect;
    ParamChar: Char;
    FWindowClassName: string;
    FParentWindow: hWnd;
    FPreviewMode: Boolean;
    FMoveCounter: Integer;
  protected
    // Current window class
    WindowClass: TWndClass;
    // Windows message handler
    function ProcessMessage(Msg: Longword; wParam: Integer; lParam: Integer): Integer; override;
    // This method should be overridden to do parameters parsing
    procedure ParseParamStr; override;
  public
    // Create and setup a screen saver with the given name. If <b>AWindowProc</b> is <b>nil</b> a default procedure will be used.
    constructor Create(const AProgramName: string; Options: TStarterOptions);
    destructor Destroy; override;
    // Runs the screen saver. If <b>APreviewMode</b> is <b>True</b> the screen saver will run in preview window.
    procedure Run(APreviewMode: Boolean); virtual;
    // Calls system routine to request password
    procedure SetPassword; virtual;
    // Calls system routine to ask user for password and returns <b>True</b> if no password needed or user enter correct password
    function QueryPassword: Boolean; virtual;
    // Shows a configuration window. Usally called from OS screen saver setup dialog
    procedure Configure; virtual;
    // Prints an error information
    procedure PrintError(const Msg: string; ErrorType: TLogLevel); override;

    // <b>True</b> if the screen saver is running in preview mode
    property PreviewMode: Boolean read FPreviewMode;
  end;

  // Win32 implementation of @Link(TAppStarter)
  TWin32AppStarter = class(TWin32BaseAppStarter)
  private
    FWindowClassName: string;
  protected
    // Current window class
    WindowClass: TWndClass;
    // Windows message handler
    function ProcessMessage(Msg: Longword; wParam: Integer; lParam: Integer): Integer; override;
    // Should be override for custom window settings
    procedure InitWindowSettings(var AWindowClass: TWndClass; var ARect: BaseTypes.TRect); virtual;
  public
    constructor Create(const AProgramName: string; Options: TStarterOptions);
    destructor Destroy; override;
    { Returns <b>True</b> if another instance of the application (currently, an application with the same window class name) is already rinning.
      If <b>ActivateExisting</b> is <b>True</b> the other instance will be activated. }
    function isAlreadyRunning(ActivateExisting: Boolean): Boolean; override;
    // Performs win32 messages processing
    function Process: Boolean; override;
    procedure PrintError(const Msg: string; ErrorType: TLogLevel); override;

    // Application's window class name
    property WindowClassName: string read FWindowClassName;
  end;

  // Starter class for a Win32 application with an icon in system tray
  TTrayAppStarter = class(TWin32AppStarter)
  private
    TrayIcon: TNotifyIconData;
  protected
    // Windows message handler
    function ProcessMessage(Msg: Longword; wParam: Integer; lParam: Integer): Integer; override;
  public
    // Adds an icon to system tray and returns <b>True</b> if success
    function AddTrayIcon: Boolean;
    // Removes an icon to system tray
    procedure RemoveTrayIcon;
    destructor Destroy; override;
  end;

implementation

uses SysUtils;

type
  TVerifySSPassFunc = function(Parent: hWnd): Bool; StdCall;
  TChgPassAFunc = function(A: PChar; Parent: hWnd; B, C: Integer): Integer; StdCall;

var
  CurrentStarter: TWin32BaseAppStarter;

function StdWindowProc(WHandle: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  if (CurrentStarter = nil) or (CurrentStarter.WindowHandle = 0) or (CurrentStarter.Terminated) then begin
//    Log('*** <Default> Message: ' + Format('%D, %D, %D', [Msg, wParam, lParam]), lkError);
    Result := DefWindowProc(WHandle, Msg, wParam, lParam)
  end else begin
//    Log('*** Message: ' + Format('%D, %D, %D', [Msg, wParam, lParam]), lkError);
    CurrentStarter.CallDefaultMsgHandler := True;
    Result := CurrentStarter.ProcessMessage(Msg, wParam, lParam);
    if CurrentStarter.CallDefaultMsgHandler then Result := DefWindowProc(WHandle, Msg, wParam, lParam);
  end;
end;

{ TWin32BaseAppStarter }

constructor TWin32BaseAppStarter.Create(const AProgramName: string; Options: TStarterOptions);
begin
  inherited;
  CurrentStarter := Self;
  SetWndProc(@StdWindowProc);
  Active := GetActiveWindow = WindowHandle;
end;

procedure TWin32BaseAppStarter.SetWndProc(AWindowProc: TWndProc);
begin
  FWindowProc := AWindowProc;
end;

{ TWin32AppStarter }

function TWin32AppStarter.ProcessMessage(Msg: Longword; wParam, lParam: Integer): Integer;
begin
  Result := inherited ProcessMessage(Msg, wParam, lParam);
  case Msg of
    WM_CLOSE: begin
      Result := 0; Terminated := True;
    end;
    WM_ACTIVATEAPP: begin
      if (wParam and 65535 = WA_ACTIVE) or (wParam and 65535 = WA_CLICKACTIVE) then Active := True;
      if wParam and 65535 = WA_INACTIVE then Active := False;
    end;
  end;
end;

procedure TWin32AppStarter.InitWindowSettings(var AWindowClass: TWndClass; var ARect: BaseTypes.TRect);
begin
end;

constructor TWin32AppStarter.Create(const AProgramName: string; Options: TStarterOptions);
const SizePercent = 70;
var
  ScreenX, ScreenY: Integer;
  WinRect: BaseTypes.TRect;
  R: HRGN;
begin
  inherited;
  FWindowStyle := WS_OVERLAPPED or WS_CAPTION or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX or WS_SYSMENU;
//  WindowStyle := WS_OVERLAPPEDWINDOW{ or WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX};
  WindowClass.style := 0;//CS_VREDRAW or CS_HREDRAW or CS_OWNDC;
  WindowClass.lpfnWndProc := @FWindowProc;
  WindowClass.cbClsExtra := 0;
  WindowClass.cbWndExtra := 0;
  WindowClass.hIcon := LoadIcon(hInstance, 'MAINICON');
  WindowClass.hCursor := LoadCursor(WindowClass.hInstance*0, IDC_ARROW);
  WindowClass.hInstance := HInstance;
  WindowClass.hbrBackground := 0;//GetStockObject(WHITE_BRUSH);
  WindowClass.lpszMenuName := nil;
  FWindowClassName := 'TAWindowClass(' + AProgramName + ')';
  WindowClass.lpszClassName := PChar(FWindowClassName);

  if RegisterClass(WindowClass) = 0 then begin
    Log('TWin32AppStarter.Create: Window class registration failed', lkFatalError);
    Exit;
  end;
  ScreenX := GetSystemMetrics(SM_CXSCREEN);
  ScreenY := GetSystemMetrics(SM_CYSCREEN);
  if ScreenX = 0 then ScreenX := 640;
  if ScreenY = 0 then ScreenY := 480;

//  WinRect := GetRectWH((ScreenX - ScreenX * SizePercent div 100) div 2, (ScreenY - ScreenY * SizePercent div 100) div 2,
//                       ScreenX * SizePercent div 100, ScreenY * SizePercent div 100);
  WinRect := GetRectWH((ScreenX - 1024) div 2+300, (ScreenY - 768) div 2, 1024+4, 768+28);

//  WinRect := GetRectWH(-4, -30, ScreenX+8, ScreenY + 30);

  InitWindowSettings(WindowClass, WinRect);

  FWindowHandle := Windows.CreateWindow(WindowClass.lpszClassName, PChar(AProgramName), FWindowStyle,
                                        WinRect.Left, WinRect.Top, WinRect.Right-WinRect.Left, WinRect.Bottom-WinRect.Top,
                                        0, 0, HInstance, nil);
  if FWindowHandle = 0 then begin
    Log('TWin32AppStarter.Create: Window creation failed', lkFatalError);
    Exit;
  end;

//  R:=CreateRectRgn(4,30,WinRect.Right,WinRect.Bottom);
//  SetWindowRgn(FWindowHandle,R,TRUE);

  ShowWindow(FWindowHandle, SW_NORMAL);

  HandleMessages := True;
end;

procedure TWin32AppStarter.PrintError(const Msg: string; ErrorType: TLogLevel);
begin
  if ErrorType = LLInfo then
    MessageBox(WindowHandle, PChar(Msg), 'Information', MB_ICONINFORMATION)
  else if ErrorType = LLWarning then
    MessageBox(WindowHandle, PChar(Msg), 'Warning',     MB_ICONWARNING)
  else if ErrorType = LLError then
    MessageBox(WindowHandle, PChar(Msg), 'Error',       MB_ICONERROR)
  else if ErrorType = LLFatalError then
    MessageBox(WindowHandle, PChar(Msg), 'Fatal error', MB_ICONSTOP);

  Log(Msg, ErrorType);
end;

destructor TWin32AppStarter.Destroy;
begin
  if WindowHandle <> 0 then DestroyWindow(WindowHandle);
  if not UnRegisterClass(PChar(WindowClassName), hInstance) then
  Log('Error unregistering window class: ' + GetOSErrorStr(GetLastError), lkError);
  inherited;
end;

function TWin32AppStarter.isAlreadyRunning(ActivateExisting: Boolean): Boolean;
var h: HWND;
begin
  h := FindWindow(PChar(WindowClassName), nil);
  Result := h <> 0;
  if Result and ActivateExisting then begin
//    SetActiveWindow(h);
    SetForegroundWindow(h);
    PostMessage(h, WM_NOTIFYTRAYICON, 0, WM_LBUTTONDOWN);
  end;
  {$IFDEF DEBUGMODE}
  if Result and ActivateExisting then PostMessage(h, WM_NOTIFYTRAYICON, 0, WM_LBUTTONDOWN);
  SetWindowPos(h, HWND_TOP, GetSystemMetrics(SM_CXSCREEN) div 2, 0, GetSystemMetrics(SM_CXSCREEN) div 2, GetSystemMetrics(SM_CYSCREEN)*2 div 3, SWP_NOACTIVATE{ or SWP_NOSIZE});
  Result := False;
  {$ENDIF}
end;

function TWin32AppStarter.Process: Boolean;
var Msg: tagMSG;
begin
  if HandleMessages then begin
    if (PeekMessage(Msg, WindowHandle, 0, 0, PM_REMOVE)) then begin
      repeat
        with Msg do begin
          if message = WM_QUIT then Terminated := True;
          if (message = WM_KEYDOWN) or (message = WM_KEYUP) or (message = WM_SYSKEYDOWN) or (message = WM_SYSKEYUP) then TranslateMessage(Msg);
        end;
        DispatchMessage(Msg);
      until not PeekMessage(Msg, WindowHandle, 0, 0, PM_REMOVE);
    end else if not Active then begin
      if InactiveSleepAmount >= 0 then begin
        Sleep(InactiveSleepAmount);
  //      Log('sleeping...');
      end;
      Active := GetActiveWindow = WindowHandle;
    end;
  end;
  Result := not Terminated;
end;

{ TTrayAppStarter }

function TTrayAppStarter.AddTrayIcon: Boolean;
const
  TrayMsg = 'Click to restore ';
  MsgMaxLength = 64;
var i, len: Integer; Title: PChar;
begin
  TrayIcon.cbSize := SizeOf(TNotifyIconData);
  {$IFDEF FPC} TrayIcon.HWnd := WindowHandle; {$ELSE} TrayIcon.Wnd := WindowHandle; {$ENDIF}
  TrayIcon.uID := 1;
  TrayIcon.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
  TrayIcon.uCallBackMessage := WM_NOTIFYTRAYICON;
  TrayIcon.hIcon := WindowClass.hIcon;
  TrayIcon.szTip := TrayMsg;

  Getmem(Title, MsgMaxLength*4);       // Reserve memory for a unicode string

  if GetWindowText(WindowHandle, Title, MsgMaxLength-1) = 0 then begin
    FreeMem(Title);
    Title := PChar(WindowClassName);
  end;
  if Length(Title) + Length(TrayMsg) < MsgMaxLength then
    Len := Length(Title) else
      Len := MsgMaxLength-Length(TrayMsg);
  for i := 1 to Len do TrayIcon.szTip[i+Length(TrayMsg)-1] := Title[i-1];

  FreeMem(Title);
  Result := Shell_NotifyIcon(NIM_ADD, PNotifyIconData(@TrayIcon));
end;

procedure TTrayAppStarter.RemoveTrayIcon;
begin
  Shell_NotifyIcon(NIM_DELETE, PNotifyIconData(@TrayIcon));
end;

function TTrayAppStarter.ProcessMessage(Msg: Longword; wParam, lParam: Integer): Integer;
begin
  Result := inherited ProcessMessage(Msg, wParam, lParam);
  case Msg of
    WM_NOTIFYTRAYICON: if lParam = WM_LBUTTONDOWN then begin
      RemoveTrayIcon;
      ShowWindow(WindowHandle, SW_SHOW);
      ShowWindow(WindowHandle, SW_RESTORE);
    end;
//    WM_ERASEBKGND, WM_PAINT: Result := 1;//DefWindowProc(WHandle, Msg, WParam, LParam);
    WM_SIZE{, WM_CANCELMODE}: begin
      if wParam = SIZE_MINIMIZED then begin
        if AddTrayIcon then ShowWindow(WindowHandle, SW_HIDE);
        Active := False;
      end;
    end;
  end;
end;

destructor TTrayAppStarter.Destroy;
begin
  RemoveTrayIcon;
  inherited;
end;

{ TScreenSaverStarter }

function PreviewThreadProc(Data : Integer) : Integer; StdCall;
begin
  Sleep(1000);
  Result := 0; Randomize;
  ShowWindow(CurrentStarter.WindowHandle, SW_SHOW); UpdateWindow(CurrentStarter.WindowHandle);
  repeat
    InvalidateRect(CurrentStarter.WindowHandle, nil, False);
    Sleep(30);
  until CurrentStarter.Terminated;
  PostMessage(CurrentStarter.WindowHandle, wm_Destroy, 0, 0);
end;

constructor TScreenSaverStarter.Create(const AProgramName: string; Options: TStarterOptions);
begin
  inherited;

  GetWindowRect(GetDesktopWindow, Rect);

  ParseParamStr;

  Run(FParentWindow <> 0);
{  if (cc = 'C') Then RunSettings
  Else If (cc = 'P') Then RunPreview
       Else If (cc = 'A') Then RunSetPassword
            Else RunFullScreen;}
end;

procedure TScreenSaverStarter.ParseParamStr;
var s: string;
begin
  s := ParamStr(1);
  if (Length(s) > 1) then begin
    Delete(s, 1, 1); { delete first char - usally "/" or "-" }
//    S[1] := UpCase(S[1]);
    ParamChar := UpCase(s[1]);
  end;

  if (ParamChar = 'P') then begin
    FParentWindow := StrToIntDef(ParamStr(2), 0);
    GetWindowRect(FParentWindow, Rect);
  end else FParentWindow := 0;
  if (ParamChar = 'C') then Configure;
end;

procedure TScreenSaverStarter.Run(APreviewMode: Boolean);
var Dummy: Cardinal;
begin
  FPreviewMode := APreviewMode;
  FMoveCounter := 10;

  WindowClass.style := 0; //CS_VREDRAW or CS_HREDRAW or CS_OWNDC;
  WindowClass.lpfnWndProc := @FWindowProc;
  WindowClass.cbClsExtra := 0;
  WindowClass.cbWndExtra := 0;
  WindowClass.hIcon := LoadIcon(hInstance, 'MAINICON');
  WindowClass.hCursor := LoadCursor(WindowClass.hInstance*0, IDC_ARROW);
  WindowClass.hInstance := HInstance;
  WindowClass.hbrBackground := 0;//GetStockObject(WHITE_BRUSH);
  WindowClass.lpszMenuName := nil;
  FWindowClassName := 'TAWindowClass(' + ProgramName + ')';
  WindowClass.lpszClassName := PChar(FWindowClassName);

  if RegisterClass(WindowClass) = 0 then begin
    Log('TScreenSaverStarter.Create: Window class registration failed', lkFatalError); 
    Exit;
  end;
  if (FParentWindow <> 0) then begin
    FWindowStyle  := WS_CHILD or WS_VISIBLE or WS_DISABLED;
    FWindowHandle := CreateWindow(WindowClass.lpszClassName, WindowClass.lpszClassName, FWindowStyle, 0, 0, Rect.Right-Rect.Left, Rect.Bottom-Rect.Top, FParentWindow, 0, hInstance, nil);
    MutexWindowHandle := 0;//CreateWindow(WindowClass.lpszClassName, 'Mutex', WS_DISABLED, -10, -10, 1, 1, 0, 0, hInstance, nil);
//    SetWindowPos(MutexWindowHandle, 0, -10, -10, 1, 1, SWP_HIDEWINDOW or SWP_NOACTIVATE);
  end else begin
//    WindowStyle := WS_OVERLAPPED or WS_CAPTION or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX or WS_SYSMENU;
    FWindowStyle  := Cardinal(WS_VISIBLE or WS_POPUP);
    FWindowHandle := CreateWindow(WindowClass.lpszClassName, nil{WindowClass.lpszClassName},
                                 FWindowStyle, 0, 0,
                                 Rect.Right-Rect.Left, Rect.Bottom-Rect.Top, 0, 0, hInstance, nil);
    {$IFNDEF DEBUGMODE}
    SetWindowPos(WindowHandle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOREDRAW);
    {$ENDIF}    
  end;

// ShowWindow(CurrentStarter.WindowHandle, SW_SHOW); UpdateWindow(CurrentStarter.WindowHandle);

  if FPreviewMode then OSUtils.ShowCursor;
//  if PreviewMode then CreateThread(nil, 0, @PreviewThreadProc, nil, 0, Dummy);
  if not FPreviewMode then SystemParametersInfo(SPI_SCREENSAVERRUNNING, 1, @Dummy, 0);
end;

procedure TScreenSaverStarter.SetPassword;
var
  Lib: THandle;
  ChgPassAFunc: TChgPassAFunc;
begin
  Lib := LoadLibrary('MPR.DLL');
  if Lib > 0 Then begin
    ChgPassAFunc := TChgPassAFunc(GetProcAddress(Lib,'PwdChangePasswordA'));
    if (@ChgPassAFunc <> nil) then ChgPassAFunc('SCRSAVE', StrToInt(ParamStr(2)), 0, 0);
    FreeLibrary(Lib);
  end;
end;

function TScreenSaverStarter.QueryPassword: Boolean;
var
  Key: hKey;
  D1, D2: Integer; { two dummies }
  Value: Integer;
  Lib: THandle;
  VerifySSPassFunc: TVerifySSPassFunc;
begin
  Result := True;
  if RegOpenKeyEx(HKEY_CURRENT_USER, 'Control Panel\Desktop', 0, KEY_READ,Key) = ERROR_SUCCESS then begin
    D2 := SizeOf(Value);
    if RegQueryValueEx(Key, 'ScreenSaveUsePassword', nil, @D1, @Value, @D2) = ERROR_SUCCESS then begin
      if Value <> 0 then begin
        Lib := LoadLibrary('PASSWORD.CPL');
        if Lib > 0 then begin
          VerifySSPassFunc := TVerifySSPassFunc(GetProcAddress(Lib,'VerifyScreenSavePwd'));
          AdjustCursorVisibility(True);
          if @VerifySSPassFunc <> nil then Result := VerifySSPassFunc(FParentWindow);
          AdjustCursorVisibility(False);
          FMoveCounter := 10; { reset again if password was wrong }
          FreeLibrary(Lib);
        end;
      end;
    end;
    RegCloseKey(Key);
  end;
end;

procedure TScreenSaverStarter.Configure;
begin
  MessageBox(WindowHandle, 'There is no settings yet.'#13#10#13#10'You can use Q/W/E/S/Z/C keys to control view angle', 'Info', MB_OK);
  Terminated := True;
end;

procedure DrawSingleBox;
{var
  PaintDC  : hDC;
  Info     : TPaintStruct;
  OldBrush : hBrush;
  X,Y      : Integer;
  Color    : LongInt;
  WndRect: TRect;}
begin
{  PaintDC := beginPaint(CurrentStarter.WindowHandle, Info);
  GetWindowRect(CurrentStarter.WindowHandle, WndRect);
  X := Random(WndRect.Right); Y := Random(WndRect.Bottom);
  Color := RGB(Random(255),Random(255),Random(255));
  OldBrush := SelectObject(PaintDC,CreateSolidBrush(Color));
  RoundRect(PaintDC,X,Y,X+Random(WndRect.Right-X),Y+Random(WndRect.Bottom-Y),20,20);
  DeleteObject(SelectObject(PaintDC,OldBrush));
  EndPaint(CurrentStarter.WindowHandle, Info);}
end;

function TScreenSaverStarter.ProcessMessage(Msg: Longword; wParam, lParam: Integer): Integer;
begin
  Result := inherited ProcessMessage(Msg, wParam, lParam);
  case Msg of
    WM_NCCREATE: begin Result := 1; Exit; end;
    WM_DESTROY: begin Result := 1; PostQuitMessage(0); Terminated := True; end;
//    WM_PAINT: DrawSingleBox; { paint something }
    WM_KEYDOWN: ;//if not PreviewMode then Finished := True;//AskPassword;
    WM_LBUTTONDOWN, WM_MBUTTONDOWN, WM_RBUTTONDOWN, WM_MOUSEMOVE: begin
      if (not FPreviewMode) then begin
        Dec(FMoveCounter);
       if (FMoveCounter <= 0) then Terminated := True;//AskPassword;
      end;
    end;
    WM_CLOSE: begin Result := 1; Terminated := True; end;
    WM_SHOWWINDOW: if wParam = 0 then Terminated := True;
    WM_ACTIVATEAPP, WM_ACTIVATE, WM_NCACTIVATE: if not FPreviewMode then begin
      if wParam and 65535 = WA_INACTIVE then Terminated := True;
    end;
    WM_SYSCOMMAND: begin
      CallDefaultMsgHandler := False;
      case wParam and $FFF0 of
        SC_CLOSE: ;//Finished := True;
        SC_SCREENSAVE: ;
        else CallDefaultMsgHandler := True;
      end;
    end;
  end;
end;

procedure TScreenSaverStarter.PrintError(const Msg: string; ErrorType: TLogLevel);
begin
  Log(Msg, ErrorType);
end;

destructor TScreenSaverStarter.Destroy;
var Dummy: Cardinal;
begin
//  if not PreviewMode then
  SystemParametersInfo(SPI_SCREENSAVERRUNNING, 0, @Dummy, 0);
  AdjustCursorVisibility(True);
  if MutexWindowHandle <> 0 then DestroyWindow(MutexWindowHandle);
  if WindowHandle <> 0 then DestroyWindow(WindowHandle);
  UnRegisterClass(PChar(FWindowClassName), hInstance);
  inherited;
end;

end.
