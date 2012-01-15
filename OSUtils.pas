(*
 @Abstract(Operating systems support unit)
 (C) 2006-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains basic OS-related classes
*)
{$Include GDefines.inc}

{$IFDEF USEGLUT}
  {$DEFINE GLUT}              // Use GLUT implementation
{$ELSE}
  {$IFDEF WINDOWS}
    {$DEFINE WINAPI}               // Use WinAPI implementation
  {$ENDIF}
  {$IFDEF LINUX}
    {$DEFINE X11}               // Use X11 implementation
    {$UNDEF GLUT}
  {$ENDIF}
{$ENDIF}
unit OSUtils;

interface

uses
  {$IFDEF WINAPI}
    {$IFDEF FPC} FPCWindows, {$ENDIF}
    ShlObj, ShellAPI,
    Windows, Messages,
  {$ENDIF}
  {$IFDEF LINUX}
    unix, x, xlib,
  {$ENDIF}
  {$IFDEF GLUT}
    glut, freeglut,
  {$ENDIF}    
  SysUtils,                // ToDo: Move to advanced unit

  Basics, BaseTypes, BaseMsg;

{$IFDEF WINAPI}
const
  kernel = 'kernel32.dll';
{$ENDIF}

type
  THandle = Cardinal;
  // State of each key in keyboard. The key is pressed if the corresponding elements is non-zero.
  TKbdState = array[0..255] of Byte;
  {$IFDEF WINAPI}
    TRect = Windows.TRect;
  {$ELSE}
    TRect = BaseTypes.TRect;
  {$ENDIF}
  {$IFDEF X11}
    TPoint = packed record
      X: Longint;
      Y: Longint;
    end;
  {$ENDIF}
  {$IFDEF GLUT}
    TGLUTState = record
      WindowId: Integer;
      MouseCnt: Integer;
      MouseX, MouseY: Integer;
      KbdState: TKbdstate;
    end;
  {$ENDIF}
  // System path
  TSysFolder = (sfRecycled, sfDesktop, sfStartMenu, sfPrograms, sfStartup, sfPersonal, sfTemplates, sfRecent, sfSendTo, sfNetHood, sfAppData, sfWinRoot, sfWinSys);
  // Window non-client elements
  TWindowElement = (// Border across a window
                    weBorder,
                    // Window caption
                    weCaption,
                    // Minimize button
                    weMinimizeButton,
                    // Maximize button
                    weMaximizeButton,
                    // Close button
                    weCloseButton,
                    // Window menu
                    weMenu);
  TWindowElements = set of TWindowElement;                   


   // OS dependent
// Obtains mouse cursor position relative to screen and fills X and Y with the position
procedure ObtainCursorPos(out X, Y: Integer);
// Sets mouse cursor position relative to screen
procedure SetCursorPos(X, Y: Integer);
// Adjust mouse cursor visibility counter. The cursor will be visible if the counter >= 0. Initial value of the counter is zero.
function AdjustCursorVisibility(Show: Boolean): Integer;
procedure ClipCursor(Rect: TRect);
function GetClipCursor: TRect;

procedure GetWindowRect(Handle: THandle; out Rect: TRect);
procedure GetClientRect(Handle: THandle; out Rect: TRect);
procedure ScreenToClient(Handle: THandle; var X, Y: Integer);
procedure ClientToScreen(Handle: THandle; var X, Y: Integer);

procedure ShowWindow(Handle: THandle);
procedure HideWindow(Handle: THandle);
procedure MinimizeWindow(Handle: THandle);
procedure RestoreWindow(Handle: THandle);
function IsWindowVisible(Handle: THandle): Boolean;
procedure SetWindowCaption(Handle: THandle; const ACaption: string);

procedure ObtainKeyboardState(var State: TKbdState);
function GetAsyncKeyState(Key: Integer): Integer;

function GetOSErrorStr(ErrorID: Integer): string;
function ActivateWindow(Handle: THandle): Boolean;

function GetCurrentMs: Int64;
procedure ObtainPerformanceFrequency;
function GetPerformanceCounter: Int64;

procedure OpenWith(ParentHandle: Cardinal; const FileName: string);
procedure OpenURL(const URL: string);

