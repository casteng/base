(*
 @Abstract(Applications Helper Unit)
 (C) 2006 George "Mirage" Bakhtadze.
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains advanced GUI controls
*)
{$Include GDefines.inc}
unit AppHelper;

interface

uses
  Logger,
  {$IFDEF SHAREWARE} RS2, {$ENDIF}
  BaseMsg, Basics, Props, AppsInit;

const
  // Extension of configuration file
  IniFileExtension = '.ini';
  // A name of property in config representing license name
  LicenseNameProp = 'License name';
  // A name of property in config representing license code
  LicenseCodeProp = 'License code';

type
  // Application actions. Usally actions are bond to input events specified by <b>ActivateBinding</b> and <b>DeactivateBinding</b>
  TAction = record
    Name, ActivateBinding, DeactivateBinding: string;
    Message: CMessage;
    Active: Boolean;
  end;

  { @Abstract(Base application class)
  }
  TApp = class
  private
    FStarter: TAppStarter;
    FConfig: TNiceFileConfig;
    function IsActionActive(const AName: string): Boolean;
  protected
    // Array of registered actions
    FActions: array of TAction;
    // Returns action index in array by its name or -1 if not found
    function GetActionIndex(const AName: string): Integer;
    // Active status of action by action name
    property Action[const Name: string]: Boolean read IsActionActive;
  public
    // Config to store license information
    KeyCfg: TProperties;

    {$IFDEF SHAREWARE}
    // A number which determines a random chain used to generate license keys
    RandomChain: Cardinal;
    {$ENDIF}

    // Create an application with the specified name using the specified starter
    constructor Create(const AProgramName: string; AStarter: TAppStarter); virtual;
    // Destroy the application
    destructor Destroy; override;

    // Returns <b>True</b> if a trial restrictions should be applied to the application
    function IsTrial: Boolean; virtual;
    {$IFDEF SHAREWARE}
    // Extracts a license name and code from a string by signatures
    function ExtractLicense(s: string; out Name, Code: string): Boolean;
    {$ENDIF}

    // Application starter
    property Starter: TAppStarter read FStarter;
    // Application configuration 
    property Config: TNiceFileConfig read FConfig;
  end;

implementation

uses SysUtils;

{ TApp }

// Private

function TApp.GetActionIndex(const AName: string): Integer;
begin
  for Result := 0 to High(FActions) do if FActions[Result].Name = AName then Exit;
  Result := -1;
end;

function TApp.IsActionActive(const AName: string): Boolean;
var Index: Integer;
begin
  Result := False;
  Index := GetActionIndex(AName);
  if (Index = -1) or (FActions[Index].DeactivateBinding = '') then begin
    Log(ClassName + '.IsActive: Action "' + AName + '" not found or does not have activation semantics', lkWarning);
    Exit;
  end;
  Result := FActions[Index].Active;
end;

constructor TApp.Create(const AProgramName: string; AStarter: TAppStarter);
begin
  FStarter := AStarter;
  FConfig  := TNiceFileConfig.CreateFromFile(IncludeTrailingPathDelimiter(Starter.ProgramWorkDir) + AStarter.ProgramExeName + IniFileExtension);
end;

{$IFDEF SHAREWARE}
function TApp.ExtractLicense(s: string; out Name, Code: string): Boolean;
var i: Integer; 
begin
  Result := False;
  s := UpperCase(s);
  for i := 0 to TotalLicCodeSignatures-1 do begin
    {$IFNDEF PORTALBUILD}
    Name := ExtractStr(s, UpperCase(NameSigs[i]));
    if Name = '' then Continue;
    {$ENDIF}
    Code := ExtractStr(s, UpperCase(KeySigs[i]));
    if Code <> '' then Break;
  end;
  Result := Code <> '';
end;
{$ENDIF}

destructor TApp.Destroy;
begin
  FreeAndNil(FConfig);
  Starter.Terminate;
end;

function TApp.IsTrial: Boolean;
begin
  {$IFDEF SHAREWARE}
  Result := not RS2.VC(KeyCfg[LicenseNameProp], KeyCfg[LicenseCodeProp], RandomChain);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

end.