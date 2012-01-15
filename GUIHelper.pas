(*
 @Abstract(GUI helper unit)
 (C) 2006 George "Mirage" Bakhtadze <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains abstract (independent of GUI library used) helper classes for GUI applications
*)
{$Include GDefines.inc}
unit GUIHelper;

interface

uses
  Logger,
  SysUtils,
  BaseMsg,
  Props, BaseClasses;

const
  TotalImmediateApplyControls = 3;
  ImmediateApplyControls: array[0..TotalImmediateApplyControls-1] of string =
   ('Gamma', 'Contrast', 'Brightness');
  TotalNotifyingApplyControls = 1;
  NotifyingApplyControls: array[0..TotalNotifyingApplyControls-1] of string =
   ('UserName');
  FormNamesCapacityStep = 1;
  // On click predefined actions
  TotalActions = 9;
  aShow = 0; aShowSolely = 1; aToggle = 2; aClose = 3; aOK = 4; aApply = 5; aCancel = 6; aReset = 7; aBack = 8;
  ActionStr: array[0..TotalActions-1] of string = ('Show', 'Invoke', 'Toggle', 'Close', 'OK', 'Apply', 'Cancel', 'Reset', 'Back');

type
  TGUIHelper = class
  protected
    procedure ControlToConfig(const FormName, OptionName: string; AConfig: Props.TProperties); virtual; abstract;
    procedure ConfigToControl(const FormName, OptionName: string; AConfig: Props.TProperties); virtual; abstract;
  public
    DefaultConfig: Props.TProperties;                                      // Default config used for resetting
    procedure HandleMessage(const Msg: TMessage); virtual; abstract;
    // Items manipulation
    function ControlExists(const Name: string): Boolean; virtual; abstract;
    function IsControlVisible(const Name: string; CheckHierarchy: Boolean): Boolean; virtual; abstract;
    procedure ShowControl(const Name: string); virtual; abstract;
    procedure HideControl(const Name: string); virtual; abstract;
    procedure ToggleControl(const Name: string); virtual; abstract;  // Toggles item's visibility
    procedure EnableControl(const Name: string); virtual; abstract;
    procedure DisableControl(const Name: string); virtual; abstract;
    procedure SetControlText(const Name, Text: string); virtual; abstract;
    function GetControlText(const Name: string): string; virtual; abstract;
    function GetControlFormName(const Name: string): string; virtual; abstract;
    // Properties filling
    procedure ConfigToForm(const FormName: string; AConfig: Props.TProperties); virtual;
    procedure FormToConfig(const FormName: string; AConfig: Props.TProperties); virtual;
    procedure ItemToForm(const FormName: string; AItem: TItem);
    procedure FormToItem(const FormName: string; AItem: TItem);
    procedure ResetConfig(const FormName: string; ADefaultConfig: Props.TProperties); virtual;
    // Returns True if a user input is in process in some edit control
    function IsInputInProcess(): Boolean; virtual; abstract;
  end;

implementation

{ TGUIHelper }

procedure TGUIHelper.ConfigToForm(const FormName: string; AConfig: Props.TProperties);
var i: Integer;
begin
  for i := 0 to AConfig.TotalProperties-1 do ConfigToControl(FormName, AConfig.GetNameByIndex(i), AConfig);
end;

procedure TGUIHelper.FormToConfig(const FormName: string; AConfig: Props.TProperties);
var i: Integer;
begin
  for i := 0 to AConfig.TotalProperties-1 do ControlToConfig(FormName, AConfig.GetNameByIndex(i), AConfig);
end;

procedure TGUIHelper.ItemToForm(const FormName: string; AItem: TItem);
var Props: TProperties;
begin
  Props := TProperties.Create;
  AItem.GetProperties(Props);
  ConfigToForm(FormName, Props);
  Props.Free;
end;

procedure TGUIHelper.FormToItem(const FormName: string; AItem: TItem);
var Props: TProperties;
begin
  Props := TProperties.Create;
  AItem.GetProperties(Props);
  FormToConfig(FormName, Props);
  AItem.SetProperties(Props);
  Props.Free;
end;

procedure TGUIHelper.ResetConfig(const FormName: string; ADefaultConfig: Props.TProperties);
begin
  if (ADefaultConfig = nil) or not ControlExists(FormName) then Exit;
  ConfigToForm(FormName, ADefaultConfig);
end;

end.