{$IFDEF WINAPI}
  function ThreadSafeIncrement(var Addend: Integer): Integer; stdcall; external kernel name 'InterlockedIncrement';
  function ThreadSafeDecrement(var Addend: Integer): Integer; stdcall; external kernel name 'InterlockedDecrement';
{$ENDIF}

function WMToMessage(MsgID: Cardinal; wParam, lParam: Integer): TMessage; overload;
{$IFDEF WINAPI}
  function WMToMessage(const Msg: Messages.TMessage): TMessage; overload;
{$ENDIF}

procedure Sleep(Milliseconds: Integer);           // Not accurate (~10ms)
procedure Delay(Microseconds: Integer);           // Accurate
procedure Exec(const Command: string);
function GetActiveWindow: THandle;
function GetSysFolder(SysFolder: TSysFolder): string;

function GetTextFromClipboard: string;

// OS independent
// Returns time of last file modification
function GetFileModifiedTime(const FileName: string): TDateTime;
procedure SetCursorVisibility(Counter: Integer);
procedure ShowCursor;
procedure HideCursor;

{$IFDEF LINUX}
  (* Initializes X11 window system.
     Handle is any valid X11 window handle used in some X11 function calls.
     Should stay valid for the time when OSUtils unit is used. *)
  procedure InitX11(Handle: TWindow);
  // Returns pointer to X11 display
  function GetXDisplay(): PXDisplay;
{$ENDIF}

var
  PerformanceFrequency: Int64;
  OneOverPerformanceFrequency: Single;

  {$IFDEF GLUT}
    GlutState: TGLUTState;
  {$ENDIF}

implementation

{$IFDEF LINUX}
  var
    XScreen: record
      Display: PXDisplay;
      // Should be a valid X11 window handle on the time of any OSUtils call
      Window: TWindow;
    end;

  procedure InitX11(Handle: TWindow);
  begin
    if XScreen.Display <> nil then XScreen.Display := XOpenDisplay(nil);
    XScreen.Window := Handle;
  end;

  function GetXDisplay(): PXDisplay;
  begin
    Assert((Xscreen.Display <> nil), 'Call InitX11() first!');
    Result := XScreen.Display;
  end;
{$ENDIF}

// OS dependent

{$IFDEF WINAPI}
procedure ObtainCursorPos(out X, Y: Integer);
var
  Pnt: TPoint;
begin
    Windows.GetCursorPos(Pnt);
    X := Pnt.X; Y := Pnt.Y;
end;

procedure SetCursorPos(X, Y: Integer);
begin
  Windows.SetCursorPos(X, Y);
end;

function AdjustCursorVisibility(Show: Boolean): Integer;
begin
  Result := Windows.ShowCursor(Show);
end;

procedure ClipCursor(Rect: TRect);
begin
  Windows.ClipCursor(@Rect);
end;

function GetClipCursor: TRect;
begin
  Windows.GetClipCursor(Result);
end;

procedure GetWindowRect(Handle: THandle; out Rect: TRect);
begin
  Windows.GetWindowRect(Handle, Rect)
end;

procedure GetClientRect(Handle: THandle; out Rect: TRect);
begin
  Windows.GetClientRect(Handle, Rect)
end;

procedure ScreenToClient(Handle: THandle; var X, Y: Integer);
var Pnt: TPoint;
begin
  Pnt.X := X; Pnt.Y := Y;
  Windows.ScreenToClient(Handle, Pnt);
  X := Pnt.X; Y := Pnt.Y;
end;

procedure ClientToScreen(Handle: THandle; var X, Y: Integer);
var Pnt: TPoint;
begin
  Pnt.X := X; Pnt.Y := Y;
  Windows.ClientToScreen(Handle, Pnt);
  X := Pnt.X; Y := Pnt.Y;
end;

procedure ShowWindow(Handle: THandle);
begin
  Windows.ShowWindow(Handle, SW_SHOWNORMAL);
end;

procedure HideWindow(Handle: THandle);
begin
  Windows.ShowWindow(Handle, SW_HIDE);
end;

procedure MinimizeWindow(Handle: THandle);
begin
  Windows.ShowWindow(Handle, SW_MINIMIZE);
