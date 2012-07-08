(*
 @Abstract(ACS GUI library unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains simple GUI controls
*)
{$Include GDefines.inc}
unit ACS;

interface

uses
  SysUtils,
  Logger,
  ACSBase, 
  BaseTypes, Basics, Base3D, BaseGraph, BaseClasses, BaseMsg, Props, GUIFitter;

type
  TValueDelegate = function(Caller: TGUIItem): Integer of object;

  TGUIPoint = class(TGUIItem)
  end;

  TGUILine = class(TGUIItem)
    procedure Draw; override;
  end;

  TLabel = class(TTextGUIItem)
    procedure Draw; override;
  end;

  TPanel = class(TUVGUIItem)
    procedure Draw; override;
  end;

  TButton = class(TPanel)
  protected
    procedure UpdateVisualParameters; override;
  end;

  TSwitchButton = class(TButton)
  private
    BaseFrame: Integer;
    FVariantIndex, TotalVariants: Integer;
    procedure SetVariantIndex(const Value: Integer); virtual;
  public
    function GUIHandleMessage(const Msg: TMessage): Boolean; override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    property VariantIndex: Integer read FVariantIndex write SetVariantIndex;
  end;

  TCheckBox = class(TButton)
  private
    BaseFrame: Integer;
    FChecked: Boolean;
    procedure SetChecked(const Value: Boolean);
  public
    function GUIHandleMessage(const Msg: TMessage): Boolean; override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    procedure Draw; override;

    property Checked: Boolean read FChecked write SetChecked;
  end;

  TTrackBar = class(TUVGUIItem)
  private
    FMinValue, FMaxValue: Integer;

    FValue: Integer;
    BarColor: BaseTypes.TColor;
    BarFrame: Integer;
    Vertical: Boolean;

    procedure SetMinValue(const Value: Integer);
    procedure SetMaxValue(const Value: Integer);
    procedure SetValue(const Value: Integer);
    function GetMaxValue: Integer;
    function GetMinValue: Integer;
    function GetValue: Integer;
  public
    OnGetMinValue, OnGetMaxValue, OnGetValue: TValueDelegate;         // Used instead of fields if assigned

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    property MinValue: Integer read GetMinValue write SetMinValue;
    property MaxValue: Integer read GetMaxValue write SetMaxValue;
    property Value: Integer read GetValue write SetValue;
  end;

  TProgressBar = class(TTrackBar)
    procedure Draw; override;
  end;

  TSlider = class(TTrackBar)
  private
    BarSize, SliderSize: Single;
  public
    function GUIHandleMessage(const Msg: TMessage): Boolean; override;
    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;
    procedure Draw; override;
  end;

  TEdit = class(TPanel)
  private
    Changed: Boolean;
    function GetTextItem: TTextGUIItem;
    function GetText: string;
    procedure SetText(const Value: string);
  public
    MaxLength: Integer;
    FocusedLinesColor, CursorColor: BaseTypes.TColor;
    Counter: Longword;
    CursorHeight: Single;
    constructor Create(AManager: TItemsManager); override;
    constructor Construct(AManager: TItemsManager); override;
    function GUIHandleMessage(const Msg: TMessage): Boolean; override;
    procedure Process(const DeltaT: Float); override;
    procedure Draw; override;
    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;
    property Text: string read GetText write SetText;
  end;

  TCursorPicture = class(TGUIItem)
  private
    HotX, HotY: Single;
    WindowX1, WindowY1, WindowX2, WindowY2: Single;
    procedure CheckPosition;
  public
    function GUIHandleMessage(const Msg: TMessage): Boolean; override;

    procedure AddProperties(const Result: Props.TProperties); override;
    procedure SetProperties(Properties: Props.TProperties); override;

    procedure SetWindow(const X1, Y1, X2, Y2: Single); virtual;
  end;

  TCaptionArea = class(TGUIItem)
    procedure HandleMessage(const Msg: TMessage); override;
  end;

  TClientArea = class(TGUIItem)
    procedure HandleMessage(const Msg: TMessage); override;
  end;

  TWindow = class(TGUIItem)
  private
    CaptionArea: TCaptionArea;
    ClientArea: TClientArea;
  public
    constructor Create(AManager: TItemsManager); override;
    constructor Construct(AManager: TItemsManager); override;

    function SetChild(Index: Integer; AItem: TItem): TItem; override;

    procedure Draw; override;
    procedure Process(const DeltaT: Float); override;
  end;

  // Returns list of classes introduced by the unit
  function GetUnitClassList: TClassArray;

implementation

uses GUIMsg;

function GetUnitClassList: TClassArray;
begin
  Result := GetClassList([TGUIItem, TGUIRootItem,
                          T2DFitter,
                          TGUIPoint, TGUILine, TCursorPicture,
                          TLabel, TPanel, TButton, TSwitchButton, TCheckBox,
                          TProgressBar, TSlider, TEdit,
                          TWindow, TCaptionArea, TClientArea
                          ]);
end;

{ TGUILine }

procedure TGUILine.Draw;
var i, PCnt: Integer; Point: TGUIPoint;
begin
  inherited;
  PCnt := 0;
  for i := 0 to TotalChilds-1 do if (Childs[i] is TGUIPoint) and (isVisible in Childs[i].State) then begin
    Point := Childs[i] as TGUIPoint;
    Screen.SetColor(Point.Color);
    if PCnt = 0 then Screen.MoveTo(Point.PxX, Point.PxY) else Screen.LineTo(Point.PxX, Point.PxY);
    Inc(PCnt);
  end;
end;

{ TLabel }

procedure TLabel.Draw;
begin
  inherited;
  Screen.SetColor(Color);
  Screen.SetFont(Font);

  DrawText(0, 0);
end;

{ TPanel }

procedure TPanel.Draw;
begin
  inherited;
  Screen.SetColor(Color);
  Screen.SetUV(UVMap^[Frame]);
  Screen.Bar(0, 0, PxWidth, PxHeight);
  Screen.SetUV(DefaultUV);
end;

{ TButton }

procedure TButton.UpdateVisualParameters;
begin
  inherited;
{  if csPressed in GetStatesSource.ControlState then begin
    if GetStatesSource.GetHover then begin
      Color := PressedColor;
      if frPressed in UsedFrames then
        Frame := NormalFrame + Ord(frHover in UsedFrames) + Ord(frFocused in UsedFrames) + Ord(frDisabled in UsedFrames) + 1;
    end;
  end else Frame := NormalFrame + Ord(frHover in UsedFrames) * Ord(GetStatesSource.GetHover);}
end;

{ TSwitchButton }

procedure TSwitchButton.SetVariantIndex(const Value: Integer);
begin
  if Value = FVariantIndex then Exit;
  if (Value >= 0) and (Value < TotalVariants) then FVariantIndex := Value;
  NormalFrame := BaseFrame + (Ord(frHover in UsedFrames) + Ord(frPushed in UsedFrames) + Ord(frFocused in UsedFrames) + Ord(frDisabled in UsedFrames) + 1) * VariantIndex;
  Frame := NormalFrame;
  UpdateVisualParameters;
  if isVisibleAndEnabled then ReturnMessage(TGUIChangeMsg.Create(Self));
end;

function TSwitchButton.GUIHandleMessage(const Msg: TMessage): Boolean;
begin
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;

  if Msg.ClassType = TMouseClickMsg then with TMouseClickMsg(Msg) do begin
    if (Button = mbLeft) and Hover then
      if VariantIndex < TotalVariants-1 then
        VariantIndex := VariantIndex + 1
      else
        VariantIndex := 0;
  end;
end;

procedure TSwitchButton.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  Result.Add('Base frame',     vtInt, [], IntToStr(BaseFrame),     '');
  Result.Add('Variant index',  vtInt, [], IntToStr(VariantIndex),  '');
  Result.Add('Total variants', vtInt, [], IntToStr(TotalVariants), '');
end;

procedure TSwitchButton.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Properties.Valid('Base frame')     then BaseFrame     := StrToIntDef(Properties['Base frame'],     0);
  if Properties.Valid('Variant index')  then VariantIndex  := StrToIntDef(Properties['Variant index'],  0);
  if Properties.Valid('Total variants') then TotalVariants := StrToIntDef(Properties['Total variants'], 0);

  UpdateVisualParameters;
  VariantIndex := VariantIndex;
end;

{ TCheckBox }

procedure TCheckBox.SetChecked(const Value: Boolean);
begin
  if FChecked = Value then Exit;
  FChecked := Value;
  NormalFrame := BaseFrame + (Ord(frHover in UsedFrames) + Ord(frPushed in UsedFrames) + Ord(frFocused in UsedFrames) + Ord(frDisabled in UsedFrames) + 1) * Ord(Checked);
  Frame := NormalFrame;
  UpdateVisualParameters;
  if isVisibleAndEnabled then ReturnMessage(TGUIChangeMsg.Create(Self));
end;

function TCheckBox.GUIHandleMessage(const Msg: TMessage): Boolean;
begin
  Result := inherited GUIHandleMessage(Msg);
  if Hover and (Msg.ClassType = TMouseClickMsg) and (TMouseClickMsg(Msg).Button = mbLeft) then
    Checked := not Checked;
end;

procedure TCheckBox.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  Result.Add('Base frame',     vtInt,     [], IntToStr(BaseFrame),     '');
  Result.Add('Checked',        vtBoolean, [], OnOffStr[Checked],       '');
end;

procedure TCheckBox.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Properties.Valid('Base frame') then BaseFrame := StrToIntDef(Properties['Base frame'], 0);
  if Properties.Valid('Checked')    then Checked   := Properties.GetAsInteger('Checked') > 0;

  UpdateVisualParameters;
end;

procedure TCheckBox.Draw;
begin
  inherited;
end;

{ TWindow }

constructor TWindow.Create(AManager: TItemsManager);
begin
  inherited;
end;

constructor TWindow.Construct(AManager: TItemsManager);
begin
  inherited;
  CaptionArea := TCaptionArea.Create(AManager);
//  CaptionArea.Name := 'CaptionArea';
  ClientArea := TClientArea.Create(AManager);
//  ClientArea.Name := 'ClientArea';
  AddChild(CaptionArea);
  AddChild(ClientArea);
end;

procedure TWindow.Draw;
begin
  inherited;
  Screen.SetColor(Color);
  Screen.MoveTo(-0*PxWidth * 0.5, -0*PxHeight * 0.5);
  Screen.LineTo(   PxWidth * 1,   -0*PxHeight * 0.5);
  Screen.LineTo(   PxWidth * 1,      PxHeight * 1);
  Screen.LineTo(-0*PxWidth * 0.5,    PxHeight * 1);
  Screen.LineTo(-0*PxWidth * 0.5, -0*PxHeight * 0.5);
end;

procedure TWindow.Process(const DeltaT: Float);
begin
  inherited;
//  Angle := Angle + 30*pi/180;
end;

function TWindow.SetChild(Index: Integer; AItem: TItem): TItem;

procedure SetArea(var AreaItem: TGUIItem; NewAreaItem: TGUIItem);
begin
  if AreaItem = NewAreaItem then Exit;
  if AreaItem <> nil then FreeAndNil(AreaItem);
  AreaItem := NewAreaItem;
end;

begin
//  Assert((Index <= 1) and (AItem is TClientArea), ClassName + '.SetChild: Only two childs of class TClientArea allowed');
//  Result := nil;
//  if (Index > 1) or not (AItem is TClientArea) then Exit;
  Result := inherited SetChild(Index, AItem);
  case Index of
    0: if (CaptionArea <> AItem) and (AItem is TCaptionArea) then begin
      if CaptionArea <> nil then FreeAndNil(CaptionArea);
      CaptionArea := AItem as TCaptionArea;
    end;
    1: if (ClientArea <> AItem) and (AItem is TClientArea) then begin
      if ClientArea <> nil then FreeAndNil(ClientArea);
      ClientArea := AItem as TClientArea;
    end;
  end;
end;

{ TCursorPicture }

procedure TCursorPicture.CheckPosition;
var WX1, WY1, WX2, WY2: Single;
begin
  Exit;
  if WindowX1 = 0 then WX1 := -HotX else WX1 := WindowX1-HotX;
  if WindowY1 = 0 then WY1 := -HotY else WY1 := WindowY1-HotY;
  if WindowX2 = 0 then WX2 := Screen.Width-1-HotX  else WX2 := WindowX2-HotX;
  if WindowY2 = 0 then WY2 := Screen.Height-1-HotY else WY2 := WindowY2-HotY;
  X := MinS(MaxS(X, WX1), WX2) + 0.5;
  Y := MinS(MaxS(Y, WY1), WY2) + 0.5;
end;

function TCursorPicture.GUIHandleMessage(const Msg: TMessage): Boolean;
begin
  Enabled := False;                            // To prevent mouse occlusion
  Result := inherited GUIHandleMessage(Msg);
  Enabled := True;
  if not Result then Exit;

  if (Msg.ClassType = TMouseMoveMsg) then with TMouseMoveMsg(Msg) do begin
    Self.X := X - HotX;
    Self.Y := Y - HotY;
    CheckPosition;
  end;
end;

procedure TCursorPicture.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  Result.Add('Hot X', vtSingle, [], FloatToStr(HotX), '');
  Result.Add('Hot Y', vtSingle, [], FloatToStr(HotY), '');
end;

procedure TCursorPicture.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Properties.Valid('Hot X') then HotX := StrToFloatDef(Properties['Hot X'], 0);
  if Properties.Valid('Hot Y') then HotX := StrToFloatDef(Properties['Hot Y'], 0);
end;

procedure TCursorPicture.SetWindow(const X1, Y1, X2, Y2: Single);
begin
  WindowX1 := X1; WindowY1 := Y1; WindowX2 := X2; WindowY2 := Y2;
  if WindowX1 > WindowX2 then Swap(WindowX1, WindowX2);
  if WindowY1 > WindowY2 then Swap(WindowY1, WindowY2);
  CheckPosition;
end;

{ TCaptionArea }

procedure TCaptionArea.HandleMessage(const Msg: TMessage);
begin
  inherited;
  if Msg.ClassType = TWindowResizeMsg then with TWindowResizeMsg(Msg) do begin
    PxWidth :=  NewWidth;
    PxX     := -NewWidth*0.5;
    PxY     := -NewHeight*0.5 - PxHeight;
  end;
end;

{ TClientArea }

procedure TClientArea.HandleMessage(const Msg: TMessage);
begin
  inherited;
  if Msg.ClassType = TWindowResizeMsg then with TWindowResizeMsg(Msg) do begin
    PxWidth  :=  NewWidth;
    PxHeight :=  NewHeight;
    PxX      := -NewWidth*0.5;
    PxY      := -NewHeight*0.5;
  end;
end;

{ TTrackBar }

function TTrackBar.GetMinValue: Integer;
begin
  if Assigned(OnGetMinValue) then FMinValue := OnGetMinValue(Self);
  Result := FMinValue;
end;

function TTrackBar.GetMaxValue: Integer;
begin
  if Assigned(OnGetMaxValue) then FMaxValue := OnGetMaxValue(Self);
  Result := FMaxValue;
end;

function TTrackBar.GetValue: Integer;
begin
  if Assigned(OnGetValue) then FValue := OnGetValue(Self);
  Result := FValue;
end;

procedure TTrackBar.SetMinValue(const Value: Integer);
begin
  FMinValue := MinI(MaxValue, Value);
end;

procedure TTrackBar.SetMaxValue(const Value: Integer);
begin
  FMaxValue := MaxI(MinValue, Value);
end;

procedure TTrackBar.SetValue(const Value: Integer);
var OldValue: Integer;
begin
  OldValue := FValue;
  FValue := MaxI(MinValue, MinI(MaxValue, Value));
  if (OldValue <> FValue) and isVisibleAndEnabled then ReturnMessage(TGUIChangeMsg.Create(Self));
//  FValue := Value;
end;

procedure TTrackBar.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;

  Result.Add('Value',        vtInt,     [], IntToStr(FValue),   '');
  Result.Add('Value\Min',    vtInt,     [], IntToStr(MinValue), '');
  Result.Add('Value\Max',    vtInt,     [], IntToStr(MaxValue), '');
  AddColorProperty(Result, 'Color\Bar', BarColor);
  Result.Add('UV\Bar frame', vtInt,     [], IntToStr(BarFrame),          '');
  Result.Add('Vertical',     vtBoolean, [], OnOffStr[Vertical],          '');
end;

procedure TTrackBar.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Properties.Valid('Value\Min')    then MinValue := StrToIntDef(Properties['Value\Min'], 0);
  if Properties.Valid('Value\Max')    then MaxValue := StrToIntDef(Properties['Value\Max'], 0);
  if Properties.Valid('Value')        then Value    := StrToIntDef(Properties['Value'],     0);
  SetColorProperty(Properties, 'Color\Bar', BarColor);
  if Properties.Valid('UV\Bar frame') then BarFrame := StrToIntDef(Properties['UV\Bar frame'], 0);
  if Properties.Valid('Vertical')     then Vertical := Properties.GetAsInteger('Vertical') > 0;
end;

{ TProgressBar }

procedure TProgressBar.Draw;
var Temp: Single; UV: TUV;
begin
  inherited;

  if MaxValue = 0 then Temp := 0 else Temp := Value / MaxValue;

  if Vertical then begin
    UV.U := UVMap^[Frame].U; UV.W := UVMap^[Frame].W;
    UV.V := UVMap^[Frame].V; UV.H := UVMap^[Frame].H * (1-Temp);
    Screen.SetUV(UV);
    Screen.SetColor(Color);
    Screen.Bar(0, 0, PxWidth, PxHeight - PxHeight * Temp);

    UV.U := UVMap^[BarFrame].U; UV.W := UVMap^[BarFrame].W;
    UV.V := UVMap^[BarFrame].V + UVMap^[BarFrame].H * (1-Temp); UV.H := UVMap^[BarFrame].H * Temp;
    Screen.SetUV(UV);
    Screen.SetColor(BarColor);
    Screen.Bar(0, PxHeight - PxHeight * Temp, PxWidth, PxHeight);
  end else begin
    UV.U := UVMap^[Frame].U; UV.W := UVMap^[Frame].W * Temp;
    UV.V := UVMap^[Frame].V; UV.H := UVMap^[Frame].H;
    Screen.SetUV(UV);
    Screen.SetColor(Color);
    Screen.Bar(0, 0, PxWidth * Temp, PxHeight);

    UV.U := UVMap^[BarFrame].U + UVMap^[BarFrame].W * Temp; UV.W := UVMap^[BarFrame].W * (1 - Temp);
    UV.V := UVMap^[BarFrame].V; UV.H := UVMap^[BarFrame].H;
    Screen.SetUV(UV);
    Screen.SetColor(BarColor);
    Screen.Bar(PxWidth * Temp, 0, PxWidth, PxHeight);
  end;
  Screen.SetUV(DefaultUV);
end;

{ TSlider }

function TSlider.GUIHandleMessage(const Msg: TMessage): Boolean;
var MX, MY: Single;
begin
  if (Msg.ClassType = TMouseMoveMsg) then with TMouseMoveMsg(Msg) do begin
    MX := X; MY := Y;
  end;
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;

  if (Msg.ClassType = TMouseMoveMsg) then with TMouseMoveMsg(Msg) do begin
    if Pushed {and GetHover} then begin
      ScreenToClient(MX, MY);
      if Vertical then
        Value := Trunc(0.5 + MY / PxHeight * MaxValue) else
          Value := Trunc(0.5 + MX / PxWidth * MaxValue);
      UpdateVisualParameters;
    end;
  end;
  if Msg.ClassType = TMouseDownMsg then with TMouseDownMsg(Msg) do begin
    if (Button = mbLeft) and Hover then begin
      Pushed := True;
      UpdateVisualParameters;
    end;
  end;
  if Msg.ClassType = TMouseUpMsg then with TMouseDownMsg(Msg) do begin
    if (Button = mbLeft) then begin
      Pushed := False;
      UpdateVisualParameters;
    end;
  end;
end;

procedure TSlider.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;
  Result.Add('Bar size',    vtSingle, [], FloatToStr(BarSize),    '');
  Result.Add('Slider size', vtSingle, [], FloatToStr(SliderSize), '');
end;

procedure TSlider.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Properties.Valid('Bar size')    then BarSize    := StrToFloatDef(Properties['Bar size'],    0);
  if Properties.Valid('Slider size') then SliderSize := StrToFloatDef(Properties['Slider size'], 0);
end;

procedure TSlider.Draw;
var Temp: Single;
begin
  inherited;

  if MaxValue = 0 then Temp := 0 else Temp := Value / MaxValue;

  if Vertical then begin
    Screen.SetUV(UVMap^[BarFrame]);
    Screen.SetColor(BarColor);
    Screen.Bar((PxWidth - BarSize) * 0.5, 0, (PxWidth + BarSize) * 0.5, PxHeight);

    Screen.SetUV(UVMap^[Frame]);
    Screen.SetColor(Color);
    Screen.Bar((PxWidth - SliderSize)*0.5, PxHeight * Temp - SliderSize*0.5, (PxWidth + SliderSize)*0.5, PxHeight * Temp + SliderSize*0.5);
  end else begin
    Screen.SetUV(UVMap^[BarFrame]);
    Screen.SetColor(BarColor);
    Screen.Bar(0, (PxHeight - BarSize) * 0.5, PxWidth, (PxHeight + BarSize) * 0.5);

    Screen.SetUV(UVMap^[Frame]);
    Screen.SetColor(Color);
    Screen.Bar(PxWidth * Temp - SliderSize*0.5, (PxHeight - SliderSize)*0.5, PxWidth * Temp + SliderSize*0.5, (PxHeight + SliderSize)*0.5);
  end;
  Screen.SetUV(DefaultUV);
end;

 { TEditor }

function TEdit.GetTextItem: TTextGUIItem;
var Item: TItem;
begin
  Item := GetChildByName('Text', False);
  if not (Item is TTextGUIItem) then begin
     Log(ClassName + '.GetTextItem: Can''t find a child item of class descendant from TTextGUIItem', lkError); 
    Result := nil;
  end else Result := TTextGUIItem(Item);
end;

function TEdit.GetText: string;
begin
  if GetTextItem <> nil then Result := GetTextItem.Text else Result := '';
end;

procedure TEdit.SetText(const Value: string);
begin
//  Changed := Changed or (Value <> Text);
  if GetTextItem <> nil then GetTextItem.Text := Value;
end;

constructor TEdit.Create(AManager: TItemsManager);
begin
  inherited;
  CanFocus := True;
  CursorHeight := 2;
  MaxLength := 255;
end;

constructor TEdit.Construct(AManager: TItemsManager);
begin
  inherited;
  AddChild(TLabel.Construct(AManager)).Name := 'Text';  
end;

function TEdit.GUIHandleMessage(const Msg: TMessage): Boolean;
begin
  Result := inherited GUIHandleMessage(Msg);
  if not Result then Exit;

  if Focused and (Msg.ClassType = TCharInputMsg) then with TCharInputMsg(Msg) do begin
    if Character = #8 then begin
      if (Length(Text) > 0) then begin
        Text := Copy(Text, 0, Length(Text)-1);
        Changed := True;
      end;
    end else if not (Character in [#9, #13, #27]) then Text := Text + Character;
  end;
end;

procedure TEdit.AddProperties(const Result: Props.TProperties);
begin
  inherited;
  if not Assigned(Result) then Exit;
  Result.Add('Max length',          vtInt,   [], IntToStr(MaxLength), '');
  AddColorProperty(Result, 'Color\Focused lines', FocusedLinesColor);
end;

procedure TEdit.SetProperties(Properties: Props.TProperties);
begin
  inherited;
  if Properties.Valid('Max length')          then MaxLength         := StrToIntDef(Properties['Max length'], 0);
  SetColorProperty(Properties, 'Color\Focused lines', FocusedLinesColor);
end;

procedure TEdit.Process(const DeltaT: Float);
begin
  inherited;
  if Odd(Round(TimeProcessed*2)) then CursorColor.C := $FF000000 else CursorColor.C := $FFFFFFFF;
end;

procedure TEdit.Draw;
var TextItem: TTextGUIItem; CursorX2, CursorW, TextWidth, TextHeight: Single;
begin
  inherited;
  if Focused then begin
    TextItem := GetTextItem;
    if TextItem.Font = nil then Exit;
    Screen.SetColor(CursorColor);

    TextItem.Font.GetTextExtent(Text, TextWidth, TextHeight);

    CursorW  := MaxS(1, MinS(PxWidth, PxHeight * 0.5));
    if TextItem.X + TextWidth < 0 then begin
      TextItem.X := Trunc(0.5 + MinS(0, TextItem.X - TextItem.X - TextWidth + PxWidth*0.5)) + Frac(TextItem.X);
    end;
    CursorX2 := TextItem.X + TextWidth + CursorW;
    if CursorX2 > PxWidth then begin
      TextItem.X := Trunc(0.5 + TextItem.X - (CursorX2 - PxWidth)) + Frac(TextItem.X);
      CursorX2   := CursorX2   - (CursorX2 - PxWidth);
    end;
// Draw cursor
    Screen.Bar(TextItem.X + TextWidth, TextItem.Y + PxHeight - 1 - CursorHeight,
               CursorX2, TextItem.Y + PxHeight - 1);
  end;
end;

begin
  GlobalClassList.Add('ACS', GetUnitClassList);
end.
