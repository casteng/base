(*
 @Abstract(Application Initialization Unit)
 (C) 2003-2007 George "Mirage" Bakhtadze
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains crossplatform application and window initialization and maintenance classes using GLUT and FreeGLUT libraries
*)
{$Include GDefines.inc}
{$IFNDEF FPC}
  {$MESSAGE ERROR 'The is unit compatible with Free Pascal Compiler only'}
{$ENDIF}
unit AppsInitGLUT;

interface

uses
  Logger, AppsInit,
  gl, glu, glut, freeglut,
  BaseTypes, Basics, BaseMsg, OSUtils;

type
  // GLUT/FreeGLUT based application starter
  TGLUTAppStarter = class(TAppStarter)
  public
    // Create and setup an application with the given name. If <b>AWindowProc</b> is <b>nil</b> a default procedure will be used.
    constructor Create(const AProgramName: string; Options: TStarterOptions);
    destructor Destroy; override;
    // Should be called each application cycle. Usally overridden to perform message processing. Returns negate value of @Link(Terminated) property.
    function Process: Boolean; override;
    // Prints an error information
    procedure PrintError(const Msg: string; ErrorType: TLogLevel); override;
  end;

implementation

uses SysUtils;

var
  CurrentStarter: TGLUTAppStarter;

procedure RetrieveModifiers();
var mods: Integer;
begin
  mods := glutGetModifiers();

  OSUtils.GLUTState.KbdState[IK_SHIFT]  := Ord(mods and GLUT_ACTIVE_SHIFT > 0)*128;
  OSUtils.GLUTState.KbdState[IK_LSHIFT] := Ord(mods and GLUT_ACTIVE_SHIFT > 0)*128;
  OSUtils.GLUTState.KbdState[IK_RSHIFT] := Ord(mods and GLUT_ACTIVE_SHIFT > 0)*128;

  OSUtils.GLUTState.KbdState[IK_CONTROL] := Ord(mods and GLUT_ACTIVE_CTRL > 0)*128;
  OSUtils.GLUTState.KbdState[IK_CONTROL] := Ord(mods and GLUT_ACTIVE_CTRL > 0)*128;
  OSUtils.GLUTState.KbdState[IK_CONTROL] := Ord(mods and GLUT_ACTIVE_CTRL > 0)*128;

  OSUtils.GLUTState.KbdState[IK_ALT]  := Ord(mods and GLUT_ACTIVE_ALT > 0)*128;
  OSUtils.GLUTState.KbdState[IK_LALT] := Ord(mods and GLUT_ACTIVE_ALT > 0)*128;
  OSUtils.GLUTState.KbdState[IK_RALT] := Ord(mods and GLUT_ACTIVE_ALT > 0)*128;

  writeln('key: ', mods, ' / ', OSUtils.GLUTState.KbdState[IK_ALT]);

end;  

procedure CallbackDrawScene; cdecl;
begin
//  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
//  glutSolidTeapot(0.101);
  glutSwapBuffers;
//  CurrentStarter.MessageHandler(nil);
end;

procedure CallbackMouse(X, Y: Integer); cdecl;
begin
  OSUtils.ClientToScreen(glutGetWindow(), X, Y);
  OSUtils.GLUTState.MouseX := X;
  OSUtils.GLUTState.MouseY := Y;
//  RetrieveModifiers();
end;

procedure CallbackMouseButton(Button, State, X, Y: Integer); cdecl;
var Key: Integer;
begin
  case Button of
    GLUT_LEFT_BUTTON: Key := IK_MOUSELEFT;
    GLUT_RIGHT_BUTTON: Key := IK_MOUSERIGHT;
    GLUT_MIDDLE_BUTTON: Key := IK_MOUSEMIDDLE;
  end;
  if State = GLUT_UP then
    OSUtils.GLUTState.KbdState[key] := 0
  else
    OSUtils.GLUTState.KbdState[key] := 128;
  CallbackMouse(X, Y);
  RetrieveModifiers();
end;

procedure CallbackKeyboard(Key: Byte; X, Y: Longint); cdecl;
begin
  OSUtils.GLUTState.KbdState[key] := 128;
  RetrieveModifiers();
end;

procedure CallbackKeyboardUp(Key: Byte; X, Y: Longint); cdecl;
begin
  writeln('key: ', key);
  OSUtils.GLUTState.KbdState[key] := 0;
  RetrieveModifiers();
end;

procedure CallbackKeyboardAscii(Key: Byte; X, Y: Longint); cdecl;
begin
  OSUtils.GLUTState.KbdState[Ord(UpCase(Chr(key)))] := 128;
  RetrieveModifiers();
end;

procedure CallbackKeyboardAsciiUp(Key: Byte; X, Y: Longint); cdecl;
begin
  OSUtils.GLUTState.KbdState[Ord(UpCase(Chr(key)))] := 0;
  RetrieveModifiers();
end;

procedure CallbackResize(Width, Height: Integer); cdecl;
begin
  if Height = 0 then
    Height := 1;

  if Assigned(CurrentStarter.MessageHandler) then CurrentStarter.MessageHandler(TWindowResizeMsg.Create(0, 0, Width, Height));

//  glViewport(0, 0, Width, Height);
{  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(45, Width / Height, 0.1, 1000);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;}
end;

procedure CallbackCloseGLUT(); cdecl;
begin
  CurrentStarter.Terminate();
end;

{ TGLUTAppStarter }

constructor TGLUTAppStarter.Create(const AProgramName: string; Options: TStarterOptions);
var
  Cmd: array of PChar;
  CmdCount, I: Integer;
begin
//  if ParseCmdLine then
//    CmdCount := ParamCount + 1
//  else
    CmdCount := 1;
  SetLength(Cmd, CmdCount);
  for I := 0 to CmdCount - 1 do
    Cmd[I] := PChar(ParamStr(I));
  glutInit(@CmdCount, @Cmd);

  CurrentStarter := Self;

  GLUTSetOption(GLUT_ACTION_ON_WINDOW_CLOSE, GLUT_ACTION_CONTINUE_EXECUTION);

  glutInitDisplayMode(GLUT_DOUBLE or GLUT_RGBA or GLUT_DEPTH or GLUT_STENCIL);
  glutInitWindowPosition(400, 200);
  glutInitWindowSize(800, 600);

  FWindowHandle := glutCreateWindow(PChar(AProgramName));

  glClearColor(0.18, 0.20, 0.66, 0);

  glutIgnoreKeyRepeat(1);

  glutDisplayFunc(@CallbackDrawScene);
  glutReshapeFunc(@CallbackReSize);
  glutKeyboardFunc(@CallbackKeyboardAscii);
  glutKeyboardUpFunc(@CallbackKeyboardAsciiUp);
  glutSpecialFunc(@CallbackKeyboard);
  glutSpecialUpFunc(@CallbackKeyboardUp);
  glutMouseFunc(@CallbackMouseButton);
  glutPassiveMotionFunc(@CallbackMouse);
  glutMotionFunc(@CallbackMouse);
  glutCloseFunc(@CallbackCloseGLUT);
end;

destructor TGLUTAppStarter.Destroy;
begin
  glutExit();
  inherited;
end;

procedure TGLUTAppStarter.PrintError(const Msg: string; ErrorType: TLogLevel);
begin
  Writeln(Msg);
end;

function TGLUTAppStarter.Process: Boolean;
begin
  if not Terminated then begin
    glutpostredisplay();
    glutMainLoopEvent();
  end;
  Result := not Terminated;
end;

end.