end;

procedure RestoreWindow(Handle: THandle);
begin
  Windows.ShowWindow(Handle, SW_RESTORE);
end;

function IsWindowVisible(Handle: THandle): Boolean;
begin
  Result := Windows.IsWindowVisible(Handle);
end;

procedure SetWindowCaption(Handle: THandle; const ACaption: string);
begin
  Windows.SetWindowText(Handle, PChar(ACaption));
end;

procedure ObtainKeyboardState(var State: TKbdState);
begin
  Windows.GetKeyboardState(TKeyboardState(State));
end;

function GetAsyncKeyState(Key: Integer): Integer;
begin
  Result := Windows.GetAsyncKeyState(Key);
end;

function WMToMessage(MsgID: Cardinal; wParam, lParam: Integer): TMessage; overload;
begin
  case MsgID of
    WM_ACTIVATEAPP: begin
      if wParam = 0 then Result := TWindowDeactivateMsg.Create else Result := TWindowActivateMsg.Create;
    end;  
//    WM_EXITSIZEMOVE:
    WM_SIZE: begin
      if wParam = SIZE_MINIMIZED then
        Result := TWindowMinimizeMsg.Create else
          Result := TWindowResizeMsg.Create(0, 0, lParam and 65535, lParam shr 16);
    end;  
    WM_MOVE:       Result := TWindowMoveMsg.Create(lParam and 65535, lParam shr 16);
    WM_CANCELMODE: Result := TCancelModeMsg.Create;
    WM_CHAR:       Result := TCharInputMsg.Create(Chr(wParam), lParam);
    WM_SYSCOMMAND: Result := TWindowMenuCommand.Create(wParam);
    else Result := TMessage.Create; 
  end;
  Result.Flags := Result.Flags + [mfCore];
end;

function WMToMessage(const Msg: Messages.TMessage): TMessage; overload;
begin
  Result := WMToMessage(Msg.Msg, Msg.WParam, Msg.LParam);
end;

function GetOSErrorStr(ErrorID: Integer): string;
var s: PChar;
begin
  GetMem(s, 2000);
  FormatMessage({FORMAT_MESSAGE_ALLOCATE_BUFFER or }FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
                nil, ErrorID, 0, s, 2000, nil);
  Result := s;
  FreeMem(s);
end;

function ActivateWindow(Handle: THandle): Boolean;
var Input: TInput;
begin
  Result:= True;
  if Handle = GetForegroundWindow then Exit;
  if IsWindow(Handle) then begin
    Input.Itype:= Input_Mouse;
    FillChar(Input.mi, SizeOf(Input.mi), 0);
    SendInput(1, Input, SizeOf(Input));
    Result := SetForegroundWindow(Handle);
//    SetActiveWindow(hwnd);
    if IsIconic(Handle) then OpenIcon(Handle);
    Exit;
  end;
  Result:= False;
end;

function GetCurrentMs: Int64;
begin
  Result := GetTickCount;
end;

procedure ObtainPerformanceFrequency;
begin
  if QueryPerformanceFrequency(PerformanceFrequency) then begin
    if PerformanceFrequency <> 0 then OneOverPerformanceFrequency := 1 / PerformanceFrequency else OneOverPerformanceFrequency := 0;
  end else PerformanceFrequency := 0;
end;

function GetPerformanceCounter: Int64;
begin
  QueryPerformanceCounter(Result);
end;

procedure OpenWith(ParentHandle: Cardinal; const FileName: string);
begin
  ShellExecute(ParentHandle, 'open', PChar('rundll32.exe'),
    PChar('shell32.dll,OpenAs_RunDLL ' + FileName), nil, SW_SHOWNORMAL);
end;

procedure OpenURL(const URL: string);
begin
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
  Sleep(500);                                                    // To eliminate some bugs with timer
end;

procedure Sleep(Milliseconds: Integer);
begin
  Windows.Sleep(Milliseconds);
end;

procedure Delay(Microseconds: Integer);
var Cnt, Dest: Int64;
begin
  Cnt := GetPerformanceCounter;
  Dest := Cnt + Microseconds * PerformanceFrequency div 1000000;
  while GetPerformanceCounter < Dest do SpinWait(500);
