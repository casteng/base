(*
 Advanced GUI unit
 (C) 2006 George "Mirage" Bakhtadze.
 Unit contains advanced GUI controls
*)
{$Include GDefines.inc}
unit JVCLHelper;

interface

uses
  Basics, AppsInit, AppHelper, Props, GUIHelper, VCLHelper,
  Controls,
  JvPanel,
  SysUtils;

type
  TJVCLGUIHelper = class(TVCLGUIHelper)
  protected
    procedure StoreControlFont(Control: TControl; AConfig: TProperties); override;
    procedure ApplyControlFont(Control: TControl; AConfig: TProperties); override;
  end;

implementation

{ TJVCLGUIHelper }

procedure TJVCLGUIHelper.ApplyControlFont(Control: TControl; AConfig: TProperties);
var Prefix: string;
begin
  inherited;
  Prefix := Control.Owner.Name + '\' + Control.Name;
  if (Control is TJvPanel) and not (Control as TJvPanel).ParentFont then ApplyFont(Prefix+'\Font\', (Control as TJvPanel).Font, AConfig);
//  if (Control is TForm)  and (Control as TForm).ParentFont  then ApplyFont(Prefix+'\Font\', (Control as TForm).Font, AConfig);
end;

procedure TJVCLGUIHelper.StoreControlFont(Control: TControl; AConfig: TProperties);
var Prefix: string;
begin
  inherited;
  Prefix := Control.Owner.Name + '\' + Control.Name;
  if (Control is TJvPanel) and not (Control as TJvPanel).ParentFont then StoreFont(Prefix+'\Font\', (Control as TJvPanel).Font, AConfig);
//  if (Control is TForm)  and (Control as TForm).ParentFont  then StoreFont(Prefix+'\Font\', (Control as TForm).Font,  AConfig);
end;

end.
