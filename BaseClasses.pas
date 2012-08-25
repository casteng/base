(*
 @Abstract(Basic classes unit)
 (C) 2006-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains basic item-related classes
*)
{$Include GDefines.inc}
unit BaseClasses;

interface

uses
  Logger,
  SysUtils,
  BaseTypes, Basics, BaseStr, json, Models, BaseMsg, Props, BaseCompiler;

const
  // Maximum possible item state flags
  MaxStates    = 32;
  // First HiddenStates states will not be visible in editor
  HiddenStates = 4;

  // An item was removed from manager or marked to remove
  isRemoved     = 0;
  // An item was marked to release
  isReleased    = 1;
  // An item hasn't been initialized yet
  isNeedInit    = 2;
  // Visualize item's selection information with a color defined by Globals.PickedBoxColor
  isPicked      = 3;
  // An item should be visualised
  isVisible     = 4;
  // Process method of an item should be called according to its ProcessingClass field
  isProcessing  = 5;
  // Visualize item's debug information (bounding boxes, etc)
  isDrawVolumes = 6;

  {$IFDEF DEBUGMODE}
  // Childs collection capacity increment step
  ChildsCapacityStep = 1;
  // Collections capacity increment step
  CollectionsCapacityStep = 1;
  // Items collection capacity increment step
  ItemsCapacityStep = 1;
  {$ELSE}
  // Childs collection capacity increment step
  ChildsCapacityStep = 8;
  // Collections capacity increment step
  CollectionsCapacityStep = 16;
  // Items collection capacity increment step
  ItemsCapacityStep = 16;
  {$ENDIF}

  // Hierarchy delimiter
  HierarchyDelimiter = '\';
  // A simbol to address upper level of hierarchy in relative item names
  ParentAdressName = '.';

type
  // Main floating point type
  Float = Single;

  // Item flag set
  TItemFlags = TSet32;

  // Item move modes
  TItemMoveMode = (// insert before
                   mmInsertBefore,
                   // insert after
                   mmInsertAfter,
                   // add as first child
                   mmAddChildFirst,
                   // add as last child
                   mmAddChildLast,
                   // move up within the current level
                   mmMoveUp,
                   // move down within the current level
                   mmMoveDown,
                   // move up one level
                   mmMoveLeft,
                   // move down one level
                   mmMoveRight);

  // @Exclude()
  TItem = class;
  // Item class type
  CItem = class of TItem;
  // Used for classes registration
  TClassArray = array of TClass;
  TItemsManager = class;

  // General item method pointer
  TItemDelegate = procedure(Item: TItem; Data: Pointer) of object;

  // @Exclude()
  TObjectLinkFlag = (lfAbsolute);
  // @Exclude()
  TObjectLinkFlags = set of TObjectLinkFlag;
  // @Exclude() Item link property data
  TObjectLink = record
    Flags: TObjectLinkFlags;
    PropName, ObjectName: AnsiString;
    Item: TItem;
    BaseClass: CItem;
  end;

  // Simple items collection
  TItems = array of TItem;

  // Extract condition function result flags
  TExtractConditionItems = (// condition passed
                            ecPassed,
                            // do not follow current hierarchy
                            ecBreakHierarchy,
                            // completely stop traverse
                            ecBreak);
  // Extract condition function result type
  TExtractCondition = set of TExtractConditionItems;
  // Condition function for conditional extraction
  TExtractConditionFunc = function(Item: TItem): TExtractCondition of object;

  // Abstract subsystem
  TSubsystem = class(TBaseSubsystem)
  public
    { This procedure is called (by editor for example) to retrieve a list of item's properties and their values.
      Any TItem descendant class should override this method in order to add its own properties. }
    procedure AddProperties(const Result: TProperties); virtual;
    { This procedure is called (by editor for example) to set values of item's properties.
      Any TItem descendant class should override this method to allow its own properties to be set. }
    procedure SetProperties(Properties: TProperties); virtual; 
  end;

  // @Abstract(Abstract compiler class)
  TAbstractCompiler = class(TSubsystem)
  public
    // Description of last compilation error occured
    LastError: string;
    // Translate the given source to an intermediate or binary form
    function Compile(const Source: AnsiString): TRTData; virtual; abstract;
  end;

  // Scene loading error type
  TSceneLoadError = class(TError)
  end;

  { @Abstract(Base item class)
    Provides hierarchical structure, saving/loading, properties interface and some service functions. }

  TItem = class(TBaseItem)
  private
    FName: AnsiString;
    ItemLinks: array of TObjectLink;
    procedure SetName(const Value: AnsiString);
    procedure DeAlloc;

    procedure ChangeChildIndex(Child: TItem; NewIndex: Integer);
    // Internal link management
    function GetLinkIndex(const AName: AnsiString): Integer;
    function SetLinkedObjectByIndex(Index: Integer; Linked: TItem): Boolean;                   // Called from ResolveLink
    function ObtainLinkedItemNameByIndex(PropIndex: Integer): AnsiString;

    procedure DoOnSceneAddForChilds(Item: TItem; Data: Pointer);
    procedure DoOnSceneRemoveForChilds(Item: TItem; Data: Pointer);
    procedure DoSendInitToChilds(Item: TItem; Data: Pointer);

    function DoAddChild(AItem: TItem): TItem;
    function GetChild(Index: Integer): TItem;
  protected
    {$IFDEF DEBUGMODE}
    { This flag is True when the item's internal state is valid and the item can be used or queried from outside.
      If this flag is False no routines expecting that the item is valid should be called.
      Only asyncronous messages allowed to be sent by an item when its FConsistent is False. }
    FConsistent: Boolean;
    {$ENDIF}
    // Childs collection
    FChilds: TItems;
    // Number of childs
    FTotalChilds: Integer;
    // Set of state flags
    FState: TItemFlags;
    // Parent reference
    FParent: TItem;
    // Manager reference. See @Link(TItemsManager)
    FManager: TItemsManager;
    // Index in parent collection for internal use
    IndexInParent: Integer;
    // Sets a new state flags
    procedure SetState(const Value: TItemFlags); virtual;
    // Sets a new parent value
    procedure SetParent(NewParent: TItem); virtual;
    // Sets Parent to nil without removing from hierarchy, etc
    procedure ClearParent;
    // Sets manager for item and propagates the change to all childs if requested
    procedure SetManager(AManager: TItemsManager; SetChilds: Boolean);

    // Calls the specified delegate for all items in the hierarchy starting from Self. Data can be some custom generic data or nil.
    procedure DoForAllChilds(Delegate: TItemDelegate; Data: Pointer);
    // Calls HandleMessage with the message for all items in the hierarchy starting from Self
    procedure BroadcastMessage(const Msg: TMessage);
    // Sets @Link(mfNotification) flag of the message and calls HandleMessage with the message for all first-level childs
    procedure NotifyChilds(const Msg: TMessage);
    // Sets child and returns AItem if success or nil if index is invalid or impossible to set a child
    function SetChild(Index: Integer; AItem: TItem): TItem; virtual;
    // Inserts a child to the given position in childs collection
    procedure InsertChild(AItem: TItem; Index: Integer);
    // Removes a child with the specified index
    procedure RemoveChildByIndex(Index: Integer); virtual;
      // Link management
    { Adds an item link property with the given name and base class to Properties.
      Use this method in order to add a property which points to another item }
    procedure AddItemLink(Properties: TProperties; const PropName: AnsiString; PropOptions: TPOptions; const BaseClass: AnsiString);
    // Performs initialization of internal data structures. Do not call manually
    procedure BuildItemLinks;
    // Resolves (with class checking) an object link and returns <b>True</b> if a NEW linked item was resolved.
    function ResolveLink(const PropName: AnsiString; out Linked: TItem): Boolean;
    { Sets Linked as resolved linked object for a link property with the given name.
      Returns <b>True</b> if Linked passes type checking }
    function SetLinkedObject(const PropName: AnsiString; Linked: TItem): Boolean;
    // Should be called from @Link(SetProperties) to handle item link property setting
    function SetLinkProperty(const AName, Value: AnsiString): Boolean;
    { Called from default @Link(OnSceneLoaded) event handler.
      Override to resolve all link which needed to be resolved right after scene load }
    procedure ResolveLinks; virtual;
  public
    // Regular constructor
    constructor Create(AManager: TItemsManager); virtual;
    // Constructor used to construct complex objects such as windows with a header area and a client area
    constructor Construct(AManager: TItemsManager); virtual;
    // Copies all data and properties from ASource to the item
    procedure Assign(ASource: TItem); virtual;
    // Returns class reference
    class function GetClass: CItem;
    // Items of abstract classes can not be created in editor
    class function IsAbstract: Boolean; virtual;

    { Returns full size in memory of an item in bytes.
      Descendants should override this method if they have dynamic fields which sizes are not included in TObject.InstanceSize. }
    function GetItemSize(CountChilds: Boolean): Integer; virtual;

    // Sends the specified message according to the specified destination. 
    procedure SendMessage(const Msg: TMessage; Recipient: TItem; Destination: TMessageFlags);
    // Main message handler
    procedure HandleMessage(const Msg: TMessage); override;

      // Events
    // Occurs after object creation and initialization of Root variable
    procedure OnInit; virtual;
    // Occurs when a scene is completely loaded
    procedure OnSceneLoaded; virtual;
    // Occurs when the item added to a scene (usally after loading)
    procedure OnSceneAdd; virtual;
    // Occurs when the item being remove from scene
    procedure OnSceneRemove; virtual;

      // Properties system
    // Do not use this procedure directly. Call @Link(AddProperties) instead
    procedure GetProperties(const Result: TProperties);
    { This procedure is called (by editor for example) to retrieve a list of item's properties and their values.
      Any TItem descendant class should override this method in order to add its own properties. }
    procedure AddProperties(const Result: TProperties); virtual;
    { This procedure is called (by editor for example) to set values of item's properties.
      Any TItem descendant class should override this method to allow its own properties to be set. }
    procedure SetProperties(Properties: TProperties); virtual;
    // Calls @Link(AddProperties) to return a single property identified by AName
    function GetProperty(const AName: AnsiString): AnsiString;
    // Calls @Link(SetProperties) to set a single property identified by AName
    procedure SetProperty(const AName, AValue: AnsiString);

    // Returns name of an item which linked by a property with the given name
    procedure ObtainLinkedItemName(const PropName: AnsiString; out Result: AnsiString);

    { Creates and returns a clone of the item with all properties having the same value as in source.
      Descendants should override this method in order to handle specific fields if any. }
    function Clone: TItem; virtual;
    // Saving/Loading
    // Saves an item to a stream and returns <b>True</b> if success
    function Save(Stream: TStream): Boolean; virtual;
    // Loads an item from a stream and returns <b>True</b> if success
    function Load(Stream: TStream): Boolean; virtual;

        // Hierarchy routines
      //  Childs management
    { Adds and returns a child. Sends a @Link(TAddToSceneMsg) message to all items in scene and to manager (see @Link(TItemsManager) ) }
    function AddChild(AItem: TItem): TItem;
    { Removes the given child item. Sends a @Link(TRemoveFromSceneMsg) message to all items in scene and to manager (see @Link(TItemsManager) ) }
    procedure RemoveChild(AItem: TItem); virtual;
    // Returns all childs of the item
    function GetChilds: TItems;
    // Returns item's parent, skipping the dummy ones
    function GetNonDummyParent: TItem;
    { Finds child next to current assuming childs of dummy childs as own. Pass @nil as current to find the first child.
      If next child found, the function returns <b>True</b> and with Current set to that child.
      Otherwise returns <b>False</b> with Current set to @nil. }
    function FindNextChildInclDummy(var Current: TItem): Boolean;

      //  Node search
    // Returns item's full name in a filesystem-like format: <RootItemName>\<Parent>\<Name>
    function GetFullName: AnsiString;
    // Finds a child item by its name. Name is case-sensitive. If SearchChilds is False only first-level childs can be found.
    function GetChildByName(const AName: AnsiString; SearchChilds: Boolean): TItem;
    // Finds an item by the given path. The function supports relative paths as well as absolute ones. Path is case-sensitive.
    function GetItemByPath(const APath: AnsiString): TItem;
    // Finds a child next to CurrentChild
    function GetNextChild(CurrentChild: TItem): TItem;
    // Returns full path of an item specified by its full name relative to the item
    function GetRelativeItemName(const AFullName: AnsiString): AnsiString;

    // Moves a child in hierarchy as specified by Mode (see @Link(TItemMoveMode))
    procedure MoveChild(Child, Target: TItem; Mode: TItemMoveMode);
    // Returns <b>True</b> if the item is a child of any level of AParent. Returns <b>False</b> if Self = AParent.
    function IsChildOf(AParent: TItem): Boolean;
    // Returns <b>True</b> if the item is a part of the specified scene or any scene if AManager is nil
    function IsInScene(AManager: TItemsManager): Boolean;

      // Clean up and destruction
    { Marks item as removed from hierarchy and (if DoNotRelease is <b>False</b>) as released.
      These marks will be handled by @Link(CollectGarbage). }
    procedure MarkAsRemoved(DoNotRelease: Boolean);
    // Frees all childs
    procedure FreeChilds; virtual;

    // Regular destructor. Frees item itself, all it's data and all childs.
    destructor Destroy; override;

    // Manager reference. See @Link(TItemsManager)
    property Manager: TItemsManager read FManager;
    // Specifies number of childs of an item
    property TotalChilds: Integer read FTotalChilds;
    // Item's childs collection
    property Childs[Index: Integer]: TItem read GetChild;
    { Item's parent. You can set this property to move the item within items hierarchy.
      Setting Parent to @nil will remove the item from the hierarchy. }
    property Parent: TItem read FParent write SetParent;
    { A set of state flags.
      See @Link(isRemoved), @Link(isReleased), @Link(isNeedInit), @Link(isPicked), @Link(isVisible), @Link(isProcessing), @Link(isDrawVolumes). }
    property State: TItemFlags read FState write SetState;
    // Item name. Used to reference items by name in a filesystem-like way: RootItemName\Parent\Name
    property Name: AnsiString read FName write SetName;
  end;

  { @Abstract(Used to group items within a hierarchy)
    Forwards all notification messages to childs }
  TDummyItem = class(TItem)
    // Checks if the message is a notification and forwards it to childs
    procedure HandleMessage(const Msg: TMessage); override;
  end;
    

  { A hierarchy root item should be of this (or a descendant) class.
    @Abstract(Provides some item extraction methods) }
  TRootItem = class(TItem)
  public
    constructor Create(AManager: TItemsManager); override;
    // Returns an item by exact name with full path. E.g. "\Root\Landscape\Tree19".
    function GetItemByFullName(const AName: AnsiString): TItem;
    { Traverses through the items hierarchy and adds all items passing Condition to Items.
      Returns number of items in Items. }
    function Extract(Condition: TExtractConditionFunc; out Items: TItems): Integer;
    { Traverses through the items hierarchy and adds to Items all items which State contains all flags in Mask.
      If Hierarchical is <b>True</b> childs of non-matching items are not considered. Returns number of items in Items. }
    function ExtractByMask(Mask: TItemFlags; Hierarchical: Boolean; out Items: TItems): Integer;
    { Traverses through the items hierarchy and adds all items of the given class or its descendants to Items.
      Returns number of items in Items. }
    function ExtractByClass(AClass: CItem; out Items: TItems): Integer;
    { Traverses through the items hierarchy and adds all items of the given class or its descendants and with State containing all
      flags in Mask to Items. Childs of items with non-matching state are not considered.
      Returns number of items in Items. }
    function ExtractByMaskClass(Mask: TItemFlags; AClass: CItem; out Items: TItems): Integer;

    procedure HandleMessage(const Msg: TMessage); override;
  end;

  // @Abstract(Base class of all items which periodically updates their state)
  TBaseProcessing = class(TItem)
  private
    // Total time processed with the @Link(Process) method since last call of ResetProcessedTime() in seconds
    FTimeProcessed: TTimeUnit;
  public
    // Processing class specifies how an item should be processed. See @Link(TProcessingClass)
    ProcessingClass: Integer;
    // Resets TimeProcessed to zero
    procedure ResetProcessedTime;
    // Pauses processing of the item
    procedure Pause; {$I inline.inc}
    // Resumes processing of the item
    procedure Resume; {$I inline.inc}

    { This method will be called when an item is to be processed (updated).
      Actual process schedule depends on values if processing class (see @Link(TItemsManager)) to which points ProcessingClass field. }
    procedure Process(const DeltaT: Float); virtual;
    procedure AddProperties(const Result: TProperties); override;
    procedure SetProperties(Properties: TProperties); override;

    // Total time processed with the @Link(Process) method
    property TimeProcessed: TTimeUnit read FTimeProcessed;
  end;