end;

procedure Exec(const Command: string);
begin
  ShellExecute({Starter.WindowHandle}0, 'open', PChar(Command), nil, nil, SW_SHOWNORMAL);
  Sleep(500);
end;

function GetActiveWindow: THandle;
begin
  Result := Windows.GetActiveWindow;
end;

function GetSysFolder(SysFolder: TSysFolder): string;
var
 s: PChar;
 p: PItemIDList;
 Folder: Integer;
begin
   Result := '';
   p := nil;
   case SysFolder of
     sfRecycled:  Folder := CSIDL_BITBUCKET;
     sfDesktop:   Folder := CSIDL_DESKTOPDIRECTORY;
     sfStartMenu: Folder := CSIDL_STARTMENU;
     sfPrograms:  Folder := CSIDL_PROGRAMS;
     sfStartup:   Folder := CSIDL_STARTUP;
     sfPersonal:  Folder := CSIDL_PERSONAL;
     sfRecent:    Folder := CSIDL_RECENT;
     sfNetHood:   Folder := CSIDL_NETHOOD;
     sfSendTo:    Folder := CSIDL_SENDTO;
     sfTemplates: Folder := CSIDL_TEMPLATES;
     sfAppData:   Folder := CSIDL_APPDATA;
//     sfWinRoot:   Folder :=
//     sfWinSys:    Folder :=
     else begin
       Assert(False);
       Exit;
     end;
   end;
   if (SHGetSpecialFolderLocation(0 ,Folder, p) <> NOERROR) or (p = nil) then Exit;
   s := StrAlloc(MAX_PATH+1);
   if SHGetPathFromIDList(p, s) then Result := s;
   StrDispose(s);
end;

function GetTextFromClipboard: string;
var hg: THandle; P: PChar;
begin
  OpenClipboard(0);
  hg := GetClipboardData(CF_TEXT);
  CloseClipboard;
  P := GlobalLock(hg);
  Result := Copy(P, 0, Length(P));
  GlobalUnlock(hg);
end;
{$ENDIF}

{$IFDEF X11}
procedure ObtainCursorPos(out X, Y: Integer);
var
  WRoot, WChild, Mask: LongWord;
  rX, rY: LongInt;
begin
  Assert((Xscreen.Display <> nil) and (XScreen.Window <> 0), 'Call InitX11() first!');
  XQueryPointer(Xscreen.Display, XScreen.Window, @WRoot, @WChild, @rX, @rY, @X, @Y, @Mask);
end;

procedure SetCursorPos(X, Y: Integer);
begin
end;

function AdjustCursorVisibility(Show: Boolean): Integer;
begin
end;

procedure ClipCursor(Rect: TRect);
begin
end;

function GetClipCursor: TRect;
begin
end;

procedure GetWindowRect(Handle: THandle; out Rect: TRect);
begin
end;

procedure GetClientRect(Handle: THandle; out Rect: TRect);
begin
end;

procedure ScreenToClient(Handle: THandle; var X, Y: Integer);
begin
end;

procedure ClientToScreen(Handle: THandle; var X, Y: Integer);
begin
end;

procedure ShowWindow(Handle: THandle);
begin
end;

procedure HideWindow(Handle: THandle);
begin
end;

procedure MinimizeWindow(Handle: THandle);
begin
end;

procedure RestoreWindow(Handle: THandle);
begin
end;

function IsWindowVisible(Handle: THandle): Boolean;
begin
end;

procedure SetWindowCaption(Handle: THandle; const ACaption: string);
begin
end;

procedure ObtainKeyboardState(var State: TKbdState);
begin
end;

function GetAsyncKeyState(Key: Integer): Integer;
begin
end;

function WMToMessage(MsgID: Cardinal; wParam, lParam: Integer): TMessage; overload;
begin
end;

function GetOSErrorStr(ErrorID: Integer): string;
begin
end;

function ActivateWindow(Handle: THandle): Boolean;
begin
end;

function GetCurrentMs: Int64;
begin
end;

procedure ObtainPerformanceFrequency;
begin
end;

function GetPerformanceCounter: Int64;
begin
end;

