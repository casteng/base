(*
 @Abstract(VCL helper unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 Unit contains VCL helper routines and classes
*)
{$Include GDefines.inc}
unit VCLHelper;

interface

uses
  Logger,
  BaseTypes, BaseMsg, Basics, BaseStr, AppsInit, AppHelper, Props, GUIHelper,
  SysUtils,
  Windows,
  {$IFDEF USED_VIRTUAL_TREEVIEW}
  VirtualTrees,
  {$ENDIF}
  Classes, Forms, Controls, ACTNList, Graphics, StdCtrls, ComCtrls, ExtCtrls, Buttons;

type
  TCheckStoredProc = function(AControl: TControl): Boolean;

  TVCLGUIHelper = class(TGUIHelper)
  private
    StoredControls: array of TControl;
    function FindControl(const FormName: string; ControlName: string): TControl; overload;
    function FindControl(Name: string): TControl; overload;
  protected
    procedure ControlToConfig(const FormName, OptionName: string; AConfig: Props.TProperties); override;
    procedure ConfigToControl(const FormName, OptionName: string; AConfig: Props.TProperties); override;
    // VCL-specific
    procedure StoreControlFont(Control: TControl; AConfig: Props.TProperties); virtual;
    procedure ApplyControlFont(Control: TControl; AConfig: Props.TProperties); virtual;
  public
    procedure HandleMessage(const Msg: TMessage); override;
    function ControlExists(const Name: string): Boolean; override;   // ToDo: fix it to find all controls
    procedure ShowControl(const Name: string); override;
    procedure HideControl(const Name: string); override;
    procedure ToggleControl(const Name: string); override;
    procedure EnableControl(const Name: string); override;
    procedure DisableControl(const Name: string); override;

    function IsInputInProcess(): Boolean; override;
    // VCL-specific
    procedure AddStoredControl(AControl: TControl; AddChilds: Boolean; CheckStored: TCheckStoredProc);
    procedure RemoveStoredControl(AControl: TControl; RemoveChilds: Boolean);

    procedure StoreControlsConfig(Control: TControl; AConfig: Props.TProperties);
    procedure StoreFont(const Prefix: string; Font: TFont; AConfig: Props.TProperties);
    procedure ApplyControlsConfig(AControl: TControl; AConfig: Props.TProperties);
    procedure ApplyFont(const Prefix: string; Font: TFont; AConfig: Props.TProperties);
    procedure StoreForms(const FileName: string);
    procedure LoadForms(const FileName: string);
    procedure StoreLocalizable(const FileName: string);
    procedure LoadLocalizable(const FileName: string);
  end;

  TVCLStarter = class(TAppStarter)
  protected
    function GetTerminated: Boolean; override;
    procedure SetTerminated(const Value: Boolean);
  public
    // Returns <b>True</b> if another instance of the application is already rinning. If <b>ActivateExisting</b> is <b>True</b> the other instance will be activated.
    function isAlreadyRunning(ActivateExisting: Boolean): Boolean; override;
    procedure PrintError(const Msg: string; ErrorType: TLogLevel); override;
  end;

  TVCLApp = class(TApp)
  public
    constructor Create(const AProgramName: string; AStarter: TAppStarter); override;
  end;

  // VCL compatible stream class which encapsulates Basics.TStream
  TVCLStream = class(Classes.TStream)
  private
    FStream: Basics.TStream;
    procedure SetStream(const Value: Basics.TStream);
  protected
    function GetSize: Int64; override;
  public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; overload; override;
    // Encapsulated stream
    property Stream: Basics.TStream read FStream write SetStream;
  end;

  // Stream class which encapsulates VCL TStream
  TStreamFromVCL = class(Basics.TStream)
  private
    FStream: Classes.TStream;
    procedure SetStream(const Value: Classes.TStream);
  public
    // Changes the current position of the stream (if such changes are supported by particular stream class)
    function Seek(const NewPos: Cardinal): Boolean; override;
    // Reads <b>Count</b> bytes from the stream to <b>Buffer</b>, moves current position forward for number of bytes read and returns this number
    function Read(out Buffer; const Count: Cardinal): Cardinal; override;
    // Writes <b>Count</b> bytes from <b>Buffer</b> to the stream, moves current position forward for the number of bytes written and returns this number
    function Write(const Buffer; const Count: Cardinal): Cardinal; override;
    // Encapsulated stream
    property Stream: Classes.TStream read FStream write SetStream;
  end;

  function SplitToTStrings(const Str, Delim: string; Res: TStrings; EmptyOK, KeepExisting: Boolean): Integer;

  procedure CheckParentSize(AControl: TControl);
  function IsPointInRect(const Point: TPoint; const Rect: TRect): Boolean;
  function IsMouseOverControl(Control: TControl): Boolean;

implementation

uses
  Dialogs;

function IsPointInRect(const Point: TPoint; const Rect: TRect): Boolean;
begin
  Result := (Point.X >= Rect.Left) and (Point.Y >= Rect.Top) and (Point.X < Rect.Right) and (Point.Y < Rect.Bottom);
end;

function IsMouseOverControl(Control: TControl): Boolean;
var Rect: TRect;
begin
  Rect := Control.BoundsRect;
  if Assigned(Control.Parent) then begin
    Rect.TopLeft     := Control.Parent.ClientToScreen(Rect.TopLeft);
    Rect.BottomRight := Control.Parent.ClientToScreen(Rect.BottomRight);
  end;

  Result := IsPointInRect(Mouse.CursorPos, Rect);
end;

function SplitToTStrings(const Str, Delim: string; Res: TStrings; EmptyOK, KeepExisting: Boolean): Integer;
var i: Integer; sa: BaseTypes.TStringArray;
begin
  if not KeepExisting then Res.Clear;
  Result := Split(Str, Delim, sa, EmptyOK);
  for i := 0 to Result-1 do Res.Add(sa[i]);
end;

procedure CheckParentSize(AControl: TControl);
begin
  if Assigned(AControl.Parent) then begin
    AControl.Parent.Width  := MaxI(AControl.Parent.Width,  AControl.Constraints.MinWidth);
    AControl.Parent.Height := MaxI(AControl.Parent.Height, AControl.Constraints.MinHeight);
  end;
end;

{ TVCLStarter }

function TVCLStarter.GetTerminated: Boolean;
begin
  Result := Application.Terminated;
end;

function TVCLStarter.isAlreadyRunning(ActivateExisting: Boolean): Boolean;
begin
  Result := False;
end;

procedure TVCLStarter.PrintError(const Msg: string; ErrorType: TLogLevel);
begin
  MessageDlg(Msg, mtError, [mbOK], 0);
end;

procedure TVCLStarter.SetTerminated(const Value: Boolean);
begin
  Application.Terminate;
end;

{ TVCLApp }

constructor TVCLApp.Create(const AProgramName: string; AStarter: TAppStarter);
begin
  inherited;
//  FMainHandle := Application.Handle;
end;

{ TVCLGUIHelper }

function TVCLGUIHelper.FindControl(const FormName: string; ControlName: string): TControl;
var i: Integer; Comp: TComponent;
begin
  Result := nil;

  ControlName := StringReplace(ControlName, ' ', '', [rfReplaceAll]);

  i := 0;
  while (i < Application.ComponentCount) and
        not ((Application.Components[i] is TForm) and (Application.Components[i].Name = FormName)) do Inc(i);
  if i < Application.ComponentCount then begin
    Comp := (Application.Components[i] as TForm).FindComponent(ControlName);
    if Comp is TControl then Result := Comp as TControl;
  end;
{  for i := 0 to Application.ComponentCount-1 do
    if (Application.Components[i] is TForm) and (Application.Components[i].Name = FormName) then begin
      Form := Application.Components[i] as TForm;
      Break;
    end;
  if not Assigned(Form) then Exit;}
end;

function TVCLGUIHelper.FindControl(Name: string): TControl;
var i: Integer; 
begin
  Name := StringReplace(Name, ' ', '', [rfReplaceAll]);
  for i := 0 to Application.ComponentCount-1 do begin
    if SameText(Application.Components[i].Name, Name) and (Application.Components[i] is TControl) then begin
      Result := Application.Components[i] as TControl;
      Exit;
    end else if Application.Components[i] is TForm then begin
      Result := FindControl(Application.Components[i].Name, Name);
      if Assigned(Result) then Exit;
    end;
  end;
  Result := nil;
end;

procedure TVCLGUIHelper.ControlToConfig(const FormName, OptionName: string; AConfig: Props.TProperties);
var Control: TControl; Result: string;

  function GetComboBoxText(ComboBox: TComboBox): string;
  begin
    Result := '';

    if (ComboBox.ItemIndex <> -1) and
       ((AConfig.GetType(OptionName) = vtNat) or
        (AConfig.GetType(OptionName) = vtInt) or
        (AConfig.GetType(OptionName) = vtSingle) or
        (AConfig.GetType(OptionName) = vtDouble)) then
      Result := IntToStr(ComboBox.ItemIndex) else
        Result := ComboBox.Text;
  end;

  function GetCalendarText(Picker: TDateTimePicker): string;
  begin
    if AConfig.GetType(OptionName) = vtDouble then
      Result := FloatToStr(Picker.DateTime)
    else
      Result := DateToStr(Picker.DateTime);
  end;

  function GetListText(List: TCustomListBox): string;
  var i: Integer;
  begin
    Result := '';
    for i := 0 to List.Count-1 do begin
      if i > 0 then Result := Result + StringDelimiter;
      Result := Result + List.Items[i];
    end;
  end;

begin
  Control := FindControl(FormName, OptionName);
  if Control = nil then Exit;

  if (Control is TRadioButton) then
    Result := OnOffStr[(Control as TRadioButton).Checked]
  else if (Control is TCheckBox) then
    Result := OnOffStr[(Control as TCheckBox).Checked]
  else if (Control is TTrackBar) then
    Result := IntToStr((Control as TTrackBar).Position)
  else if (Control is TProgressBar) then
    Result := IntToStr((Control as TProgressBar).Position)
  else if (Control is TCustomEdit) then
    Result := (Control as TCustomEdit).Text
  else if (Control is TComboBox) then
    Result := (Control as TComboBox).Text
  else if (Control is TDateTimePicker) then
    Result := GetCalendarText(Control as TDateTimePicker)
  else if (Control is TCustomListBox) then
    Result := GetListText(Control as TCustomListBox)
  else if (Control is TSpeedButton) then
    Result := OnOffStr[(Control as TSpeedButton).Down];

  AConfig[OptionName] := Result;
end;

procedure TVCLGUIHelper.ConfigToControl(const FormName, OptionName: string; AConfig: Props.TProperties);
var Control: TControl;

  procedure SetComboBoxText(ComboBox: TComboBox);
  begin
    SplitToTStrings(AConfig.GetProperty(OptionName)^.Enumeration, StrDelim, ComboBox.Items, True, False);
    if (ComboBox.Style = csDropDown) or (ComboBox.Style = csSimple) then
      ComboBox.Text := AConfig[OptionName]
    else
      ComboBox.ItemIndex := ComboBox.Items.IndexOf(AConfig[OptionName]);
  end;

  procedure SetCalendarText(Calendar: TDateTimePicker);
  begin
    if AConfig.GetType(OptionName) = vtDouble then
      Calendar.DateTime := StrToFloatDef(AConfig[OptionName], Calendar.DateTime)
    else
      Calendar.DateTime := StrToDateDef(AConfig[OptionName], Calendar.DateTime)
  end;

begin
  Control := FindControl(FormName, OptionName);
  if Control = nil then Exit;

  if (Control is TRadioButton) then
    (Control as TRadioButton).Checked := AConfig[OptionName] = OnOffStr[True]
  else if (Control is TCheckBox) then
    (Control as TCheckBox).Checked := AConfig[OptionName] = OnOffStr[True]
  else if (Control is TTrackBar) then
    with Control as TTrackBar do Position := StrToIntDef(AConfig[OptionName], Position)
  else if (Control is TProgressBar) then
    with Control as TProgressBar do Position := StrToIntDef(AConfig[OptionName], Position)
  else if (Control is TCustomEdit) then
    (Control as TCustomEdit).Text := AConfig[OptionName]
  else if (Control is TComboBox) then
    SetComboBoxText(Control as TComboBox)
  else if (Control is TDateTimePicker) then
    SetCalendarText(Control as TDateTimePicker)
  else if (Control is TCustomListBox) then
    SplitToTStrings(AConfig[OptionName], StringDelimiter, (Control as TCustomListBox).Items, False, False)
  else if (Control is TSpeedButton) then
    (Control as TSpeedButton).Down := AConfig[OptionName] = OnOffStr[True];
end;

procedure TVCLGUIHelper.StoreControlFont(Control: TControl; AConfig: Props.TProperties);
var Prefix: string;
begin
  Prefix := Control.Owner.Name + '\' + Control.Name;
  if (Control is TPanel) and (Control as TPanel).ParentFont then StoreFont(Prefix+'\Font\', (Control as TPanel).Font, AConfig);
  if (Control is TForm)  and not (Control as TForm).ParentFont  then StoreFont(Prefix+'\Font\', (Control as TForm).Font,  AConfig);
end;

procedure TVCLGUIHelper.ApplyControlFont(Control: TControl; AConfig: Props.TProperties);
var Prefix: string;
begin
  Prefix := Control.Owner.Name + '\' + Control.Name;
  if (Control is TPanel) and not (Control as TPanel).ParentFont then ApplyFont(Prefix+'\Font\', (Control as TPanel).Font, AConfig);
  if (Control is TForm)  and not (Control as TForm).ParentFont  then ApplyFont(Prefix+'\Font\', (Control as TForm).Font, AConfig);
end;

procedure TVCLGUIHelper.HandleMessage(const Msg: TMessage);
begin
end;

function TVCLGUIHelper.ControlExists(const Name: string): Boolean;
begin
  Result := Assigned(FindControl(Name));
end;

procedure TVCLGUIHelper.AddStoredControl(AControl: TControl; AddChilds: Boolean; CheckStored: TCheckStoredProc);

  procedure Add(AControl: TControl);
  begin
    if AControl = nil then Exit;
    SetLength(StoredControls, Length(StoredControls)+1);
    StoredControls[High(StoredControls)] := AControl;
  end;

var i: Integer;

begin
  if (not Assigned(CheckStored)) or CheckStored(AControl) then Add(AControl);
  if AddChilds then
    if AControl = nil then begin
      for i := 0 to Application.ComponentCount-1 do
        if Application.Components[i] is TControl then AddStoredControl(Application.Components[i] as TControl, True, CheckStored);
    end else
      if AControl is TWinControl then for i := 0 to (AControl as TWinControl).ControlCount-1 do
        AddStoredControl((AControl as TWinControl).Controls[i], True, CheckStored);
end;

procedure TVCLGUIHelper.RemoveStoredControl(AControl: TControl; RemoveChilds: Boolean);

  procedure Remove(AControl: TControl);
  var i: Integer;
  begin
    if AControl = nil then Exit;
    for i := 0 to High(StoredControls) do if StoredControls[i] = AControl then begin
      if i < High(StoredControls) then StoredControls[i] := StoredControls[High(StoredControls)];
      SetLength(StoredControls, Length(StoredControls)-1);
      Break;
    end;    
  end;

var i: Integer;

begin
  Remove(AControl);
  if RemoveChilds then if AControl = nil then begin
    for i := 0 to Application.ComponentCount-1 do
      if Application.Components[i] is TControl then RemoveStoredControl(Application.Components[i] as TControl, True);
  end else
    if AControl is TWinControl then for i := 0 to (AControl as TWinControl).ControlCount-1 do
      RemoveStoredControl((AControl as TWinControl).Controls[i], True);
end;

procedure TVCLGUIHelper.StoreControlsConfig(Control: TControl; AConfig: Props.TProperties);
var
  OldWindowState: TWindowState; Prefix: string;
  {$IFDEF USED_VIRTUAL_TREEVIEW}
  Garbage: IRefcountedContainer;
  StrStream: TStringStream;
  {$ENDIF}
begin
  if (Control = nil) or (AConfig = nil) then Exit;

  OldWindowState := wsNormal;

  if Control is TForm then begin
    OldWindowState := TForm(Control).WindowState;
    TForm(Control).WindowState := wsNormal;
  end;

  Prefix := Control.Owner.Name + '\' + Control.Name;

  AConfig.Add(Prefix +  '\Width', vtString, [], IntToStr(Control.Width ), '');
  AConfig.Add(Prefix + '\Height', vtString, [], IntToStr(Control.Height), '');
  AConfig.Add(Prefix +   '\Left', vtString, [], IntToStr(Control.Left  ), '');
  AConfig.Add(Prefix +    '\Top', vtString, [], IntToStr(Control.Top   ), '');

  if Control is TForm then with TForm(Control) do begin
    WindowState := OldWindowState;

    AConfig.Add(Prefix + '\WindowState', vtString, [], IntToStr(Ord(WindowState)), '');

    if FormStyle = fsStayOnTop then
      AConfig.Add(Prefix + '\OnTop', vtString, [], 'Yes', '') else
        AConfig.Add(Prefix + '\OnTop', vtString, [], 'No', '');

    if Control.Floating then
      AConfig.Add(Prefix + '\Floating',      vtString, [], 'Yes', '') else begin
        AConfig.Add(Prefix + '\Floating',    vtString, [], 'No', '');
        AConfig.Add(Prefix + '\DockingHost', vtString, [], Control.Parent.Name, '');
        AConfig.Add(Prefix + '\Width',       vtString, [], IntToStr(Control.ClientWidth ), '');
        AConfig.Add(Prefix + '\Height',      vtString, [], IntToStr(Control.ClientHeight), '');
      end;
  end;

  StoreControlFont(Control, AConfig);

  if Control.Visible then
    AConfig.Add(Prefix + '\Visible', vtString, [], 'Yes', '') else
      AConfig.Add(Prefix + '\Visible', vtString, [], 'No', '');

  {$IFDEF USED_VIRTUAL_TREEVIEW}
  if (Control is TVirtualStringTree) or (Control is TVirtualDrawTree) then begin
    StrStream := TStringStream.Create('');
    Garbage := CreateRefcountedContainer;
    Garbage.AddObject(StrStream);
    if Control is TVirtualStringTree then (Control as TVirtualStringTree).Header.SaveToStream(StrStream);
    if Control is TVirtualDrawTree   then (Control as TVirtualDrawTree).Header.SaveToStream(StrStream);
    AConfig.Add(Prefix + '\Header', vtString, [], StrStream.DataString, '');
  end;
  {$ENDIF}

//  for i := 0 to Control.ComponentCount-1 do if Control.Components[i] is TControl then
//    SaveControlsConfig(Control.Components[i] as TControl, AConfig);

{  for i := 0 to Form.ComponentCount-1 do if Form.Components[i] is TControl then begin
    Cfg.Add(Form.Name + '\' + Form.Components[i].Name + '\Left'  , vtString, [], IntToStr((Form.Components[i] as TControl).Left)  , '');
    Cfg.Add(Form.Name + '\' + Form.Components[i].Name + '\Top'   , vtString, [], IntToStr((Form.Components[i] as TControl).Top)   , '');
    Cfg.Add(Form.Name + '\' + Form.Components[i].Name + '\Width' , vtString, [], IntToStr((Form.Components[i] as TControl).Width) , '');
    Cfg.Add(Form.Name + '\' + Form.Components[i].Name + '\Height', vtString, [], IntToStr((Form.Components[i] as TControl).Height), '');
  end;}
end;

procedure TVCLGUIHelper.StoreFont(const Prefix: string; Font: TFont; AConfig: Props.TProperties);
begin
  if (Font = nil) or (AConfig = nil) then Exit;

  AConfig.Add(Prefix + 'Charset',         vtInt,     [], IntToStr(Font.Charset), '');
  AConfig.Add(Prefix + 'Color',           vtColor,   [], '#' + IntToHex(Font.Color, 8), '');
  AConfig.Add(Prefix + 'Name',            vtString,  [], Font.Name, '');
  AConfig.Add(Prefix + 'Pitch',           vtInt,     [], IntToStr(Ord(Font.Pitch)), '');
  AConfig.Add(Prefix + 'Size',            vtInt,     [], IntToStr(Font.Size), '');
  AConfig.Add(Prefix + 'Style\Bold',      vtBoolean, [], OnOffStr[fsBold      in Font.Style], '');
  AConfig.Add(Prefix + 'Style\Italic',    vtBoolean, [], OnOffStr[fsItalic    in Font.Style], '');
  AConfig.Add(Prefix + 'Style\Underline', vtBoolean, [], OnOffStr[fsUnderline in Font.Style], '');
  AConfig.Add(Prefix + 'Style\StrikeOut', vtBoolean, [], OnOffStr[fsStrikeOut in Font.Style], '');
end;

procedure TVCLGUIHelper.ApplyControlsConfig(AControl: TControl; AConfig: Props.TProperties);
type
  TDockPair = record
    Control: TControl;
    Host: TWinControl;
  end;

var
  i: Integer;
  DockHost: TControl;
  DockPairs: array of TDockPair;
  Prefix: string;
  {$IFDEF USED_VIRTUAL_TREEVIEW}
  Garbage: IRefcountedContainer;
  StrStream: TStringStream;
  {$ENDIF}

  procedure AddDockPair(Control: TControl; Host: TWinControl);
  begin
    SetLength(DockPairs, Length(DockPairs)+1);
    DockPairs[High(DockPairs)].Control := Control;
    DockPairs[High(DockPairs)].Host    := Host;
  end;

  procedure ApplyConfig(Control: TControl);
  begin
    if (Control = nil) or (AConfig = nil) then Exit;

    Prefix := Control.Owner.Name + '\' + Control.Name;

    if AConfig[Prefix +  '\Width'] <> '' then Control.Width  := StrToIntDef(AConfig[Prefix + '\Width'],  Control.Width );
    if AConfig[Prefix + '\Height'] <> '' then Control.Height := StrToIntDef(AConfig[Prefix + '\Height'], Control.Height);
    if AConfig[Prefix +   '\Left'] <> '' then Control.Left   := StrToIntDef(AConfig[Prefix + '\Left'], Control.Left);
    if AConfig[Prefix +    '\Top'] <> '' then Control.Top    := StrToIntDef(AConfig[Prefix +  '\Top'], Control.Top );

    if Control is TForm then with TForm(Control) do begin
      Control.Left   := MinI(Screen.Width  - 16, MaxI( -Control.Width + 8, Control.Left));
      Control.Top    := MinI(Screen.Height - 16, MaxI(-Control.Height + 8, Control.Top ));
      if AConfig[Prefix + '\WindowState'] <> '' then WindowState := TWindowState(MinI(Ord(wsMaximized), MaxI(Ord(wsNormal), StrToIntDef(AConfig[Prefix + '\WindowState'], Ord(wsNormal)))));
      if AConfig[Prefix + '\OnTop'] = 'No' then FormStyle := fsNormal else
        if AConfig[Prefix + '\OnTop'] = 'Yes' then FormStyle := fsStayOnTop;

      if AConfig[Prefix + '\Floating'] = 'No' then begin
        DockHost := FindControl(Application.MainForm.Name, AConfig[Prefix + '\DockingHost']);
        if DockHost is TWinControl then AddDockPair(Control, TWinControl(DockHost));
      end;
    end;

    ApplyControlFont(Control, AConfig);

    if AConfig[Prefix + '\Visible'] = 'No'  then Control.Visible := False else
      if AConfig[Prefix + '\Visible'] = 'Yes' then Control.Visible := True;

    {$IFDEF USED_VIRTUAL_TREEVIEW}
    if ((Control is TVirtualStringTree) or (Control is TVirtualDrawTree)) and AConfig.Valid(Prefix + '\Header') then begin
      StrStream := TStringStream.Create(AConfig[Prefix + '\Header']);
      Garbage := CreateRefcountedContainer;
      Garbage.AddObject(StrStream);
      if Control is TVirtualStringTree then (Control as TVirtualStringTree).Header.LoadFromStream(StrStream);
      if Control is TVirtualDrawTree   then (Control as TVirtualDrawTree).Header.LoadFromStream(StrStream);
    end;
    {$ENDIF}

//    for i := 0 to Control.ComponentCount-1 do if Control.Components[i] is TControl then
//      ApplyControlsConfig(Control.Components[i] as TControl, AConfig);

  {  for i := 0 to Control.ComponentCount-1 do if Control.Components[i] is TControl then begin
      TempControl := Control.Components[i] as TControl;
      if AConfig.Valid(Prefix + '\' + Control.Components[i].Name + '\Left') then
        TempControl.Left   := MinI(Control.Width  - TempControl.Width, MaxI(0, AConfig.GetAsInteger(Prefix  + '\' + Control.Components[i].Name + '\Left')));
      if AConfig.Valid(Prefix + '\' + Control.Components[i].Name + '\Top') then
        TempControl.Top    := MinI(Control.Height - TempControl.Height, MaxI(0, AConfig.GetAsInteger(Prefix + '\' + Control.Components[i].Name + '\Top')));
      if AConfig.Valid(Prefix + '\' + Control.Components[i].Name + '\Width') then
        TempControl.Width  := MinI(Control.Width, MaxI(0, AConfig.GetAsInteger(Prefix  + '\' + Control.Components[i].Name + '\Width')));
      if AConfig.Valid(Prefix + '\' + Control.Components[i].Name + '\Height') then
        TempControl.Height := MinI(Control.Height, MaxI(0, AConfig.GetAsInteger(Prefix + '\' + Control.Components[i].Name + '\Height')));
    end;}
  end;

begin
  ApplyConfig(AControl);
  for i := Low(DockPairs) to High(DockPairs) do begin
//    DockPairs[i].Control.SetBounds(0, 0, DockPairs[i].Host.Width, DockPairs[i].Host.Height);
    Assert(DockPairs[i].Control = AControl);
    DockPairs[i].Control.ManualDock(DockPairs[i].Host);
    if not DockPairs[i].Control.Visible then begin
      DockPairs[i].Control.Show;
      DockPairs[i].Control.Hide;
    end;
    Prefix := AControl.Owner.Name + '\' + AControl.Name;

    if AConfig[Prefix +   '\Left'] <> '' then AControl.Left   := StrToIntDef(AConfig[Prefix + '\Left'], AControl.Left);
    if AConfig[Prefix +    '\Top'] <> '' then AControl.Top    := StrToIntDef(AConfig[Prefix +  '\Top'], AControl.Top );
    if AConfig[Prefix +  '\Width'] <> '' then AControl.Width  := MaxI(20, StrToIntDef(AConfig[Prefix + '\Width'],  AControl.Width ));
    if AConfig[Prefix + '\Height'] <> '' then AControl.Height := MaxI(20, StrToIntDef(AConfig[Prefix + '\Height'], AControl.Height))+2;    // ToDo: Why "+2" ???
  end;

  DockPairs := nil;
end;

procedure TVCLGUIHelper.ApplyFont(const Prefix: string; Font: TFont; AConfig: Props.TProperties);
begin
  if (Font = nil) or (AConfig = nil) then Exit;

  if AConfig.Valid(Prefix + 'Charset') then Font.Charset := StrToIntDef(AConfig[Prefix + 'Charset'], 0);
  if AConfig.Valid(Prefix + 'Color') then Font.Color := AConfig.GetAsInteger(Prefix + 'Color');
  if AConfig[Prefix +  'Name'] <> '' then Font.Name  := AConfig[Prefix + 'Name'];
  if AConfig.Valid(Prefix + 'Pitch') then Font.Pitch := TFontPitch(StrToIntDef(AConfig[Prefix + 'Pitch'], 0));
  if AConfig.Valid(Prefix + 'Size') then Font.Size := StrToIntDef(AConfig[Prefix + 'Size'], 0);
  Font.Style := [];
  if AConfig.Valid(Prefix + 'Style\Bold') and (AConfig.GetAsInteger(Prefix + 'Style\Bold') > 0) then
    Font.Style := Font.Style + [fsBold];
  if AConfig.Valid(Prefix + 'Style\Italic') and (AConfig.GetAsInteger(Prefix + 'Style\Italic') > 0) then
    Font.Style := Font.Style + [fsItalic];
  if AConfig.Valid(Prefix + 'Style\Underline') and (AConfig.GetAsInteger(Prefix + 'Style\Underline') > 0) then
    Font.Style := Font.Style + [fsUnderline];
  if AConfig.Valid(Prefix + 'Style\StrikeOut') and (AConfig.GetAsInteger(Prefix + 'Style\StrikeOut') > 0) then
    Font.Style := Font.Style + [fsStrikeOut];
end;

procedure TVCLGUIHelper.StoreForms(const FileName: string);
var i: Integer; Garbage: IRefcountedContainer; Stream: Basics.TStream; Config: Props.TProperties;
begin
  Stream := Basics.TFileStream.Create(FileName);
  Config := Props.TProperties.Create;
  Garbage := CreateRefcountedContainer;
  Garbage.AddObjects([Stream, Config]);
  for i := 0 to High(StoredControls) do StoreControlsConfig(StoredControls[i], Config);
  Config.Write(Stream);
end;

procedure TVCLGUIHelper.LoadForms(const FileName: string);
var i: Integer; Garbage: IRefcountedContainer; Stream: Basics.TStream; Config: Props.TProperties;
begin
  Stream := Basics.TFileStream.Create(FileName);
  Config := Props.TProperties.Create;
  Garbage := CreateRefcountedContainer;
  Garbage.AddObjects([Stream, Config]);
  Config.Read(Stream);
  for i := 0 to High(StoredControls) do ApplyControlsConfig(StoredControls[i], Config);
end;

type
  TMyControl = class(TControl)
  public
    property Caption;
    property Text;
  end;

procedure TVCLGUIHelper.StoreLocalizable(const FileName: string);

  procedure DoStore(AComp: TComponent; Config: Props.TProperties);
  var LName: string;
  begin
    if Assigned(AComp.Owner) and (AComp.Owner.Name <> '') then
      LName := AComp.Owner.Name + '.' + AComp.Name
    else
      LName := AComp.Name;

    if AComp is TCustomAction then begin
      if TCustomAction(AComp).Caption <> '' then Config.Add(LName + '.Caption', vtString, [], TCustomAction(AComp).Caption, '', '');
    end else if AComp is TControl then begin
      if TMyControl(AComp).Caption <> '' then Config.Add(LName + '.Caption', vtString, [], TMyControl(AComp).Caption, '', '');
      if TMyControl(AComp).Text    <> '' then Config.Add(LName + '.Text',    vtString, [], TMyControl(AComp).Text,    '', '');
      if TMyControl(AComp).Hint    <> '' then Config.Add(LName + '.Hint',    vtString, [], TMyControl(AComp).Hint,    '', '');
    end;
  end;

  procedure Traverse(AComp: TComponent; Config: Props.TProperties);
  var i: Integer;
  begin
    DoStore(AComp, Config);
    for i := 0 to AComp.ComponentCount - 1 do Traverse(AComp.Components[i], Config);
  end;

var Garbage: IRefcountedContainer; Config: Props.TNiceFileConfig;
begin
  Config := Props.TNiceFileConfig.Create(FileName);
  Config.Clear;
  Garbage := CreateRefcountedContainer;
  Garbage.AddObjects([Config]);
  Traverse(Application, Config);

  Config.Save();
end;

procedure TVCLGUIHelper.LoadLocalizable(const FileName: string);

  type TPropKind = (pkCaption, pkText, pkHint);

  procedure DoLoad(AComp: TComponent; PropKind: TPropKind; const Value: string);
  begin
    if Value = '' then Exit;

    if AComp is TCustomAction then begin
      if PropKind = pkCaption then TCustomAction(AComp).Caption := Value
    end else if AComp is TControl then begin
      case PropKind of
        pkCaption: TMyControl(AComp).Caption := Value;
        pkText:    TMyControl(AComp).Text    := Value;
        pkHint:    TMyControl(AComp).Hint    := Value;
      end;
    end;
  end;

  procedure Traverse(TotalParts: Integer; ANameParts: TStringArray; AComp: TComponent; const Value: string);
  var i: Integer;
  begin
    i := 0;
    repeat
      AComp := AComp.FindComponent(ANameParts[i]);
      if (AComp = nil) and (i = 0) then AComp := Application.MainForm.FindComponent(ANameParts[i]);     
      Inc(i);
    until (i >= TotalParts-1) or not Assigned(AComp);

    if not Assigned(AComp) then Exit;

    case UpCase(ANameParts[TotalParts-1][1]) of
      'C': DoLoad(AComp, pkCaption, Value);
      'T': DoLoad(AComp, pkText,    Value);
      'H': DoLoad(AComp, pkHint,    Value);
    end;
    
  end;

var
  i: Integer;
  Garbage: IRefcountedContainer;
  Config: Props.TNiceFileConfig;
  PropName: string;
  NameParts: TStringArray;
begin
  Config := Props.TNiceFileConfig.CreateFromFile(FileName);
  Garbage := CreateRefcountedContainer;
  Garbage.AddObjects([Config]);

  for i := 0 to Config.TotalProperties - 1 do begin
    PropName := Config.GetNameByIndex(i);
    Traverse(Split(PropName, '.', NameParts, True), NameParts, Application, Config[PropName]);
  end;
end;

procedure TVCLGUIHelper.ShowControl(const Name: string);
begin

end;

procedure TVCLGUIHelper.HideControl(const Name: string);
begin
  inherited;

end;

procedure TVCLGUIHelper.DisableControl(const Name: string);
begin
  inherited;

end;

procedure TVCLGUIHelper.EnableControl(const Name: string);
begin
  inherited;

end;

procedure TVCLGUIHelper.ToggleControl(const Name: string);
begin
  inherited;

end;

function TVCLGUIHelper.IsInputInProcess: Boolean;
var ActControl: TWinControl;
begin
  ActControl := Screen.ActiveControl;
  Result := (ActControl is TCustomEdit) or (ActControl.Handle <> GetFocus());   // Is edit control or focused a built-in editor
end;

{ TVCLStream }

procedure TVCLStream.SetStream(const Value: Basics.TStream);
begin
  FStream := Value;
  Assert(Assigned(Stream));
end;

function TVCLStream.GetSize: Int64;
begin
  Assert(Assigned(Stream));
  Result := Stream.Size;
end;

function TVCLStream.Read(var Buffer; Count: Integer): Longint;
begin
  Assert(Assigned(Stream));
  Result := Stream.Read(Buffer, Count);
end;

function TVCLStream.Write(const Buffer; Count: Integer): Longint;
begin
  Assert(Assigned(Stream));
  Result := Stream.Write(Buffer, Count);
end;

function TVCLStream.Seek(Offset: Integer; Origin: Word): Longint;
var NewPos: Int64;
begin
  Assert(Assigned(Stream));
  NewPos := Offset;
  case TSeekOrigin(Origin) of
    soCurrent: NewPos := Int64(Stream.Position) + Offset;
    soEnd: NewPos := Size + Offset;
  end;
  Stream.Seek(NewPos);
  Result := Stream.Position;
end;

{ TStreamFromVCL }

procedure TStreamFromVCL.SetStream(const Value: Classes.TStream);
begin
  Assert(Assigned(Value));
end;

function TStreamFromVCL.Seek(const NewPos: Cardinal): Boolean;
begin
  Result := FStream.Seek(NewPos, soBeginning) = NewPos;
end;

function TStreamFromVCL.Read(out Buffer; const Count: Cardinal): Cardinal;
begin
  Result := FStream.Read(Buffer, Count);
end;

function TStreamFromVCL.Write(const Buffer; const Count: Cardinal): Cardinal;
begin
  Result := FStream.Write(Buffer, Count);
end;

end.
