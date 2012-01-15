(*
 @Abstract(Base messages unit)
 (C) 2003-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains base message classes and message management classes
*)
{$Include GDefines.inc}
unit BaseMsg;

interface

uses BaseTypes;

const
  // Message pool grow step
  MessagesCapacityStep = 16;
  // Initial capacity of messages pool in bytes
  MessagePoolInitialCapacity = 65536;
  MessagePoolMaxCapacity = 65536 * 256;

type
(*  TMessageDestinationElements = (// Send message to specified recipient. Mutually exclusive with mdChilds.
                                 mdRecipient,
                                 // Send message to childs of specified item. Mutually exclusive with mdBroadcast and mdRecipient.
                                 mdChilds,
                                 // Broadcast message from root item. Mutually exclusive with mdChilds.
                                 mdBroadcast,
                                 // Send message to core handler
                                 mdCore,
                                 // Send message asyncronously
                                 mdAsync);
  TMessageDestination = set of TMessageDestinationElements;*)

  // Type to use as string type in messages. Do not use in message classes types which need finalization (such as dynamic arrays or long strings) this will cause memory leaks.
  TMessageString = ShortString;
  { @Abstract(Base class for all message classes)
    Messages are stored in specific pool (see @Link(TMessagePool)) to speed-up allocation and avoid memory leaks. <br>
    As a consequence, messages can be created in such way: <i>SomeObject.HandleMessage(TMessage.Create)</i> without risk of a memory leak. <br>
    <b>Restriction:</b> Do not use in message classes types which need finalization (such as dynamic arrays or long strings) this will cause memory leaks. Use short strings instead. }
  TMessage = class(TObject)
  private
    FFlags: TMessageFlags;
  public
    // This method overridden to store messages in specific pool
    class function NewInstance: TObject; override;
    // If you erroneously deallocate a message manually the overridden implementation of this method will signal you
    procedure FreeInstance; override;

    // Call this method if you don't want the message to be discarded
    procedure Invalidate;

    // Message flags
    property Flags: TMessageFlags read FFlags write FFlags;
  end;

  // Message class reference
  CMessage = class of TMessage;

  // Message pool data structure
  TPool = record
    Store: Pointer;
    Size:  Cardinal;
  end;
  PPool = ^TPool;

  { @Abstract(Message pool class)
    The class implements memory management for all instances of @Link(TMessage) and its descendant classes }
  TMessagePool = class
  private
    CurrentPool, BackPool: PPool;
    FCapacity: Cardinal;
    procedure SetCapacity(ACapacity: Cardinal);
    procedure SwapPools;
    function Allocate(Size: Cardinal): Pointer;
  public
    constructor Create;
    destructor Destroy; override;

    // Begins message handling. Should be called once per main applicatin cycle
    procedure BeginHandle;
    // Ends message handling and clears messages. Should be called once per main applicatin cycle after <b>BeginHandle</b>
    procedure EndHandle;
  end;

  // Base class for all items. Provides general message handling interface
  TBaseItem = class
  public
    procedure HandleMessage(const Msg: TMessage); virtual; abstract;
  end;

  // Array of messages
  TMessages = array of TMessage;

  // Message handler delegate
  TMessageHandler = procedure(const Msg: TMessage) of object;

  { @Abstract(Asynchronous messages queue implementation)
    The class provides the possibility to handle asynchronous messages. <br>
    Message handlers can generate other asynchronous messages which will be handled during next handling cycle.
    If you use this class there is no need to call any methods of @Link(TMessagePool). }
  TMessageSubsystem = class
  private
    HandleStarted: Boolean;
    BackMessages, Messages:  TMessages;
    TotalMessages, TotalBackMessages, CurrentMessageIndex: Integer;
    procedure SwapPools;
  public
    { Locks current message queue. Should be called before message handling cycle. <br>
      All asynchronous messages generated during handling will be available during next handling cycle. <br>
      Calls @Link(TMessagePool).BeginHandle so application has no need to call it. }
    procedure BeginHandle;
    // Should be called after handling cycle. Calls @Link(TMessagePool).EndHandle so application has no need to call it
    procedure EndHandle;
    // Add an asynchronous message to the queue
    procedure Add(const Msg: TMessage);
    { Extracts a message from the queue if any, places it to <b>Msg</b> and returns @True if there was a message in queue.
      Otherwise returns @False and @nil in <b>Msg</b>. Should be called only between BeginHandle and EndHandle calls. }
    function ExtractMessage(out Msg: TMessage): Boolean;
  end;

  // @Abstract(Base error class)
  TError = class(TMessage)
  public
    // Error message text
    ErrorMessage: string;
    constructor Create(AErrorMessage: string);
  end;

  { Error handler delegate. When an error occurs a delegate of this type is called (See @Link(ErrorHandler)).
    If it returns @True the application should try to continue the operation which caused the error. }
  TErrorHandler = function(const Error: TError): Boolean of object;

  // Base class for notification messages
  TNotificationMessage = class(TMessage)
  end;

  // This message is sent to an object when it should reset its timer if any
  TSyncTimeMsg = class(BaseMsg.TNotificationMessage)
  end;

  // Pause begin message
  TPauseMsg = class(TMessage)
  end;
  // Pause end message
  TResumeMsg = class(TMessage)
  end;
  // Progress report message
  TProgressMsg = class(TMessage)
  public
    // Progress indicator ranging from 0 to 1
    Progress: Single;
    constructor Create(AProgress: Single);
  end;

  // Base class for system messages
  TSystemMessage = class(TMessage)
  end;

  // Subsystem metaclass
  CSubsystem = class of TBaseSubsystem;
  { @Abstract(Base class for all subsystems)
    Subsystem is a set of routines which implements some specific function and can be connected/disconnected or replaced during runtime. <br>
    Subsystems are usually arranged in one or more classes/units }
  TBaseSubsystem = TBaseItem;
  // Subsystem action type for @Link(TSubsystemMsg) message
  TSubsystemAction = (// subsystem connected
                      saConnect,
                      // subsystem disconnected
                      saDisconnect);
  // When an application receives this message it should shut down as soon as possible
  TForceQuitMsg = class(TSystemMessage)
  end;

  // This message is sent to an <b>application</b> when an option set needs to be applyed (e.g. user clicked "Apply")
  TOptionsApplyMsg = class(TSystemMessage)
  public
    // Option set name to apply
    OptionSet: TMessageString;
    // AOptionSet is the option set name to apply
    constructor Create(const AOptionSet: TMessageString);
  end;

  // This message is sent to an <b>application</b> when an option set needs to be applyed immediately when a user changes it (without clicking the "Apply" button)
  TOptionsPreviewMsg = class(TSystemMessage)
  public
    OptionName, Value: TMessageString;
    constructor Create(const AOptionName, AValue: TMessageString);
  end;

  // This message is sent to an <b>application</b> when it should be notifyed about a particular option set change
  TOptionsApplyNotifyMsg = class(TOptionsPreviewMsg)
  end;

  // Base class for operating system messages
  TOSMessage = class(TMessage)
  end;

  // This message is sent to an <b>application</b> when its window is about to be activated
  TWindowActivateMsg = class(TOSMessage)
  end;

  // This message is sent to an <b>application</b> when its window is about to be deactivated
  TWindowDeactivateMsg = class(TOSMessage)
  end;

  // This message is sent to an <b>application</b> after its window position has changed
  TWindowMoveMsg = class(TOSMessage)
  public
    NewX, NewY: Single;
    // X, Y - new window position in screen coordinates
    constructor Create(X, Y: Single);
  end;

  // This message is sent to an <b>application</b> after its window size has changed
  TWindowResizeMsg = class(TOSMessage)
  public
    OldWidth, OldHeight, NewWidth, NewHeight: Single;
    // <b>OldWidth, OldHeight</b> - old size of the window, <b>NewWidth, NewHeight</b> - new size
    constructor Create(AOldWidth, AOldHeight, ANewWidth, ANewHeight: Single);
  end;

  // This message is sent to an <b>application</b> after its window has been minimized
  TWindowMinimizeMsg = class(TOSMessage)
  end;

  // See WM_CANCELMODE (WinAPI)
  TCancelModeMsg = class(TOSMessage)
  end;

  // This message is sent to an <b>application</b> after a command executon from its window menu
  TWindowMenuCommand = class(TOSMessage)
  public
    Command: Integer;
    constructor Create(ACommand: Integer);
  end;
  // ---

  // If some data may be referenced by pointer and the pointer to the data has changed this message is <b>broadcasted</b> with new pointer
  TDataAdressChangeMsg = class(TNotificationMessage)
  public
    OldData, NewData: Pointer;
    DataReady: Boolean;
    // <b>AOldValue</b> - old pointer, <b>ANewValue</b> - new pointer to the data, <b>ADataReady</b> - determines wheter the data is ready to use
    constructor Create(AOldValue, ANewValue: Pointer; ADataReady: Boolean);
  end;

  // This message is <b>broadcasted</b> when some data which may be used by items has modified
  TDataModifyMsg = class(TNotificationMessage)
  public
    // Pointer, identifying the data. usually it's the address of the data in memory
    Data: Pointer;
    // AData - a pointer, identifying the data. usually it's the address of the data in memory
    constructor Create(AData: Pointer);
  end;

  // Base class for user-input messages
  TInputMessage = class(TMessage)
  public
    constructor Create;
  end;

  // Base class for mouse-related messages
  TMouseMsg = class(TInputMessage)
  public
    // coordinates of the mouse pointer in screen coordinate system
    X, Y: Integer;
    // state of some special keys
    ModifierState: TKeyModifiers;
    // AX, AY - coordinates of the mouse pointer in screen coordinate system, AModifierState - state of some special keys
    constructor Create(AX, AY: Integer; AModifierState: TKeyModifiers);
  end;

  // The message is sent to <b>core handler</b> when the mouse pointer moves
  TMouseMoveMsg = class(TMouseMsg)
  end;

  // Base class for mouse button-related messages
  TMouseButtonMsg = class(TMouseMsg)
  public
    // Button number. usually 1 - left, 2 - right, 4 - middle (see Input.IK_MOUSELEFT etc)
    Button: Integer;
    // <b>AButton</b> - button number
    constructor Create(AX, AY, AButton: Integer; AModifierState: TKeyModifiers);
  end;

  // The message is sent to <b>core handler</b> when a mouse button has been pressed
  TMouseDownMsg = class(TMouseButtonMsg)
  end;

  // The message is sent to <b>core handler</b> when a mouse button has been released
  TMouseUpMsg = class(TMouseButtonMsg)
  end;

  // The message is sent to <b>core handler</b> when a mouse button has been clicked
  TMouseClickMsg = class(TMouseButtonMsg)
  end;

  // The message is sent to <b>core handler</b> when a mouse button has been double clicked
  TMouseDblClickMsg = class(TMouseButtonMsg)
  end;

  // Reference to keyboard message class
  CKeyboardMsg = class of TKeyboardMsg;
  // Base class for keyboard-related messages
  TKeyboardMsg = class(TInputMessage)
  public
    // Scan code of the key
    Key: Integer;
    // <b>AKey</b> - scan code of the key
    constructor Create(AKey: Integer);
  end;

  // The message is sent to <b>core handler</b> when a key has been pressed
  TKeyDownMsg = class(TKeyboardMsg)
  end;

  // The message is sent to <b>core handler</b> when a key has been released
  TKeyUpMsg = class(TKeyboardMsg)
  end;

  // The message is sent to <b>core handler</b> when a key has been clicked
  TKeyClickMsg = class(TKeyboardMsg)
  end;

  // The message is sent to <b>core handler</b> when a key has been double clicked
  TKeyDblClickMsg = class(TKeyboardMsg)
  end;

  // The message is sent to <b>core handler</b> when a character input has been made
  TCharInputMsg = class(TKeyboardMsg)
  public
    // Code of the character
    Character: Char;
    // <b>AChar</b> - code of the character, <b>AKey</b> - scan code
    constructor Create(AChar: Char; AKey: Integer);
  end;