procedure OpenWith(ParentHandle: Cardinal; const FileName: string);
begin
end;

procedure OpenURL(const URL: string);
begin
end;

procedure Sleep(Milliseconds: Integer);
begin
end;

procedure Delay(Microseconds: Integer);
begin
end;

procedure Exec(const Command: string);
begin
end;

function GetActiveWindow: THandle;
begin
end;

function GetSysFolder(SysFolder: TSysFolder): string;
begin
end;

function GetTextFromClipboard: string;
begin
end;
{$ENDIF}

{$IFDEF GLUT}
procedure ObtainCursorPos(out X, Y: Integer);
begin
  X := GLUTState.MouseX;
  Y := GLUTState.MouseY;
end;

procedure SetCursorPos(X, Y: Integer);
begin
  ScreenToClient(glutGetWindow(), X, Y);
  GlutWarpPointer(X, Y);
end;

function AdjustCursorVisibility(Show: Boolean): Integer;
begin
  GlutState.MouseCnt := GlutState.MouseCnt + Ord(Show)*2-1;
  Result := GlutState.MouseCnt;
  if Result >= 0 then
    glutSetCursor(GLUT_CURSOR_INHERIT)
  else
    glutSetCursor(GLUT_CURSOR_NONE);
end;

procedure ClipCursor(Rect: TRect);
begin
  Writeln('ClipCursor: Not implemented via GLUT');
end;

function GetClipCursor: TRect;
begin
  Writeln('GetClipCursor: Not implemented via GLUT');
end;

procedure GetWindowRect(Handle: THandle; out Rect: TRect);
var OldWindowId: Integer;
begin
  OldWindowId := glutGetWindow();
  glutSetWindow(Handle);

  Rect.Left   := glutGet(GLUT_WINDOW_X);
  Rect.Top    := glutGet(GLUT_WINDOW_Y);
  Rect.Right  := glutGet(GLUT_WINDOW_WIDTH)  + Rect.Left;
  Rect.Bottom := glutGet(GLUT_WINDOW_HEIGHT) + Rect.Top;

  glutSetWindow(OldWindowId);
end;

procedure GetClientRect(Handle: THandle; out Rect: TRect);
var OldWindowId: Integer;
begin
  OldWindowId := glutGetWindow();
  glutSetWindow(Handle);

  GetWindowRect(Handle, Rect);
  Rect.Left   := Rect.Left   + glutGet(GLUT_WINDOW_BORDER_WIDTH) div 2;
  Rect.Top    := Rect.Top    + glutGet(GLUT_WINDOW_BORDER_WIDTH) div 2;
  Rect.Right  := Rect.Right  - glutGet(GLUT_WINDOW_BORDER_WIDTH) div 2;
  Rect.Bottom := Rect.Bottom - glutGet(GLUT_WINDOW_BORDER_WIDTH) div 2;

  glutSetWindow(OldWindowId);
end;

procedure ScreenToClient(Handle: THandle; var X, Y: Integer);
begin
  X := X - glutGet(GLUT_WINDOW_X);
  Y := Y - glutGet(GLUT_WINDOW_Y);
end;

procedure ClientToScreen(Handle: THandle; var X, Y: Integer);
begin
  X := X + glutGet(GLUT_WINDOW_X);
  Y := Y + glutGet(GLUT_WINDOW_Y);
end;

procedure ShowWindow(Handle: THandle);
var OldWindowId: Integer;
begin
  OldWindowId := glutGetWindow();
  glutSetWindow(Handle);
  glutShowWindow();
  glutSetWindow(OldWindowId);
end;

procedure HideWindow(Handle: THandle);
var OldWindowId: Integer;
begin
  OldWindowId := glutGetWindow();
  glutSetWindow(Handle);
  glutHideWindow();
  glutSetWindow(OldWindowId);
end;

procedure MinimizeWindow(Handle: THandle);
var OldWindowId: Integer;
begin
  OldWindowId := glutGetWindow();
  glutSetWindow(Handle);
  glutIconifyWindow();
  glutSetWindow(OldWindowId);
end;

procedure RestoreWindow(Handle: THandle);
begin
  ShowWindow(Handle);
