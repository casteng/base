(*
  @Abstract(Base string manipulation unit)
  (C) 2003-2011 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: --- --, 2011
  The unit contains ...
*)
{$Include GDefines.inc}
unit BaseStr;

interface

uses SysUtils, BaseTypes;

const
  // Locale independent decimal separator
  GeneralDecimalSeparator: Char = '.';
  // Delimiter which separate strings in enumerations
  StringDelimiter = '\&';
  // Short alias for StringDelimiter
  StrDelim = StringDelimiter;
  // String representations of pixel formats
  PixelFormatsEnum = 'Undefined\&R8G8B8\&A8R8G8B8\&X8R8G8B8\&' +
                     'R5G6B5\&X1R5G5B5\&A1R5G5B5\&A4R4G4B4\&' +
                     'A8\&X4R4G4B4\&A8P8\&P8\&L8\&A8L8\&A4L4\&' +
                     'V8U8\&L6V5U5\&X8L8V8U8\&Q8W8V8U8\&V16U16\&W11V11U10\&' +
                     'D16(Lockable)\&D32\&D15S1\&D24S8\&D16\&D24X8\&D24X4S4\&' +
                     'B8G8R8\&R8G8B8A8\&R5G5B5A1\&' +
                     'Reserved1\&Reserved2\&Reserved3\&Reserved4\&' + 
                     'ATI_DF16\&ATI_DF24\&' +
                     'DXT1\&DXT3\&DXT5';

  { Splits a string into array of strings using <b>Delim</b> as a delimiter
    If <b>EmptyOK</b> is @True result strings can be empty. Returns number of strings in array }
  function Split(const Str, Delim: string; out Res: TStringArray; EmptyOK: Boolean): Integer;
  { Splits an ansi string into array of strings using <b>Delim</b> as a delimiter
    If <b>EmptyOK</b> is @True result strings can be empty. Returns number of strings in array }
  function SplitA(const Str, Delim: AnsiString; out Res: TAnsiStringArray; EmptyOK: Boolean): Integer;

  { Returns an enumeration string which consists of all elements of strings separated by @Link(StringDelimiter)
    If <b>EmptyOK</b> is @True empty elements are included in result }
  function StringsToEnumA(Strings: array of TShortName; EmptyOK: Boolean): Ansistring;

  // Extracts file name without path or extension
  function GetFileName(const FileName: string): string;
  // Extracts file extension
  function GetFileExt(const FileName: string): string;

  // Converts number in hexadecimal format without prefix (e.g. "02A") to unsigned integer or return default value if invalid format
  function HexStrToIntDef(const s: string; Default: Longword): Longword;
  // Converts color in hexadecimal format (e.g. "#FF808040") to unsigned integer or return default value if invalid format
  function ColorStrToIntDef(const color: string; Default: Longword): Longword;
  // Returns True if the given string is a valid integer value
  function IsDecimalInteger(const s: string): Boolean;
  // Returns True if the given string is a valid floating point value using current decimal separator
  function IsFloat(const s: string): Boolean;
  // Returns True if the given string is a valid color value
  function IsColor(const s: string): Boolean;

  // Returns True if the given string is a valid floating point value using general decimal separator
  function IsReal(const s: string): Boolean;
  // StrToFloatDef() version with general decimal separator
  function StrToRealDef(const s: string; Default: Extended): Extended;
  // FloatToStr() version with general decimal separator
  function RealToStr(Value: Extended): string;

  // Ansistring version of IntToStr()
  function IntToStrA(Value: Int64): AnsiString;
  // Ansistring version of IntToHex()
  function IntToHexA(Value: Int64; Digits: Integer): AnsiString;
  // Ansistring version of FloatToStr()
  function FloatToStrA(Value: Extended): AnsiString;
  // Ansistring version of Format()
  function FormatA(const Format: string; const Args: array of const): AnsiString;
  // Ansistring version of StrToFloatDef()
  function StrToFloatDefA(const S: AnsiString; const Default: Extended): Extended;

  // Returns string with space character removed at both begin and end of the given string
  function TrimSpaces(const ts: string): string;
  // Ansistring version of Trimspaces()
  function TrimSpacesA(const ts: string): AnsiString;

  // Returns the given string with "." and "," replaced with current decimal separator
  function AssureFloatFormat(const s: string): string;

  // Returns the given string formatted
  function StrFormat(const s: string; args: array of string): string;

  // Finds the given signature and returns substring between the signature and end of line
  function ExtractStr(const s, Sig: string): string;

  {$IFDEF DELPHI}{$IFNDEF Delphi2009}
    // Delphi 2009+ CharInSet replacement for compatibility
    function CharInSet(C: AnsiChar; const CharSet: TSysCharSet): Boolean;
  {$ENDIF}{$ENDIF}

  // Returns True if the specified character belongs to the specified set
  function IsCharIn(C: AnsiChar; const CharSet: TSysCharSet): Boolean;

  // Converts pixel format to string representation from PixelFormatsEnum
  function PixelFormatToStr(Format: Integer): AnsiString;

  // Returns position of last occurence of the given character in the given string or 0 if not found
  function GetLastCharPosA(ch: AnsiChar; const str: AnsiString): Integer; {$I inline.inc}
  // Searches for the substring in the string starting from the given start position and returns its position or 0 if not found
  function PosEx(const substr: AnsiString; const s: AnsiString; const start: Integer): Integer;

