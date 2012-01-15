(*
 Oberon scanner unit
 (C) 2004-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 The unit contains scanner class
*)
unit OScan;

interface

uses OTypes;

const
//  sSpecial = ['+', '-', '*', '/', '~', '&', '.', ',', ':', ';', '|', '(', ')', '[', ']', '{', '}', '=', '>', '<', '#', '^'];
  sOperation = ['+', '-', '*', '/', '~', '&', '|', '=', '>', '<', '#', '^'];
  sOperator = [':', '='];
  sRelation = ['=', '<', '>', '#'];

type
  TScaner = class
    Source, Buf: string;
    SourcePos, CurLine: Int;
    EOS: Boolean;
    constructor Create(ASource: string);
    function ReadChar(var Character: Char): Boolean;
    procedure ReturnChar(Character: Char);
    procedure ReturnBuf(Buffer: string);
    function isComment(c: Char): Boolean;
    function isDelim(c: Char): Boolean;
    function isAlpha(c: Char): Boolean;
    function isNumber(c: Char): Boolean;
    function isHexNumber(c: Char): Boolean;
    function isOperation(c: Char): Boolean;
    function isOperator(c: Char): Boolean;
    function isRelation(c: Char): Boolean;
    procedure SkipDelims;
    procedure GetIdent(c: Char);
    procedure GetNumber(c: Char);
    procedure GetString(c: Char);
    procedure GetComment(c: Char);
    function GetOperation(c: Char): Int32;
    function GetOperator(c: Char): Int32;
    function GetRelation(c: Char): Int32;
  private
    CommentStack: array of Int32;
    TotalCommentStack: Int;
    procedure AddComment(Index: Integer);
    procedure DelComment;

  end;

implementation

constructor TScaner.Create(ASource: string);
begin
  Source := ASource; SourcePos := 1; CurLine := 1; Buf := ''; TotalCommentStack := 0; EOS := False;
end;

function TScaner.ReadChar(var Character: Char): Boolean;
begin
  Result := False;
  if SourcePos > Length(Source) then begin Character := #10; Inc(SourcePos); Inc(CurLine); EOS := True; Exit; end;
  Character := Source[SourcePos];
  if Character = #10 then Inc(CurLine);
  Inc(SourcePos);
  Result := True;
  EOS := False;
end;

procedure TScaner.ReturnChar(Character: Char);
begin
  if SourcePos <= 1 then Exit;
  if Character = #10 then Dec(CurLine);
  Dec(SourcePos);
  EOS := False;
end;

procedure TScaner.ReturnBuf(Buffer: string);
var i: Integer;
begin
  for i := Length(Buffer) downto 1 do ReturnChar(Buf[i]);
  if Length(Buffer)>0 then EOS := False;
end;

function TScaner.isComment(c: Char): Boolean;
begin
  Result := (c = '/') or (c = '(') or (c='*');       // ToFix: Fix it
  Result := False;
end;