{  IResource = interface
    function GetData: Pointer;
    function GetTotalElements: Integer;
    property TotalElements: Integer read GetTotalElements;
    property Data: Pointer read GetData;
  end;}

  // Item used for time syncronization
  TSyncItem = class(TBaseProcessing)
  protected
    procedure SetState(const Value: TItemFlags); override;
  public
    // Sends TSyncTimeMsg to all sibling items and their child items
    procedure Syncronize; {$I inline.inc}
  end;

  // Items manager state
  TIMState = (// the manager is currently loading items
              imsLoading,
              // the manager is currently shutting down
              imsShuttingDown);

  // Item processing flags
  TProcessingFlag = (// force processing even when pause mode is on
                     pfIgnorePause,
                     // process as frequent as possible ignoring Interval
                     pfDeltaTimeBased);
  // Set of item processing flags                   
  TProcessingFlags = set of TProcessingFlag;


  { Processing options for processing classes (see @Link(TItemsManager)).
    Interval - process interval in seconds.
    Flags - see @Link(TProcessingFlag)
    TimerEventID - an ID of a corresponding timer event. -1 if none }
  TProcessingClass = record
    Interval: Float;
    Flags: TProcessingFlags;
    TimerEventID: Integer;
  end;

  { @Abstract(Contains and manages a hierarchy of items starting with Root)
    Contains all registered item classes. }
  TItemsManager = class
  private
    FItemClasses: array of CItem;
    FTotalItemClasses: Integer;
    function GetProcClassesEnum: AnsiString;
    // Sets a new root item
    procedure SetRoot(const Value: TRootItem);
    function GetItemClass(Index: Integer): CItem;
  protected
    // Root of a hierarchy
    FRoot: TRootItem;
    // Names of all possible state flags
    StateNames: array of AnsiString;
    // Current manager state
    FState: set of TIMState;
    // Should be <b>True</b> if world-editing capabilities are required
    FEditorMode: Boolean;
    // Item processing classes (see @Link(TProcessingClass))
    ProcessingClasses: array of TProcessingClass;
    // Asynchronous messages container
    AsyncMessages: TMessageSubsystem;
    // Returns number of processing classes
    function GetTotalProcessingClasses: Integer;
    // Adds a message to the asyncronous queue to be handled later in @Link(ProcessAsyncMessages)
    procedure SendAsyncMessage(const Msg: TMessage; Recipient: TItem); virtual;
    // Handles items market to remove and release
    procedure CollectGarbage; virtual;
    // This event occurs right before destruction of the manager
    procedure OnDestroy; virtual;
  public
    // Scripting subsystem
    Compiler: TAbstractCompiler;

    constructor Create; virtual;
    destructor Destroy; override;

    // Handles all asyncronous messages
    procedure ProcessAsyncMessages;
    // Sends the specified message according to the specified destination. Can be called as class function with mfRecipient and mfChilds destinations.
    procedure SendMessage(const Msg: TMessage; Recipient: TItem; Destination: TMessageFlags);
    // Default core message handler
    procedure HandleMessage(const Msg: TMessage); virtual;

    // Returns <b>True</b> if a scene is currently loading
    function IsSceneLoading: Boolean;
    // Returns <b>True</b> if manager is shutting down
    function IsShuttingdown: Boolean;

    // Registers an item state flag
    function RegisterState(const AName: AnsiString): Boolean;
    // Registers an item class. Only items of registered classes can be saved/loaded or be linked to via item link property.
    procedure RegisterItemClass(NewClass: CItem);
    // Registers an array of item classes. Only items of registered classes can be saved/loaded or be linked to via item link property.
    procedure RegisterItemClasses(NewClasses: array of TClass); 
    // Returns an item class by its name or @nil if not found
    function FindItemClass(const AName: AnsiString): CItem; virtual;

    { Changes class of an item to <b>NewClass</b>. <br>
      <b>All direct references to the item except via object linking mechanism become invalid.</b> }
    function ChangeClass(Item: TItem; NewClass: CItem): TItem;

    // Removes an item from the manager
    procedure RemoveItem(Item: TItem);

    { Loads an item from a stream specified and adds it to AParent as a child.
      Returns the loaded item. }
    function LoadItem(Stream: TStream; AParent: TItem): TItem;
    // Clears the current scene and loads a new scene from a stream
    function LoadScene(Stream: TStream): Boolean;
    // Saves the current scene to a stream
    function SaveScene(Stream: TStream): Boolean;

    // Clears the current scene
    procedure ClearItems; virtual;

    // Should be set to <b>True</b> if world-editing capabilities are required
    property EditorMode: Boolean read FEditorMode;

    // Number of processing classes
    property TotalProcessingClasses: Integer read GetTotalProcessingClasses;

    // Number of registered item classes
    property TotalItemClasses: Integer read FTotalItemClasses;
    // Registered item classes
    property ItemClasses[Index: Integer]: CItem read GetItemClass;

    // Root of a hierarchy
    property Root: TRootItem read FRoot write SetRoot;
  end;

  // Modifies or creates (if Item is nil) item with subitems from a JSON data string. Returns the item.
  function SetupFromJSON(Item: TItem; const aSrc: TJSONString; Manager: TItemsManager): TItem;

  // Retuns a list of the specified classes
  function GetClassList(AClasses: array of TClass): TClassArray;
  // Merges the two given class lists
  procedure MergeClassLists(var BaseList: TClassArray; AddOnList: array of TClass);