var
  MessagePool: TMessagePool;

implementation

{ TMessage }

class function TMessage.NewInstance: TObject;
begin
//  Result := InitInstance(MessagePool.Allocate(InstanceSize));
  Result := TObject(MessagePool.Allocate(InstanceSize));
  PInteger(Result)^ := Integer(Self);
end;

procedure TMessage.FreeInstance;
begin
  Assert(False, 'TMessage and descendants should not be freed manually');
end;

procedure TMessage.Invalidate;
begin
  Include(FFlags, mfInvalid);
end;

{ TError }

constructor TError.Create(AErrorMessage: string);
begin
  ErrorMessage := AErrorMessage;
end;

{ TOptionsApplyMsg }

constructor TOptionsApplyMsg.Create(const AOptionSet: TMessageString);
begin
  OptionSet := AOptionSet;
end;

{ TOptionsPreviewMsg }

constructor TOptionsPreviewMsg.Create(const AOptionName, AValue: TMessageString);
begin
  OptionName := AOptionName; Value := AValue;
end;

{ TWindowMoveMsg }

constructor TWindowMoveMsg.Create(X, Y: Single);
begin
  NewX := X; NewY := Y;
end;

{ TWindowResizeMsg }

constructor TWindowResizeMsg.Create(AOldWidth, AOldHeight, ANewWidth, ANewHeight: Single);
begin
  OldWidth  := AOldWidth;
  OldHeight := AOldHeight;
  NewWidth  := ANewWidth;
  NewHeight := ANewHeight;