function TScaner.isDelim(c: Char): Boolean;
begin
  Result := (c =  ' ') or (c =  #10) or (c =  #13);
end;

function TScaner.isAlpha(c: Char): Boolean;
begin
  Result := (c in ['a'..'z']) or (c in ['A'..'Z']) or (c = '_');
end;

function TScaner.isNumber(c: Char): Boolean;
begin
  Result := (c in ['0'..'9']);
end;

function TScaner.isHexNumber(c: Char): Boolean;
begin
  Result := (c in ['A'..'F', 'a'..'f', 'H', 'h']);
end;

function TScaner.isOperation(c: Char): Boolean;
begin
  Result := (c in sOperation);
end;

function TScaner.isOperator(c: Char): Boolean;
begin
  Result := (c in sOperator);
end;

function TScaner.isRelation(c: Char): Boolean;
begin
  Result := (c in sRelation);
end;

procedure TScaner.SkipDelims;
var ch: Char;
begin
// ( )
  repeat
    if not ReadChar(ch) then Exit;
//    if isComment(ch) then GetComment(ch);
  until not isDelim(ch);
  ReturnChar(ch);
end;

procedure TScaner.GetIdent(c: Char);
var i: Integer;
begin
  Buf := '';
//  repeat
    if isAlpha(c) then begin
      Buf := Buf + c;
      while ReadChar(c) and (isAlpha(c) or isNumber(c) or (c = '_')) do Buf := Buf + c;
    end;
//    if isComment(c) then GetComment(c) else ReturnChar(c);
//    ReadChar(c);
//  until not (isAlpha(c) or isNumber(c));
  ReturnChar(c);
end;

procedure TScaner.GetNumber(c: Char);
var i: Integer; LastChar: Char;
begin
  LastChar := #0;
  Buf := c;
//  repeat
    while ReadChar(c) and (isNumber(c) or isHexNumber(c) or (c='.') or
          ( ((c = '-') or (c = '+')) and ((UpCase(LastChar) = 'E') or (UpCase(LastChar) = 'D')) ) ) do begin
      Buf := Buf + c;
      LastChar := c;
    end;
{    if isComment(c) then GetComment(c) else ReturnChar(c);
    ReadChar(c);
  until not isNumber(c);}
  ReturnChar(c);
end;

procedure TScaner.GetString(c: Char);
var Term: Char;
begin
  Term := c; Buf := '';
  ReadChar(c);
  while c <> Term do begin
    if c = #10 then begin {Error(CurLine - 1, 2); }Exit; end;
    Buf := Buf + c;
    ReadChar(c);
  end;
//  Memo1.Text := Memo1.Text+' Str: '+Term+Buf+Term;
end;

procedure TScaner.AddComment(Index: Integer);
begin
  Inc(TotalCommentStack);
{  SetLength(CommentStack, TotalCommentStack);
  CommentStack[TotalCommentStack-1] := Index;}
end;

procedure TScaner.DelComment;
begin
  Dec(TotalCommentStack);
//  SetLength(CommentStack, TotalCommentStack);
end;

procedure TScaner.GetComment(c: Char);
var i: Integer; Buf: string; ReallyComment: Boolean;
begin
  Buf := c;
  while ReadChar(c) and isComment(c) do Buf := Buf + c;
  if not isDelim(c) then ReturnChar(c);                    // Don't return delimiters
  ReallyComment := False;
  for i := 0 to TotalComments-1 do begin
    if (Length(CommentStr[i].Open) <= Length(Buf)) and (CommentStr[i].Open = Copy(Buf, Length(Buf)-Length(CommentStr[i].Open)+1, Length(CommentStr[i].Open))) then begin
      ReallyComment := True; Break;
    end;
  end;
  if not ReallyComment then begin ReturnBuf(Buf); Exit; end;
  AddComment(0);
  while ReadChar(c) and (TotalCommentStack > 0) do begin
    Buf := Buf + c;
    for i := 0 to TotalComments-1 do begin
      if (Length(CommentStr[i].Close) <= Length(Buf)) and (CommentStr[i].Close = Copy(Buf, Length(Buf)-Length(CommentStr[i].Close)+1, Length(CommentStr[i].Close))) then DelComment;
//      if (Length(CommentStr[i].Open) <= Length(Buf)) and (CommentStr[i].Open = Copy(Buf, Length(Buf)-Length(CommentStr[i].Open)+1, Length(CommentStr[i].Open))) then GetComment;
    end;
  end;
//  Memo1.Text := Memo1.Text+' Comment: '+Buf;
  ReturnChar(c);
  Buf := '';
end;

function TScaner.GetOperation(c: Char): Int32;
var i: Integer;
begin
  Buf := c;
  repeat
    while ReadChar(c) and isOperation(c) do Buf := Buf + c;
    if isComment(c) then GetComment(c) else ReturnChar(c);
    ReadChar(c);
  until not isOperation(c);
  ReturnChar(c);
end;

function TScaner.GetOperator(c: Char): Int32;
var i: Integer;
begin
  Buf := c;
  repeat
    while ReadChar(c) and isOperator(c) do Buf := Buf + c;
    if isComment(c) then GetComment(c) else ReturnChar(c);
    ReadChar(c);
  until not isOperator(c);
  ReturnChar(c);
end;

function TScaner.GetRelation(c: Char): Int32;
var i: Integer;
begin
  Buf := c;
  repeat
    while ReadChar(c) and isRelation(c) do Buf := Buf + c;
    if isComment(c) then GetComment(c) else ReturnChar(c);
    ReadChar(c);
  until not isRelation(c);
  ReturnChar(c);
end;

end.
