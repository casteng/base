(*
 @Abstract(Timer unit)
 (C) 2006-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Created: May 16, 2007 <br>
 Unit contains base timer-related types and classes
*)
{$Include GDefines.inc}
unit Timer;

interface

uses
  Logger, Props,
  Basics, BaseStr, BaseTypes, BaseMsg,
  BaseClasses,
  OSUtils;

const
  // Number of internal time units per millisecond
  InternalUnitsInMillisecond = 10;
  // Event ID corresponding to no event
  eIDNone = -1;

type
  // Type for time measured in seconds
  TSecond = TTimeUnit;
  // Type for timer internal time processing. Currently one tenth of millisecond.
  TInternalTimeUnit = Int64;
  // Type of recurring event identifiers
  TEventID = Integer;

  { Methods of this type can be bound to timer events.
    <b>EventID</b> - identifies event (specified in <b>SetEvent()</b> call).
    <b>ErrorDelta</b> - delta time between time the event actually occured and scheduled event time. }
  TTimerDelegate = procedure(EventID: Integer; const ErrorDelta: TTimeUnit) of object;
  { Timer query function type. Methods of this type can be used to query a custom implementation of timer.
    Should return time in @Link(TInternalTimeUnit) units. }
  TTimerQueryFunc = function: TInternalTimeUnit of object;

  { Timer event data structure. <br>
    <b>Time</b>         - time of the event in @Link(TInternalTimeUnit) units <br>
    <b>Delegate</b>     - a function of @Link(TTimerDelegate) which will be called when the event occurs. <b>Nil</b> for no call <br>
    <b>MessageClass</b> - class of message generated when the event occurs. <b>Nil</b> for no message <br>
    <b>EventID</b>      - Some identification number to supply delegate with }
  TTimerEvent = record
    Time: TInternalTimeUnit;
    Delegate: TTimerDelegate; 
    case Boolean of
      False: (MessageClass: CMessage);
      True:  (EventID: Integer)
  end;

  { Timer recurring event data structure. <br>
    <b>Delay</b>        - delay between occurences of the event in @Link(TInternalTimeUnit) units <br>
    <b>Time</b>         - time of next occurence in @Link(TInternalTimeUnit) units <br>
    <b>Delegate</b>     - a function of @Link(TTimerDelegate) which will be called when the event occurs. <b>Nil</b> for no call <br>
    <b>MessageClass</b> - class of message generated when the event occurs. <b>Nil</b> for no message <br>
    <b>EventID</b>      - Some identification number to supply delegate with }
  TRecurringEvent = record
    Delay, Time: TInternalTimeUnit;
    Delegate: TTimerDelegate; 
    case Boolean of
      False: (MessageClass: CMessage);
      True:  (EventID: Integer)
  end;

  // Data structure containing the information necessary for correct measure of intervals
  TTimeMark = record
    Signature: TFileSignature;
    ID: Integer;
    Stamp: TInternalTimeUnit;
  end;

  { @Abstract(Timer service class)
    The class can be used to measure time intervals as well as to bind a message generation or
    a delegate call. <br>
    Default implementation uses <b>GetPerformanceCounter</b> from @Link(OSUtils) if available or less precise <b>GetCurrentMs()</b>
    otherwise. A custom implemetation can be easily connected. <br>
    ToDo: Make the class thread-safe. }
  TTimer = class(TSubsystem)
  private
    MessageHandler: TMessageHandler;

    InsideProcess: Boolean;
    TmpEvents: array of TTimerEvent;
    TotalTmpEvents: Integer;

    PerfCounterMultiplier: TSecond;
    SecondsToInternalMultiplier: Int64;
    InternalToSecondsMultiplier: TSecond;

    // Events sorted by Time
    Events: array of TTimerEvent;
    // Recurring events
    RecEvents: array of TRecurringEvent;

    FTotalRecEvents, FMaxRecEvents, FTotalEvents: Integer;
    TimerBias: TInternalTimeUnit;
    FLastTime: TInternalTimeUnit;
    function SecondsToInternal(Value: TSecond): TInternalTimeUnit;
    function InternalToSeconds(Value: TInternalTimeUnit): TSecond;
    function QueryTimer: TInternalTimeUnit;
    function QueryHiResTimer: TInternalTimeUnit;
    function GetCurrent: TInternalTimeUnit;
    // Adds an event to a temporary array to handle calls to SetEvent() from Process();
    procedure AddTmpEvent(const Time: TInternalTimeUnit; MessageClass: CMessage; Delegate: TTimerDelegate; EventID: Integer);
    // Inserts a new event and returns its index
    function Insert(const EventTime: TInternalTimeUnit): Integer;
    function IsRecEventIndexValid(EventID: Integer): Boolean;
    function GetFreeRecIndex: Integer;
  public
    { This variable limits the time interval on which recurring events will be processed
      to prevent too much computations when a lot of time passed since last Process() call.
      Default value is 3 seconds. }
    MaxInterval: TTimeUnit;
    // Timer query delegate. Can be overwritten to use a custom timer implementation
    TimerQueryFunc: TTimerQueryFunc;
    constructor Create(AMessageHandler: TMessageHandler);

    // Message handler. No messages need to be handled so it's empty.
    procedure HandleMessage(const Msg: TMessage); override;

    procedure AddProperties(const Result: TProperties); override;
    procedure SetProperties(Properties: TProperties); override;

    { Returns time passed from previous call of the method with the same TimeMark variable and ModifyMark set to True.
      First call (with uninitialized TimeMark) returns 0 and performs initialization of the TimeMark. }
    function GetInterval(var TimeMark: TTimeMark; ModifyMark: Boolean): TSecond;
    { Returns True if more then Intervak time passed from previous call of the method with the same TimeMark variable and ModifyMark set to True.
      First call (with uninitialized TimeMark) returns True and performs initialization of the TimeMark. }
    function IsIntervalPassed(var TimeMark: TTimeMark; ModifyMark: Boolean; Interval: TSecond): Boolean;

    // Sets (binds) a message of the specified class to generate in <b>Delay</b> seconds
    procedure SetEvent(const Delay: TSecond; MessageClass: CMessage); overload;
    // Sets (binds) the specified delegate to call in <b>Delay</b> seconds. <b>EventID</b> is an application-specific identification number to supply the delegate with.
    procedure SetEvent(const Delay: TSecond; Delegate: TTimerDelegate; EventID: Integer); overload;
    { Sets (binds) a message of the specified class to generate every <b>Delay</b> seconds starting from the moment of call.
      Returns an ID of the new event. }
    function SetRecurringEvent(const Delay: TSecond; MessageClass: CMessage): Integer; overload;
    { Sets (binds) the specified delegate to call every <b>Delay</b> seconds starting from the moment of call.
      <b>EventID</b> is an application-specific identification number to supply the delegate with. Returns an ID of the new event. }
    function SetRecurringEvent(const Delay: TSecond; Delegate: TTimerDelegate; EventID: Integer): Integer; overload;
    // Removes the specified recurring event
    procedure RemoveRecurringEvent(EventID: Integer);
    // Changes interval of the specified recurring event
    procedure SetRecurringEventInterval(EventID: Integer; const Delay: TSecond);

    { Processes timer events and returns delay to the nearest event.
      Events will be processed and therefore can emerge only within this method. }
    function Process: TSecond;

    // Number of active events not including recurring ones
    property TotalEvents: Integer read FTotalEvents;
    // Number of active recurring events
    property TotalRecurringEvents: Integer read FTotalRecEvents;
  end;