end;

function IsWindowVisible(Handle: THandle): Boolean;
begin
  Writeln('IsWindowVisible: Not implemented via GLUT');
end;

procedure SetWindowCaption(Handle: THandle; const ACaption: string);
var OldWindowId: Integer; Caption: PChar;
begin
  OldWindowId := glutGetWindow();
  glutSetWindow(Handle);
  Caption := PChar(ACaption);
  glutSetWindowTitle(Caption);
  glutSetIconTitle(Caption);
  glutSetWindow(OldWindowId);
end;

procedure ObtainKeyboardState(var State: TKbdState);
begin
  State := GLUTState.KbdState;
end;

function GetAsyncKeyState(Key: Integer): Integer;
begin
//  Writeln('GetAsyncKeyState: Not implemented via GLUT');
end;

function WMToMessage(MsgID: Cardinal; wParam, lParam: Integer): TMessage; overload;
begin
  Writeln('WMToMessage: Not implemented via GLUT');
end;

function GetOSErrorStr(ErrorID: Integer): string;
begin
  Writeln('GetOSErrorStr: Not implemented via GLUT');
  Result := 'Unknown';
end;

function ActivateWindow(Handle: THandle): Boolean;
begin
  ShowWindow(Handle);
end;

function GetCurrentMs: Int64;
var tm: TimeVal;
begin
//  Result := Trunc(TimeStampToMSecs(DateTimeToTimeStamp(Now))); // Range error?!
  fpGetTimeOfDay(@tm, nil);
//  writeln('time: ', tm.tv_sec);
  Result := tm.tv_sec * Int64(1000) + tm.tv_usec div 1000;
end;

procedure ObtainPerformanceFrequency;
begin
end;

function GetPerformanceCounter: Int64;
begin
end;

procedure OpenWith(ParentHandle: Cardinal; const FileName: string);
begin
end;

procedure OpenURL(const URL: string);
begin
end;

procedure Sleep(Milliseconds: Integer);
begin
  Writeln('Sleep: Not implemented via GLUT');
end;

procedure Delay(Microseconds: Integer);
begin
  Writeln('Delay: Not implemented via GLUT');
end;

procedure Exec(const Command: string);
begin
end;

function GetActiveWindow: THandle;
begin
  Writeln('GetActiveWindow: Not implemented via GLUT');
end;

function GetSysFolder(SysFolder: TSysFolder): string;
begin
end;

function GetTextFromClipboard: string;
begin
end;
{$ENDIF}

// OS independent

function GetFileModifiedTime(const FileName: string): TDateTime;
var sr: TSearchRec;
begin
  Result := 0;
  if SysUtils.FindFirst(FileName, faDirectory, sr) = 0 then begin
    {$IFDEF DELPHIXE}
      Result := sr.TimeStamp;
    {$ELSE}
      Result := SysUtils.FileDateToDateTime(sr.Time);
    {$ENDIF}
//    Writeln(' ===*** sr.time: ',  sr.Time, ', sr.timestamp: ', Result);
  end;
  SysUtils.FindClose(sr);
end;

procedure SetCursorVisibility(Counter: Integer);
var i, Cur: Integer;
begin
  Cur := AdjustCursorVisibility(True);
  for i := 0 to Abs(Cur-Counter)-1 do AdjustCursorVisibility(Cur < Counter);
end;

procedure ShowCursor;
begin
  SetCursorVisibility(0);
end;

procedure HideCursor;
begin
  SetCursorVisibility(-1);
end;

initialization
  {$IFDEF LINUX}
    XScreen.Display := nil;
    XScreen.Window := 0;
  {$ENDIF}
  {$IFDEF GLUT}
    GLUTState.WindowId := 0;
    GLUTState.MouseCnt := 0;
    GLUTState.MouseX := 0;
    GLUTState.MouseY := 0;
    FillChar(GLUTState.KbdState, SizeOf(TGLUTState.KbdState), 0);
  {$ENDIF}
  ObtainPerformanceFrequency;
finalization
  {$IFDEF LINUX}
    if XScreen.Display <> nil then XCloseDisplay(XScreen.Display);
  {$ENDIF}
end.