{ Returns position where the given mask matches the string starting from Start or 0 if no match found.
  The mask can contain "?" characters which matches to any single character in string. }
  function MaskSimplePos(Mask, Str: AnsiString; Start: Integer): Integer;
{ Returns True if the given mask matches the string. <br/>
  The mask can contain "?" characters which matches to any signle character in string and
  "*" characters which matches to any number (including zero) of any characters. <br/>
  <b>Example:</b> <br/>
  MaskMatch('same*',          'same string') returns True <br/>
  MaskMatch('??me*ng',        'same string') returns True <br/>
  MaskMatch('*some string',   'same string') returns False <br/>
  MaskMatch('*sa**me string', 'same string') returns True }
  function MaskMatch(Mask, Str: AnsiString): Boolean;

  // from textfile
  function SkipBeforeSTR(var TextFile : text; SkipSTR : string):boolean;
  function ReadLine(var TextFile : text):string;


implementation

{$IFDEF RUSSIAN} uses FIOPadeg, Math {$ENDIF}

function Split(const Str, Delim: string; out Res: TStringArray; EmptyOK: Boolean): Integer;
var i: Integer; s: string;
begin
  Result := 1;
  s := Str;
  while s <> '' do begin
    i := Pos(Delim, s);
    if i > 0 then begin
      if (i > 1) or EmptyOK then begin
        Inc(Result);
        if Length(Res) < Result then SetLength(Res, Result);
        Res[Result-2] := Copy(s, 1, i-1);
      end;
      s := Copy(s, i + Length(Delim), Length(s));
    end else Break;
  end;

  if Length(Res) < Result then SetLength(Res, Result);
  if EmptyOK or (s <> '') then
    Res[Result-1] := s
  else
    Dec(Result);
  if Length(Res) <> Result then SetLength(Res, Result);
end;

function SplitA(const Str, Delim: AnsiString; out Res: TAnsiStringArray; EmptyOK: Boolean): Integer;
// Splits s at all occurences of Delim. Res contains splitted strings; Returns number of parts
{ TODO -cOptimization : Optimize it }
(*
function explode(Delim: Char; const S: string): TStringArr;
var i, k, Len, Count: Integer;
begin
  Len := Length(S);
  Count := 0;
  for i := 1 to Len do
    if S[i] = Delim then Inc(Count);
  SetLength(Result, Count + 1);
  Count := 0;
  k := 1;
  for i := 1 to Len do
  begin
    if S[i] = Delim then
    begin
      Inc(Count);
      SetString(Result[Count-1], PChar(@S[k]), i-k);
      k := i + 1;
    end;
  end; // for i
  Inc(Count);
  SetString(Result[Count-1], PChar(@S[k]), Len-k+1);
end;
*)
var i: Integer; s: AnsiString;
begin
  Result := 1;
  s := Str;
  while s <> '' do begin
    i := Pos(Delim, s);
    if i > 0 then begin
      if (i > 1) or EmptyOK then begin
        Inc(Result);
        if Length(Res) < Result then SetLength(Res, Result);
        Res[Result-2] := Copy(s, 1, i-1);
      end;
      s := Copy(s, i + Length(Delim), Length(s));
    end else Break;
  end;

  if Length(Res) < Result then SetLength(Res, Result);
  if EmptyOK or (s <> '') then
    Res[Result-1] := s
  else
    Dec(Result);
  if Length(Res) <> Result then SetLength(Res, Result);
end;

function StringsToEnumA(Strings: array of TShortName; EmptyOK: Boolean): Ansistring;
var i: Integer;
begin                                                                       // Can be optimized
  if Length(Strings) = 0 then
    Result := ''
  else begin
    Result := Strings[0];
    for i := 1 to High(Strings) do
      if EmptyOK or (Strings[i] <> '') then
        Result := Result + StringDelimiter + Strings[i];
  end;