end;

{ TWindowMenuCommand }

constructor TWindowMenuCommand.Create(ACommand: Integer);
begin
  Command := ACommand;
end;

{ TDataAdressChangeMsg }

constructor TDataAdressChangeMsg.Create(AOldValue, ANewValue: Pointer; ADataReady: Boolean);
begin
  OldData   := AOldValue;
  NewData   := ANewValue;
  DataReady := ADataReady;
end;

{ TDataModifyMsg }

constructor TDataModifyMsg.Create(AData: Pointer);
begin
  Data := AData;
end;

{ TInputMessage }

constructor TInputMessage.Create;
begin
  Flags := [mfCore];
end;

{ TMouseMsg }

constructor TMouseMsg.Create(AX, AY: Integer; AModifierState: TKeyModifiers);
begin
  inherited Create;
  X := AX; Y := AY;
  ModifierState := AModifierState;
end;

{ TMouseButtonMsg }

constructor TMouseButtonMsg.Create(AX, AY, AButton: Integer; AModifierState: TKeyModifiers);
begin
  inherited Create(AX, AY, AModifierState);
  Button := AButton;
end;

{ TKeyClick }

constructor TKeyboardMsg.Create(AKey: Integer);
begin
  inherited Create;
  Key := AKey;
end;

{ TCharInputMsg }