implementation

{ TTimer }

const
  CapacityStep = 8;
  OneOver1000 = 1/1000;
  TimeMarkSignature: TFileSignature = 'TSTP';

function TTimer.InternalToSeconds(Value: TInternalTimeUnit): TSecond;
begin
  Result := Value * InternalToSecondsMultiplier;
end;

function TTimer.SecondsToInternal(Value: TSecond): TInternalTimeUnit;
begin
  Assert(Value * SecondsToInternalMultiplier < MaxInt);
  Result := Round(Value * SecondsToInternalMultiplier);
end;

function TTimer.QueryTimer: TInternalTimeUnit;
begin
  Result := TInternalTimeUnit(OSUtils.GetCurrentMs()) * TInternalTimeUnit(InternalUnitsInMillisecond);
end;

function TTimer.QueryHiResTimer: TInternalTimeUnit;
begin
  Result := Round((OSUtils.GetPerformanceCounter() - TimerBias) * PerfCounterMultiplier);
end;

function TTimer.GetCurrent: TInternalTimeUnit;
begin
  FLastTime := TimerQueryFunc();
  Result := FLastTime;
end;

procedure TTimer.AddTmpEvent(const Time: TInternalTimeUnit; MessageClass: CMessage; Delegate: TTimerDelegate; EventID: Integer);
begin
  if Length(TmpEvents) <= TotalTmpEvents then SetLength(TmpEvents, Length(TmpEvents) + CapacityStep);
  TmpEvents[TotalTmpEvents].Time         := Time;
  TmpEvents[TotalTmpEvents].MessageClass := MessageClass;
  TmpEvents[TotalTmpEvents].Delegate     := Delegate;
  TmpEvents[TotalTmpEvents].EventID      := EventID;
  Inc(TotalTmpEvents);