type
  TClassRec = record
    ItemClass: TClass;
    ModuleName: TShortName;
  end;
  TClassesList = class
  private
    TotalClasses: Integer;
    FClasses: array of TClassRec;
    function GetClasses: TClassArray;
    function GetClassesByModule(const AModuleName: TShortName): TClassArray;
  public
    destructor Destroy; override;
    procedure Add(const AModuleName: TShortName; AClass: TClass); overload;
    procedure Add(const AModuleName: TShortName; AClasses: array of TClass); overload;
    function ClassExists(AClass: TClass): Boolean;
    function FindClass(AClass: TClass): TClassRec;
    function FindClassByName(const AModuleName, AClassName: TShortName): TClassRec;

    property Classes: TClassArray read GetClasses;
    property ClassesByModule[const AModuleName: TShortName]: TClassArray read GetClassesByModule;
  end;

var
  GlobalClassList: TClassesList;

implementation

uses ItemMsg;

function GetClassList(AClasses: array of TClass): TClassArray;
begin
  Result := nil;
  MergeClassLists(Result, AClasses);
end;

procedure MergeClassLists(var BaseList: TClassArray; AddOnList: array of TClass);
var i, OldLen: Integer;
begin
  OldLen := Length(BaseList);
  SetLength(BaseList, OldLen + Length(AddOnList));
  for i := 0 to High(AddOnList) do BaseList[OldLen + i] := AddOnList[i];
end;

{ TItemsManager }

procedure TItemsManager.OnDestroy;
begin
  ClearItems;
  StateNames := nil;
  FreeAndNil(AsyncMessages);
end;

constructor TItemsManager.Create;
begin
  AsyncMessages := TMessageSubsystem.Create;

  RegisterItemClass(TItem);
  RegisterItemClass(TRootItem);
  RegisterItemClass(TDummyItem);
  RegisterItemClass(TSyncItem);

  RegisterState('Removed');
  RegisterState('Released');
  RegisterState('Uninitialized');
  RegisterState('Picked');
  RegisterState('Render');
  RegisterState('Process');
  RegisterState('Draw bounds');
end;

destructor TItemsManager.Destroy;
begin
  OnDestroy;
  inherited;
end;

function TItemsManager.GetTotalProcessingClasses: Integer;
begin
  Result := Length(ProcessingClasses);
end;

procedure TItemsManager.SendAsyncMessage(const Msg: TMessage; Recipient: TItem);
begin
  Assert((Recipient = nil) or not (mfRecipient in Msg.Flags), 'TItemsManager.SendAsyncMessage: Invalid recipient');
  Assert([mfRecipient, mfChilds, mfBroadcast, mfCore] * Msg.Flags <> [], 'TItemsManager.SendAsyncMessage: Invalid message flags');;

  if ([mfRecipient, mfChilds] * Msg.Flags <> []) then
    AsyncMessages.Add(TMessageEnvelope.Create(Recipient, Msg)) else
      AsyncMessages.Add(Msg);
end;

procedure TItemsManager.SendMessage(const Msg: TMessage; Recipient: TItem; Destination: TMessageFlags);
begin
  Assert(Assigned(Msg));
  Assert(Destination <> [], 'Invalid destination');
//  Assert((Destination <> []) and
//         (not (mdRecipient in Destination) or not (mdChilds    in Destination)), 'Invalid destination');

  if ([mfRecipient, mfChilds] * Destination <> []) then
    Assert(Assigned(Recipient))
  else
    Recipient := nil;

  if (mfBroadcast in Destination) and not Assigned(Recipient) then begin
    if Assigned(Root) then Recipient := Root else Exclude(Destination, mfBroadcast);
  end;

//  Msg.Flags := Destination;
{
  if mdRecipient in Destination then Msg.Flags := Msg.Flags + [mfRecipient];
  if mdBroadcast in Destination then Msg.Flags := Msg.Flags + [mfBroadcast];
  if mdCore      in Destination then Msg.Flags := Msg.Flags + [mfCore];
  if mdChilds    in Destination then Msg.Flags := Msg.Flags + [mfNotification];}

  if mfAsync in Destination then SendAsyncMessage(Msg, Recipient) else begin
    if mfCore      in Destination then begin
      Msg.Flags := [mfCore];
      HandleMessage(Msg);
    end;
    if mfRecipient in Destination then begin
      Msg.Flags := [mfRecipient];
      Recipient.HandleMessage(Msg);
    end;
    if mfChilds    in Destination then begin
      Msg.Flags := [mfChilds];
      Recipient.NotifyChilds(Msg);
    end;
    if mfBroadcast in Destination then begin
      Msg.Flags := [mfBroadcast];
      Recipient.BroadcastMessage(Msg);
    end;
  end;
end;

procedure TItemsManager.HandleMessage(const Msg: TMessage);
begin
  {$IFDEF DEBUGMODE} 
  Assert(mfCore in Msg.Flags);
  {$ENDIF}
//  if (Msg.ClassType = TOperationMsg) and not (ofHandled in TOperationMsg(Msg).Operation.Flags) then TOperationMsg(Msg).Operation.Free;
end;

procedure TItemsManager.ProcessAsyncMessages;
var Msg: TMessage; Recipient: TItem;
begin
  AsyncMessages.BeginHandle;
  while AsyncMessages.ExtractMessage(Msg) do begin
    if (Msg is TMessageEnvelope) then begin
      Recipient := TMessageEnvelope(Msg).Recipient;
      Msg       := TMessageEnvelope(Msg).Message;
    end else Recipient := nil;
    SendMessage(Msg, Recipient, Msg.Flags - [mfAsync]);
  end;
  AsyncMessages.EndHandle;
end;

function TItemsManager.IsSceneLoading: Boolean;
begin
  Result := imsLoading in FState;
end;

function TItemsManager.IsShuttingdown: Boolean;
begin
  Result := imsShuttingDown in FState;
end;

function TItemsManager.RegisterState(const AName: AnsiString): Boolean;
begin
  Result := False;
  if Length(StateNames) >= MaxStates then begin
    Log(Format(ClassName + '.RegisterState: Only %D states allowed', [MaxStates]), lkError);
    Exit;
  end;
  SetLength(StateNames, Length(StateNames)+1);
  StateNames[High(StateNames)] := AName;
  Result := True;
end;

procedure TItemsManager.RegisterItemClass(NewClass: CItem);
begin
  if FindItemClass(AnsiString(NewClass.ClassName)) <> nil then begin
    Log(ClassName + '.RegisterItemClass: Class "' + NewClass.ClassName + '" already registered', lkWarning);
    Exit;
  end;
  SetLength(FItemClasses, TotalItemClasses+1);
  FItemClasses[TotalItemClasses] := NewClass;
  Inc(FTotalItemClasses);
end;

procedure TItemsManager.RegisterItemClasses(NewClasses: array of TClass);
var i: Integer;
begin
  for i := 0 to High(NewClasses) do if NewClasses[i].InheritsFrom(TItem) then RegisterItemClass(CItem(NewClasses[i]));
end;

function TItemsManager.FindItemClass(const AName: AnsiString): CItem;
var i: Integer;
begin
  Result := nil;
  i := TotalItemClasses-1;
  while (i >= 0) and (ItemClasses[i].ClassName <> AName) do Dec(i);
  if i >= 0 then Result := ItemClasses[i];
end;

function TItemsManager.ChangeClass(Item: TItem; NewClass: CItem): TItem;
var i: Integer; Props: TProperties;
begin
  Result := nil;

  if Item = nil then begin
     Log(ClassName + '.ChangeClass: Item is undefined', lkError);
    Exit;
  end;

  Result := NewClass.Construct(Item.FManager);
// Copy childs
  Result.FTotalChilds := Item.TotalChilds;
  SetLength(Result.FChilds, Length(Item.FChilds));
  for i := 0 to High(Item.FChilds) do begin
    Result.FChilds[i] := Item.FChilds[i];
    if Result.FChilds[i] <> nil then Result.FChilds[i].FParent := Result;
  end;
// Copy state and parent
  Result.FState := Item.FState;
  Result.FParent := Item.FParent;
  Result.IndexInParent := Item.IndexInParent;
// Copy object links data
  SetLength(Result.ItemLinks, Length(Item.ItemLinks));
  for i := 0 to High(Item.ItemLinks) do Result.ItemLinks[i] := Item.ItemLinks[i];
// Replace the item in parent's collection
  if Result = FRoot then begin
    if not (Result is TRootItem) then begin
       Log(ClassName + '.ChangeClass: Root item'' class should be TRootItem or one of its descendants', lkError);
      TObject(Result).Destroy;                                          // There is no need to call FreeChilds
      Result := nil;
      Exit;
    end;
    FRoot := Result as TRootItem;
  end else Item.Parent.FChilds[Item.IndexInParent] := Result;

  if isNeedInit in Result.FState then SendMessage(ItemMsg.TInitMsg.Create, Result, [mfRecipient]);

  Props := TProperties.Create;
  Item.GetProperties(Props);
  Result.SetProperties(Props);
  FreeAndNil(Props);

  SendMessage(ItemMsg.TReplaceMsg.Create(Item, Result), Item, [mfRecipient, mfBroadcast, mfCore]);

  Item.DeAlloc;
