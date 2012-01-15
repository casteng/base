(*
 @Abstract(Text markup unit)
 (C) 2006 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains text markup base class and simple markup language implementation class
*)
{$Include GDefines.inc}
unit Markup;

interface

uses Logger, BaseTypes, Basics, BaseStr, BaseGraph;

const
// Align modes
  amLeft = 0; amCenter = 1; amRight = 2; amJustify = 3;

type
  TName = string[128];

  TTag = class
    Position: Integer;
    constructor Create(APosition: Integer);
  end;

  TColorTag = class(TTag)
    Color: BaseTypes.TColor;
    constructor Create(APosition: Integer; AColor: BaseTypes.TColor);
  end;

  TAlphaColorTag = class(TColorTag)
  end;

  TColorResetTag = class(TTag)
  end;

  TFontStyleTag = class(TTag)
    Kind, Amount: Word;
    constructor Create(APosition: Integer; AKind, AAmount: Word);
  end;

  TIndentTag = class(TTag)
    Amount: Integer;
    constructor Create(APosition: Integer; AAmount: Integer);
  end;

  TReturnTag = class(TTag)
  end;

  TMoveToTag = class(TTag)
    X, Y: Single;
    constructor Create(APosition: Integer; AX, AY: Single);
  end;

  TAlignTag = class(TTag)
    Align: Integer;
    constructor Create(APosition: Integer; AAlign: Integer);
  end;

  TLinkTag = class(TTag)
    Name: TName;
    constructor Create(APosition: Integer; const AName: string);
  end;

  TTags = array of TTag;

  TMarkup = class
  protected
    FPureText, FText: string;
    FTotalTags: Integer;
    procedure ParseFormatting; virtual;
  private
    Parsed: Boolean;
    FTags: TTags;
    procedure AddTag(const Tag: TTag);
    procedure InsertTag(Pos: Integer; const Tag: TTag);
    procedure SetFText(const Value: string); virtual;
    function GetPureText: string;
    function GetTag(Index: Integer): TTag;
  public
    DefaultFont: TFont;
    DefaultWidth: Single;
    SeparatorChars, InvisibleChars: string;
    constructor Create;
    destructor Destroy; override;
    procedure Invalidate;
    property FormattedText: string read FText write SetFText;
    property PureText: string read GetPureText;
    property Tags[Index: Integer]: TTag read GetTag;
    property TotalTags: Integer read FTotalTags;
  end;

  TSimpleMarkup = class(TMarkup)
  protected
    procedure ParseFormatting; override;
  end;

implementation

uses SysUtils;

{ TTag }

constructor TTag.Create(APosition: Integer);
begin
  Assert(APosition >= 0, ClassName + '.Create: Position is negative');
  Position := APosition;
end;

{ TColorTag }

constructor TColorTag.Create(APosition: Integer; AColor: BaseTypes.TColor);
begin
  inherited Create(APosition);
  Color := AColor;
end;

{ TFontStyleTag }

constructor TFontStyleTag.Create(APosition: Integer; AKind, AAmount: Word);
begin
  inherited Create(APosition);
  Kind := AKind; Amount := AAmount;
end;

{ TIndentTag }

constructor TIndentTag.Create(APosition: Integer; AAmount: Integer);
begin
  inherited Create(APosition);
  Amount := AAmount;
end;

{ TMoveToTag }

constructor TMoveToTag.Create(APosition: Integer; AX, AY: Single);
begin
  inherited Create(APosition);
  X := AX;
  Y := AY;
end;

{ TAlignTag }

constructor TAlignTag.Create(APosition: Integer; AAlign: Integer);
begin
  inherited Create(APosition);
  Align := AAlign;
end;

{ TLinkTag }

constructor TLinkTag.Create(APosition: Integer; const AName: string);
begin
  inherited Create(APosition);
  Name := AName;
end;

{ TMarkup }

procedure TMarkup.ParseFormatting;
begin
  FTotalTags := 0;
  SetLength(FTags, 0);
end;

procedure TMarkup.AddTag(const Tag: TTag);
begin
  Inc(FTotalTags); SetLength(FTags, FTotalTags);
  FTags[TotalTags-1] := Tag;
end;

procedure TMarkup.InsertTag(Pos: Integer; const Tag: TTag);
var i: Integer;
begin
  AddTag(Tag);
  for i := FTotalTags-2 downto Pos do FTags[i+1] := FTags[i];
  FTags[Pos] := Tag;
end;

procedure TMarkup.SetFText(const Value: string);
begin
  if Value = FText then Exit;
  FText  := Value;
  Parsed := False;
end;

function TMarkup.GetPureText: string;
begin
  if not Parsed then ParseFormatting;
  Result := FPureText;
end;

function TMarkup.GetTag(Index: Integer): TTag;
begin
  if not Parsed then ParseFormatting;
  Result := FTags[Index];
end;

constructor TMarkup.Create;
begin
  SeparatorChars := ' +-*/\<>.,'#10#13;
  InvisibleChars := ' -'#10#13;
end;

destructor TMarkup.Destroy;
var i: Integer;
begin
  for i := 0 to FTotalTags-1 do FreeAndNil(FTags[i]);
  FTotalTags := 0;
  FTags := nil;
  FText := ''; FPureText := '';
  inherited;
end;

procedure TMarkup.Invalidate;
begin
  Parsed := False;
end;

{ TSimpleMarkup }

