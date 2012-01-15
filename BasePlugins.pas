(*
 @Abstract(Basic plugins interface unit)
 (C) 2006-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 Created: Aug 17, 2007 <br>
 Unit contains base plugin interface class
*)
unit BasePlugins;

interface

type
  TLoadPluginResult = (lpOK, lpLoadPackageFail, lpRegisterNotCalled);

  TClasses = array of TClass;
  
  TPackageInfo = record
    Name, FileName, Description: string;
    Handle: HModule;
    ClassesAdded: TClasses;
  end;

  TPluginSystem = class
  private
    LoadedPackages: array of TPackageInfo;
    RegisterPluginCalled: Boolean;
    function GetPlugin(Index: Integer): TPackageInfo;
    function GetTotalPlugins: Integer;
  protected
    /// Called by RegisterPlugin
    procedure RegisterClasses(AClasses: array of TClass); virtual; abstract;
  public
    /// Called by an application to load a plugin
    function LoadPlugin(const FileName: string): TLoadPluginResult;
    /// Should be called by a plugin from its initialization part to register itself
    procedure RegisterPlugin(const AName, ADescription: string; AClasses: array of TClass);

    property TotalPlugins: Integer read GetTotalPlugins;
    property Plugin[Index: Integer]: TPackageInfo read GetPlugin;
  end;

var
  PluginSystem: TPluginSystem;

implementation

uses SysUtils;

{ TC2EdPluginSystem }

function TPluginSystem.GetPlugin(Index: Integer): TPackageInfo;
begin
  Assert((Index >= 0) and (Index < TotalPlugins), 'TPluginSystem.GetPlugin: Invalid index');
  if (Index < 0) or (Index >= TotalPlugins) then Exit;

  Result := LoadedPackages[Index];
end;

function TPluginSystem.GetTotalPlugins: Integer;
begin
  Result := Length(LoadedPackages);
end;

function TPluginSystem.LoadPlugin(const FileName: string): TLoadPluginResult;
var Handle: HModule;
begin
  try
    RegisterPluginCalled := False;
    Handle := LoadPackage(FileName);
  except
    Handle := 0;
  end;

  if Handle = 0 then Result := lpLoadPackageFail else
    if not RegisterPluginCalled then Result := lpRegisterNotCalled else
      Result := lpOK;

  if Result = lpOK then begin
    LoadedPackages[High(LoadedPackages)].Handle   := Handle;
    LoadedPackages[High(LoadedPackages)].FileName := FileName;
  end;
end;

procedure TPluginSystem.RegisterPlugin(const AName, ADescription: string; AClasses: array of TClass);
var i: Integer;
begin
  SetLength(LoadedPackages, Length(LoadedPackages)+1);
  RegisterPluginCalled := True;
  LoadedPackages[High(LoadedPackages)].Name         := AName;
  LoadedPackages[High(LoadedPackages)].Description  := ADescription;
  SetLength(LoadedPackages[High(LoadedPackages)].ClassesAdded, Length(AClasses));
  for i := 0 to High(AClasses) do LoadedPackages[High(LoadedPackages)].ClassesAdded[i] := AClasses[i];
  RegisterClasses(LoadedPackages[High(LoadedPackages)].ClassesAdded);
end;

initialization
finalization
  FreeAndNil(PluginSystem);
end.
