(*
 @Abstract(GUI helper unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 Unit contains helper classes for GUI applications <br>
 Supported controls (including all descendants): TTextGUIItem , TSwitchButton, TCheckBox, TTrackBar
*)
{$Include C2Defines.inc}
unit ACSHelper;

interface

uses
  Logger,
  SysUtils, 
  Basics, BaseClasses, GUIHelper, BaseMsg, GUIMsg, ItemMsg, Props, ACSBase, ACS, ACSAdv;

const
  TotalImmediateApplyControls = 5;                                                      // ToDo: Move out of here
  ImmediateApplyControls: array[0..TotalImmediateApplyControls-1] of string =
   ('Gamma', 'Contrast', 'Brightness', 'SoundVolume', 'MusicVolume');
  TotalNotifyingApplyControls = 1;
  NotifyingApplyControls: array[0..TotalNotifyingApplyControls-1] of string =
   ('UserName');
  FormNamesCapacityStep = 1;
  // On click predefined actions
  TotalActions = 9;
  aShow = 0; aShowSolely = 1; aToggle = 2; aClose = 3; aOK = 4; aApply = 5; aCancel = 6; aReset = 7; aBack = 8;
  ActionStr: array[0..TotalActions-1] of string = ('Show', 'Invoke', 'Toggle', 'Close', 'OK', 'Apply', 'Cancel', 'Reset', 'Back');

type
  TGUIState = record
    Visibility: array of Boolean;
  end;

  TACSHelper = class(TGUIHelper)
  private
    Config: TProperties;
    Items: TItemsManager;
    GUIRoot: TGUIRootItem;

    TotalFormNames: Integer;
    FormNames: array of string;
    TotalHistory: Integer;
    History: array of TGUIState;

    procedure Initialize;
    function GetCommand(const s: string; var Argument: string): Integer;
    function FindForm(const s: string): TItem;
  protected
    procedure ControlToConfig(const FormName, OptionName: string; AConfig: TProperties); override;
    procedure ConfigToControl(const FormName, OptionName: string; AConfig: TProperties); override;
  public
    GUIState: Integer;

    constructor Create(AItems: TItemsManager; AConfig: TProperties);
    destructor Destroy; override;

    procedure HandleMessage(const Msg: TMessage); override;
    procedure HandleGUIClick(const Item: TGUIItem);
// Items manipulation
    procedure HideAllForms; virtual;
    function ControlExists(const Name: string): Boolean; override;
    function IsControlVisible(const Name: string; CheckHierarchy: Boolean): Boolean; override;
    procedure ShowControl(const Name: string); override;
    procedure HideControl(const Name: string); override;
    procedure ToggleControl(const Name: string); override;                    // Toggles item's visibility
    procedure EnableControl(const Name: string); override;
    procedure DisableControl(const Name: string); override;
    procedure SetControlText(const Name, Text: string); override;
    function GetControlText(const Name: string): string; override;
    function GetControlFormName(const Name: string): string; override;
// Properties filling
    function GUIToString(Item: TItem): string; virtual;
    procedure ResetConfig(const FormName: string; ADefaultConfig: TProperties); override;
// Form navigation
    procedure AddForm(const FormName: string);
    procedure LoadForms(const FileName: string);
    procedure ShowForm(const FormName: string; Solely: Boolean);
    procedure RememberState;
    procedure ShowPreviousState;
    function IsWithinGUI(AX, AY: Single): Boolean;
  end;

implementation

{ TACSHelper }

procedure TACSHelper.Initialize;
var Temp: TItems;
begin
  if Items.Root.ExtractByClass(TGUIRootItem, Temp) > 1 then begin
     Log(ClassName + '.Create: More than one items of class TGUIRootItem found', lkWarning); 
  end;
  if Temp = nil then begin
     Log(ClassName + '.Create: No items of class TGUIRootItem found', lkError); 
    Exit;
  end;
  GUIRoot := Temp[0] as TGUIRootItem;
  Temp := nil;
end;

function TACSHelper.GetCommand(const s: string; var Argument: string): Integer;
var i, t: Integer;
begin
  Result := -1;
  for i := 0 to TotalActions-1 do begin
    t := Pos(UpperCase(ActionStr[i]), UpperCase(s));
    if (t > 0) and (t = Length(s) - Length(ActionStr[i]) + 1) then begin
      Argument := Copy(s, 1, t-1);
      Result := i;
      Exit;
    end;
  end;
end;

function TACSHelper.FindForm(const s: string): TItem;
var i: Integer;
begin
  Result := nil;
  for i := 0 to TotalFormNames-1 do if FormNames[i] = s then begin
    Result := GUIRoot.GetChildByName(s, True);
    Exit;
  end;
end;

procedure TACSHelper.ControlToConfig(const FormName, OptionName: string; AConfig: TProperties);
var i: Integer; Form, Item: TItem;
begin
  Form := GUIRoot.GetChildByName(FormName, True);
  if not (Form is TGUIItem) then Exit;
  Item := Form.GetChildByName(OptionName, True);
  if Item = nil then Exit;

  for i := 0 to TotalNotifyingApplyControls-1 do
    if UpperCase(Item.Name) = UpperCase(NotifyingApplyControls[i]) then
      Items.HandleMessage(TOptionsApplyNotifyMsg.Create(UpperCase(Item.Name), GUIToString(Item)));

  AConfig[OptionName] := GUIToString(Item);
end;

procedure TACSHelper.ConfigToControl(const FormName, OptionName: string; AConfig: TProperties);
var Form, Item: TItem; Prop: PProperty;
begin
  Form := GUIRoot.GetChildByName(FormName, True);
  if not (Form is TGUIItem) then Exit;
  Item := Form.GetChildByName(OptionName, True);
  if not (Item is TGUIItem) then Exit;
//  if TGUIItem(Item).Data is TTextListItems then
//    TTextListItems(TGUIItem(Item).Data).VariantsText := AConfig.GetProperty(OptionName).Enumeration;
  if (Item is TSwitchButton) then with Item as TSwitchButton do VariantIndex := StrToIntDef(AConfig[Name], VariantIndex) else
    if (Item is TTrackBar) then with Item as TTrackBar do Value := StrToIntDef(AConfig[Name], Value) else
      if (Item is TCheckBox) then (Item as TCheckBox).Checked := AConfig[OptionName] = OnOffStr[True] else
        if (Item is TComboList) then begin
          if Assigned((Item as TComboList).Items) and Assigned((Item as TComboList).Items.Items) then begin
            Prop := AConfig.GetProperty(OptionName);
            if Assigned(Prop) then (Item as TComboList).Items.Items.VariantsText := Prop^.Enumeration;
            (Item as TComboList).Text := AConfig[OptionName];
          end;
        end else if (Item is TBaseList) then begin
          Prop := AConfig.GetProperty(OptionName);
          if Assigned(Prop) then (Item as TBaseList).VariantsText := Prop^.Enumeration;
          (Item as TBaseList).Text := AConfig[OptionName];
        end else if (Item is TTextGUIItem) then
          (Item as TTextGUIItem).Text := AConfig[OptionName];
end;

constructor TACSHelper.Create(AItems: TItemsManager; AConfig: TProperties);
begin
  Config := AConfig;
  Items  := AItems;

  Items.RegisterItemClass(TGUIItem);
  Items.RegisterItemClass(TGUIRootItem);

  Items.RegisterItemClass(TGUIPoint);
  Items.RegisterItemClass(TGUILine);

  Items.RegisterItemClass(TCursorPicture);

  Items.RegisterItemClass(TPanel);
  Items.RegisterItemClass(TLabel);
  Items.RegisterItemClass(TButton);
  Items.RegisterItemClass(TSwitchButton);
  Items.RegisterItemClass(ACSAdv.TSwitchLabel);
  Items.RegisterItemClass(TCheckBox);

  Items.RegisterItemClass(TProgressBar);
  Items.RegisterItemClass(TSlider);

  Items.RegisterItemClass(TEdit);
  Items.RegisterItemClass(TList);
  Items.RegisterItemClass(TComboList);

  Items.RegisterItemClass(TWindow);
  Items.RegisterItemClass(TCaptionArea);
  Items.RegisterItemClass(TClientArea);
end;

destructor TACSHelper.Destroy;
var i: Integer;
begin
  FormNames := nil;
  for i := 0 to High(History) do History[i].Visibility := nil;
  History := nil;
  inherited;
end;

procedure TACSHelper.HandleMessage(const Msg: TMessage);
var i: Integer;
begin
  if Msg is TSceneLoadedMsg then Initialize else if GUIRoot = nil then Exit;
//  if Msg is TInputMessage then GUIRoot.BroadcastMessage(Msg) else
    if not (Msg is TGUIMessage) then Exit;
  if Msg.ClassType = TGUIClickMsg then HandleGUIClick((Msg as TGUIClickMsg).Item);
  if Msg.ClassType = TGUIChangeMsg then with TGUIChangeMsg(Msg) do begin
    Assert(Assigned(Item), Format('%S.%S: ', [ClassName, 'HandleMessage: Message of class %S contains undefined(nil) item', Msg.ClassName]));
    for i := 0 to TotalImmediateApplyControls-1 do
      if UpperCase(Item.Name) = UpperCase(ImmediateApplyControls[i]) then
        Items.HandleMessage(TOptionsPreviewMsg.Create(UpperCase(Item.Name), GUIToString(Item)));
  end;
end;

procedure TACSHelper.HandleGUIClick(const Item: TGUIItem);
var Action: Integer; Arg: string;
begin
  if Item.Name = 'ForceQuit' then Items.HandleMessage(TForceQuitMsg.Create);
  Action := GetCommand(Item.Name, Arg);
  case Action of
    aShow: if ControlExists(Arg) then begin
      RememberState;
      ConfigToForm(Arg, Config);
      ShowForm(Arg, False);
    end;
    aShowSolely: if ControlExists(Arg) then begin
      RememberState;
      ConfigToForm(Arg, Config);
      ShowForm(Arg, True);
    end;
    aToggle: if ControlExists(Arg) then ToggleControl(Arg);
    aClose: HideControl(Arg);
    aOK: if ControlExists(Arg) then begin
      FormToConfig(Arg, Config);
      ShowPreviousState;
      Items.HandleMessage(TOptionsApplyMsg.Create(UpperCase(Arg)));
    end;
    aApply: if ControlExists(Arg) then begin
      FormToConfig(Arg, Config);
      Items.HandleMessage(TOptionsApplyMsg.Create(UpperCase(Arg)));
    end;
    aCancel: if ControlExists(Arg) then begin
      ConfigToForm(Arg, Config);
      ShowPreviousState;
    end;
    aReset: if ControlExists(Arg) then ResetConfig(Arg, DefaultConfig);
    aBack: ShowPreviousState;
  end;
end;

procedure TACSHelper.HideAllForms;
var i: Integer;
begin
  for i := 0 to TotalFormNames-1 do HideControl(FormNames[i]);
end;

function TACSHelper.ControlExists(const Name: string): Boolean;
begin
  Result := GUIRoot.GetChildByName(Name, True) <> nil;
end;

function TACSHelper.IsControlVisible(const Name: string; CheckHierarchy: Boolean): Boolean;
var Item: TItem;
begin
  Item := GUIRoot.GetChildByName(Name, True);
  Result := (Item is TGUIItem) and (isVisible in Item.State);
  Item := Item.Parent;
  if CheckHierarchy then while (Item is TGUIItem) or (Item is TDummyItem) do if not (Item is TDummyItem) then begin
    Result := Result and (isVisible in Item.State);
    Item := Item.Parent;
  end;  
end;

procedure TACSHelper.ShowControl(const Name: string);
var Item: TItem;
begin
  Item := GUIRoot.GetChildByName(Name, True);
  while (Item is TGUIItem) or (Item is TDummyItem) do begin
    if not (Item is TDummyItem) then Item.State := Item.State + [isVisible];
    Item := Item.Parent;
  end;
end;

procedure TACSHelper.HideControl(const Name: string);
var Item: TItem;
begin
  Item := GUIRoot.GetChildByName(Name, True);
  if Item is TGUIItem then Item.State := Item.State - [isVisible];
end;

procedure TACSHelper.ToggleControl(const Name: string);
var Item: TItem;
begin
  Item := GUIRoot.GetChildByName(Name, True);
  if not (Item is TGUIItem) then Exit;
  if isVisible in Item.State then
    Item.State := Item.State - [isVisible] else
      Item.State := Item.State + [isVisible];
end;

procedure TACSHelper.EnableControl(const Name: string);
var Item: TGUIItem;
begin
  Item := Items.Root.GetChildByName(Name, True) as TGUIItem;
  if Item is TGUIItem then Item.State := Item.State - [isProcessing];
end;

procedure TACSHelper.DisableControl(const Name: string);
var Item: TGUIItem;
begin
  Item := Items.Root.GetChildByName(Name, True) as TGUIItem;
  if Item is TGUIItem then Item.State := Item.State + [isProcessing];
end;

procedure TACSHelper.SetControlText(const Name, Text: string);
var Item: TItem;
begin
  Item := Items.Root.GetChildByName(Name, True);
  if Item is TTextGUIItem then (Item as TTextGUIItem).Text := Text else
//   if Item is TEdit then (Item as TEdit).Text := Text;
end;

function TACSHelper.GetControlText(const Name: string): string;
var Item: TItem;
begin
  Result := '';
  Item := GUIRoot.GetChildByName(Name, True);
  if Item is TTextGUIItem then Result := (Item as TTextGUIItem).Text else
//   if Item is TEdit then Result := (Item as TEdit).Text;
end;

function TACSHelper.GUIToString(Item: TItem): string;
begin
  Result := '';
  if Item = nil then Exit;
  if (Item is TSwitchButton) then Result := IntToStr((Item as TSwitchButton).VariantIndex) else
    if (Item is TTrackBar) then Result := IntToStr((Item as TTrackBar).Value) else
      if (Item is TCheckBox) then Result := OnOffStr[(Item as TCheckBox).Checked] else
//        if (Item is TBaseList) then Result := (Item as TBaseList).Text else
          if (Item is TTextGUIItem) then Result := (Item as TTextGUIItem).Text;
end;

procedure TACSHelper.ResetConfig(const FormName: string; ADefaultConfig: TProperties);
begin
  inherited;
  Items.HandleMessage(TOptionsApplyMsg.Create(UpperCase(FormName)));
end;

procedure TACSHelper.AddForm(const FormName: string);
begin
  
  if (GUIRoot <> nil) and (GUIRoot.GetChildByName(FormName, True) = nil) then Log(ClassName + '.AddForm: GUI container item "' + FormName + '" doest not exists', lkWarning);
  
  
  if Length(FormNames) <= TotalFormNames then SetLength(FormNames, Length(FormNames) + FormNamesCapacityStep);
  FormNames[TotalFormNames] := FormName;
  Inc(TotalFormNames);
end;

procedure TACSHelper.LoadForms(const FileName: string);
var cf: Text; s: string;
begin
{$I-}
  Assign(cf, FileName); Reset(cf);
  if IOResult <> 0 then begin
     Log(ClassName + '.LoadForms: Error opening file "' + FileName + '"', lkError); 
    Exit;
  end;
  while not EOF(cf) do begin
    Readln(cf, s);
    if IOResult <> 0 then begin
       Log(ClassName + '.Load: Error reading from file "' + FileName + '"', lkError); 
      Break;
    end else if s <> '' then AddForm(s);
  end;
  Close(cf);
end;

procedure TACSHelper.ShowForm(const FormName: string; Solely: Boolean);
begin
  if ControlExists(FormName) then begin
    if Solely then HideAllForms;
    ShowControl(FormName);
  end;  
end;

procedure TACSHelper.RememberState;
var i: Integer; Item: TItem; Changed: Boolean;
begin
// Check if something changed
  Changed := TotalHistory = 0;
  if TotalHistory > 0 then for i := 0 to TotalFormNames-1 do begin
    Item := GUIRoot.GetChildByName(FormNames[i], True);
    if History[TotalHistory-1].Visibility[i] <> (Item is TGUIItem) and (isVisible in Item.State) then begin
      Changed := True;
      Break;
    end;
  end;

  if not Changed then Exit;

  if Length(History) <= TotalHistory then SetLength(History, Length(History) + FormNamesCapacityStep);
  SetLength(History[TotalHistory].Visibility, TotalFormNames);
  for i := 0 to TotalFormNames-1 do begin
    Item := GUIRoot.GetChildByName(FormNames[i], True);
    History[TotalHistory].Visibility[i] := (Item is TGUIItem) and (isVisible in Item.State);
  end;
  Inc(TotalHistory);
end;

procedure TACSHelper.ShowPreviousState;
var i: Integer;
begin
  if TotalHistory > 0 then Dec(TotalHistory) else Exit;
  for i := 0 to High(History[TotalHistory].Visibility) do
    if History[TotalHistory].Visibility[i] then ShowControl(FormNames[i]) else HideControl(FormNames[i]); 
end;

function TACSHelper.GetControlFormName(const Name: string): string;
//var Item: TGUIItem;
begin
  Assert(False, '');
{  Result := '';
  while not (Item is TGUIItem) do begin
    if FindForm(Item.Name) <> nil then begin
      Result := Item.Name;
      Exit;
    end;
  end;}
end;

function TACSHelper.IsWithinGUI(AX, AY: Single): Boolean;
begin
  Result := GUIRoot.IsWithinGUI(AX, AY);
end;

end.
