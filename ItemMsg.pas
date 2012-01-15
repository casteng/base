(*
 @Abstract(Item messages unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 Unit contains basic item message classes
*)
{$Include GDefines.inc}
unit ItemMsg;

interface

uses BaseClasses, BaseMsg;

type
  // This message is sent to an item when it needs to be initialized
  TInitMsg = class(BaseMsg.TNotificationMessage)
  end;

  // Base item notification message class. Should not be used directly.
  TItemNotificationMessage = class(BaseMsg.TNotificationMessage)
    // the item affected
    Item: BaseClasses.TItem;
    constructor Create(AItem: BaseClasses.TItem);
  end;

  // After attachment of a new item to a scene this message is sent to <b>the item being attached</b> and <b>core handler</b>
  TAddToSceneMsg = class(TItemNotificationMessage)
  end;

  // Before removal of an item from a scene this message is sent to <b>the item being removed</b>, <b>scene root</b> and <b>core handler</b>
  TRemoveFromSceneMsg = class(TItemNotificationMessage)
  end;

  // Before destruction of an item this message is sent to <b>the item being destroyed</b>, <b>scene root</b> and <b>core handler</b> (?)
  TDestroyMsg = class(TItemNotificationMessage)
  end;

  { When a physical address (pointer) to an item has changed (E.g. during change of the item's class.),
    this message is sent to <b>the item affected</b> and <b>core handler</b> and broadcast from <b>scene root</b>. }
  TReplaceMsg = class(BaseMsg.TNotificationMessage)
    // Old pointer. Valid only within message handler
    OldItem: BaseClasses.TItem;
    // New pointer
    NewItem: BaseClasses.TItem;
    constructor Create(AOldItem, ANewItem: BaseClasses.TItem);
  end;

  // This message is sent to <b>core handler</b> and broadcast from <b>scene root</b> when an item has been modified with an operation (see @Link(TOperation))
  TItemModifiedMsg = class(TItemNotificationMessage)
  end;

  // This message is sent to <b>core handler</b> after modification of the item's name
  TItemNameModifiedMsg = class(TItemNotificationMessage)
  public
    OldName: ShortString;                              // ToFix: name may not fit
    constructor Create(AItem: BaseClasses.TItem; const AOldName: AnsiString);
  end;

  // This message is sent to <b>core handler</b> when position, orientation or transformation matrix of a physics-enabled item has been modified
  TPhysicalTransformModifiedMsg = class(TItemNotificationMessage)
  end;

  // This message is sent to <b>core handler</b> when a physics parameter except transform of a physics-enabled item has been modified
  TPhysicalParameterModifiedMsg = class(TItemNotificationMessage)
  end;

  { This message is sent to <b>core handler</b> when a processing status of a TProcessing item has been modified
    (e.g. changed isProcessing state of the item or one of its parent items).
    <b>Note: curretnly, hierarchical processing status propagation not implemented }
  TItemProcessingModifiedMsg = class(TItemNotificationMessage)
  end;

  // This message is sent to <b>core handler</b> before a scene clearing
  TSceneClearMsg = class(BaseMsg.TNotificationMessage)
  end;

  { After a scene has been completely loaded this message is sent to <b>scene root</b> and <b>core handler</b>.
    Also this message is sent to added to scene items. }
  TSceneLoadedMsg = class(BaseMsg.TNotificationMessage)
  end;

  // This message is sent to a <b>subsystem manager</b> when a subsystem connects or disconnects from the manager
  TSubsystemMsg = class(TSystemMessage)
  public
    // Event which occured to subsystem
    Action: TSubsystemAction;
    // Affected subsystem
    Subsystem: TBaseSubsystem;
    constructor Create(AAction: TSubsystemAction; ASubsystem: TBaseSubsystem);
  end;

  // Message envelope class. Used by asyncronous messaging system. Should not be used directly.
  TMessageEnvelope = class(TMessage)
    // Message in envelope
    Message: TMessage;
    // The item which should receive the message
    Recipient: BaseClasses.TItem;
    // Creates the enveloped message
    constructor Create(ARecipient: TItem; AMsg: TMessage);
  end;

  // This message is sent to <b>all aggregated items</b> during the initialization of the aggregate
  TAggregateMsg = class(TMessage)
    // The aggregate which aggregates the item
    Aggregate: BaseClasses.TItem;
    constructor Create(AAggregate: BaseClasses.TItem);
  end;

implementation

{ TItemNotificationMessage }

constructor TItemNotificationMessage.Create(AItem: BaseClasses.TItem);
begin
  Item := AItem;
end;

{ TReplaceItemMessage }

constructor TReplaceMsg.Create(AOldItem, ANewItem: BaseClasses.TItem);
begin
  OldItem := AOldItem; NewItem := ANewItem;
end;

{ TItemNameModifiedMsg }

constructor TItemNameModifiedMsg.Create(AItem: BaseClasses.TItem; const AOldName: AnsiString);
begin
  inherited Create(AItem);
  OldName := AOldName;
end;

{ TSubsystemMsg }

constructor TSubsystemMsg.Create(AAction: TSubsystemAction; ASubsystem: TBaseSubsystem);
begin
  Action    := AAction;
  Subsystem := ASubsystem;
end;

{ TMessageEnvelope }

constructor TMessageEnvelope.Create(ARecipient: TItem; AMsg: TMessage);
begin
  Recipient := ARecipient;
  Message   := AMsg;
end;

{ TAggregateMsg }

constructor TAggregateMsg.Create(AAggregate: BaseClasses.TItem);
begin
  Aggregate := AAggregate;
end;

end.