end;

function GetLastCharPosA(ch: AnsiChar; const str: AnsiString): Integer;
begin
  Result := Length(str);
  while (Result >= 1) and (str[Result] <> ch) do Dec(Result);
end;

function GetFileName(const FileName: string): string;
var i: Integer;
begin
  if Pos('\', FileName) = 0 then begin
    if Pos(':', FileName) = 0 then
      Result := FileName
    else
      Result := Copy(FileName, Pos(':', FileName)+1, Length(FileName));
  end else begin
        i := Length(FileName);
        while (i >= 1) and (FileName[i] <> '\') do Dec(i);
    if i >=1 then Result := Copy(FileName, i+1, Length(FileName));
  end;
  
  i := Pos('.', Result);
  if i > 0 then Result := Copy(Result, 1, i-1);
end;

function GetFileExt(const FileName: string): string;
var i, ind: Integer;
begin
  ind := -1;
  for i := 1 to Length(FileName) do begin
    if FileName[i] = '.' then
      ind := i
    else if FileName[i] = '\' then
      ind := -1;
  end;

  if ind = -1 then
    Result := ''
  else
    Result := Copy(FileName, ind+1, Length(FileName));
end;

function HexStrToIntDef(const s: string; Default: Longword): Longword;
var E: Integer;
begin
  Val('0x' + s, Result, E);
  if E <> 0 then Result := Default;
end;

function ColorStrToIntDef(const color: string; Default: Longword): Longword;
var E: Integer;
begin
  if (color <> '') and (color[1] = '#') then begin
    Val('0x' + Copy(color, 2, Length(color)), Result, E);
    if E <> 0 then Result := Default;
  end else Result := Default;
end;

{$HINTS OFF}
function IsDecimalInteger(const s: string): Boolean;
var E, R: Integer;
begin
  Val(s, R, E);
  Result := E = 0;
end;
{$HINTS ON}

function IsFloat(const s: string): Boolean;
begin
  Result := Abs(StrToFloatDef(s, 0) - StrToFloatDef(s, 1)) < 0.5;
end;

{$HINTS OFF}
function IsColor(const s: string): Boolean;
var E, R: Integer;
begin
  Result := False;
  if (s = '') or (s[1] <> '#') then Exit;
  Val('0x' + Copy(s, 2, Length(s)), R, E);
  Result := E = 0;
end;
{$HINTS ON}

function IsReal(const s: string): Boolean;                           // Tests with current decimal separator
begin
  Result := Abs(StrToRealDef(s, 0) - StrToRealDef(s, 1)) < 0.5;
end;

function StrToRealDef(const s: string; Default: Extended): Extended;
var OldDecimalSeparator: Char;
begin
  OldDecimalSeparator := DecimalSeparator;
  DecimalSeparator := GeneralDecimalSeparator;
  Result := StrToFloatDef(s, Default);
  DecimalSeparator := OldDecimalSeparator;
end;

function RealToStr(Value: Extended): string;
var OldDecimalSeparator: Char;
begin
  OldDecimalSeparator := DecimalSeparator;
  DecimalSeparator := GeneralDecimalSeparator;
  Result := FloatToStrF(Value, ffGeneral, 7, 0);
  DecimalSeparator := OldDecimalSeparator;
end;

function IntToStrA(Value: Int64): AnsiString;
begin
  Result := AnsiString(IntToStr(Value));
end;

function IntToHexA(Value: Int64; Digits: Integer): AnsiString;
begin
  Result := AnsiString(IntToHex(Int64(Value), Digits));
end;

function FloatToStrA(Value: Extended): AnsiString;
begin
  Result := AnsiString(FloatToStr(Value));
end;

function FormatA(const Format: string; const Args: array of const): AnsiString;
begin
  Result := AnsiString(SysUtils.Format(Format, Args));
end;

function StrToFloatDefA(const S: AnsiString; const Default: Extended): Extended;
begin
  Result := StrToFloatDef(string(S), Default);
end;

function TrimSpaces(const ts: string): string;
const CharsToTrim = ' '#9#0;
var LeadingSpaces, TrailingSpaces: Integer;
begin
  Result := '';
  LeadingSpaces := 0;
  while (LeadingSpaces < Length(ts)) and (Pos(ts[LeadingSpaces+1], CharsToTrim) > 0) do Inc(LeadingSpaces);
  TrailingSpaces := 0;
  while ((Length(ts)-TrailingSpaces) > LeadingSpaces) and (Pos(ts[Length(ts)-TrailingSpaces], CharsToTrim) > 0) do Inc(TrailingSpaces);
  Result := Copy(ts, LeadingSpaces+1, Length(ts) - LeadingSpaces - TrailingSpaces);
end;

function TrimSpacesA(const ts: string): AnsiString;
begin
  Result := AnsiString(TrimSpaces(ts));
end;

function AssureFloatFormat(const s: string): string;
var i: Integer;
begin
  SetLength(Result, Length(s));
  for i := 1 to Length(s) do
    if (s[i] <> '.') and (s[i] <> ',') then
      Result[i] := s[i]
    else
      Result[i] := DecimalSeparator;
end;

function StrFormat(const s: string; Args: array of string): string;
{$IFDEF RUSSIAN}
const GenderStr = 'לז';
var GenderI  : Integer;
{$ENDIF}
var i, ArgI, PadegI: Integer; ArgState: Boolean;

  function ReadNumber: Integer;
  var rs: string;
  begin
    rs := '';
    Inc(i);
    while AnsiChar(s[i]) in ['0'..'9'] do begin
      rs := rs + s[i];
      Inc(i);
    end;
    Dec(i);
    Result := StrToIntDef(rs, -1);
  end;

begin
  ArgState := False;
  Result := '';
  ArgI := 1; PadegI := 1; {$IFDEF RUSSIAN} GenderI := 1; {$ENDIF}
  i := 1;
  while i <= Length(s) do begin
    if ArgState then begin
      case s[i] of
        'A': begin
          ArgI := ReadNumber;
          if (ArgI < 1) or (ArgI > Length(Args)) then ArgI := 1;
        end;
{$IFDEF RUSSIAN}
        'P': begin
          PadegI := ReadNumber;
          if (PadegI < 1) or (PadegI > MaxPadeg) then PadegI := 1;
        end;
        'G': begin
          GenderI := ReadNumber;
          if (GenderI < 1) or (GenderI > 2) then GenderI := 1;
        end;
{$ENDIF}
      end;
    end else if s[i] <> '%' then Result := Result + s[i];
    if s[i] = '%' then begin
      if ArgState and (ArgI > 0) and (ArgI <= Length(Args)) and (Length(Args[ArgI-1]) > 0) then begin
        if PadegI = 1 then Result := Result + Args[ArgI-1]
{$IFDEF RUSSIAN}
         else begin
           if Ord(Args[ArgI-1][Length(Args[ArgI-1])]) <= 127 then
            Result := Result + GetFIO('', Args[ArgI-1]+'''', '', GenderStr[GenderI], PadegI) else
             Result := Result + GetFIO('', Args[ArgI-1], '', GenderStr[GenderI], PadegI);
         end;
{$ENDIF};
        if ArgI < Length(Args) then Inc(ArgI);
      end;
      ArgState := not ArgState;
    end;
    Inc(i);
  end;
end;

function ExtractStr(const s, Sig: string): string;
var p1, p2: Integer; s1: string;
begin
  Result := '';
  p1 := Pos(Sig, s);
  if p1 = 0 then Exit;
  s1 := Copy(s, p1 + Length(Sig), Length(s));

  p2 := Pos(#10, s1);
  if (p2 = 0) or ( (Pos(#13, s1) > 0) and (Pos(#13, s1) < p2) ) then p2 := Pos(#13, s1);
  if p2 = 0 then p2 := Length(s1)+1;
  if p2 < 2 then Exit;
  Result := TrimSpaces(Copy(s1, 1, p2-1));
end;

{$IFDEF DELPHI}{$IFNDEF Delphi2009}
  function CharInSet(C: AnsiChar; const CharSet: TSysCharSet): Boolean;
  begin
    Result := C in CharSet;
  end;
{$ENDIF}{$ENDIF}  

function IsCharIn(C: AnsiChar; const CharSet: TSysCharSet): Boolean;
begin
  Result := C in CharSet;
end;

function PixelFormatToStr(Format: Integer): AnsiString;
var Strs: TAnsiStringArray;
begin
  Strs := nil;
  if (Format < SplitA(PixelFormatsEnum, '\&', Strs, True)) then
    Result := Strs[Format] else
      Result := 'Unknown';
  SetLength(Strs, 0);
end;

function PosEx(const Substr: AnsiString; const s: AnsiString; const Start: Integer ): Integer;
{$IFDEF PUREPASCAL}
begin
  Result := Pos(Substr, Copy(s, Start, Length(s)));
  if Result > 0 then Result := Result + Start;
{$ELSE}
assembler;
type StrRec = record allocSiz, refCnt, length: Longint; end;
const skew = sizeof(StrRec);
asm
{     ->EAX     Pointer to substr               }
{       EDX     Pointer to string               }
{       ECX     Pointer to start      //cs      }
{     <-EAX     Position of substr in s or 0    }

        TEST    EAX,EAX
        JE      @@noWork
        TEST    EDX,EDX
        JE      @@stringEmpty
        TEST    ECX,ECX           //cs
        JE      @@stringEmpty     //cs

        PUSH    EBX
        PUSH    ESI
        PUSH    EDI

        MOV     ESI,EAX                         { Point ESI to  }
        MOV     EDI,EDX                         { Point EDI to  }

        MOV     EBX,ECX        //cs save start
        MOV     ECX,[EDI-skew].StrRec.length    { ECX =    }
        PUSH    EDI                             { remember s position to calculate index }

        CMP     EBX,ECX        //cs
        JG      @@fail         //cs

        MOV     EDX,[ESI-skew].StrRec.length    { EDX = bstr)          }

        DEC     EDX                             { EDX = Length(substr) -   }
        JS      @@fail                          { < 0 ? return             }
        MOV     AL,[ESI]                        { AL = first char of       }
        INC     ESI                             { Point ESI to 2'nd char of substr }
        SUB     ECX,EDX                         { #positions in s to look  }
                                                { = Length(s) - Length(substr) + 1      }
        JLE     @@fail
        DEC     EBX       //cs
        SUB     ECX,EBX   //cs
        JLE     @@fail    //cs
        ADD     EDI,EBX   //cs

@@loop:
        REPNE   SCASB
        JNE     @@fail
        MOV     EBX,ECX                         { save outer loop                }
        PUSH    ESI                             { save outer loop substr pointer }
        PUSH    EDI                             { save outer loop s              }

        MOV     ECX,EDX
        REPE    CMPSB
        POP     EDI                             { restore outer loop s pointer      }
        POP     ESI                             { restore outer loop substr pointer }
        JE      @@found
        MOV     ECX,EBX                         { restore outer loop nter    }
        JMP     @@loop

@@fail:
        POP     EDX                             { get rid of saved s nter    }
        XOR     EAX,EAX
        JMP     @@exit

@@stringEmpty:
        XOR     EAX,EAX
        JMP     @@noWork

@@found:
        POP     EDX                             { restore pointer to first char of s    }
        MOV     EAX,EDI                         { EDI points of char after match        }
        SUB     EAX,EDX                         { the difference is the correct index   }
@@exit:
        POP     EDI
        POP     ESI
        POP     EBX
@@noWork:
{$ENDIF}
end;

function MaskSimplePos(Mask, Str: AnsiString; Start: Integer): Integer;
var
  Pos1, Pos2: Integer;
  Found: Boolean;
begin
  Result := 0;
  if Mask = '' then Exit;
  Result := Start - 1;
  Found := False;

  while not Found and (Result <= Length(Str) - Length(Mask)) do begin
    Result := result + 1;

    Found := True;
    Pos1 := 1;
    Pos2 := Result;
    while Found and (Pos1 <= Length(Mask)) do begin
      Found := (Pos2 <= Length(Str)) and ( (mask[pos1] = '?') or (mask[pos1] = Str[pos2]) );
      Pos1 := Pos1 + 1;
      Pos2 := Pos2 + 1;
    end;
  end;

  if not Found then Result := 0;
end;

function MaskMatch(Mask, Str: AnsiString): Boolean;
var
  i, matchPos, strPos, cnt: Integer;
  m1: TAnsiStringArray;
begin
  Result := True;
  cnt := SplitA(mask, '*', m1, false);

  i := 0;
  strPos := 1;
  while Result and (i < cnt) do begin
    matchPos := MaskSimplePos(m1[i], str, strPos);
    Result := matchPos > 0;
    strPos := matchPos + Length(m1[i]);
    Inc(i);
  end;

  Result := Result and ( (strPos > Length(Str)) or (Mask[Length(Mask)] = '*') );
end;

function SkipBeforeSTR(var TextFile : text; SkipSTR : string):boolean;
var s: string;
begin
  repeat
    readln(TextFile, s);
    if s = SkipSTR then begin
      Result := True; Exit;
    end;
  until False;
  Result := False;
end;

function ReadLine(var TextFile : Text):string;
var i: Word; var s: string;
begin
  if EOF(TextFile) then exit;
  i:=1;
  repeat
    ReadLn(TextFile, s);
  until  (s<>'') and (s[1]<>'#') or EOF(TextFile);
  if s<>'' then begin
    while s[i]=' ' do inc(i);
    if i=Length(s) then s:='' else s:=Copy(s, i, Length(s)-i+1);
  end;
  Result:=s;
end;

end.