end;

function TTimer.Insert(const EventTime: TInternalTimeUnit): Integer;
var i: Integer;
begin
  Result := FTotalEvents-1;
  while (Result >= 0) and (Events[Result].Time < EventTime) do Dec(Result);
  if FTotalEvents >= Length(Events) then SetLength(Events, Length(Events) + CapacityStep);
  Inc(Result);
  for i := Result to FTotalEvents-1 do Events[i+1] := Events[i];
  Inc(FTotalEvents);
  Events[Result].Time := EventTime;
end;

constructor TTimer.Create(AMessageHandler: TMessageHandler);
begin
  MessageHandler := AMessageHandler;
//  Assert(Assigned(MessageHandler), 'TTimer.Create: Message handler should be assigned');
  MaxInterval := 3;
  FMaxRecEvents := 0;                      // Current capacity of recurring events array
  OSUtils.ObtainPerformanceFrequency;
  SecondsToInternalMultiplier := 1000 * InternalUnitsInMillisecond;
  if OSUtils.PerformanceFrequency <> 0 then begin
    PerfCounterMultiplier := OSUtils.OneOverPerformanceFrequency * SecondsToInternalMultiplier;
    Log('TTimer.Create: High resolution timer initialization success. Frequency is: ' + BaseStr.IntToStrA(OSUtils.PerformanceFrequency));
    TimerQueryFunc := {$IFDEF OBJFPCEnable}@{$ENDIF}QueryHiResTimer;
    TimerBias := OSUtils.GetPerformanceCounter();
  end else begin
    TimerQueryFunc := {$IFDEF OBJFPCEnable}@{$ENDIF}QueryTimer;
    Log('TTimer.Create: High resolution timer initialization failed. Using low resolution timer', lkWarning);
  end;
  InternalToSecondsMultiplier := 1/SecondsToInternalMultiplier;
  GetCurrent();
end;

procedure TTimer.HandleMessage(const Msg: TMessage);
begin
end;

procedure TTimer.AddProperties(const Result: TProperties);
begin
  inherited;
  Result.Add('Timer\Max interval', vtSingle, [], FloatToStrA(MaxInterval), '');
end;

procedure TTimer.SetProperties(Properties: TProperties);
begin
  inherited;
  if Properties.Valid('Timer\Max interval') then MaxInterval := StrToFloatDefA(Properties['Timer\Max interval'], 3);
end;

procedure TTimer.SetEvent(const Delay: TSecond; MessageClass: CMessage);
var Ind: Integer;
begin
  if InsideProcess then
    AddTmpEvent(TimerQueryFunc() + SecondsToInternal(Delay), MessageClass, nil, 0)
  else begin
    Ind := Insert(TimerQueryFunc() + SecondsToInternal(Delay));
    Events[Ind].MessageClass := MessageClass;
  end;
end;

procedure TTimer.SetEvent(const Delay: TSecond; Delegate: TTimerDelegate; EventID: Integer);
var Ind: Integer;
begin
  if InsideProcess then
    AddTmpEvent(TimerQueryFunc() + SecondsToInternal(Delay), nil, Delegate, EventID)
  else begin
    Ind := Insert(TimerQueryFunc() + SecondsToInternal(Delay));
    Events[Ind].Delegate := Delegate;
    Events[Ind].EventID  := EventID;
  end;
end;

function TTimer.IsRecEventIndexValid(EventID: Integer): Boolean;
begin
  Result := (EventID >= 0) or (EventID < FMaxRecEvents) and
            (Assigned(RecEvents[EventID].Delegate) or (RecEvents[EventID].MessageClass <> nil));
end;

function TTimer.GetFreeRecIndex: Integer;
begin
  Result := 0;
  while (Result < FMaxRecEvents) and IsRecEventIndexValid(Result) do Inc(Result);
  if not (Result < FMaxRecEvents) then begin
    FMaxRecEvents := Result + 1;
    if FMaxRecEvents > Length(RecEvents) then SetLength(RecEvents, Length(RecEvents) + CapacityStep);
  end;
end;

