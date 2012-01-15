(*
  @Abstract(Free Pascal Compiler specific Windows support unit)
  (C) 2003-2011 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  The unit contains some Free Pascal Compiler specific Windows OS support routines and types
*)
{$Include GDefines.inc}
unit FPCWindows;
interface
const
  user32    = 'user32.dll';

  INPUT_MOUSE = 0;
  INPUT_KEYBOARD = 1;
  INPUT_HARDWARE = 2;

  CSIDL_PROGRAMS                      = $0002;
  CSIDL_PERSONAL                      = $0005;
  CSIDL_STARTUP                       = $0007;
  CSIDL_RECENT                        = $0008;
  CSIDL_SENDTO                        = $0009;
  CSIDL_BITBUCKET                     = $000a;
  CSIDL_STARTMENU                     = $000b;
  CSIDL_DESKTOPDIRECTORY              = $0010;
  CSIDL_NETHOOD                       = $0013;
  CSIDL_TEMPLATES                     = $0015;
  CSIDL_APPDATA                       = $001a;

type
  UINT = LongWord;

  PKeyboardState = ^TKeyboardState;
  TKeyboardState = array[0..255] of Byte;

  PMouseInput = ^TMouseInput;
  tagMOUSEINPUT = packed record
    dx: Longint;
    dy: Longint;
    mouseData: DWORD;
    dwFlags: DWORD;
    time: DWORD;
    dwExtraInfo: DWORD;
  end;
  TMouseInput = tagMOUSEINPUT;

  PKeybdInput = ^TKeybdInput;
  tagKEYBDINPUT = packed record
    wVk: WORD;
    wScan: WORD;
    dwFlags: DWORD;
    time: DWORD;
    dwExtraInfo: DWORD;
  end;
  TKeybdInput = tagKEYBDINPUT;

  PHardwareInput = ^THardwareInput;
  tagHARDWAREINPUT = packed record
    uMsg: DWORD;
    wParamL: WORD;
    wParamH: WORD;
  end;
  THardwareInput = tagHARDWAREINPUT;

  PInput = ^TInput;
  tagINPUT = packed record
    Itype: DWORD;
    case Integer of
      0: (mi: TMouseInput);
      1: (ki: TKeybdInput);
      2: (hi: THardwareInput);
  end;
  TInput = tagINPUT;

  _RTL_CRITICAL_SECTION = TRTLCRITICALSECTION;

  function SendInput(cInputs: UINT; var pInputs: TInput; cbSize: Integer): UINT; stdcall;
implementation

  function SendInput(cInputs: UINT; var pInputs: TInput; cbSize: Integer): UINT; stdcall external user32 name 'SendInput';

end.
