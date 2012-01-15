(*
 Memory utility unit
 (C) 2006 Mirage
 Created May 25, 2006
 The unit contains various memory utilites
*)
{$Include GDefines}
unit MemUtils;

interface

uses Singletons;

type
  TPersistentObjectsPool = class
    CapacityStep: Cardinal;
    constructor Create(ACapacityStep: Cardinal);
    function Allocate(Size: Cardinal): Pointer;
    procedure ClearPool;
    procedure CleanUp;
    destructor Free;
  protected
    FCapacity, Offset: Cardinal;
    Data: Pointer;
    procedure SetCapacity(NewCapacity: Cardinal);
  public
    property Capacity: Cardinal read FCapacity write SetCapacity;
  end;

var
  PersistentObjectsPool: TPersistentObjectsPool;

implementation

{ TPersistentObjectsPool }

constructor TPersistentObjectsPool.Create(ACapacityStep: Cardinal);
begin
  Data := nil;
  CapacityStep := ACapacityStep;
  SetCapacity(CapacityStep);
end;

function TPersistentObjectsPool.Allocate(Size: Cardinal): Pointer;
begin
  if Offset + Size < Capacity then Capacity := (Offset + Size) div CapacityStep * CapacityStep + CapacityStep;
  Result := Pointer(Cardinal(Data) + Offset);
  Inc(Offset, Size);
end;

procedure TPersistentObjectsPool.ClearPool;
begin
  Offset := 0;
end;

procedure TPersistentObjectsPool.CleanUp;
begin
  Offset := 0;
  FreeMem(Data);
end;

destructor TPersistentObjectsPool.Free;
begin
  CleanUp;
end;

procedure TPersistentObjectsPool.SetCapacity(NewCapacity: Cardinal);
var OldData: Pointer; TempCapacity: Cardinal;
begin
  OldData := Data; TempCapacity := Capacity;
  FCapacity := NewCapacity;
  GetMem(Data, Capacity);
  if OldData <> nil then begin
    if NewCapacity < TempCapacity then TempCapacity := NewCapacity;
    if TempCapacity <> 0 then Move(OldData^, Data^, TempCapacity);
    FreeMem(OldData);
  end;
end;

end.
