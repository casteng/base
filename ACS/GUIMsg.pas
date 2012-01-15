(*
 @Abstract(GUI messages unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 Unit contains GUI message classes
*)
{$Include GDefines.inc}
unit GUIMsg;

interface

uses BaseClasses, ACSBase, BaseMsg;

type
  // Base class for all GUI messages
  TGUIMessage = class(TMessage)
    Item: ACSBase.TGUIItem;
    constructor Create(AItem: ACSBase.TGUIItem);
  end;

  TGUIStateChangeMsg = class(TGUIMessage)
  end;

  TGUIChangeMsg = class(TGUIMessage)
  end;

  TGUIEnterMsg = class(TGUIMessage)
  end;

  TGUILeaveMsg = class(TGUIMessage)
  end;

  TGUIDownMsg = class(TGUIMessage)
  end;

  TGUIUpMsg = class(TGUIMessage)
  end;

  TGUIClickMsg = class(TGUIMessage)
  end;

  TGUIDblClickMsg = class(TGUIMessage)
  end;

  TGUIFocusNext = class(TGUIMessage)
  end;

  TGUIFocusPrev = class(TGUIMessage)
  end;

implementation

{ TGUIMessage }

constructor TGUIMessage.Create(AItem: ACSBase.TGUIItem);
begin
  Item := AItem;
end;

end.
