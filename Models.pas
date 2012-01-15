(*
 @Abstract(Basic models unit)
 (C) 2006-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 Created: Apr 04, 2007 <br>
 Unit contains basic model (from Model-View-Controller) classes
*)
{$Include GDefines.inc}
unit Models;

interface

uses Basics, Props, BaseMsg;

const
  // Operations array grow step
  OperationsCapacityStep = 32;

type
  // Operation flag
  TOperationFlag = (// Operation is in applied state
                    ofApplied,
                    // Operation was handled
                    ofHandled,
                    // Operation is intermediate and for example should not be added to editor's queue
                    ofIntermediate
                    );
  TOperationFlags = set of TOperationFlag;

  // Auto-inverse operation class
  TOperation = class
  protected
    // Should actually perform the operation. Repeated call should undo all changes made by previous call.
    procedure DoApply; virtual; abstract;
    // Should try to merge the operations and undo information taking in account applied state
    function DoMerge(AOperation: TOperation): Boolean; virtual;
  public
    // Flag set
    Flags: TOperationFlags;
    // Applies the operation. Repeated call will undo the operation.
    procedure Apply;
    // Adds to the operation actions of the given one if possible and returns True if success. Both operations should be in applied or both in unapplied state.
    function Merge(AOperation: TOperation): Boolean; 
  end;

  // Operations manager 
  TOperationManager = class
  private
    FOperations: array of TOperation;
    // Total valid operations
    FTotalOperations,
    // Last applied operation index
    FCurOperation: Integer;
    // Last operation applyed (added, undone, redone)
    FLastOperation: TOperation;
    procedure FreeRange(FromIndex, Count: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    // Remove all operations
    procedure Clear;
    // Add an operation
    procedure Add(Operation: TOperation);
    // Undo last operations
    procedure Undo;
    // Redo previously undone operation
    procedure Redo;
    // Returns True if there is at least one operation to undo
    function CanUndo: Boolean;
    // Returns True if there is at least one operation to redo
    function CanRedo: Boolean;
    // Last operation applyed (added, undone, redone)
    property LastOperation: TOperation read FLastOperation;
  end;

  IModel = interface
  end;

  TModel = class(TInterfacedObject, IModel)
  protected
    FOperations: TOperation;                               // Points to last applied operation
  public
    procedure GetProperties(const Result: TProperties); virtual; abstract;
    procedure SetProperties(Properties: TProperties); virtual; abstract;

    procedure DoOperation(const Operation: TOperation); virtual; abstract;

    property LastOperation: TOperation read FOperations;
  end;

  // This message usually is sent to core handler when an operation is ready to apply. Default handler will free all unhandled operations.
  TOperationMsg = class(TMessage)
    Operation: TOperation;
    constructor Create(AOperation: TOperation);
  end;

implementation

{ TOperationMessage }

constructor TOperationMsg.Create(AOperation: TOperation);
begin
  Operation := AOperation;
end;

{ TOperation }

function TOperation.DoMerge(AOperation: TOperation): Boolean;
begin
  Result := False;
end;

procedure TOperation.Apply;
begin
  DoApply;
  if ofApplied in Flags then Exclude(Flags, ofApplied) else Include(Flags, ofApplied);
end;

function TOperation.Merge(AOperation: TOperation): Boolean;
begin
  Assert(((ofApplied in Flags) and (ofApplied in AOperation.Flags)) or
         (not (ofApplied in Flags) and not (ofApplied in AOperation.Flags)),
         'TOperation.Merge: Both operations should be in applied or both in unapplied state');
  Result := DoMerge(AOperation);
end;

{ TOperationManager }

procedure TOperationManager.FreeRange(FromIndex, Count: Integer);
var i: Integer;
begin
  for i := FromIndex to FromIndex + Count - 1 do begin
    if FLastOperation = FOperations[i] then FLastOperation := nil;
    FOperations[i].Free;
    FOperations[i] := nil;
  end;
end;

constructor TOperationManager.Create;
begin
  FLastOperation := nil;
  FCurOperation  := -1;
end;

destructor TOperationManager.Destroy;
begin
  Clear;
  inherited;
end;

procedure TOperationManager.Clear;
begin
  FreeRange(0, FTotalOperations);
  FLastOperation   := nil;
  FCurOperation    := -1;
  FTotalOperations := 0;
end;

procedure TOperationManager.Add(Operation: TOperation);        // o o o X o o
begin
  if CanUndo and FOperations[FCurOperation].Merge(Operation) then begin
    Operation.Free;
//    FOperations[FCurOperation].Apply;
    Exit;
  end;

  Inc(FCurOperation);

  if FCurOperation < FTotalOperations-1 then FreeRange(FCurOperation, FTotalOperations - FCurOperation -1);
  FTotalOperations := FCurOperation+1;

  if Length(FOperations) <= FTotalOperations then SetLength(FOperations, Length(FOperations) + OperationsCapacityStep);

  FOperations[FCurOperation] := Operation;
  FLastOperation := Operation
end;

procedure TOperationManager.Undo;
begin
  if CanUndo then begin
    FLastOperation := FOperations[FCurOperation];
    FLastOperation.Apply;
    Dec(FCurOperation);
  end;
end;

procedure TOperationManager.Redo;
begin
  if CanRedo then begin
    Inc(FCurOperation);
    FLastOperation := FOperations[FCurOperation];
    FLastOperation.Apply;
  end;
end;

function TOperationManager.CanUndo: Boolean;
begin
  Result := FCurOperation >= 0;
end;

function TOperationManager.CanRedo: Boolean;
begin
  Result := FCurOperation < FTotalOperations-1;
end;

end.