constructor TCharInputMsg.Create(AChar: Char; AKey: Integer);
begin
  inherited Create(AKey);
  Character := AChar;
end;

{ TMessageSubsystem }

procedure TMessageSubsystem.SwapPools;
var t: TMessages;
begin
  t            := BackMessages;
  BackMessages := Messages;
  Messages       := t;
  t              := nil;

  TotalBackMessages := TotalMessages;
  TotalMessages := 0;
end;

procedure TMessageSubsystem.BeginHandle;
begin
  HandleStarted := True;
  SwapPools;
  CurrentMessageIndex := 0;
  MessagePool.BeginHandle;
end;

procedure TMessageSubsystem.EndHandle;
begin
  Assert(HandleStarted, 'TMessageSubsystem.EndHandle: Invalid call');
  HandleStarted := False;
  MessagePool.EndHandle;
end;

procedure TMessageSubsystem.Add(const Msg: TMessage);
begin
  if Length(Messages) <= TotalMessages then SetLength(Messages, Length(Messages) + MessagesCapacityStep);
  Messages[TotalMessages] := Msg;
  Inc(TotalMessages);
end;

function TMessageSubsystem.ExtractMessage(out Msg: TMessage): Boolean;
begin                                           // ToDo: Needs testing
  Assert(HandleStarted, 'TMessageSubsystem.ExtractMessage: Should be called only between BeginHandle and EndHandle pair');
  Msg := nil;
  if CurrentMessageIndex < TotalBackMessages then begin
    Msg := BackMessages[CurrentMessageIndex];
    Inc(CurrentMessageIndex);
  end;
  Result := Msg <> nil;
end;

{ TMessagePool }

procedure TMessagePool.SetCapacity(ACapacity: Cardinal);
begin
  FCapacity := ACapacity;
  ReAllocMem(CurrentPool^.Store, ACapacity);
  ReAllocMem(BackPool^.Store, ACapacity);
end;

procedure TMessagePool.SwapPools;
var Temp: Pointer;
begin
  Temp := BackPool;
  BackPool := CurrentPool;
  CurrentPool := Temp;
end;

constructor TMessagePool.Create;
begin
  New(CurrentPool);
  CurrentPool^.Store := nil;
  CurrentPool^.Size  := 0;
  New(BackPool);
  BackPool^.Store := nil;
  BackPool^.Size  := 0;
  SetCapacity(MessagePoolInitialCapacity);
end;

destructor TMessagePool.Destroy;
begin
  SetCapacity(0);
  Dispose(CurrentPool);
  Dispose(BackPool);
  inherited;
end;

function TMessagePool.Allocate(Size: Cardinal): Pointer;
var NewCapacity: Integer;
begin
  Assert(CurrentPool^.Size + Size < MessagePoolMaxCapacity, 'Message pool is full');       // Todo: Handle this situation
  if CurrentPool^.Size + Size > FCapacity then begin
    NewCapacity := FCapacity + MessagePoolInitialCapacity;
    if NewCapacity > MessagePoolMaxCapacity then NewCapacity := MessagePoolMaxCapacity;
    SetCapacity(NewCapacity);
  end;

  Result := Pointer(Cardinal(CurrentPool^.Store) + CurrentPool^.Size);
  Inc(CurrentPool^.Size, Size);
end;

procedure TMessagePool.BeginHandle;
begin
  SwapPools;
end;

procedure TMessagePool.EndHandle;
begin
  BackPool^.Size := 0;
end;

{ TProgressMsg }

constructor TProgressMsg.Create(AProgress: Single);
begin
  Progress := AProgress;
end;

initialization
  MessagePool := TMessagePool.Create;
finalization
  MessagePool.Free;
  MessagePool := nil;
end.