end;

procedure TItemsManager.RemoveItem(Item: TItem);
begin
  if Item = nil then Exit;
  if Item.Parent <> nil then Item.Parent.RemoveChild(Item);
  if Item = FRoot then FRoot := nil;
end;

procedure TItemsManager.ClearItems;
begin
  SendMessage(TSceneClearMsg.Create, nil, [mfCore]);
  Include(FState, imsShuttingDown);
  if FRoot <> nil then begin
    FRoot.OnSceneRemove;
    FRoot.FreeChilds;
    FRoot.Free;
    FRoot := nil;
  end;
  Exclude(FState, imsShuttingDown);
end;

function TItemsManager.LoadItem(Stream: TStream; AParent: TItem): TItem;
var s: AnsiString; ItemClass: CItem;
begin
  Result := nil;
  if not LoadString(Stream, s) then Exit;
//  s := 'TItem';
//  if s = 'TCBitmapFont' then s := 'TBitmapFont';
  if s = 'TTextureResource' then s := 'TImageResource';

  ItemClass := FindItemClass(s);
  if ItemClass = nil then begin
    Log(ClassName + '.LoadItem: Unknown item class "' + s + '". Substitued by TItem', lkError);
    ItemClass := TItem;
  end;

  Result := ItemClass.Create(Self);

  if Assigned(AParent) and ((FRoot = nil) or (AParent.FManager <> Self)) then begin
    Log(Format('%S.%S: The specified parent "%S" not found or invalid - discarding', [ClassName, 'LoadItem', AParent.Name]), lkError);
    AParent := nil;
  end;
  if (AParent = nil) then begin
    if Result.InheritsFrom(TRootItem) then begin
      if Assigned(FRoot) then Log(ClassName + '.LoadItem: replacing existing root item', lkWarning);
      FRoot := Result as TRootItem;
    end else begin
      Log(Format('%S.%S: A descendant of TRootItem expected but an item of class "%S" got. Using existing root item.', [ClassName, 'LoadItem', Result.ClassName]), lkWarning);
      if Assigned(FRoot) then
        AParent := FRoot else begin
          ErrorHandler(TSceneLoadError.Create(Format('%S.%S: No root item.', [ClassName, 'LoadItem'])));
          FreeAndNil(Result);
          Exit;
        end;
    end;
  end else if Result.InheritsFrom(TRootItem) then begin
    Log(ClassName + '.LoadItem: Additional root item found', lkNotice);
  end;

  if AParent <> nil then AParent.DoAddChild(Result);
  
  if isNeedInit in Result.FState then SendMessage(ItemMsg.TInitMsg.Create, Result, [mfRecipient]);

  if Result.Load(Stream) then
    SendMessage(ItemMsg.TAddToSceneMsg.Create(Result), Result, [mfCore, mfRecipient])
  else
    Result := nil;
//  if not Result.Load(Stream) then Result := nil;
end;

function TItemsManager.LoadScene(Stream: TStream): Boolean;
var Item: TItem;
begin
  Result := False;

  ClearItems;

  Include(FState, imsLoading);

  Item := LoadItem(Stream, nil);

  Exclude(FState, imsLoading);

  if Item is TRootItem then begin
    FRoot := Item as TRootItem;

    Log(ClassName + '.LoadScene: Scene load successful', lkNotice);

    SendMessage(ItemMsg.TSceneLoadedMsg.Create, nil, [mfBroadcast, mfCore]);
    Result := True;
  end;
end;

function TItemsManager.SaveScene(Stream: TStream): Boolean;
begin
  Result := FRoot.Save(Stream);

  if Result then Log(ClassName + '.SaveScene: Scene save successful', lkNotice);

end;

procedure TItemsManager.CollectGarbage;
var i: Integer; Items: TItems;
begin
  for i := 0 to FRoot.ExtractByMask([isRemoved], False, Items)-1 do begin
    Items[i].Parent.RemoveChild(Items[i]);
    if isReleased in Items[i].State then begin
      Items[i].Free;
    end;
  end;
  Items := nil;
end;

procedure TItemsManager.SetRoot(const Value: TRootItem);
begin
  FRoot := Value;
  FRoot.FManager := Self;
end;

function TItemsManager.GetItemClass(Index: Integer): CItem;
begin
  Result := FItemClasses[Index];
end;

function TItemsManager.GetProcClassesEnum: AnsiString;
var i: Integer;
begin
  Result := 'None';
//  if (Parent <> nil) or (Root <> Self) then Exit;
  for i := 0 to TotalProcessingClasses-1 do begin
    Result := Result + '\&' + IntToStrA(i) + ':';
    if pfDeltaTimeBased in ProcessingClasses[i].Flags then
      Result := Result + ' Delta time-based'
    else
      Result := Result + ' Every ' + IntToStrA(Round(ProcessingClasses[i].Interval * 1000)) + ' ms';
    if pfIgnorePause in ProcessingClasses[i].Flags then Result := Result + ', ignore pause';
  end;
end;

{ TItem }

type
  TLinkParam = record
    CachedProps: TProperties;                // Cached properties for object links management
    LastCachedPropsClass: TClass;            // Item class of which properties last cached in TempProps
    CurLinkIndex: Integer;                   // Index of current object link
  end;

threadvar
  LinksParams: array of TLinkParam;
  CurrentLinkParam: Integer;

procedure NewLinksParameters;
begin
  SetLength(LinksParams, Length(LinksParams)+1);
  LinksParams[High(LinksParams)].CachedProps := TProperties.Create;
end;

procedure TItem.SetName(const Value: AnsiString);
var OldName: ShortString;
begin
  if FName = Value then Exit;
  OldName := GetFullName();
  FName := Value;
  {$IFDEF DEBUGMODE} if FConsistent then {$ENDIF}
  if Assigned(FManager) then SendMessage(TItemNameModifiedMsg.Create(Self, OldName), nil, [mfCore]);
end;

/// Changes childs's index to NewIndex, preserving the order of other childs
/// NewIndex clamps if it is outside childs collection
procedure TItem.ChangeChildIndex(Child: TItem; NewIndex: Integer);
var i: Integer;
begin
  if not Assigned(FChilds) then Exit;
  NewIndex := MaxI(0, MinI(TotalChilds-1, NewIndex));
  if NewIndex = Child.IndexInParent then Exit;
//  0  1  2  3  4  5  6  7
//  0  1  4  2  3  5  6  7
//  0  1  2  3  5  6  4  7

  if NewIndex < Child.IndexInParent then begin
    for i := Child.IndexInParent-1 downto NewIndex do begin
      FChilds[i+1] := FChilds[i];
      FChilds[i+1].IndexInParent := i+1;
    end;
  end else begin
    for i := Child.IndexInParent to NewIndex-1 do begin
      FChilds[i] := FChilds[i+1];
      FChilds[i].IndexInParent := i;
    end;
  end;

  FChilds[NewIndex]   := Child;
  Child.IndexInParent := NewIndex;
end;

function TItem.GetLinkIndex(const AName: AnsiString): Integer;
// Returns an index in ItemLinks array by property's name
begin
  for Result := 0 to High(ItemLinks) do
    if ItemLinks[Result].PropName = AName then Exit;
  Result := -1;
end;

function TItem.SetLinkedObjectByIndex(Index: Integer; Linked: TItem): Boolean;
// Sets Linked as resolved linked object for LinkedObjects[Index]. Returns true if Linked passes type checking
begin
  Result := False;
  if (Linked is ItemLinks[Index].BaseClass) then begin
    ItemLinks[Index].Item := Linked;
    ItemLinks[Index].ObjectName := '';                                             // Prevent unnecessary link resolution
    Result := True;
  end else begin

    Log(Format('%S("%S").%S: Item "%S" not found or not an instance of %S',
            [ClassName, Name, 'SetLinkedObjectByIndex', ItemLinks[Index].ObjectName, ItemLinks[Index].BaseClass.ClassName]) , lkError);

  end;
end;

function TItem.ObtainLinkedItemNameByIndex(PropIndex: Integer): AnsiString;
begin
  if ItemLinks[PropIndex].Item is ItemLinks[PropIndex].BaseClass then begin
    if lfAbsolute in ItemLinks[PropIndex].Flags then
      Result := ItemLinks[PropIndex].Item.GetFullName
    else
      Result := GetRelativeItemName(ItemLinks[PropIndex].Item.GetFullName);
  end else Result := ItemLinks[PropIndex].ObjectName;
end;

procedure TItem.DoOnSceneAddForChilds(Item: TItem; Data: Pointer);
begin
//  if not (Item.Parent is TDummyItem) then
    SendMessage(ItemMsg.TAddToSceneMsg.Create(Item), Item, [mfCore, mfRecipient]);
end;

procedure TItem.DoOnSceneRemoveForChilds(Item: TItem; Data: Pointer);
begin
//  if not (Item.Parent is TDummyItem) then
    SendMessage(ItemMsg.TRemoveFromSceneMsg.Create(Item), Item, [mfRecipient, mfCore]);
end;

procedure TItem.DoSendInitToChilds(Item: TItem; Data: Pointer);
begin
//  if not (Item.Parent is TDummyItem) then
    SendMessage(ItemMsg.TInitMsg.Create, Item, [mfRecipient]);
end;

function TItem.DoAddChild(AItem: TItem): TItem;
begin
  Inc(FTotalChilds);
  if Length(FChilds) < TotalChilds then
    SetLength(FChilds, Length(FChilds) + ChildsCapacityStep);

  Result := SetChild(TotalChilds-1, AItem);

  if Result = nil then begin
    Dec(FTotalChilds);
     Log(ClassName + '.DoAddChild: Error adding a child', lkError);
  end;
end;

procedure TItem.SetState(const Value: TItemFlags);
begin
//  Root.IncludeItem(Self, Value - FTraverseMask);
//  Root.ExcludeItem(Self, FTraverseMask - Value);
  FState  := Value;