function TTimer.SetRecurringEvent(const Delay: TSecond; MessageClass: CMessage): Integer;
begin
  Result := GetFreeRecIndex();
  RecEvents[Result].Delay        := SecondsToInternal(Delay);
  RecEvents[Result].Time         := GetCurrent() + RecEvents[Result].Delay;
  RecEvents[Result].MessageClass := MessageClass;
  Inc(FTotalRecEvents);
end;

function TTimer.SetRecurringEvent(const Delay: TSecond; Delegate: TTimerDelegate; EventID: Integer): Integer;
begin
  Result := SetRecurringEvent(Delay, CMessage(nil));
  RecEvents[Result].Delegate := Delegate;
  RecEvents[Result].EventID  := EventID;
end;

procedure TTimer.RemoveRecurringEvent(EventID: Integer);
begin
  if not IsRecEventIndexValid(EventID) then begin
    Log(ClassName + '.RemoveRecurringEvent: Invalid event ID', lkError);
    Exit;
  end;
  RecEvents[EventID].Delegate     := nil;
  RecEvents[EventID].MessageClass := nil;
  if EventID = FMaxRecEvents-1 then Dec(FMaxRecEvents);
  Dec(FTotalRecEvents);
end;

procedure TTimer.SetRecurringEventInterval(EventID: Integer; const Delay: TSecond);
begin
  if not IsRecEventIndexValid(EventID) then begin
    Log(ClassName + '.SetRecurringEventInterval: Invalid event ID', lkError);
    Exit;
  end;
  RecEvents[EventID].Delay := SecondsToInternal(Delay);
end;

function TTimer.Process: TSecond;
var i, Ind: Integer; Cur, MaxIntervalInternal, Nearest: TInternalTimeUnit;
begin
  InsideProcess := True;
  Cur := GetCurrent();
  Nearest := Cur;

  // Process disposable events
  i := FTotalEvents-1;
  while (i >= 0) and (Events[i].Time <= Cur) do begin
    if Assigned(Events[i].Delegate) then
      Events[i].Delegate(Events[i].EventID, InternalToSeconds(Cur - Events[i].Time))
    else if
      Assigned(Events[i].MessageClass) then MessageHandler(Events[i].MessageClass.Create);
    Dec(i);
    Dec(FTotalEvents);
  end;

  if FTotalEvents > 0 then Nearest := Events[FTotalEvents-1].Time;

  // Process recurring events
  MaxIntervalInternal := SecondsToInternal(MaxInterval);
  for i := 0 to FMaxRecEvents-1 do if IsRecEventIndexValid(i) then begin
    if Cur - RecEvents[i].Time > MaxIntervalInternal then
      RecEvents[i].Time := Cur - MaxIntervalInternal;
    while RecEvents[i].Time <= Cur do begin
      if Assigned(RecEvents[i].Delegate) then
        RecEvents[i].Delegate(RecEvents[i].EventID, 0)
      else if            
        Assigned(RecEvents[i].MessageClass) then MessageHandler(RecEvents[i].MessageClass.Create);
      RecEvents[i].Time := RecEvents[i].Time + RecEvents[i].Delay;
    end;
    if (Nearest > RecEvents[i].Time) or (Nearest = Cur) then Nearest := RecEvents[i].Time;
  end;

  Result := InternalToSeconds(Nearest - Cur);

  InsideProcess := False;

  // Insert events which was issued during process
  for i := 0 to TotalTmpEvents-1 do begin
    Ind := Insert(TmpEvents[i].Time);
    Events[Ind] := TmpEvents[i];
  end;
  TotalTmpEvents := 0;
end;

function TTimer.GetInterval(var TimeMark: TTimeMark; ModifyMark: Boolean): TSecond;
var RawTime: TInternalTimeUnit;
begin
  RawTime := TimerQueryFunc();
  if TimeMark.Signature = TimeMarkSignature then begin
    Result := InternalToSeconds(RawTime - TimeMark.Stamp);
    if ModifyMark then TimeMark.Stamp := RawTime;
  end else begin
    TimeMark.Signature := TimeMarkSignature;
    Result := 0;
    TimeMark.Stamp := RawTime;
  end;
end;

function TTimer.IsIntervalPassed(var TimeMark: TTimeMark; ModifyMark: Boolean; Interval: TSecond): Boolean;
var Passed: TSecond;
begin
  Passed := GetInterval(TimeMark, ModifyMark);
  Result := (Passed = 0) or (Passed >= Interval);
end;

end.
