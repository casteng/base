(*
 @Abstract(OS-based input unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains OS-based input implementation
*)
{$Include GDefines.inc}
unit WInput;

interface

uses Basics, BaseMsg, BaseTypes, OSUtils, Input;

type
  // OS-routines based controller implementation
  TOSController = class(TController)
  private
    LastMouseX, LastMouseY: LongInt;
  protected
    procedure ApplyMouseCapture(Value: Boolean); override;
  public
    constructor Create(AHandle: Cardinal; AMessageHandler: TMessageHandler); override;
    procedure SetMouseWindow(const X1, Y1, X2, Y2: Longint); override;    
    procedure GetInputState; override;
  end;

implementation

{ TOSController }

constructor TOSController.Create(AHandle: Cardinal; AMessageHandler: TMessageHandler);
begin
  {$I WI_CONST.inc}
  inherited;  
end;

procedure TOSController.GetInputState;
begin
  ObtainKeyboardState(KeyboardState);
  ObtainCursorPos(MouseX, MouseY);

  with MouseState do begin
    lX := MouseX - LastMouseX;
    lY := MouseY - LastMouseY;
    Buttons[mbLeft]   := GetAsyncKeyState(IK_MOUSELEFT)   < 0;
    Buttons[mbRight]  := GetAsyncKeyState(IK_MOUSERIGHT)  < 0;
    Buttons[mbMiddle] := GetAsyncKeyState(IK_MOUSEMIDDLE) < 0;
  end;
  
  if MouseCapture then SetCursorCapturePos else begin
    LastMouseX := MouseX; LastMouseY := MouseY;
  end;
  ScreenToClient(Handle, MouseX, MouseY);
  MouseX := MinI(MouseWindow.Right,  MaxI(MouseWindow.Left, MouseX));
  MouseY := MinI(MouseWindow.Bottom, MaxI(MouseWindow.Top,  MouseY));
end;

procedure TOSController.ApplyMouseCapture(Value: Boolean);
begin
  inherited;
  if Value then begin
//    AdjustCursorVisibility(False);
    OSUtils.HideCursor;
    SetCursorCapturePos;
    ObtainCursorPos(LastMouseX, LastMouseY);
  end else OSUtils.ShowCursor;// AdjustCursorVisibility(True);
end;

procedure TOSController.SetMouseWindow(const X1, Y1, X2, Y2: Integer);
begin
  inherited;
  ClipCursor(MouseWindow);
end;

end.
