(*
 @Abstract(Input unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains basic input classes
*)
{$Include GDefines.inc}
unit Input;
{ ToDo
  Optionally break sequence if another sequense completed }

interface

uses SysUtils, Logger, BaseTypes, OSUtils, Basics, BaseStr, BaseMsg, BaseClasses;

const
  // Default value of maximum timeout between two consequent events
  DefaultTimeout = 500;
  // Maximum simultaneous events
  MaxEvents = 127;
  // Amount of mouse move to count it as a stroke
  MouseStrokeTolerance = 3;

      // Action types
  // Set a boolean flag
  atBooleanOn = 1;
  // Reset a boolean flag
  atBooleanOff = 2;
  // Toggle a boolean flag
  atBooleanToggle = 3;
  // Set a byte value
  atSetByte = 4;
  // Set a word (two byte) value
  atSetWord = 5;
  // Set a long word (four byte) value
  atSetLongWord = 6;

type
  (* Binding string type. Syntax: <br>
    BindElement = (&lt;<b>Key</b>&gt;&lt;<b>Specifier</b>&gt;)|&lt;<b>Gesture</b>&gt;"^" <br>
    <b>Key</b>         = A key name <br>
    <b>Specifier</b>   = ","|"+"|"-"|":" - can be omitted at the end of the binding ("," will be assumed) <br>
    <b>Gesture</b>      = "MouseMove"|"MouseMoveH"|"MouseMoveV"|"MouseRoll"|
                         "MouseStrokeLeft"|"MouseStrokeRight"|"MouseStrokeUp"|"MouseStrokeDown"|
                         "MouseStrokeLeftUp"|"MouseStrokeRightUp"|"MouseStrokeLeftDown"|"MouseStrokeRightDown"

    <b>Binding</b>     = &lt;<b>BindElement</b>&gt; {&lt;<b>BindElement</b>&gt;} <br>
  Specifiers: <br>
    ,   - click <br>
    +   - key down <br>
    -   - key up <br>
    :   - double click <br>
  Examples: <br>
    <b>Alt+Q</b> - the binding will be activated when user press Alt, then click (press and release) Q (without releasing Alt) <br>
    <b>A,B,C</b> - the binding will be activated when user click A, then B and then C <br>
    <b>A+B,A-</b> - the binding will be activated when user press A, then press and release B and then release A <br>
  A maximum timeout between two consequent events can be specified when binding *)
  TBindingStr = string;

  // Key query states
  TKeyQueryState = (// Key is up
                    kqsUp,
                    // Key is down
                    kqsDown);
  // Query input results elements
  TInputQueryResultElement = (// Some key (including mouse buttons) was pressed
                              iqrKeyPressed,
                              // Some key (including mouse buttons) state was changed
                              iqrKeyChanged,
                              // Mouse was moved
                              iqrMouseMoved);
  // Query input results
  TInputQueryResult = set of TInputQueryResultElement;

  // Input event filters
  TInputFilterElement = (// Query only events which was bound using <b>@Link(BindCommand)</b>, <b>@Link(BindDelegate)</b> or <b>@Link(BindPointer)</b>
                         ifBound,
                         // Query all events
                         ifNotBound);
  // Input filter
  TInputFilter = set of TInputFilterElement;

  // Hotkey
  THotkey = type Longword;

  // Possible event types
  TEventType = (// Some key (including mouse buttons) was pushed down
                btKeyDown,
                // Some previously pressed key was released
                btKeyUp,
                // A key was clicked (btKeyDown + btKeyUp)
                btKeyClick,
                // A key was clicked two times within double click timeout
                btKeyDblClick,
                // Mouse was moved
                btMouseMove,
                // Mouse was moved horizontally
                btMouseHMove,
                // Mouse was moved vertically
                btMouseVMove,
                // Mouse wheel was rolled
                btMouseRoll,
                // Mouse was moved left at least by @Link(MouseStrokeTolerance) units
                btStrokeLeft,
                // Mouse was moved right at least by @Link(MouseStrokeTolerance) units
                btStrokeRight,
                // Mouse was moved up at least by @Link(MouseStrokeTolerance) units
                btStrokeUp,
                // Mouse was moved down at least by @Link(MouseStrokeTolerance) units
                btStrokeDown,
                // Mouse was moved left+up at least by @Link(MouseStrokeTolerance) units
                btStrokeLeftUp,
                // Mouse was moved right+up at least by @Link(MouseStrokeTolerance) units
                btStrokeRightUp,
                // Mouse was moved left+down at least by @Link(MouseStrokeTolerance) units
                btStrokeLeftDown,
                // Mouse was moved right+down at least by @Link(MouseStrokeTolerance) units
                btStrokeRightDown,
                // No event
                btNone);

  // Pointer to a binding
  PBinding = ^TBinding;
  // Binding contains an event type, event data and a pointer to next binding (or nil) to be able to bind a sequense of input events to a single action
  TBinding = record
    BindType: TEventType;
    BindData: Word;
    Next: PBinding;
  end;

  // Element of binding array
  TBindingElement = packed record
    First, Current, Terminator: PBinding;
    LastMs: Int64;
    TimeOutMs: Word;
    MembersKind: Word;                                        // Keyboard or mouse, also indicates binding kind (message, delegate or pointer)
    case Integer of
      0: (MessageType: CMessage);
      1: (DelegateIndex: Word; CustomData: Smallint);
      2: (PTRIndex, AType: Byte; Value: Word);
  end;

  TBindingName = ShortString;

  { Type of a method to which an input event sequence can be bound. <b>CustomData</b> is an optional user data.
    Value of <b>EventData</b> depends on type of event which finishes the sequence (the last one).
    If it's a keyboard event <b>EventData</b> contains a key code, if it's a mouse event <b>EventData</b> contains event-specific
    mouse coordinate or both (for @Link(btMouseMove) event type) in format where low 16 bit is X coordinate and high 16 bit is Y coordinate. }
  TInputDelegate = procedure(EventData: Integer; CustomData: SmallInt) of object;

  // Input event. <b>EventData</b> is an event type-specific data such as a key code
  TInputEvent = packed record
    EventType: TEventType;
    EventData: SmallInt;
  end;
  TInputEvents = array of TInputEvent;

  // Mouse state data structure. <b>lX</b>, <b>lY</b> and <b>lZ</b> is mouse position at corresponding axis. <b>Buttons</b> - mouse buttons state
  TMouseState = packed record
    lX, lY, lZ: LongInt;
    Buttons: array[0..3] of Byte;
  end;

  CController = class of TController;
  { @Abstract(CAST II input controller base class)
    TController polls input, checks if it matches specified in bindings event sequences and performs bond actions.
    Also some input-related routines and properties are provided. }
  TController = class(TSubsystem)
  private
    CurrentMs: Int64;
    MouseQueryMs: Int64;
    FSystemCursor, MouseCaptureActuallyActive: Boolean;
//    LastMouseEvent: TBindTypes;
    InputEvents: array[0..MaxEvents] of TInputEvent; TotalEvents: Integer;
    MouseXCounter, MouseYCounter: LongInt;
    Pointers: array of Pointer;
    Delegates: array of TInputDelegate;
    Bindings: array of TBindingElement;
    TotalBindings, TotalDelegates, TotalPointers: Word;

    procedure SetSystemCursor(const Value: Boolean); 
    procedure RecalcCaptureCoords;

    function NewBinding(BType: TEventType; BData: Word; ANext: PBinding = nil): PBinding;
    function GetLastBinding(Binding: PBinding): PBinding;
    procedure ParseBinding(s: string; out Binding, Terminator: PBinding);
    procedure UnBind(const Index: Longword);
    procedure CleanPointers; virtual;
  protected
    // Application window handle
    Handle: Cardinal;
    // Last keyboard state
    LastKeyState,
    // Current state of each virtual key.
    KeyboardState: TKbdState;
    // Last mouse state
    LastMouseState,
    // Current mouse state
    MouseState: TMouseState;
    // Current user input buffer
    FInputBuffer: string;
    // Current key query state
    KeyQueryState: array[0..255] of record
      State: TKeyQueryState;
      LastClickedTime: Cardinal;
    end;
    // Mouse capture state
    FMouseCapture: Boolean;
    // Mouse X before mouse was captured
    CaptureMouseX,
    // Mouse Y before mouse was captured
    CaptureMouseY: Integer;
    // A rectangle where the mouse cursor can be
    MouseWindow: OSUtils.TRect;
    // String names of keys
    KeyStr: array[0..255] of TBindingName;
    // Returns mouse event which occured since last process
    function GetMouseEvent: TEventType;
    // Implementation-specific mouse capture routine
    procedure ApplyMouseCapture(Value: Boolean); virtual; 
    // If set to <b>True</b> captures mouse and hide its cursor
    procedure SetMouseCapture(const Value: Boolean); virtual;
    // Places mouse cursor to capture position (center of current window)
    procedure SetCursorCapturePos;
    // Returns user input buffer and clear it
    function GetInputBuffer: string;

    // Performs input query. Returns set of input query elements and fills internal events array.
    function QueryInput: TInputQueryResult; virtual;
  public
    // A message handler to direct events to
    MessageHandler: BaseMsg.TMessageHandler;
    // Double click timeout. Used by events with @Link(btKeyDblClick) event type.
    DblClickTimeout: Cardinal;

    // If <b>True</b> all entered aplhabetical characters will be stored in @Link(InputBuffer)
    EnableCharactersInput: Boolean;

    // Current mouse X
    MouseX,
    // Current mouse Y
    MouseY: Integer;
    // Minimum time in ms between queries for mouse strokes
    MouseQueryTimeOut: Cardinal;
    // Current state of modifier keys
    Modifiers: TKeyModifiers;
    constructor Create(AHandle: Cardinal; AMessageHandler: BaseMsg.TMessageHandler); virtual;
    destructor Destroy; override;

    // Returns a string name of the specified key
    function KeyToStr(Key: Integer): string;
    // Returns a key which corresponds to the specified name
    function StrToKey(Name: string): Integer;
    // Returns <b>True</b> if <b>Key</b> is a one of modifiers key (CTRL, ALT, etc)
    function IsModifierKey(Key: Word): Boolean;
    // Returns a hot key by key and set of modifiers
    function GetHotKey(Key: Word; Modifiers: TKeyModifiers): THotkey;
    // Returns a string representation of the specified hot key
    function HotKeyToStr(HotKey: THotkey): string;
    // Parses a binding string and returns hot key
    function StrToHotKey(const BindStr: TBindingStr): THotkey;
    // Returns a set of modifiers from a hotkey
    function GetHotkeyModifiers(HotKey: THotkey): TKeyModifiers;

    // Default message handler
    procedure HandleMessage(const Msg: TMessage); override;

    // Parses the specified binding string and binds the specified message class to it. <b>ATimeoutMs</b> specifies the maximum time between two consequent events.
    procedure BindCommand(const ABinding: TBindingStr; MsgType: CMessage; const ATimeoutMs: LongWord = DefaultTimeout); virtual;
    // Parses the specified binding string and binds the specified delegate call to it. <b>ATimeoutMs</b> specifies the maximum time between two consequent events.
    procedure BindDelegate(const ABinding: TBindingStr; Delegate: TInputDelegate; ACustomData: SmallInt; const ATimeoutMs: LongWord = 0); virtual;
    { Parses the specified binding string and binds the specified pointer action to it. <b>ATimeoutMs</b> specifies the maximum time between two consequent events. <br>
      ActionType can be one of the following: <br>
      @Link(atBooleanOn), @Link(atBooleanOff), @Link(atBooleanToggle), @Link(atSetByte), @Link(atSetWord), @Link(atSetLongWord)
      It's recommended to use BindCommand or BindDelegate instead. }
    procedure BindPointer(const ABinding: TBindingStr; const ActionType: Longword; const Data: Pointer; const Value: Word = 0; const ATimeoutMs: LongWord = 0); virtual;

    // Clears all bindings
    procedure UnBindAll;

    // Sets mouse window
    procedure SetMouseWindow(const X1, Y1, X2, Y2: Longint); virtual;
    // Implementation-specific input poll
    procedure GetInputState; virtual; abstract;
    // Retunrs True if the specified key is pressed
    function IsKeyPressed(Key: Integer): Boolean;
    // Update modifier keys state using current input state. Called automatically by ProcessInput().
    procedure UpdateModifiers();
    // Pools input and checks if any of bindings should be activated
    procedure ProcessInput(const EventFilter: TInputFilter);

    // Transforms all input events to corresponding messages and directs them to @Link(MessageHandler)
    procedure InputEventsToMessages;

    // Current user input buffer. Reading this property will clear the buffer.
    property InputBuffer: string read GetInputBuffer;
    // Read/write this property to determine if system mouse cursor is used.
    property SystemCursor: Boolean read FSystemCursor write SetSystemCursor;
    // If set to <b>True</b> captures mouse and hide its cursor
    property MouseCapture: Boolean read FMouseCapture write SetMouseCapture;
  end;

implementation

const
  // Maximum number of bound pointers (currently must fit in a single byte)
  MaxPointers = 256;
  // Maximum number of bound delegates
  MaxDelegates = $FFFF;

    // Binding members
  bmNone = 0;
  bmKeyboard = 1;
  bmMouseButtons = 2;
  bmMouseMotion = 4;
    // Binding kinds
  bkMessage = 0;
  bkDelegate = $4000;
  bkPointer  = $8000;
    // Modifier keys
  hmControl  = 1 shl 30;
  hmLControl = 1 shl 29;
  hmRControl = 1 shl 28;
  hmShift    = 1 shl 27;
  hmLShift   = 1 shl 26;
  hmRShift   = 1 shl 25;
  hmAlt      = 1 shl 24;
  hmLAlt     = 1 shl 23;
  hmRAlt     = 1 shl 22;
  hmLOS      = 1 shl 20;
  hmROS      = 1 shl 19;
  hmOS       = 1 shl 18;

{ TController }

procedure TController.SetSystemCursor(const Value: Boolean);
begin
//  if not Active then Exit;
  FSystemCursor := Value;
  if FSystemCursor then ShowCursor else HideCursor;
end;

procedure TController.RecalcCaptureCoords;
var Rect: TRect;
begin
  OSUtils.GetWindowRect(Handle, Rect);
  CaptureMouseX := (Rect.Left + Rect.Right)  div 2;
  CaptureMouseY := (Rect.Top  + Rect.Bottom) div 2;
end;

function TController.NewBinding(BType: TEventType; BData: Word; ANext: PBinding = nil): PBinding;
var BindKey: Byte;
begin
  BindKey := BData and 255;
  GetMem(Result, SizeOf(TBinding));
  case BType of
    btKeyClick: begin
      with Result^ do begin
        BindType := btKeyDown; BindData := 0*BData and $FF00 + BindKey;
      end;
      GetMem(Result^.Next, SizeOf(TBinding));
      with Result^.Next^ do begin
        BindType := btKeyUp; BindData := 0*BData and $FF00 + BindKey; Next := ANext;
      end;
    end;
    else with Result^ do begin
      BindType := BType; BindData := 0*BData and $FF00 + BindKey; Next := ANext;
    end;
  end;
end;

function TController.GetLastBinding(Binding: PBinding): PBinding;
begin
  Result  := Binding;
  if Binding = nil then Exit;
  Binding := Result^.Next;
  while Binding <> nil do begin
    Result  := Binding;
    Binding := Result^.Next;
  end;
end;

function TController.GetMouseEvent: TEventType;   // ToDo: mouse roll support
var Rel, RelX, RelY: Single;
begin
  Result := btNone;
  Inc(MouseXCounter, MouseState.LX);
  Inc(MouseYCounter, MouseState.LY);
  if Abs(MouseXCounter) > 0 then Result := btMouseHMove;
  if Abs(MouseYCounter) > Abs(MouseXCounter) then Result := btMouseVMove;
  if CurrentMs - MouseQueryMs >= MouseQueryTimeOut then begin
    MouseQueryMs := CurrentMs;
    if MouseYCounter <> 0 then begin
      Rel := MouseXCounter / MouseYCounter;
      if MouseYCounter > 0 then RelX := Rel else RelX := -Rel;
      if RelX < -MouseStrokeTolerance then Result := btStrokeLeft;
      if RelX >  MouseStrokeTolerance then Result := btStrokeRight;
      if MouseXCounter > 0 then RelY := Rel else RelY := -Rel;
      if (RelY <   1/MouseStrokeTolerance) and (RelY >   0) then Result := btStrokeDown;
      if (RelY >  -1/MouseStrokeTolerance) and (RelY <   0) then Result := btStrokeUp;
      if (Rel  > 1-1/MouseStrokeTolerance) and (Rel  < 1+1/MouseStrokeTolerance) then begin
        if MouseYCounter > 0 then Result := btStrokeRightDown else Result := btStrokeLeftUp;
      end;
      if (Rel > -1-1/MouseStrokeTolerance) and (Rel < -1+1/MouseStrokeTolerance) then begin
        if MouseYCounter > 0 then Result := btStrokeLeftDown else Result := btStrokeRightUp;
      end;
    end else begin
      if MouseXCounter < -MouseStrokeTolerance then Result := btStrokeLeft;
      if MouseXCounter >  MouseStrokeTolerance then Result := btStrokeRight;
    end;
    MouseXCounter := 0; MouseYCounter := 0;
  end;
end;

procedure TController.ApplyMouseCapture(Value: Boolean);
begin
  MouseCaptureActuallyActive := Value;
end;

procedure TController.SetMouseCapture(const Value: Boolean);
var SX, SY: Integer;
begin
  if FMouseCapture = Value then Exit;
  if Value then begin
    CaptureMouseX := MouseX;
    CaptureMouseY := MouseY;
    RecalcCaptureCoords;
  end else begin
    MouseX := CaptureMouseX;
    MouseY := CaptureMouseY;
    SX := MouseX; SY := MouseY;
    ClientToScreen(Handle, SX, SY);
    SetCursorPos(SX, SY);
  end;
  FMouseCapture := Value;
  ApplyMouseCapture(Value);
end;

procedure TController.SetCursorCapturePos;
begin
  if not MouseCaptureActuallyActive then Exit;
  SetCursorPos(CaptureMouseX, CaptureMouseY);
end;

function TController.GetInputBuffer: string;
begin
  Result := FInputBuffer;
  FInputBuffer := '';
end;

function TController.QueryInput: TInputQueryResult;
var i: Integer;

  procedure AddEvent(EType: TEventType; EData: Smallint);
  begin
    Assert(TotalEvents < MaxEvents, 'TController.QueryInput: too many events');
    if (EType = btNone) or (TotalEvents >= MaxEvents) then Exit;

    Inc(TotalEvents);
    InputEvents[TotalEvents-1].EventType := EType;
    InputEvents[TotalEvents-1].EventData := EData;
    case EType of
      btKeyDown: begin
        Result := Result + [iqrKeyPressed, iqrKeyChanged];
  {      if (EData = IK_LSHIFT)   or (EData = IK_RSHIFT)   or (EData = IK_SHIFT)   then ShiftState := True;
        if (EData = IK_LCONTROL) or (EData = IK_RCONTROL) or (EData = IK_CONTROL) then CtrlState  := True;
        if (EData = IK_LALT)     or (EData = IK_RALT)     or (EData = IK_ALT)     then AltState   := True;}
      end;
      btKeyUp: begin
        Result := Result + [iqrKeyChanged];
  {      if (EData = IK_LSHIFT)   or (EData = IK_RSHIFT)   or (EData = IK_SHIFT)   then ShiftState := False;
        if (EData = IK_LCONTROL) or (EData = IK_RCONTROL) or (EData = IK_CONTROL) then CtrlState  := False;
        if (EData = IK_LALT)     or (EData = IK_RALT)     or (EData = IK_ALT)     then AltState   := False;}
      end;
      btStrokeLeft..btStrokeRightDown: Result := Result + [iqrMouseMoved];
    end;
  end;

begin
  Result := [];
  TotalEvents := 0;
  AddEvent(GetMouseEvent, 0);
  for i := 0 to 255 do begin
    if KeyboardState[i] <> LastKeyState[i] then begin
      if KeyboardState[i] >= 128 then AddEvent(btKeyDown, i) else AddEvent(btKeyUp, i);
    end;
  end;
end;

constructor TController.Create(AHandle: Cardinal; AMessageHandler: BaseMsg.TMessageHandler);
begin
  Handle := AHandle;
  FSystemCursor := True;
  {$Include I_KeyStr.inc}
  MouseQueryTimeOut := 0;
  DblClickTimeout   := 300;

{  ShiftState := False;
  CtrlState := False;
  AltState := False;}

  MessageHandler := AMessageHandler;

  GetInputState;

  MouseWindow := GetClipCursor;
  SetMouseWindow(MouseWindow.Left, MouseWindow.Top, MouseWindow.Right, MouseWindow.Bottom);

  FillChar(KeyQueryState, SizeOf(KeyQueryState), 0);
end;

destructor TController.Destroy;
var i: Integer;
begin
  MouseCapture := False;
  for i := 0 to TotalBindings - 1 do with Bindings[i] do begin
    Current := First;
    while Current <> nil do begin
      First := Current;
      Current := Current^.Next;
      FreeMem(First);
    end;
  end;
  SetLength(Bindings, 0);
  inherited;
end;

function TController.KeyToStr(Key: Integer): string;
begin
  Result := KeyStr[Key];
end;

function TController.StrToKey(Name: string): Integer;
begin
  Name := UpperCase(TrimSpaces(Name));
  Result := 255;
  while (Result >= 0) and (UpperCase(KeyStr[Result]) <> Name) do Dec(Result);
end;

function TController.IsModifierKey(Key: Word): Boolean;
begin
  Result := (Key = IK_CONTROL) or (Key = IK_LCONTROL) or (Key = IK_RCONTROL) or
            (Key = IK_ALT)     or (Key = IK_LALT)     or (Key = IK_RALT)     or
            (Key = IK_SHIFT)   or (Key = IK_LSHIFT)   or (Key = IK_RSHIFT)   or
                                  (Key = IK_ROS)     or (Key = IK_LOS);
end;

function TController.GetHotKey(Key: Word; Modifiers: TKeyModifiers): THotkey;
begin
  Result := Key;
  if kmControl  in Modifiers then Result := Result or hmControl;
  if kmLControl in Modifiers then Result := Result or hmLControl;
  if kmRControl in Modifiers then Result := Result or hmRControl;
  if kmShift    in Modifiers then Result := Result or hmShift;
  if kmLShift   in Modifiers then Result := Result or hmLShift;
  if kmRShift   in Modifiers then Result := Result or hmRShift;
  if kmAlt      in Modifiers then Result := Result or hmAlt;
  if kmLAlt     in Modifiers then Result := Result or hmLAlt;
  if kmRAlt     in Modifiers then Result := Result or hmRAlt;
  if kmLOS      in Modifiers then Result := Result or hmLOS;
  if kmROS      in Modifiers then Result := Result or hmROS;
  if kmOS       in Modifiers then Result := Result or hmOS;
end;

function TController.HotKeyToStr(HotKey: THotkey): string;
begin
  Result := '';

  if HotKey and hmControl  = hmControl  then Result := Result + 'Ctrl + ';
  if HotKey and hmLControl = hmLControl then Result := Result + 'LControl + ';
  if HotKey and hmRControl = hmRControl then Result := Result + 'RControl + ';
  if HotKey and hmShift    = hmShift    then Result := Result + 'Shift + ';
  if HotKey and hmLShift   = hmLShift   then Result := Result + 'LShift + ';
  if HotKey and hmRShift   = hmRShift   then Result := Result + 'RShift + ';
  if HotKey and hmAlt      = hmAlt      then Result := Result + 'Alt + ';
  if HotKey and hmLAlt     = hmLAlt     then Result := Result + 'LAlt + ';
  if HotKey and hmRAlt     = hmRAlt     then Result := Result + 'RAlt + ';
  if HotKey and hmLOS      = hmLOS      then Result := Result + 'LOS + ';
  if HotKey and hmROS      = hmROS      then Result := Result + 'ROS + ';
  if HotKey and hmOS       = hmOS       then Result := Result + 'OS + ';

  if (HotKey and $FFFF <> 0) and not IsModifierKey(HotKey and $FFFF) then
    Result := Result + KeyToStr(HotKey and $FFFF) else
      Result := Result + 'NONE';
end;

function TController.StrToHotKey(const BindStr: TBindingStr): THotkey;
var Cur, LBindings, Terminator: PBinding;
begin
  Result := 0;
  ParseBinding(BindStr, LBindings, Terminator);
  Cur := LBindings;
  while (Cur <> nil) and (Cur^.BindType = btKeyDown) and IsModifierKey(Cur^.BindData) do begin
    if Cur^.BindData = IK_CONTROL  then Result := Result or hmControl;
    if Cur^.BindData = IK_LCONTROL then Result := Result or hmLControl;
    if Cur^.BindData = IK_RCONTROL then Result := Result or hmRControl;

    if Cur^.BindData = IK_ALT  then Result := Result or hmAlt;
    if Cur^.BindData = IK_LALT then Result := Result or hmLAlt;
    if Cur^.BindData = IK_RALT then Result := Result or hmRAlt;

    if Cur^.BindData = IK_SHIFT  then Result := Result or hmShift;
    if Cur^.BindData = IK_LSHIFT then Result := Result or hmLShift;
    if Cur^.BindData = IK_RSHIFT then Result := Result or hmRShift;

    if Cur^.BindData = IK_LOS then Result := Result or hmLOS;
    if Cur^.BindData = IK_ROS then Result := Result or hmROS;

    Cur := Cur^.Next;
  end;

//  if Result := 0 then Exit;                      // No modifiers
  if (Cur <> nil) and not IsModifierKey(Cur^.BindData) and
     ((Cur^.BindType = btKeyDown) or (Cur^.BindType = btKeyClick)) then 
    Result := Result or Cur^.BindData else
      Result := 0;
end;

function TController.GetHotkeyModifiers(HotKey: THotkey): TKeyModifiers;
begin
  Result := [];
  if HotKey and hmControl > 0 then Include(Result, kmControl);
  if HotKey and hmShift   > 0 then Include(Result, kmShift);
  if HotKey and hmAlt     > 0 then Include(Result, kmAlt);
  if HotKey and hmLOS     > 0 then Include(Result, kmLOS);
  if HotKey and hmROS     > 0 then Include(Result, kmROS);
end;

procedure TController.BindCommand(const ABinding: string; MsgType: CMessage; const ATimeoutMs: LongWord = DefaultTimeout);
var TB: PBinding;
begin
  Inc(TotalBindings); SetLength(Bindings, TotalBindings);

  with Bindings[TotalBindings - 1] do begin
    ParseBinding(ABinding, First, Terminator);
    Current := First;
    TimeoutMs := ATimeoutMs;
    MessageType := MsgType;
    MembersKind := 0;
  end;

  TB := Bindings[TotalBindings - 1].First;
  while TB <> nil do begin
    case TB^.BindType of
      btKeyDown, btKeyUp, btKeyClick: if (TB^.BindData = IK_MOUSELEFT) or (TB^.BindData = IK_MOUSEMIDDLE) or (TB^.BindData = IK_MOUSERIGHT) then
                                        Bindings[TotalBindings - 1].MembersKind := Bindings[TotalBindings - 1].MembersKind or bmMouseButtons else
                                          Bindings[TotalBindings - 1].MembersKind := Bindings[TotalBindings - 1].MembersKind or bmKeyboard;
      btMouseMove, btMouseHMove, btMouseVMove, btMouseRoll, btStrokeLeft..btStrokeRightDown: Bindings[TotalBindings - 1].MembersKind := Bindings[TotalBindings - 1].MembersKind or bmMouseMotion;
    end;
    TB := TB^.Next;
  end;
end;

procedure TController.BindDelegate(const ABinding: string; Delegate: TInputDelegate; ACustomData: SmallInt; const ATimeoutMs: Longword = 0);
var i, CBIndex: Integer;
begin
  CBIndex := -1;
  for i := 0 to TotalDelegates - 1 do if @Delegates[i] = @Delegate then begin CBIndex := i; Break; end;
  if CBIndex < 0 then begin
    if TotalDelegates >= MaxDelegates then begin
       Log(ClassName + '.BindDelegate: Too many Delegates', lkError); 
      Exit;
    end;
    Inc(TotalDelegates); SetLength(Delegates, TotalDelegates);
    CBIndex := TotalDelegates - 1;
    Delegates[CBIndex] := Delegate;
  end;
  Inc(TotalBindings); SetLength(Bindings, TotalBindings);
  with Bindings[TotalBindings - 1] do begin
    ParseBinding(ABinding, First, Terminator);

    Current := First;
    TimeoutMs := ATimeoutMs;

    CustomData := ACustomData;
    DelegateIndex := Word(CBIndex);
    MembersKind := bkDelegate;
  end;
end;

procedure TController.BindPointer(const ABinding: string; const ActionType: Longword; const Data: Pointer; const Value: Word = 0; const ATimeoutMs: LongWord = 0);
var i, PointerIndex: Integer;
begin
  PointerIndex := -1;
  for i := 0 to TotalPointers - 1 do if Pointers[i] = Data then begin PointerIndex := i; Break; end;
  if PointerIndex < 0 then begin
    if TotalPointers >= MaxPointers then begin
       Log(ClassName + '.BindPointer: Too many pointers', lkError); 
      Exit;
    end;
    Inc(TotalPointers); SetLength(Pointers, TotalPointers);
    PointerIndex := TotalPointers - 1;
    Pointers[PointerIndex] := Data;
  end;
  Inc(TotalBindings); SetLength(Bindings, TotalBindings);
  with Bindings[TotalBindings - 1] do begin
    ParseBinding(ABinding, First, Terminator);
    Current := First;
    TimeoutMs := ATimeoutMs;
    AType := ActionType;
    Value := Value;
    PTRIndex := Byte(PointerIndex);
    MembersKind := bkPointer;
  end;
end;

procedure TController.UnBind(const Index: Longword);
begin
  Dec(TotalBindings); 
  if Index < TotalBindings then Bindings[Index] := Bindings[TotalBindings];
  SetLength(Bindings, TotalBindings);
  CleanPointers;
end;

procedure TController.CleanPointers;                               //ToFix: Bug here
var i, j: Cardinal; Used: Boolean;
begin
  for j := TotalPointers - 1 downto 0 do begin
    Used := False;
    for i := 0 to TotalBindings - 1 do if (Bindings[i].MembersKind and bkPointer = bkPointer) and (Bindings[i].PTRIndex = j) then begin
      Used := True; Break;
    end;
    if not Used then begin
      Dec(TotalPointers);
      SetLength(Pointers, TotalPointers);
    end;
  end;

  for j := TotalDelegates - 1 downto 0 do begin
    Used := False;
    for i := 0 to TotalBindings - 1 do if (Bindings[i].MembersKind and bkDelegate = bkDelegate) and (Bindings[i].DelegateIndex = j) then begin
      Used := True; Break;
    end;
    if not Used then begin
      Dec(TotalDelegates);
      SetLength(Delegates, TotalDelegates);
    end;
  end;
end;

procedure TController.UnBindAll;
begin
  TotalBindings := 0; TotalDelegates := 0; TotalPointers := 0;
  SetLength(Bindings,  TotalBindings);
  SetLength(Delegates, TotalDelegates);
  SetLength(Pointers,  TotalPointers);
end;

function TController.IsKeyPressed(Key: Integer): Boolean;
begin
  Result := KeyBoardState[Key] >= 128;
end;

procedure TController.UpdateModifiers;
begin
  Modifiers := [];
  if IsKeyPressed(IK_SHIFT) or IsKeyPressed(IK_LSHIFT) or IsKeyPressed(IK_RSHIFT) then Include(Modifiers, kmShift);
  if IsKeyPressed(IK_LSHIFT) then Include(Modifiers, kmLShift);
  if IsKeyPressed(IK_RSHIFT) then Include(Modifiers, kmRShift);

  if IsKeyPressed(IK_Alt) or IsKeyPressed(IK_LAlt) or IsKeyPressed(IK_RAlt) then Include(Modifiers, kmAlt);
  if IsKeyPressed(IK_LAlt) then Include(Modifiers, kmLAlt);
  if IsKeyPressed(IK_RAlt) then Include(Modifiers, kmRAlt);

  if IsKeyPressed(IK_Control) or IsKeyPressed(IK_LControl) or IsKeyPressed(IK_RControl) then Include(Modifiers, kmControl);
  if IsKeyPressed(IK_LControl) then Include(Modifiers, kmLControl);
  if IsKeyPressed(IK_RControl) then Include(Modifiers, kmRControl);

  if IsKeyPressed(IK_LOS) or IsKeyPressed(IK_ROS) then Include(Modifiers, kmOS);
  if IsKeyPressed(IK_LOS) then Include(Modifiers, kmLOS);
  if IsKeyPressed(IK_ROS) then Include(Modifiers, kmROS);
end;

procedure TController.ProcessInput(const EventFilter: TInputFilter);
var
  i: Integer; CurTerm: PBinding;
  EndPass, Terminated: Boolean;
  MouseEvent: TEventType;

  function MatchMouseEvent(Event1, Event2: TEventType): Boolean;
  begin
    Result := False;
    case Event1 of
      btMouseMove:  Result := (Event2 >= btMouseMove) and (Event2 <= btStrokeRightDown);
      btMouseHMove: Result := (Event2  = btMouseHMove) or (Event2  = btStrokeLeft) or (Event2 = btStrokeRight) or (Event2 >= btStrokeLeftUp) and (Event2 <= btStrokeRightDown);
      btMouseVMove: Result := (Event2  = btMouseVMove) or (Event2  = btStrokeUp)   or (Event2 = btStrokeDown)  or (Event2 >= btStrokeLeftUp) and (Event2 <= btStrokeRightDown);

      btStrokeLeft:  Result := (Event2 = btStrokeLeft)  or (Event2 = btStrokeLeftUp)   or (Event2 <= btStrokeLeftDown);
      btStrokeRight: Result := (Event2 = btStrokeRight) or (Event2 = btStrokeRightUp)  or (Event2 <= btStrokeRightDown);
      btStrokeUp:    Result := (Event2 = btStrokeUp)    or (Event2 = btStrokeLeftUp)   or (Event2 <= btStrokeRightUp);
      btStrokeDown:  Result := (Event2 = btStrokeDown)  or (Event2 = btStrokeLeftDown) or (Event2 <= btStrokeRightDown);
      btStrokeLeftUp, btStrokeRightUp, btStrokeLeftDown, btStrokeRightDown, btMouseRoll: Result := (Event2 = Event1);
    end;
  end;

  procedure MatchBinding(BData: Integer);
  var Msg: TMessage;
  begin
    with Bindings[i], Current^ do begin
      if Next = nil then begin
        if MembersKind and bkPointer = bkPointer then case AType of    // Pointer
          atBooleanOn:     Boolean(Pointers[PTRIndex]^) := True;
          atBooleanOff:    Boolean(Pointers[PTRIndex]^) := False;
          atBooleanToggle: Boolean(Pointers[PTRIndex]^) := not Boolean(Pointers[PTRIndex]^);
          atSetByte: Byte(Pointers[PTRIndex]^) := Value;
          atSetWord: Word(Pointers[PTRIndex]^) := Value;
          atSetLongWord: LongWord(Pointers[PTRIndex]^) := Value;
        end else if MembersKind and bkDelegate = bkDelegate then begin   // Delegate
          Delegates[DelegateIndex](BData, CustomData);
        end else begin                                                   // Message
          Msg := MessageType.Create;
          Msg.Flags := Msg.Flags + [mfCore];
          if Msg is TKeyboardMsg then
            TKeyboardMsg(Msg).Create(BData) else
              if Msg is TMouseMsg then
                TMouseMsg(Msg).Create(MouseX, MouseY, Modifiers);
          if Assigned(MessageHandler) then MessageHandler(Msg);
        end;
        Current := First;
      end else begin
        Current := Next;
        EndPass := False;
      end;
      LastMs := CurrentMs;
    end;
  end;

  function IsKeyWasPressed(Key: Integer): Boolean;
  begin
    Result := (KeyboardState[Key] >= 128) and (LastKeyState[Key] <  128);
  end;

  function IsKeyWasReleased(Key: Integer): Boolean;
  begin
    Result := (KeyboardState[Key] < 128) and (LastKeyState[Key] >= 128);
  end;

begin
//  if not Active then Exit;
  CurrentMs := GetCurrentMs;

  Move(KeyboardState[0], LastKeyState[0], 256);
  GetInputState;

  UpdateModifiers();

  if ifNotBound in EventFilter then begin                      //
    if iqrMouseMoved in QueryInput then MouseEvent := InputEvents[0].EventType else MouseEvent := btNone;
  end else MouseEvent := GetMouseEvent;

//  if MouseEvent = LastMouseEvent then MouseEvent := btNone;

  if ifBound in EventFilter then for i := 0 to TotalBindings - 1 do with Bindings[i] do if First <> nil then begin
    EndPass := False; Terminated := False;
    while not EndPass do begin
      EndPass := True;
      if Current <> First then begin
        if (TimeoutMs > 0) then begin                                   // Handle timeout
          if CurrentMs - LastMs > TimeoutMs then begin
            Current := First;
          end;
        end;

        CurTerm := Terminator;
        while (CurTerm <> nil) and (Current <> First) do begin
          with CurTerm^ do case BindType of
            btKeyDown: if  IsKeyWasPressed(BindData) then Break;//Current := First;
            btKeyUp:   if IsKeyWasReleased(BindData) then Break;//Current := First;
            btMouseMove..btStrokeRightDown: if MatchMouseEvent(CurTerm^.BindType, MouseEvent) then Break;
          end;
          CurTerm := CurTerm^.Next;
        end;
        Terminated := CurTerm <> nil;
      end;
      if Terminated then begin                                        // Reset sequence if terminated
        Current := First;
      end else with Current^ do begin                                 // Else go on
        case BindType of
          btKeyDown: if IsKeyWasPressed(BindData)  then MatchBinding(BindData);
          btKeyUp:   if IsKeyWasReleased(BindData) then MatchBinding(BindData);
          btMouseMove:  if (MouseState.lX <> 0) or (MouseState.lY <> 0) then MatchBinding((MouseState.lY) shl 16 + (MouseState.lX));
          btMouseHMove: if  MouseState.lX <> 0 then MatchBinding(MouseState.lX);
          btMouseVMove: if  MouseState.lY <> 0 then MatchBinding(MouseState.lY);
          btMouseRoll:  if  MouseState.lZ <> 0 then MatchBinding(MouseState.lZ);
        end;
        if BindType = MouseEvent then MatchBinding(0);
      end;
    end;
  end else begin
    MouseXCounter := 0;
    MouseYCounter := 0;
  end;
end;

procedure TController.SetMouseWindow(const X1, Y1, X2, Y2: Integer);
begin
//  if not Active then Exit;
  MouseWindow.Left := X1; MouseWindow.Top := Y1;
  MouseWindow.Right := X2; MouseWindow.Bottom := Y2;
end;

procedure TController.InputEventsToMessages;
var i: Integer; CurMs: Int64; MouseEvent: Boolean;
begin
  CurMs := GetCurrentMs;
  for i := 0 to TotalEvents-1 do begin
    case InputEvents[i].EventType of
      btKeyDown, btKeyUp: begin
        MouseEvent := (InputEvents[i].EventData = IK_MOUSELEFT) or (InputEvents[i].EventData = IK_MOUSEMIDDLE) or (InputEvents[i].EventData = IK_MOUSERIGHT);

        if (InputEvents[i].EventType = btKeyDown) then begin
          if MouseEvent then
            MessageHandler(TMouseDownMsg.Create(MouseX, MouseY, InputEvents[i].EventData, Modifiers)) else
              MessageHandler(TKeyDownMsg.Create(InputEvents[i].EventData));
          KeyQueryState[InputEvents[i].EventData].State := kqsDown;
        end else begin
          if MouseEvent then
            MessageHandler(TMouseUpMsg.Create(MouseX, MouseY, InputEvents[i].EventData, Modifiers)) else
              MessageHandler(TKeyUpMsg.Create(InputEvents[i].EventData));
          if KeyQueryState[InputEvents[i].EventData].State = kqsDown then begin
            if MouseEvent then
              MessageHandler(TMouseClickMsg.Create(MouseX, MouseY, InputEvents[i].EventData, Modifiers)) else
                MessageHandler(TKeyClickMsg.Create(InputEvents[i].EventData));
            if (CurMs - KeyQueryState[InputEvents[i].EventData].LastClickedTime < DblClickTimeout) then begin
              if MouseEvent then
                MessageHandler(TMouseDblClickMsg.Create(MouseX, MouseY, InputEvents[i].EventData, Modifiers)) else
                  MessageHandler(TKeyDblClickMsg.Create(InputEvents[i].EventData));
              KeyQueryState[InputEvents[i].EventData].LastClickedTime := 0;
            end else KeyQueryState[InputEvents[i].EventData].LastClickedTime := CurMs;
          end;
          KeyQueryState[InputEvents[i].EventData].State := kqsUp;
        end;
      end;
      btMouseMove, btMouseHMove, btMouseVMove, btMouseRoll, btStrokeLeft..btStrokeRightDown: begin
        MessageHandler(TMouseMoveMsg.Create(MouseX, MouseY, Modifiers));
{        case InputEvents[i].EventType of
          btMouseMove, btMouseHMove, btMouseVMove,
          btMouseRoll,
          btStrokeLeft, btStrokeRight, btStrokeUp, btStrokeDown,
          btStrokeLeftUp, btStrokeRightUp, btStrokeLeftDown, btStrokeRightDow
        end;}
      end;
    end;
  end;
end;

procedure TController.HandleMessage(const Msg: TMessage);
begin
  if Msg = nil then Exit;

  if (Msg.ClassType = TWindowResizeMsg) or (Msg.ClassType = TWindowMoveMsg) then begin
    RecalcCaptureCoords;
    if FMouseCapture then ApplyMouseCapture(True);
  end else if Msg.ClassType = TWindowActivateMsg then begin
    ProcessInput([]);
    SetSystemCursor(FSystemCursor);
    if FMouseCapture then ApplyMouseCapture(True);
  end else if (Msg.ClassType = TWindowDeactivateMsg) or
              (Msg.ClassType = TWindowMinimizeMsg)   then begin
    if FMouseCapture then ApplyMouseCapture(False);
  end else if (EnableCharactersInput) and (Msg.ClassType = TCharInputMsg) then with TCharInputMsg(Msg) do
    if Character = #8 then if FInputBuffer <> '' then FInputBuffer := Copy(FInputBuffer, 0, Length(FInputBuffer)-1) else
      if Character = ' ' then FInputBuffer := FInputBuffer + Character;
end;

procedure TController.ParseBinding(s: string; out Binding, Terminator: PBinding);
const
  Specifiers = ',+-:^';
  GestureSpecifier = 4;
  ModifiedBindTypes: array[0..3] of TEventType = (btKeyClick, btKeyDown, btKeyUp, btKeyDblClick);
  GestureNames: array[0..11] of string[20] = ('MouseMove', 'MouseMoveH', 'MouseMoveV', 'MouseRoll',
                                              'MouseStrokeLeft', 'MouseStrokeRight', 'MouseStrokeUp', 'MouseStrokeDown',
                                              'MouseStrokeLeftUp', 'MouseStrokeRightUp', 'MouseStrokeLeftDown', 'MouseStrokeRightDown');
  GestureTypes: array[0..11] of TEventType = (btMouseMove, btMouseHMove, btMouseVMove, btMouseRoll,
                                              btStrokeLeft, btStrokeRight, btStrokeUp, btStrokeDown,
                                              btStrokeLeftUp, btStrokeRightUp, btStrokeLeftDown, btStrokeRightDown);
(*  BindElement	= (<Key><Specifier>)|<Gesture>"^"
    Key			= Key name
    Specifier		= ","|"+"|"-"|":" - can be omitted at the end ("," will be assumed)
    Gesture             = "MouseMove"|"MouseMoveH"|"MouseMoveV"|"MouseRoll"|
                          "MouseStrokeLeft"|"MouseStrokeRight"|"MouseStrokeUp"|"MouseStrokeDown"|
                          "MouseStrokeLeftUp"|"MouseStrokeRightUp"|"MouseStrokeLeftDown"|"MouseStrokeRightDown"
    Binding		= <BindElement> {<BindElement>}
    "," - key click event
    "+"	- key down event
    "-"	- key up event
    ":"	- key double click *)
var Specifier, CurPos, Len, Key: Integer; Current: PBinding;

  function GetGestureType(const AName: string): TEventType;
  var i: Integer;
  begin
    Result := btNone;
    i := High(GestureNames);
    while (i >= 0) and (AName <> GestureNames[i]) do Dec(i);
    if i >= 0 then Result := GestureTypes[i];
  end;

  function ParseElement: PBinding;
  var Name: TBindingName; BindType: TEventType;
  begin
    Result := nil;
    Name := '';
    while (CurPos <= Len) and (Pos(s[CurPos], Specifiers) = 0) do begin          // Scan name
      Name := Name + s[CurPos];
      Inc(CurPos);
    end;
    
    if CurPos > Len then Specifier := 0 else begin                       // end of string - click specifier, else
{      if (CurPos = Len) and (Pos(s[CurPos], Modifiers) > 0) and (TrimSpaces(Name) = '') then begin   // a specifier at the end is key name if Name is empty
        Name := Name + s[CurPos];
        Modifier := 0
        Inc(CurPos);
      end else}
      if (CurPos+1 <= Len) and (Pos(s[CurPos+1], Specifiers) > 0) then begin     // if doubled modifier add the first one to name
        Name := Name + s[CurPos];
        Inc(CurPos);
      end;
      Specifier := Pos(s[CurPos], Specifiers)-1;
      Inc(CurPos);
    end;

    Name := TrimSpaces(Name);
    if Name = '' then Exit;

    if Specifier = GestureSpecifier then begin
      Key := 0;
      BindType := GetGestureType(Name);
      if BindType = btNone then begin
        Log(ClassName + '.ParseBinding: Invalid gesture name: "' + Name + '"', lkError);
        Exit;
      end;
    end else begin
      Key := StrToKey(Name);
      if Key = -1 then begin
        Log(ClassName + '.ParseBinding: Invalid key name: "' + Name + '"', lkError);
        Exit;
      end;
      BindType := ModifiedBindTypes[Specifier];
    end;

    Result := NewBinding(BindType, Key);

    {$IFDEF DEBUGMODE} 
{    case ModifiedBindTypes[Modifier] of
      btKeyClick:    Log(' "' + Name + '" click');
      btKeyDown:     Log(' "' + Name + '" down');
      btKeyUp:       Log(' "' + Name + '" up');
      btKeyDblClick: Log(' "' + Name + '" double click');
    end;}
     {$ENDIF}
  end;

begin
  {$IFDEF DEBUGMODE} 
//  Log('Parsing binding...', lkTitle);
   {$ENDIF}
  Binding := nil;
  if s = '' then Exit;
  if Pos(s[Length(s)], Specifiers) = 0 then s := s + ',';
  Len := Length(s);
  CurPos := 1;
  Binding := ParseElement;
  Current := Binding;

  while (CurPos <= Len) and (Current <> nil) do begin
    Current^.Next := ParseElement;
    Current := GetLastBinding(Current^.Next);
  end;
end;

end.