procedure TSimpleMarkup.ParseFormatting;
// Syntax: "["<Command>[nn]"]"
const
  sNone = 0; sBeginCmd = 1;
  OpenBracket = '['; CloseBracket = ']';
  amLeft = 0; amCenter = 1; amRight = 2; amJustify = 3;
var
  i, PureLength: Integer;
  Argument: string;
  Command: Char;
  State, AlignMode: Cardinal;
//
  LineWidth, LineHeight, WordWidth, WordHeight, CharWidth: Single;
  CurrentWord: string;
  CurFont: TFont;
  MaxWidth, CurY: Single;
  LastSeparator: Char;
  LastTagPosition: Integer;
  

  LastNewLineTag: TMoveToTag;

  procedure ScanArgument;                     // ToDo: optimize
  begin
    Inc(i);
    Argument := '';
    while (i <= Length(FText)) and (FText[i] <> CloseBracket) do begin
      Argument := Argument + FText[i];
      Inc(i);
    end;
  end;

  procedure AdjustAlign;
  begin
    if LastNewLineTag <> nil then case AlignMode of
      amCenter: LastNewLineTag.X := (MaxWidth - (LineWidth -0* WordWidth)) * 0.5;
      amRight:  LastNewLineTag.X := (MaxWidth - (LineWidth -0* WordWidth));
    end;
  end;

  procedure NewLine;
  begin
    CurY       := CurY + LineHeight;
    AdjustAlign;
    LineWidth  := WordWidth + CharWidth;
    LineHeight := WordHeight;
    // Add a MoveTo tag after an invisible separator but before a visible one
    LastNewLineTag := TMoveToTag.Create(MaxI(0, Length(FPureText) + 0*Ord(WordWidth = 0)), 0, CurY);
    InsertTag(LastTagPosition, LastNewLineTag);
  end;

  procedure AddToPureText(Ch: Char);      // ToFix: coupled visible separators can exceed the area

    procedure AddChar;
    begin
      CurrentWord := CurrentWord + Ch;
      Inc(PureLength);
    end;

  begin
    if (Pos(Ch, SeparatorChars) > 0) or (Ch = #0) then begin                  // Separator character
      CurFont.GetTextExtent(Ch, CharWidth, WordHeight);
      CurFont.GetTextExtent(CurrentWord, WordWidth, WordHeight);
      if (LineWidth + WordWidth + CharWidth > MaxWidth) and (LineWidth > 0) then begin // A new line needed
        if LineWidth + WordWidth <= MaxWidth then begin                       // But it fits without separator
          FPureText := FPureText + CurrentWord;
          if Pos(Ch, InvisibleChars) > 0 then begin                           // The separator is invisible
            FPureText := FPureText + Ch;
            WordWidth := 0;
            CharWidth := 0;
            Ch := #0;
          end else WordWidth := CharWidth;
          CurrentWord := '';
        end;
        NewLine;
      end else LineWidth  := LineWidth + WordWidth + CharWidth;
      LineHeight := MaxS(LineHeight, WordHeight);
      if Ch <> #0 then begin                                                  // Add Ch's width and height to line
        AddChar;
        CurFont.GetTextExtent(Ch, WordWidth, WordHeight);
//         LineWidth  := LineWidth + WordWidth;
        LineHeight := MaxS(LineHeight, WordHeight);
      end;
      FPureText := FPureText + CurrentWord;
      CurrentWord := '';
      LastSeparator := Ch;
      LastTagPosition := TotalTags;
    end else if Ch <> #0 then AddChar;
  end;

begin                                              // ToDo: optimize
  inherited;
  if DefaultFont = nil then Exit;
  i := 1;
  CurY := 0;
  CurFont := DefaultFont;
  MaxWidth := DefaultWidth;
  FPureText   := '';
  CurrentWord := '';
  LineWidth  := 0;
  LineHeight := 0;
  CharWidth  := 0;
  WordWidth  := 0;
  WordHeight := 0;
  PureLength := 0;
  LastSeparator := #0;
  LastTagPosition := 0;
  State := sNone;
  AlignMode := amRight;
  AlignMode := amLeft;
  LastNewLineTag := nil;
  NewLine;
  while i <= Length(FText) do begin
    case State of
      sNone:     if FText[i] = OpenBracket then State := sBeginCmd else AddToPureText(FText[i]);
      sBeginCmd: if FText[i] = OpenBracket then begin            // Escape symbol occured
        AddToPureText(FText[i]);
        State := sNone;
      end else begin                                             // Process command
        Command := UpCase(FText[i]);
        ScanArgument;
        case Command of
          '#': if Argument <> '' then begin
            if Length(Argument) = 6 then                         // Preserve alpha component
              AddTag(TColorTag.Create(PureLength, GetColor(HexStrToIntDef(Argument, 0)))) else
                AddTag(TAlphaColorTag.Create(PureLength, GetColor(HexStrToIntDef(Argument, 0))));
          end else AddTag(TColorResetTag.Create(PureLength));
          'B': ;
          'I': ;
          '_': ;
          'E': NewLine;
          else  Log(ClassName + '.ParseFormatting: Unknown command "' + Command + '"', lkWarning); 
        end;
        State := sNone;
      end;
    end;
    Inc(i);
  end;
  AddToPureText(#0);                        // Handle last word
  AdjustAlign;                              // Check if this already called by previous line of code
  Parsed := True;
end;

end.
