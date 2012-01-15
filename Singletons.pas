(*
 Singletons unit
 (C) 2006 Mirage
 Created May 25, 2006
 The unit contains base singleton class. Any descendant class will have a singleton-like behaviour
*)
{$Include GDefines}
unit Singletons;

interface

type
  TSingleton = class
    procedure Init; virtual;
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
  end;

implementation

type
  TSingletonEntry = record
    Instance: TObject;
  end;

var
  SingletonEntries: array of TSingletonEntry;

function FindSingletonEntry(AClassType: TClass): Integer;
begin
  for Result := 0 to High(SingletonEntries) do if SingletonEntries[Result].Instance.ClassType = AClassType then Exit;
  Result := -1;
end;

procedure NewSingletonEntry(AInstance: TObject);
begin
  SetLength(SingletonEntries, Length(SingletonEntries)+1);
  SingletonEntries[High(SingletonEntries)].Instance := AInstance;
end;

procedure DeleteSingletonEntry(AInstance: TObject);
var i: Integer; Found: Boolean;
begin
  Found := False;
  for i := 0 to High(SingletonEntries) do begin
    if not Found and (SingletonEntries[i].Instance = AInstance) then Found := True;
    if Found and (i < High(SingletonEntries)) then SingletonEntries[i] := SingletonEntries[i+1];
  end;
  SetLength(SingletonEntries, Length(SingletonEntries)-1);
end;

procedure DestroyAllSingletons;
var i: Integer;
begin
  for i := 0 to High(SingletonEntries) do if Assigned(SingletonEntries[i].Instance) then begin
    SingletonEntries[i].Instance.Free;
    SingletonEntries[i].Instance := nil;
  end;
end;

{ TSingleton }

procedure TSingleton.Init;
begin
end;

class function TSingleton.NewInstance: TObject;
var Index: Integer;
begin
  Index := FindSingletonEntry(Self);
  if Index = -1 then begin
    Result := inherited NewInstance;
    NewSingletonEntry(Result);                                 // ToDo: Don't add if an exception in the constructor occured (use AfterConstruction)
    (Result as TSingleton).Init;
  end else Result := SingletonEntries[Index].Instance;
end;

procedure TSingleton.FreeInstance;
begin
  DeleteSingletonEntry(Self);
  inherited;
end;

initialization
finalization
  DestroyAllSingletons;
end.
