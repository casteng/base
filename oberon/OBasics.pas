(*
 !!! The unit will be replaced with Basics !!!
 Oberon basics unit
 (C) 2004-2007 George "Mirage" Bakhtadze.
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 The unit contains compiler basic functions and classes
*)
unit OBasics;

interface

uses SysUtils;

const
// File errors
  feOK = 0; feNotFound = -1; feCannotRead = -2; feCannotWrite = -3; feInvalidFileFormat = -4; feCannotSeek = -5; feCannotOpen = -6;
// File usage modes
  fuRead = 1; fuWrite = 2; fuAppend = 3;

  OneAsInt: LongWord = $3F800000;
  OneAsInt2: LongWord = $3F800000 shl 1;

type
  TDStream = class                                // All these stream classes can be replaced with standard TStream
    Position, Size: Cardinal;
    function Open(const Usage: Integer = fuRead; const Mode: Integer = fmOpenReadWrite or fmShareDenyWrite): Integer; virtual; abstract;
    function Seek(const NewPos: Cardinal): Integer; virtual; abstract;
    function Read(var Buffer; const Count: Cardinal): Integer; virtual; abstract;
    function Write(const Buffer; const Count: Cardinal): Integer; virtual; abstract;
    function Close: Integer; virtual; abstract;
  end;

  TFileDStream = class(TDStream)
    Filename: string;
    FHandle, FMode: Integer;
    constructor Create(const AFileName: string; const Usage: Integer = fuRead; const Mode: Integer = fmOpenReadWrite or fmShareDenyWrite);
    function Open(const Usage: Integer = fuRead; const Mode: Integer = fmOpenReadWrite or fmShareDenyWrite): Integer; override;
    function Seek(const NewPos: Cardinal): Integer; override;
    function Read(var Buffer; const Count: Cardinal): Integer; override;
    function Write(const Buffer; const Count: Cardinal): Integer; override;
    function Close: Integer; override;
    destructor Free;
  end;

  function MaxS(V1, V2: Single): Single;
  function MinS(V1, V2: Single): Single;

  function InvSqrt(x: Single): Single;   // Fast inverse square root. Depends on float numbers representation

  function AddColorW(Color1, Color2: Cardinal; W1, W2: Single): Cardinal;
  function BlendColor(Color1, Color2: Cardinal; K: Single): Cardinal;

implementation

{ TFileDStream }

constructor TFileDStream.Create(const AFileName: string; const Usage: Integer = fuRead; const Mode: Integer = fmOpenReadWrite or fmShareDenyWrite);
begin
  Filename := ExpandFileName(AFileName);
  Open(Usage, Mode);
end;

function TFileDStream.Open(const Usage, Mode: Integer): Integer;
var F: file;
begin
  Result := feCannotOpen;
  FMode := Mode;
  if (Usage = fuWrite) or (not FileExists(FileName)) then begin
    if Usage = fuRead then Exit;
    FHandle := FileCreate(FileName); FileClose(FHandle);
  end;
  if (Usage = fuRead) or (Usage = fuAppend) then begin
    Assign(F, FileName); Reset(F, 1);
    Size := FileSize(F);
    CloseFile(F);
  end;
  Position := 0;
  FHandle := FileOpen(FileName, Mode);
  if Usage = fuAppend then Seek(Size);
  if FHandle >= 0 then Result := feOK;
end;

function TFileDStream.Read(var Buffer; const Count: Cardinal): Integer;
var BytesRead: Integer;
begin
  BytesRead := FileRead(FHandle, Buffer, Count);
  if BytesRead >= 0 then Inc(Position, BytesRead);
  if BytesRead = Count then Result := feOK else Result := feCannotRead;
end;

function TFileDStream.Seek(const NewPos: Cardinal): Integer;
begin
  Result := 0;
  if FileSeek(FHandle, NewPos, 0) < 0 then Result := -feCannotSeek else Position := NewPos;
end;

function TFileDStream.Write(const Buffer; const Count: Cardinal): Integer;
var BytesWrite: Integer;
begin
  BytesWrite := FileWrite(FHandle, Buffer, Count);
  if BytesWrite >= 0 then Inc(Position, BytesWrite);
  Size := Position;
  if BytesWrite = Count then Result := feOK else Result := feCannotWrite;
end;

function TFileDStream.Close: Integer;
begin
  Result := feOK;
  FileClose(FHandle);
end;

destructor TFileDStream.Free;
begin
  Close;
end;

{$IFDEF USEP6ASM}
function MaxS(V1, V2: Single): Single; assembler;
asm
  fld     dword ptr [ebp+$08]
  fld     dword ptr [ebp+$0c]
  fcomi   st(0), st(1)
  fcmovb  st(0), st(1)
  ffree   st(1)
end;

function MinS(V1, V2: Single): Single; assembler;
asm
  fld     dword ptr [ebp+$08]
  fld     dword ptr [ebp+$0c]
  fcomi   st(0), st(1)
  fcmovnb st(0), st(1)
  ffree   st(1)
end;
{$ELSE}
function MaxS(V1, V2: Single): Single;
begin
  if V1 > V2 then Result := V1 else Result := V2;
end;

function MinS(V1, V2: Single): Single;
begin
  if V1 < V2 then Result := V1 else Result := V2;
end;
{$ENDIF}

function InvSqrt(x: Single): Single;   // Fast inverse square root. Depends on float numbers representation
var tmp: LongWord;
begin
  asm
    mov        eax, OneAsInt
    sub        eax, x
    add        eax, OneAsInt2
    shr        eax, 1
    mov        tmp, eax
  end;
  Result := Single((@tmp)^) * (1.47 - 0.47 * x * Single((@tmp)^) * Single((@tmp)^));
end;

function AddColorW(Color1, Color2: Cardinal; W1, W2: Single): Cardinal;
begin
  Result := Cardinal(Trunc(0.5+MinS(255, (Color1 and 255)*W1 + (Color2 and 255)*W2))) +
            Cardinal(Trunc(0.5+MinS(255, ((Color1 shr 8) and 255)*W1 + ((Color2 shr 8) and 255)*W2))) shl 8 +
            Cardinal(Trunc(0.5+MinS(255, ((Color1 shr 16) and 255)*W1 + ((Color2 shr 16) and 255)*W2))) shl 16 +
            Cardinal(Trunc(0.5+MinS(255, ((Color1 shr 24) and 255)*W1 + ((Color2 shr 24) and 255)*W2))) shl 24;
end;

function BlendColor(Color1, Color2: Cardinal; K: Single): Cardinal;
begin
  if K > 1 then K := 1; if K < 0 then K := 0;
  Result := AddColorW(Color1, Color2, 1-K, K);
end;

end.