//  if OldMask <> Value then Self.BroadcastMessage(TParentStateChangeMsg.Create(OldMask, Value));
end;

procedure TItem.SetParent(NewParent: TItem);
begin
  Assert(NewParent <> Self, 'Can''t attach an item to itself');
  if FParent = NewParent then Exit;
  if Assigned(FParent)   then FParent.RemoveChild(Self);
  if Assigned(NewParent) then NewParent.AddChild(Self);
  FParent := NewParent;
end;

procedure TItem.ClearParent;
begin
  FParent := nil;
end;

procedure TItem.SetManager(AManager: TItemsManager; SetChilds: Boolean);
var i: Integer;
begin
  FManager := AManager;
  if SetChilds then
    for i := 0 to TotalChilds-1 do
      Childs[i].SetManager(AManager, True);
end;

procedure TItem.AddItemLink(Properties: TProperties; const PropName: AnsiString; PropOptions: TPOptions; const BaseClass: AnsiString);
var Index: Integer; Value: AnsiString;
begin
  Index := GetLinkIndex(PropName);
  if Index = -1 then begin
    SetLength(ItemLinks, Length(ItemLinks)+1);
    Index := High(ItemLinks);
    ItemLinks[Index].Flags      := [];
    ItemLinks[Index].ObjectName := '';
    ItemLinks[Index].Item       := nil;
    ItemLinks[Index].PropName := PropName;
  end;

  if FManager = nil then
    ItemLinks[Index].BaseClass := nil else
      ItemLinks[Index].BaseClass := FManager.FindItemClass(BaseClass);

  if ItemLinks[Index].BaseClass = nil then begin
    Log(ClassName + '.AddItemLink: Linked object base class "' + BaseClass + '" not found', lkError);
    ItemLinks[Index].BaseClass := TItem;
  end;

  Value := ObtainLinkedItemNameByIndex(Index);

  if Properties <> nil then Properties.Add(PropName, vtObjectLink, PropOptions, Value, BaseClass);
end;

procedure TItem.BuildItemLinks;
begin
  AddProperties(nil);
end;

function TItem.ResolveLink(const PropName: AnsiString; out Linked: TItem): Boolean;
// Initializes ItemLinks[].Item and resets ItemLinks[].Name to empty string
var Index: Integer;
begin
  Result := False;
  Linked := nil;
  if (FManager = nil) or (FManager.IsShuttingdown()) then begin
     if FManager = nil then Log(ClassName + '.ResolveLink: Undefined items manager', lkError);
    Exit;
  end;

  Index := GetLinkIndex(PropName);
  if Index = -1 then Exit;
