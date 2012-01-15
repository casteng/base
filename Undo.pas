unit Undo;

interface

uses BaseTypes, Basics, Base2D;

type
  TUndoLevel = record
    Rect: BaseTypes.TRect;
    Buffer: BaseTypes.PImageBuffer;
  end;

  TUndo = class
    Levels: array of TUndoLevel;
    CurrentLevel, TotalLevels, MaxLevels, DestWidth, ElementSize: Cardinal;
    CurrentRect: BaseTypes.TRect;
    Buffer, Destination: Pointer; BufferSize: Cardinal;
    constructor Create(Dest: Pointer; Size, Width, ElSize: Cardinal); 
    procedure Init(Dest: Pointer; Size, Width, ElSize: Cardinal); virtual;
    procedure FillBuffer(ABuffer: Pointer; Size: Cardinal); virtual;
    procedure UpdateRect(Rect: BaseTypes.TRect); virtual;
    procedure SaveLevel; virtual;
    function Undo: BaseTypes.TRect; virtual;
    function Redo: BaseTypes.TRect; virtual;
    destructor Free;
  protected
    procedure SetTotalLevels(ATotalLevels: Cardinal); virtual;
    procedure FlipData(const Rect: BaseTypes.TRect); virtual;
  end;

implementation

constructor TUndo.Create(Dest: Pointer; Size, Width, ElSize: Cardinal);
begin
  Init(Dest, Size, Width, ElSize);
end;

procedure TUndo.Init(Dest: Pointer; Size, Width, ElSize: Cardinal);
begin
  CurrentRect := BaseTypes.GetRect(-1, -1, -1, -1);
  if Buffer <> nil then FreeMem(Buffer);
  BufferSize := Size; GetMem(Buffer, BufferSize);
  ElementSize := ElSize;
  DestWidth := Width;
  Destination := Dest;
  SetTotalLevels(0);
  CurrentLevel := 0;
end;

procedure TUndo.FillBuffer(ABuffer: Pointer; Size: Cardinal);
begin
  Move(ABuffer^, Buffer^, Size);
end;

procedure TUndo.SaveLevel;
begin
  if CurrentRect.Left <> -1 then begin
    Inc(CurrentLevel);
    SetTotalLevels(CurrentLevel);
    Levels[TotalLevels-1].Rect := CurrentRect;
    GetMem(Levels[TotalLevels-1].Buffer, (CurrentRect.Right-CurrentRect.Left)*(CurrentRect.Bottom-CurrentRect.Top)*Integer(ElementSize));
    Base2D.BufferCut(Buffer, Levels[TotalLevels-1].Buffer, DestWidth, ElementSize, CurrentRect);
//    FillUndoBuffer;
    CurrentRect := BaseTypes.GetRect(-1, -1, -1, -1);
  end;
end;

function TUndo.Undo: BaseTypes.TRect;
begin
  Result := BaseTypes.GetRect(-1, -1, -1, -1);
  if CurrentLevel = 0 then Exit;
  Result := Levels[CurrentLevel-1].Rect;
  FlipData(Result);
//  FreeMem(Levels[TotalLevels-1].Buffer);
//  Dec(TotalLevels); SetLength(Levels, TotalLevels);
  Dec(CurrentLevel);
end;

function TUndo.Redo: BaseTypes.TRect;
begin
  Result := BaseTypes.GetRect(-1, -1, -1, -1);
  if CurrentLevel = TotalLevels then Exit;
  Inc(CurrentLevel);
  Result := Levels[CurrentLevel-1].Rect;
  FlipData(Result);
//  FreeMem(Levels[TotalLevels-1].Buffer);
//  Dec(TotalLevels); SetLength(Levels, TotalLevels);
end;

procedure TUndo.UpdateRect(Rect: BaseTypes.TRect);
var t: Integer;
begin
  if Rect.Left > Rect.Right then begin t := Rect.Left; Rect.Left := Rect.Right; Rect.Right := t; end;
  if Rect.Top > Rect.Bottom then begin t := Rect.Top; Rect.Top := Rect.Bottom; Rect.Bottom := t; end;
  if CurrentRect.Left = -1 then CurrentRect := Rect else begin
    CurrentRect.Left := MinI(CurrentRect.Left, Rect.Left);
    CurrentRect.Top := MinI(CurrentRect.Top, Rect.Top);
    CurrentRect.Right := MaxI(CurrentRect.Right, Rect.Right);
    CurrentRect.Bottom := MaxI(CurrentRect.Bottom, Rect.Bottom);
  end;
  Assert(CurrentRect.Left <= CurrentRect.Right, 'fff');
end;

procedure TUndo.SetTotalLevels(ATotalLevels: Cardinal);
var i: Integer;
begin
  if TotalLevels = ATotalLevels then Exit;
  if TotalLevels > ATotalLevels then begin
    for i := ATotalLevels to TotalLevels-1 do FreeMem(Levels[i].Buffer);
  end;
  TotalLevels := ATotalLevels;
  SetLength(Levels, TotalLevels);
end;

destructor TUndo.Free;
begin
  SetTotalLevels(0);
end;

procedure TUndo.FlipData(const Rect: BaseTypes.TRect);
begin
  Base2D.BufferCopy(Destination, Buffer, DestWidth, ElementSize, Rect);
  Base2D.BufferPaste(Levels[CurrentLevel-1].Buffer, Destination, DestWidth, ElementSize, Rect);
  Base2D.BufferCut(Buffer, Levels[CurrentLevel-1].Buffer, DestWidth, ElementSize, Rect);
end;

end.
