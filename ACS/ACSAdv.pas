(*
 @Abstract(Advanced ACS GUI library unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains advanced GUI controls
*)
{$Include GDefines.inc}
unit ACSAdv;

interface

uses
  Logger, 
  SysUtils, BaseTypes, Basics, BaseStr, Props, MarkUp, BaseGraph, BaseClasses, BaseMsg, GUIMsg, Models, ACSBase, ACS;

type
  TTextListItems = class(TModel)
  private
    FItems: BaseTypes.TAnsiStringArray;
    FTotalItems: Integer;
    FVariantsText: string;
    procedure SetVariantsText(const Value: string);                            // Splits text to variants by "\&". "\\" treat as "\"
    function GetItem(Index: Integer): string;
    procedure SetItem(Index: Integer; const Value: string);
  protected
    procedure DoSort(Ascending: Boolean; CompareFunc: TStringCompareDelegate); virtual;
  public
    procedure GetProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    function IndexOf(const Value: string): Integer;
    procedure Add(const Value: string);
    procedure Remove(Index: Integer);

    procedure Sort(Ascending: Boolean; CompareFunc: TStringCompareDelegate);

    property VariantsText: string read FVariantsText write SetVariantsText;

    property TotalItems: Integer read FTotalItems write FTotalItems;
    property Items[Index: Integer]: string read GetItem write SetItem; default;
  end;

  TBaseList = class(TTextGUIItem)
  private
    function GetVariantsText: string;
    procedure SetVariantsText(const Value: string);
  protected
    FItemIndex: Integer;
    FItems: TTextListItems;
    function GetModel: TModel; override;
    procedure SetItemIndex(Value: Integer); virtual;
  public
    constructor Create(AManager: TItemsManager); override;
    destructor Destroy; override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    property Items: TTextListItems read FItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property VariantsText: string read GetVariantsText write SetVariantsText;
  end;

  TSwitchLabel = class(TBaseList)
    function GUIHandleMessage(const Msg: TMessage): Boolean; override;
    procedure Draw; override;
  end;

  TList = class(TBaseList)
  protected
    BottomVisible, HoverItem: Integer;
    FocusedBarColor, SelectedBarColor: TColor;
    function GetSizeAdjustable: Boolean; override;
    procedure SetItemIndex(Value: Integer); override;
  public
    TopVisible: Integer;
    constructor Create(AManager: TItemsManager); override;

    function GUIHandleMessage(const Msg: TMessage): Boolean; override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    function GetItemAt(AX, AY: Single): Integer; virtual;
    function GetItemByMouse(AX, AY: Single): Integer; virtual;

    procedure Draw; override;
  end;

  TTable = class(TBaseList)
  protected   
  public
{    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    procedure Draw; override;}
  end;

  TComboList = class(TLabel)
  private
    function GetItems: TBaseList;
  protected
    function GetModel: TModel; override;
    function FindListControl(PopupControl: TGUIItem): TBaseList;
    function GetPopupControl: TGUIItem;
    procedure HandleClick(Button, MX, MY: Integer); override;
  public
    function GUIHandleMessage(const Msg: TMessage): Boolean; override;
    procedure ReturnMessage(const Msg: TMessage); override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    property Items: TBaseList read GetItems;
  end;

  // Returns list of classes introduced by the unit
  function GetUnitClassList: TClassArray;

implementation

function GetUnitClassList: TClassArray;
begin
  Result := GetClassList([TSwitchLabel, TList, TComboList]);
end;

{ TTextListItems }

procedure TTextListItems.SetVariantsText(const Value: string);
begin
  FVariantsText := Value;
  TotalItems := SplitA(FVariantsText, '\&', FItems, False);
end;

function TTextListItems.GetItem(Index: Integer): string;
begin
  Assert((Index >= 0) and (Index < TotalItems), ClassName + '.SetItem: Index out of range');
  Result := FItems[Index];
end;

procedure TTextListItems.SetItem(Index: Integer; const Value: string);
begin
  Assert((Index >= 0) and (Index < TotalItems), ClassName + '.SetItem: Index out of range');
  FItems[Index] := Value;
end;

procedure TTextListItems.GetProperties(const Result: Props.TProperties);
begin
  Result.Add('Variants', vtString, [], FVariantsText, '');
end;

procedure TTextListItems.SetProperties(Properties: Props.TProperties);
begin
  if Properties.Valid('Variants') then VariantsText := Properties['Variants'];
end;

function TTextListItems.IndexOf(const Value: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to TotalItems-1 do if FItems[i] = Value then begin
    Result := i;
    Exit;
  end;
end;

procedure TTextListItems.Add(const Value: string);
begin
  if Length(FItems) <= TotalItems then SetLength(FItems, Length(FItems) + CollectionsCapacityStep);
  FItems[FTotalItems] := Value;
  Inc(FTotalItems);
end;

procedure TTextListItems.Remove(Index: Integer);
begin
  while Index < TotalItems-1 do begin
    FItems[Index] := FItems[Index+1];
    Inc(Index);
  end;

  FItems[Index] := '';

  Dec(FTotalItems);
end;

procedure TTextListItems.DoSort(Ascending: Boolean; CompareFunc: TStringCompareDelegate);
var i, j: Integer;
begin
  if Assigned(CompareFunc) then begin
  end else
    Basics.QuickSortStr(TotalItems, FItems);

  j := FTotalItems-1;
  if not Ascending then for i := 0 to FTotalItems div 2-1 do begin
    Swap(FItems[i], FItems[j]);
    Dec(j);
  end;
end;

procedure TTextListItems.Sort(Ascending: Boolean; CompareFunc: TStringCompareDelegate);
begin
  DoSort(Ascending, CompareFunc);
end;

{ TBaseList }

function TBaseList.GetVariantsText: string;
begin
  if Assigned(FItems) then Result := FItems.VariantsText else Result := '';
end;

procedure TBaseList.SetVariantsText(const Value: string);
begin
  if Assigned(FItems) then FItems.VariantsText := Value;
end;

function TBaseList.GetModel: TModel;
begin
  Result := FItems;
end;

constructor TBaseList.Create(AManager: TItemsManager);
begin
  inherited;
  FItems := TTextListItems.Create;
end;

destructor TBaseList.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

procedure TBaseList.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  Result.Add('Item index', vtInt, [], IntToStr(ItemIndex), '');
end;

procedure TBaseList.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Properties.Valid('Item index') then ItemIndex := StrToIntDef(Properties['Item index'], 0);
end;

procedure TBaseList.SetItemIndex(Value: Integer);
begin
  if (Value < 0) or (Value >= FItems.TotalItems) then Value := -1;
  if (FItemIndex <> Value) and isVisibleAndEnabled then ReturnMessage(TGUIChangeMsg.Create(Self));
  FItemIndex := Value;
  if FItemIndex = -1 then Text := '' else Text := FItems[FItemIndex];
end;

{ TSwitchLabel }

procedure TSwitchLabel.Draw;
begin
  inherited;
  Screen.SetColor(Color);
  Screen.SetFont(Font);

  DrawText(0, 0);
end;

function TSwitchLabel.GUIHandleMessage(const Msg: TMessage): Boolean;
begin
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;

  if Msg.ClassType = TMouseClickMsg then with TMouseClickMsg(Msg) do begin
    if (Button = mbLeft) and Hover then
      if ItemIndex < FItems.TotalItems-1 then ItemIndex := ItemIndex + 1 else ItemIndex := 0;
  end;
end;

{ TList }

function TList.GetSizeAdjustable: Boolean;
begin
  Result := False;
end;

procedure TList.SetItemIndex(Value: Integer);
begin
  inherited;
  if ItemIndex < TopVisible    then TopVisible := ItemIndex;
  if ItemIndex > BottomVisible then if ItemIndex = BottomVisible + 1 then Inc(TopVisible) else TopVisible := ItemIndex;
end;

constructor TList.Create(AManager: TItemsManager);
begin
  inherited;
  HoverItem := -1;
end;

function TList.GUIHandleMessage(const Msg: TMessage): Boolean;
var MX, MY: Single;
begin
  if (Msg.ClassType = TMouseMoveMsg) or (Msg.ClassType = TMouseDownMsg) then with TMouseMoveMsg(Msg) do begin
    MX := X; MY := Y;
    ScreenToClient(MX, MY);
  end;
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;

  if (Msg.ClassType = TMouseDownMsg) or
     (Msg.ClassType = TMouseMoveMsg) then with TMouseMsg(Msg) do begin
    if Hover then HoverItem := GetItemAt(MX, MY) else HoverItem := -1;
    if Pushed then begin
      ItemIndex := GetItemByMouse(MX, MY);
      UpdateVisualParameters;
    end;
  end;
end;

procedure TList.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  AddColorProperty(Result, 'Color\Selected bar', SelectedBarColor);
  AddColorProperty(Result, 'Color\Focused bar',  FocusedBarColor);
end;

procedure TList.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  SetColorProperty(Properties, 'Color\Selected bar', SelectedBarColor);
  SetColorProperty(Properties, 'Color\Focused bar',  FocusedBarColor);
end;

procedure TList.Draw;
var i, CurPos: Integer; Tag: TTag; LY, w, h: Single;
begin
  inherited;
  LY := 0;
  BottomVisible := TopVisible;
  for i := MaxI(TopVisible, 0) to FItems.TotalItems-1 do begin
    Font.GetTextExtent(FItems[i], w, h);

    if i = ItemIndex then begin
      if Focused then Screen.Color := FocusedBarColor else Screen.Color := SelectedBarColor;
      Screen.Bar(0, LY, PxWidth, LY + h);
      Screen.Color := FocusedColor;
    end else if i = HoverItem then Screen.Color := HoverColor else Screen.Color := NormalColor;
    Screen.SetFont(Font);
//    DrawText(0, LY);
    Screen.PutTextXY(0, LY, FItems[i]);
    LY := LY + h;
    if LY >= PxHeight then Exit else BottomVisible := i;
  end;

{  if Colored and (MarkUp <> nil) then begin
    GetClearedText;
    CurPos := 0;
    Screen.MoveTo(0, 0);
    for i := 0 to MarkUp.TotalTags-1 do begin
      Tag := MarkUp.Tags[i];
      if CurPos <> Tag.Position then begin
        Screen.PutText(Copy(MarkUp.PureText, CurPos+1, Tag.Position-CurPos));
        CurPos := Tag.Position;
      end;
      if Tag.ClassType = TMoveToTag     then with TMoveToTag(Tag)     do Screen.MoveTo(X, Y);
      if Tag.ClassType = TColorTag      then with TColorTag(Tag)      do Screen.SetColor(Screen.Color and $FF000000 or Color);
      if Tag.ClassType = TAlphaColorTag then with TAlphaColorTag(Tag) do Screen.SetColor(Color);
      if Tag.ClassType = TColorResetTag then with TColorResetTag(Tag) do Screen.SetColor(Self.Color);
    end;
    Screen.PutText(Copy(MarkUp.PureText, CurPos+1, Length(MarkUp.PureText)));
  end else   }
end;

function TList.GetItemAt(AX, AY: Single): Integer;
var LY, w, h: Single;
begin
  Result := 0;
  if AX < 0       then Result := miLeft;
  if AX >= PxWidth  then Result := miRight;
  if AY < 0       then Result := miUp;
  if AY >= PxHeight then Result := miDown;
  if Result <> 0 then Exit; 
  LY := 0;
  for Result := MaxI(TopVisible, 0) to FItems.TotalItems-1 do begin
    Font.GetTextExtent(FItems[Result], w, h);
    if (AY >= LY) and (AY < LY+h) then Exit;
    LY := LY + h;
    if LY >= PxHeight then Exit;
  end;
  Result := miDown;
end;

function TList.GetItemByMouse(AX, AY: Single): Integer;
begin
  if Pushed then AX := 0;
  Result := GetItemAt(AX, AY);
  if Result < 0 then if Pushed then begin
    case Result of
      miUp:   Result := MaxI(ItemIndex-1, 0);
      miDown: Result := MinI(ItemIndex+1, FItems.TotalItems-1);
      miLeft, miRight: Result := ItemIndex;
   end;
 end else Result := ItemIndex;
end;

{ TComboList }

const PopupListProp = 'Popup control';

function TComboList.GetItems: TBaseList;
var Item: TItem;
begin
  Item := GetPopupControl;
  if Item is TBaseList then Result := Item as TBaseList else Result := nil;
end;

function TComboList.GetModel: TModel;
var List: TBaseList;
begin
  List := FindListControl(GetPopupControl);
  if List <> nil then Result := List.FItems else Result := nil;
end;

function TComboList.FindListControl(PopupControl: TGUIItem): TBaseList;

function GetListChild(Item: TItem): TBaseList;
var i: Integer;
begin
  Result := nil;
  if Item is TBaseList then Result := TBaseList(Item) else
    for i := 0 to Item.TotalChilds-1 do begin
      Result := GetListChild(Item.Childs[i]);
      if Result <> nil then Exit;
    end;
end;

begin
  Result := nil;
  if PopupControl = nil then Exit;
  Result := GetListChild(PopupControl);
end;

function TComboList.GetPopupControl: TGUIItem;
var PopupList: TItem;
begin
  ResolveLink(PopupListProp, PopupList);
  if PopupList is TGUIItem then Result := TGUIItem(PopupList) else Result := nil;
end;

procedure TComboList.HandleClick(Button, MX, MY: Integer);
var PopupList: TGUIItem;
begin
  inherited;
  if Hover and (Button = IK_MOUSELEFT) then begin
    PopupList := GetPopupControl;
    if PopupList <> nil then begin
      PopupList.State := PopupList.State + [isVisible];
      Height := PopupList.Height + Height * 0;
    end;
  end;
end;

function TComboList.GUIHandleMessage(const Msg: TMessage): Boolean;
begin
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;

  if Msg.ClassType = TMouseClickMsg then
    if Hover then
      with TMouseClickMsg(Msg) do HandleClick(IK_MOUSEBUTTON[Button], X, Y);
end;

procedure TComboList.ReturnMessage(const Msg: TMessage);
var CallInherited: Boolean;
begin
  CallInherited := True;
  if Msg.ClassType = TGUIClickMsg then with TGUIClickMsg(Msg) do begin
    if Item is TBaseList then begin
      CallInherited := False;
      Text := TBaseList(Item).Text;
      if GetPopupControl <> nil then GetPopupControl.State := GetPopupControl.State - [isVisible];
    end;
  end;
  if CallInherited then inherited;
end;

procedure TComboList.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  AddItemLink(Result, PopupListProp, [], 'TGUIItem');
end;

procedure TComboList.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Properties.Valid(PopupListProp) then SetLinkProperty(PopupListProp, Properties[PopupListProp]);
end;

begin
  GlobalClassList.Add('ACSAdv', GetUnitClassList);
end.