//  Assert(Index <> -1, ClassName + '.ResolveLink: Invalid name "' + PropName + '"');

  Linked := ItemLinks[Index].Item;

  if (ItemLinks[Index].Item = nil) and (ItemLinks[Index].ObjectName <> '') and not FManager.IsSceneLoading then begin            // If link resolution is needed and possible
    if ItemLinks[Index].ObjectName[1] = HierarchyDelimiter then begin
      Include(ItemLinks[Index].Flags, lfAbsolute);
      Linked := FManager.FRoot.GetItemByFullName(ItemLinks[Index].ObjectName);
    end else begin
      Exclude(ItemLinks[Index].Flags, lfAbsolute);
      Linked := GetItemByPath(ItemLinks[Index].ObjectName);
      if Linked = nil then begin
        Linked := FManager.FRoot.GetItemByFullName('\' + ItemLinks[Index].ObjectName);
        Include(ItemLinks[Index].Flags, lfAbsolute);
      end;
    end;
    
    {if (Linked <> ObjectLinks[Index].Item) then }Result := SetLinkedObjectByIndex(Index, Linked);
    if not Result then Linked := nil;
  end;
end;

function TItem.SetLinkedObject(const PropName: AnsiString; Linked: TItem): Boolean;
begin
  Assert(GetLinkIndex(PropName) >= 0, Format('%S("%S").%S: Property "%S" not found', [ClassName, Name, 'SetLinkedObject', PropName]));
  Result := SetLinkedObjectByIndex(GetLinkIndex(PropName), Linked);
end;

/// Sets an object link property to "unresolved" state.
/// Returns True if the property is found False otherwise
function TItem.SetLinkProperty(const AName, Value: AnsiString): Boolean;
var Index: Integer;
begin
  Result := False;
  Index := GetLinkIndex(AName);

  Assert(Index <> -1, ClassName + '.SetLinkProperty: Invalid name: ' + AName);
  if Index = -1 then begin
    Log(ClassName + '.SetLinkProperty: Object link property named "' + AName + '" not found', lkError);
    Exit;
  end;

  Result := True;
  ItemLinks[Index].ObjectName := Value;
  ItemLinks[Index].Item       := nil;
end;

procedure TItem.ResolveLinks;
begin
end;

constructor TItem.Create(AManager: TItemsManager);
begin
//  TPersistentObjectsPool.Create(64);
  Name := AnsiString(Copy(ClassName, 2, Length(ClassName)));
  FManager := AManager;
  FChilds := nil; FTotalChilds := 0;
  FParent := nil;
  FState := [isNeedInit];

  BuildItemLinks;

  {$IFDEF DEBUGMODE}
  FConsistent := True;
  {$ENDIF}
end;

constructor TItem.Construct(AManager: TItemsManager);
begin
  Create(AManager);
end;

procedure TItem.Assign(ASource: TItem);
var
  Props: TProperties;
  Garbage: IRefcountedContainer;
begin
  if not Assigned(ASource) then Exit;

  Garbage := CreateRefcountedContainer();
  Props := TProperties.Create;
  Garbage.AddObject(Props);

  ASource.GetProperties(Props);
  SetProperties(Props);
end;

class function TItem.GetClass: CItem;
begin
  Result := Self;
end;

class function TItem.IsAbstract: Boolean;
begin
  Result := Self = TItem;
end;

function TItem.GetItemSize(CountChilds: Boolean): Integer;
var i: Integer;
begin
  Result := InstanceSize + Length(FChilds) * SizeOf(TItem);
  if Name <> '' then Inc(Result, Length(Name) * SizeOf(Name[1]));
  Inc(Result, Length(ItemLinks) * SizeOf(TObjectLink));
  for i := 0 to High(ItemLinks) do begin
    if ItemLinks[i].PropName   <> '' then Inc(Result, Length(ItemLinks[i].PropName)   * SizeOf(ItemLinks[i].PropName[1]));
    if ItemLinks[i].ObjectName <> '' then Inc(Result, Length(ItemLinks[i].ObjectName) * SizeOf(ItemLinks[i].ObjectName[1]));
  end;
  if CountChilds then for i := 0 to TotalChilds-1 do if Assigned(FChilds[i]) then Inc(Result, FChilds[i].GetItemSize(True));
end;

procedure TItem.HandleMessage(const Msg: TMessage);
begin
  if Msg.ClassType = ItemMsg.TInitMsg then
    OnInit
  else if Msg.ClassType = ItemMsg.TSceneLoadedMsg then begin
    ResolveLinks();
    OnSceneLoaded();
  end else if (Msg.ClassType = ItemMsg.TAddToSceneMsg) and (ItemMsg.TAddToSceneMsg(Msg).Item = Self) then
    OnSceneAdd()
  else if (Msg.ClassType = ItemMsg.TRemoveFromSceneMsg) then if (ItemMsg.TRemoveFromSceneMsg(Msg).Item = Self) then
    OnSceneRemove()
  {else if IsChildOf(ItemMsg.TRemoveFromSceneMsg(Msg).Item) then
    FManager.SendMessage(ItemMsg.TRemoveFromSceneMsg.Create(Self), nil, [mfBroadcast, mfCore]); }
end;

procedure TItem.DoForAllChilds(Delegate: TItemDelegate; Data: Pointer);
var i: Integer;
begin
  Assert(Assigned(Delegate), ClassName + '.DoForAllChilds: Can''t call undefined method pointer');
  Delegate(Self, Data);
  for i := 0 to TotalChilds-1 do if Assigned(FChilds[i]) then FChilds[i].DoForAllChilds(Delegate, Data);
end;

procedure TItem.BroadcastMessage(const Msg: TMessage);
var i: Integer;
begin
  if mfInvalid in Msg.Flags then Exit;
  Assert(mfBroadcast in Msg.Flags, 'Message is not for broadcast');
  HandleMessage(Msg);
  i := 0;
  while (i < TotalChilds) and not (mfInvalid in Msg.Flags) do begin
    FChilds[i].BroadcastMessage(Msg);
    Inc(i);
  end;
end;

procedure TItem.NotifyChilds(const Msg: TMessage);
var i: Integer;
begin
  Assert(mfChilds in Msg.Flags, 'TItem.NotifyChilds:Message is not for childs notification');
  for i := 0 to TotalChilds-1 do FChilds[i].HandleMessage(Msg);
end;

procedure TItem.OnInit;
begin
//  Assert(FManager <> nil, ClassName + '.OnInit: Manager is undefined');
  State := State - [isNeedInit];
end;

procedure TItem.OnSceneLoaded;
begin
  // All necessary work is done in main message handler (see @Link(TSceneLoadedMsg)) to avoid errors in client code (absent inherited call)
end;

procedure TItem.OnSceneAdd;
begin
end;

procedure TItem.OnSceneRemove;
//var i: Integer;
begin
//  for i := 0 to TotalChilds-1 do if Assigned(FChilds[i]) then FChilds[i].OnSceneRemove;
end;

procedure TItem.GetProperties(const Result: TProperties);
begin
  LinksParams[CurrentLinkParam].CurLinkIndex := 0;                                 // Object links number
//  ItemLinks := nil;
  if not Assigned(Result) then begin
     Log(ClassName + '.GetProperties: Result should be initialized', lkError);
//    Exit;
  end else Result.Clear;
  AddProperties(Result);
end;

procedure TItem.AddProperties(const Result: TProperties);
var i: Integer;
begin
  if Result = nil then Exit;

  Result.Add('Name', vtString, [], Name, '');

  if FManager <> nil then begin
    for i := 0 to HiddenStates-1 do
      Result.Add('Traverse mask\' + FManager.StateNames[i], vtBoolean, [poHidden], OnOffStr[i in FState], '');
    for i := HiddenStates to High(FManager.StateNames) do
      Result.Add('Traverse mask\' + FManager.StateNames[i], vtBoolean, [],         OnOffStr[i in FState], '');
  end;
end;

procedure TItem.SetProperties(Properties: TProperties);
var
  i: Integer;
  NewState: TItemFlags;
begin
  LinksParams[CurrentLinkParam].CurLinkIndex := 0;                                 // Object links number
  if Properties.Valid('Name') then Name := Properties['Name'];
  NewState := FState;
  if FManager <> nil then for i := 0 to High(FManager.StateNames) do
    if Properties.Valid('Traverse mask\' + FManager.StateNames[i]) then
      if Properties.GetAsInteger('Traverse mask\' + FManager.StateNames[i]) > 0 then
        NewState := NewState + [i] else NewState := NewState - [i];
  State := NewState;
end;

function TItem.GetProperty(const AName: AnsiString): AnsiString;
var Garbage: IRefcountedContainer; Props: TProperties; 
begin
  Garbage := CreateRefcountedContainer();
  Props := TProperties.Create;
  Garbage.AddObject(Props);
  GetProperties(Props);
  Result := Props[AName];
end;

procedure TItem.SetProperty(const AName, AValue: AnsiString);
var Garbage: IRefcountedContainer; Props: TProperties; Prop, LProp: PProperty;
begin
  Garbage := CreateRefcountedContainer();
  Props := TProperties.Create;
  Garbage.AddObject(Props);

  GetProperties(Props);
  Prop := Props.GetProperty(AName);
  if Assigned(Prop) and ([poReadonly, poDerivative, poDecor] * Prop^.Options = []) then begin
    New(LProp);
    Garbage.AddPointer(LProp);
    CopyProperty(Prop^, LProp^);
    Props.Clear;
    Props.Add(AName, LProp^.ValueType, LProp^.Options, AValue, LProp^.Enumeration, LProp^.Description);
    SetProperties(Props);
  end else Log(ClassName + '.SetProperty: Try to write to a non-existent or read-only property "' + AName + '"', lkWarning);
end;

procedure TItem.ObtainLinkedItemName(const PropName: AnsiString; out Result: AnsiString);
// Returns in the Result variable full name of linked item referenced by property with the given name without type checking
var Index: Integer;
begin
  Result := '';
  Index := GetLinkIndex(PropName);
  if Index = -1 then Exit;

  Result := ObtainLinkedItemNameByIndex(Index);
end;

function TItem.Clone: TItem;
var
  Props: TProperties;
  Garbage: IRefcountedContainer;
begin
  Result := GetClass.Construct(FManager);

  if Assigned(FManager) and (isNeedInit in Result.FState) then FManager.SendMessage(ItemMsg.TInitMsg.Create, Result, [mfRecipient]);

  if Assigned(FManager) then
    Result.Parent := Parent;

  Garbage := CreateRefcountedContainer();
  Props := TProperties.Create;
  Garbage.AddObject(Props);
  GetProperties(Props);
  Result.SetProperties(Props);

  Result.ResolveLinks;
end;

function TItem.Save(Stream: TStream): Boolean;
var i: Integer; Properties: TProperties;
begin
  Result := SaveString(Stream, AnsiString(ClassName));

  Properties := TProperties.Create;
  GetProperties(Properties);
  Result := Result and Properties.Write(Stream);
  Properties.Free;

  Result := Result and
            Stream.WriteCheck(TotalChilds, SizeOf(TotalChilds));

  for i := 0 to TotalChilds-1 do if Assigned(Childs[i]) then
    Result := Result and Childs[i].Save(Stream);
end;

function TItem.Load(Stream: TStream): Boolean;
var i, ATotalChilds: Integer; Properties: TProperties;
begin
  {$IFDEF DEBUGLOG}
  Log(ClassName + '.Load: Loading item "' + Name +'"');
  {$ENDIF}
  Properties := TProperties.Create;
  try
    Result := Properties.Read(Stream);
    SetProperties(Properties);
  finally
    Properties.Free;
  end;

//{$IFDEF DEBUGMODE} Assert(TotalChilds = 0, 'TItem.Load: TotalChilds should be zero'); {$ENDIF}
  Result := Result and Stream.ReadCheck(ATotalChilds, SizeOf(TotalChilds));
//  SetLength(FChilds, TotalChilds);

  for i := 0 to ATotalChilds-1 do Result := Result and (FManager.LoadItem(Stream, Self) <> nil);
end;

function TItem.GetChild(Index: Integer): TItem;
begin
  Result := FChilds[Index];
end;

function TItem.SetChild(Index: Integer; AItem: TItem): TItem;
begin
  Result := nil;
  if (Index < 0) or (Index >= TotalChilds) then Exit;
  Result := AItem;
  if (AItem = FChilds[Index]) then Exit;

  AItem.SetManager(FManager, True);
  AItem.FParent       := Self;
  AItem.IndexInParent := Index;

//  Root.IncludeItem(AItem, AItem.FTraverseMask);

  FChilds[Index] := AItem;
end;

procedure TItem.InsertChild(AItem: TItem; Index: Integer);
begin
  AddChild(AItem);
  ChangeChildIndex(AItem, Index);
end;

function TItem.AddChild(AItem: TItem): TItem;
var NeedInit, InScene: Boolean;
begin
  Result := nil;

  Assert(Self <> nil);
  Assert(not ((AItem = nil) or (AItem.IndexInParent >= 0) and (AItem.IndexInParent < TotalChilds) and (FChilds[AItem.IndexInParent] = AItem)));
  Assert(not Assigned(AItem.Parent), 'TItem.AddChild: item "' + AItem.GetFullName + '" already has a parent');

  if not Assigned(AItem) or (AItem.IndexInParent >= 0) and (AItem.IndexInParent < TotalChilds) and (FChilds[AItem.IndexInParent] = AItem) then begin
{    if AItem = nil then
      Log(' ****** AItem is nil')
    else
      Log(Format(' ****** %s("%s"), IIp: %d, totchlds: %d, ', [AItem.ClassName, AItem.Name, AItem.IndexInParent, TotalChilds]));}
    Exit;
  end;
//  for i := 0 to TotalChilds-1 do if Childs[i] = AItem then Exit;

  Result := DoAddChild(AItem);

  InScene := IsInScene(FManager);

  if Assigned(FManager) then begin
    NeedInit := isNeedInit in AItem.FState;
    if NeedInit then
      FManager.SendMessage(ItemMsg.TInitMsg.Create, AItem, [mfRecipient]);

//    FManager.SendMessage(ItemMsg.TAddToSceneMsg.Create(Result), AItem, [mfCore]);
    if InScene then AItem.DoForAllChilds(DoOnSceneAddForChilds, nil);

    if NeedInit then begin
      AItem.DoForAllChilds(DoSendInitToChilds, nil);
      if InScene then FManager.SendMessage(ItemMsg.TSceneLoadedMsg.Create(), Result, [mfBroadcast]);
    end;
  end;
end;

procedure TItem.RemoveChildByIndex(Index: Integer);
begin
  Assert((Index >= 0) and (Index < TotalChilds));

  if IsInScene(FManager){ and not FManager.IsShuttingdown} then begin                                       // Notify all items and subsystems
//    FManager.SendMessage(ItemMsg.TRemoveFromSceneMsg.Create(FChilds[Index]), Self, [mfRecipient, mfCore]);
    FChilds[Index].DoForAllChilds(DoOnSceneRemoveForChilds, nil);
  end;

  FChilds[Index].IndexInParent := -1;
  FChilds[Index].FParent       := nil;

//  FManager.FRoot.ExcludeItem(FChilds[Index], FChilds[Index].FTraverseMask);

  while Index < TotalChilds-1 do begin
    FChilds[Index] := FChilds[Index+1];
    FChilds[Index].IndexInParent := Index;
    Inc(Index);
  end;

  FChilds[Index] := nil;
  Dec(FTotalChilds);
end;

procedure TItem.RemoveChild(AItem: TItem);
var i: Integer;
begin
  if AItem = nil then Exit;
  Assert((AItem.IndexInParent >= 0) and (AItem.IndexInParent < TotalChilds) and (FChilds[AItem.IndexInParent] = AItem), ClassName + '.RemoveChild: AItem.Index is invalid: ' + IntToStr(AItem.IndexInParent));
  if (AItem.IndexInParent >= 0) and (AItem.IndexInParent < TotalChilds) and (FChilds[AItem.IndexInParent] = AItem) then begin
    RemoveChildByIndex(AItem.IndexInParent);
    Exit;
  end;

    Log(Format('%S.%S: "%S".Index is invalid: %D', [ClassName, 'RemoveChild', AItem.Name, AItem.IndexInParent]), lkWarning);
    Log('  Searching for the item in parent''s childs collection...');

  i := 0;
  while i < TotalChilds do begin
    if FChilds[i] = AItem then begin
      RemoveChildByIndex(i);
       Log(Format('  The item found at index %D', [i]), lkWarning);
      Exit;
    end;
    Inc(i);
  end;
   Log(Format('  The item not found', []), lkError);
end;

function TItem.GetChilds: TItems;
begin
  Result := FChilds;
end;

function TItem.GetFullName: AnsiString;
var Item: TItem;
begin
  Result := HierarchyDelimiter + Name;
  Item := Self.Parent;
  while Item <> nil do begin
    Result := HierarchyDelimiter + Item.Name + Result;
    Item := Item.Parent;
  end;
end;

function TItem.GetChildByName(const AName: AnsiString; SearchChilds: Boolean): TItem;
var i: Integer;
begin
  i := 0;
  while (i < TotalChilds) and not (Assigned(FChilds[i]) and (FChilds[i].Name = AName)) do Inc(i);

  if i < TotalChilds then
    Result := FChilds[i]
  else
    Result := nil;

  // Search in childs
  i := 0;
  if SearchChilds then
    while (i < TotalChilds) and (Result = nil) do begin
      Result := FChilds[i].GetChildByName(AName, True);
      Inc(i);
    end;
end;

function TItem.GetItemByPath(const APath: AnsiString): TItem;
var Levels: TAnsiStringArray; i, TotalLevels: Integer;
begin
  Result := nil;
  if APath = '' then Exit;

  TotalLevels := SplitA(APath, HierarchyDelimiter, Levels, False);

  if APath[1] = HierarchyDelimiter then begin
    if (TotalLevels > 0) and (FManager.FRoot.Name = Levels[0]) then
      Result := FManager.FRoot
    else
      Result := nil;
    i := 1;
  end else begin
    Result := Self;
    i := 0;
  end;
    
  while (i < TotalLevels) and (Result <> nil) do begin
    if Levels[i] = ParentAdressName then begin
      if Assigned(Result.Parent) then Result := Result.Parent
    end else
      Result := Result.GetChildByName(Levels[i], False);
    Inc(i);
  end;
end;

procedure TItem.MoveChild(Child, Target: TItem; Mode: TItemMoveMode);
var LParent: TItem; Index: Integer;
begin
  if Child = nil then Exit;

  LParent := nil;
  
  case Mode of
    mmInsertBefore, mmInsertAfter:   LParent := Target.Parent;
    mmAddChildFirst, mmAddChildLast: LParent := Target;
    mmMoveUp, mmMoveDown:            LParent := Child.Parent;
    mmMoveLeft: if Assigned(Child.Parent) then LParent := Child.Parent.Parent;
    mmMoveRight: if Assigned(Child.Parent) then LParent := Child.Parent.GetNextChild(Child);
    else Assert(False, ClassName + '.MoveChild: Invalid mode');
  end;

  if LParent = nil then Exit;

  Child.SetParent(LParent);

  Index := 0;

  case Mode of
    mmInsertBefore: Index := Target.IndexInParent - Ord(Target.IndexInParent > Child.IndexInParent);
    mmInsertAfter:  Index := Target.IndexInParent + Ord(Target.IndexInParent < Child.IndexInParent);
    mmAddChildLast: Index := Target.TotalChilds;
    mmMoveUp:       Index := MinI(Child.Parent.TotalChilds, MaxI(0, Child.IndexInParent-1));
    mmMoveDown:     Index := MinI(Child.Parent.TotalChilds, MaxI(0, Child.IndexInParent+1));
    mmMoveLeft:     Index := Child.Parent.IndexInParent;
  end;

  LParent.ChangeChildIndex(Child, Index);
end;

function TItem.IsChildOf(AParent: TItem): Boolean;
var Item: TItem;
begin
  Item := Parent;
  while Assigned(Item) and (Item <> AParent) do Item := Item.Parent;
  Result := Assigned(Item);
end;

function TItem.IsInScene(AManager: TItemsManager): Boolean;
begin
  Result := ( ( Assigned(AManager) and (FManager = AManager) ) or (not Assigned(AManager) and Assigned(FManager)) ) and
            ( (Self = FManager.Root) or IsChildOf(FManager.Root) );
end;

procedure TItem.MarkAsRemoved(DoNotRelease: Boolean);
begin
  if DoNotRelease then
    FState := FState + [isRemoved]
  else
    FState := FState + [isRemoved, isReleased];
end;

procedure TItem.FreeChilds;
var i: Integer; Item: TItem;
begin
  i := TotalChilds - 1;
  while i >= 0 do begin
    if Assigned(Childs[i]) then begin
//      Root.ExcludeItem(FChilds[i], FChilds[i].FTraverseMask);
      Item := FChilds[i];
      RemoveChildByIndex(i);
      Item.Free;
    end;
    Dec(i);  
  end;
  FChilds := nil; FTotalChilds := 0;
end;

procedure TItem.DeAlloc;
begin
  inherited Destroy;
end;

destructor TItem.Destroy;
begin
  FreeChilds;
  if Assigned(Parent) then Parent := nil;
  inherited;
end;

function TItem.GetNonDummyParent: TItem;
begin
  Result := Parent;
  while Result is TDummyItem do Result := Result.Parent;                        // Skip dummy items
end;

function TItem.FindNextChildInclDummy(var Current: TItem): Boolean;
var Ind: Integer; Done: Boolean;

  function GetNext(Par, Cur: TItem): TItem;
  begin
    repeat
      if Assigned(Cur) then Ind := Cur.IndexInParent else Ind := -1;
      Assert(Assigned(Par));
      if Ind < Par.TotalChilds-1 then begin       // Get next child
        Result := Par.Childs[Ind+1];
        if Result is TDummyItem then begin        // If it's dummy go through its childs
          Done := False;
          Par := Result;
          Cur := nil;
  //        Ind := -1;
        end else Done := True;
      end else begin                              // Reached end of the Par's childs
        Result := nil;
        Done := Par = Self;
        if not Done then begin                    //
          Cur := Par;
          Par := Par.Parent;        
        end;
      end;
    until Done;
  end;

begin
  if Assigned(Current) then
    Current := GetNext(Current.Parent, Current) else
      Current := GetNext(Self, Current);
  Result := Assigned(Current);
end;

function TItem.GetNextChild(CurrentChild: TItem): TItem;
begin
  Result := nil;
  if CurrentChild.IndexInParent < TotalChilds-1 then Result := Childs[CurrentChild.IndexInParent+1];
end;

function TItem.GetRelativeItemName(const AFullName: AnsiString): AnsiString;
var LevelsSelf, LevelsItem: TAnsiStringArray; i, TotalLevelsSelf, TotalLevelsItem, TotalLevelsMin, TotalLevelsEq: Integer;
begin
//   a0\b0\c0
//   a0\b0\c1\d0
//   a0\b0\c0\ ..\c1\d0
  TotalLevelsSelf := SplitA(GetFullName, HierarchyDelimiter, LevelsSelf, False);
  TotalLevelsItem := SplitA(AFullName,   HierarchyDelimiter, LevelsItem, False);
  TotalLevelsMin  := MinI(TotalLevelsSelf, TotalLevelsItem);

  i := 0;
  while (i < TotalLevelsMin) and (LevelsSelf[i] = LevelsItem[i]) do Inc(i);

  Result := '';

  TotalLevelsEq := i;   // Number of equal levels in path

  for i := TotalLevelsSelf-1 downto TotalLevelsEq do Result := Result + ParentAdressName + HierarchyDelimiter;
  for i := TotalLevelsEq to TotalLevelsItem-1 do Result := Result + LevelsItem[i] + HierarchyDelimiter;
end;

procedure TItem.SendMessage(const Msg: TMessage; Recipient: TItem; Destination: TMessageFlags);
begin
  {$IFDEF DEBUGMODE} Assert(FConsistent); {$ENDIF}    // Do not send messages when in an invalid state
  if mfRecipient in Destination then Assert(Assigned(Recipient));
  if (mfChilds in Destination) and not Assigned(Recipient) then Recipient := Self;
  if Assigned(FManager) then
    FManager.SendMessage(Msg, Recipient, Destination)
  else
    Log(Format('%S("%S").%S: Stand alone item sending a message of class "%S"', [ClassName, Name, 'SendMessage', Msg.ClassName]), lkWarning);
(*  Assert((Destination = [mdChilds]) or (Destination = [mdBroadcast]), 'Invalid destination');

  if mdChilds in Destination then begin
    Msg.Flags := Msg.Flags + [mfNotification];
    NotifyChilds(Msg);
  end else if mdBroadcast in Destination then begin
    Msg.Flags := Msg.Flags + [mfBroadcast];
    FManager.Root.BroadcastMessage(Msg);
  end;

  Assert(Assigned(Msg));
  Assert((Destination <> []), 'Invalid destination');

  if mdRecipient in Destination then Assert(Assigned(Recipient)) else Recipient := nil;
  if mdBroadcast in Destination then Msg.Flags := Msg.Flags + [mfBroadcast];
  if mdCore      in Destination then Msg.Flags := Msg.Flags + [mfCore];
  if mdChilds    in Destination then Msg.Flags := Msg.Flags + [mfNotification];

  if mdAsync in Destination then SendAsyncMessage(Msg, Recipient) else begin
    if mdRecipient in Destination then Recipient.HandleMessage(Msg);
    if mdCore      in Destination then HandleMessage(Msg);
    if mdChilds    in Destination then NotifyChilds(Msg);
    if (mdBroadcast in Destination) and Assigned(Root) then Root.BroadcastMessage(Msg);
  end; *)
end;

{ TBaseProcessing }

procedure TBaseProcessing.ResetProcessedTime;
begin
  FTimeProcessed := 0;
end;

procedure TBaseProcessing.Process(const DeltaT: Float);
begin
  FTimeProcessed := FTimeProcessed + DeltaT;
end;

procedure TBaseProcessing.AddProperties(const Result: TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  Result.AddEnumerated('Processing class', [], ProcessingClass+1, FManager.GetProcClassesEnum);
end;

procedure TBaseProcessing.SetProperties(Properties: TProperties);
begin
  inherited;

  if Properties.Valid('Processing class') then ProcessingClass := Properties.GetAsInteger('Processing class')-1;
end;

procedure TBaseProcessing.Pause;
begin
  State := FState - [isProcessing];
end;

procedure TBaseProcessing.Resume;
begin
  State := FState + [isProcessing];
end;

{ TDummyItem }

procedure TDummyItem.HandleMessage(const Msg: TMessage);
begin
  inherited;
  if (mfChilds in Msg.Flags)// and
//     (Msg.ClassType <> ItemMsg.TInitMsg) and (Msg.ClassType <> ItemMsg.TSceneLoadedMsg)
     then
    NotifyChilds(Msg);
end;

{ TRootItem }

constructor TRootItem.Create(AManager: TItemsManager);
begin
  inherited;
end;

function TRootItem.GetItemByFullName(const AName: AnsiString): TItem;
var Levels: TAnsiStringArray; i, TotalLevels: Integer; Item: TItem;
begin
  TotalLevels := SplitA(AName, HierarchyDelimiter, Levels, False);

  if (TotalLevels = 0) or (Name <> Levels[0]) then begin
    Result := GetItemByPath(AName)
  end else
{  Item := Self;
  for i := 1 to TotalLevels-1 do begin
    Item := Item.GetChildByName(Levels[i], False);
    if Item = nil then Exit;
  end;

  Result := Item;

  if Item <> GetItemByPath(AName) then begin
    Result := GetItemByPath(AName)
  end;}

  Result := GetItemByPath(AName)

{  Result := nil;
  if APath = '' then Exit;

  TotalLevels := SplitA(APath, HierarchyDelimiter, Levels, False);

  if APath[1] = HierarchyDelimiter then
    Result := FManager.FRoot
  else
    Result := Self;

  i := 0;
  while (i < TotalLevels) and (Result <> nil) do begin
    if Levels[i] = ParentAdressName then begin
      if Assigned(Result.Parent) then Result := Result.Parent
    end else
      Result := Result.GetChildByName(Levels[i], False);
    Inc(i);
  end; }
end;

function TRootItem.Extract(Condition: TExtractConditionFunc; out Items: TItems): Integer;
var LastCond: TExtractCondition;

  procedure TraverseExtract(Item: TItem);
  var i: Integer;
  begin
    LastCond := Condition(Item);
    if ecPassed in LastCond then begin
      if Length(Items) <= Result then SetLength(Items, Length(Items) + ItemsCapacityStep);
      Items[Result] := Item;
      Inc(Result);
    end;

    if not (ecBreakHierarchy in LastCond) and not (ecBreak in LastCond) then for i := 0 to Item.TotalChilds-1 do begin
      {$IFDEF DEBUGMODE}
      Assert(Item.Childs[i] <> nil, 'TRootItem.Extract.TraverseExtract: Childs[i] cannot be nil');
      {$ENDIF}
      TraverseExtract(Item.Childs[i]);
      if ecBreak in LastCond then Exit;
    end;
  end;

var i: Integer;

begin
  Result := 0;
  for i := 0 to TotalChilds-1 do begin
    {$IFDEF DEBUGMODE}
    Assert(Childs[i] <> nil, 'TRootItem.Extract: Childs[i] cannot be nil');
    {$ENDIF}
    TraverseExtract(Childs[i]);
  end;
  {$IFDEF DEBUGMODE}
  for i := Result to High(Items) do Items[i] := nil;
  {$ENDIF}
end;

function TRootItem.ExtractByMask(Mask: TItemFlags; Hierarchical: Boolean; out Items: TItems): Integer;
  procedure TraverseExtract(Item: TItem);
  var i: Integer;
  begin
    if Item.FState >= Mask then begin
      if Length(Items) <= Result then SetLength(Items, Length(Items) + ItemsCapacityStep);
      Items[Result] := Item;
      Inc(Result);
    end;
    for i := 0 to Item.TotalChilds-1 do begin
      {$IFDEF DEBUGMODE}
      Assert(Item.Childs[i] <> nil, 'TRootItem.Extract.TraverseExtract: Childs[i] cannot be nil');
      {$ENDIF}
      TraverseExtract(Item.Childs[i]);
    end;
  end;

  procedure TraverseExtractH(Item: TItem);
  var i: Integer;
  begin
    if Item.FState >= Mask then begin
      if Length(Items) <= Result then SetLength(Items, Length(Items) + ItemsCapacityStep);
      Items[Result] := Item;
      Inc(Result);
    end else if not (Item is TDummyItem) then Exit;
    for i := 0 to Item.TotalChilds-1 do begin
      {$IFDEF DEBUGMODE}
      Assert(Item.Childs[i] <> nil, 'TRootItem.Extract.TraverseExtract: Childs[i] cannot be nil');
      {$ENDIF}
      TraverseExtractH(Item.Childs[i]);
    end;
  end;

var i: Integer;

begin
  Result := 0;
  for i := 0 to TotalChilds-1 do begin
    {$IFDEF DEBUGMODE}
    Assert(Childs[i] <> nil, 'TRootItem.Extract: Childs[i] cannot be nil');
    {$ENDIF}
    if Hierarchical then TraverseExtractH(Childs[i]) else TraverseExtract(Childs[i]);
  end;
  {$IFDEF DEBUGMODE}
  SetLength(Items, Result);
  {$ENDIF}
end;

function TRootItem.ExtractByClass(AClass: CItem; out Items: TItems): Integer;
// Traverses through the items hierarchy and adds all items matching Mask to Items

  procedure TraverseExtract(Item: TItem);
  var i: Integer;
  begin
    if Item is AClass then begin
      if Length(Items) <= Result then SetLength(Items, Length(Items) + ItemsCapacityStep);
      Items[Result] := Item;
      Inc(Result);
    end;// else if not (Item is TDummyItem) then Exit;
    for i := 0 to Item.TotalChilds-1 do begin
      {$IFDEF DEBUGMODE}
      Assert(Item.Childs[i] <> nil, 'TRootItem.Extract.TraverseExtract: Childs[i] cannot be nil');
      {$ENDIF}
      TraverseExtract(Item.Childs[i]);
    end;
  end;

var i: Integer;

begin
  Result := 0;
  for i := 0 to TotalChilds-1 do begin
    {$IFDEF DEBUGMODE}
    Assert(Childs[i] <> nil, 'TRootItem.Extract: Childs[i] cannot be nil');
    {$ENDIF}
    TraverseExtract(Childs[i]);
  end;
  {$IFDEF DEBUGMODE}
  SetLength(Items, Result);
  {$ENDIF}
end;

function TRootItem.ExtractByMaskClass(Mask: TItemFlags; AClass: CItem; out Items: TItems): Integer;
var i: Integer;
begin
  Result := 0;
  for i := 0 to ExtractByMask(Mask, True, Items)-1 do
    if Items[i] is AClass then begin
      Items[Result] := Items[i];
      Inc(Result);
    end;
  {$IFDEF DEBUGMODE}
  SetLength(Items, Result);
  {$ENDIF}
end;

procedure TRootItem.HandleMessage(const Msg: TMessage);
begin
  inherited;
end;

{ TClassesList }

function TClassesList.GetClasses: TClassArray;
var i: Integer;
begin
  SetLength(Result, TotalClasses);
  for i := 0 to TotalClasses-1 do Result[i] := FClasses[i].ItemClass;
end;

function TClassesList.GetClassesByModule(const AModuleName: TShortName): TClassArray;
var i: Integer;
begin
  SetLength(Result, 0);
  for i := 0 to TotalClasses-1 do
    if FClasses[i].ModuleName = AModuleName then begin
      SetLength(Result, Length(Result)+1);
      Result[High(Result)] := FClasses[i].ItemClass;
    end;
end;

destructor TClassesList.Destroy;
begin
  SetLength(FClasses, 0);
  inherited;
end;

procedure TClassesList.Add(const AModuleName: TShortName; AClass: TClass);
begin
  if Length(FClasses) <= TotalClasses then
    SetLength(FClasses, Length(FClasses) + CollectionsCapacityStep);
  Inc(TotalClasses);
end;

procedure TClassesList.Add(const AModuleName: TShortName; AClasses: array of TClass);
var i: Integer;
begin
  if Length(FClasses) < TotalClasses + Length(AClasses) then
    SetLength(FClasses, TotalClasses + Length(AClasses));
  for i := 0 to High(AClasses) do begin
    FClasses[TotalClasses + i].ItemClass  := AClasses[i];
    FClasses[TotalClasses + i].ModuleName := AModuleName;
  end;
  Inc(TotalClasses, Length(AClasses));
end;

function TClassesList.ClassExists(AClass: TClass): Boolean;
begin
  Result := FindClass(AClass).ItemClass <> nil;
end;

function TClassesList.FindClass(AClass: TClass): TClassRec;
var i: Integer;
begin
  Result.ItemClass  := nil;
  Result.ModuleName := '';
  i := TotalClasses-1;
  while (i >= 0) and (FClasses[i].ItemClass <> AClass) do Dec(i);
  if i >= 0 then begin
    Result.ItemClass  := FClasses[i].ItemClass;
    Result.ModuleName := FClasses[i].ModuleName;
  end;
end;

function TClassesList.FindClassByName(const AModuleName, AClassName: TShortName): TClassRec;
var i: Integer;
begin
  Result.ItemClass  := nil;
  Result.ModuleName := '';
  i := TotalClasses-1;
  while (i >= 0) and
        ( (FClasses[i].ItemClass.ClassName <> AClassName) or (FClasses[i].ModuleName <> AModuleName) ) do Dec(i);
  if i >= 0 then begin
    Result.ItemClass  := FClasses[i].ItemClass;
    Result.ModuleName := FClasses[i].ModuleName;
  end;
end;

{ TSyncItem }

procedure TSyncItem.SetState(const Value: TItemFlags);
var OldState: TItemFlags;
begin
  OldState := FState;
  inherited;
  if not (isProcessing in OldState) and (isProcessing in Value) then Syncronize();
end;

procedure TSyncItem.Syncronize;
begin
  Parent.SendMessage(TSyncTimeMsg.Create(), Self, [mfBroadcast]);
end;

{ TSubsystem }

procedure TSubsystem.AddProperties(const Result: TProperties);
begin
end;

procedure TSubsystem.SetProperties(Properties: TProperties);
begin
end;

(*
  1. Parse JSON data
  2. Create item instance
  3. Set properties
  4. For object fields in JSON call CreateFromJSON
*)
function SetupFromJSON(Item: TItem; const aSrc: TJSONString; Manager: TItemsManager): TItem;
var
  Props: TProperties;
  Iter: TJSONNamesIterator;
  Name: TJSONString;
  Value: TJSONValue;
  PropVal: TPropertyValue;
  ItemClass: CItem;
  Child: TItem;
begin
  with CreateRefcountedContainer do begin
    with TJSON.Create(aSrc) do begin
      Props := TProperties.Create();
      Container.AddObjects([this, Props]);

      if not Assigned(Item) then
        if This.Contains('Class') then begin
          ItemClass := Manager.FindItemClass(This['Class'].asStr);
          if Assigned(ItemClass) then
            Item := ItemClass.Create(Manager);
        end;

      if Assigned(Item) then begin
        Iter := This.GetNamesIterator();
        while Iter.GoToNext do begin
          Name := Iter.Current;
          Value := This[Name];
          if Value.ValueType = jvObject then begin
            Child := SetupFromJSON(nil, Value.asStr, Manager);
            if Child <> nil then Item.AddChild(Child);
            PropVal := Child.Name;                            // Relative link
          end else begin
            PropVal := Value.asStr;
          end;
          Props.Add(Name, JSONToPropertyType[Value.ValueType], [], PropVal, '');
        end;
        Item.SetProperties(Props);
      end;
      Result := Item;
    end;
  end;
end;

initialization
  GlobalClassList := TClassesList.Create;
  NewLinksParameters;
finalization
  CurrentLinkParam := High(LinksParams);
  while CurrentLinkParam >= 0 do begin
    LinksParams[CurrentLinkParam].CachedProps.Free;
    Dec(CurrentLinkParam);
  end;
  LinksParams := nil;
  FreeAndNil(GlobalClassList);
end.