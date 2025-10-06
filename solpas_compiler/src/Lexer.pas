unit Lexer;

{$MODE OBJFPC}{$H+}

interface

uses
  Token;

type
  TLexer = class
  private
    FSource: string;
    FPosition: integer;
    FLine: integer;
    FColumn: integer;
    FCurrentChar: char;
    procedure Advance;
    procedure SkipWhitespace;
    procedure SkipComment;
    function Peek: char;
    function IntegerLiteral: TToken;
    function StringLiteral: TToken;
    function Identifier: TToken;
    function GetKeywordTokenType(const AIdentifier: string): TTokenType;
    function NewToken(ATokenType: TTokenType; ALexeme: string): TToken;
  public
    constructor Create(const Source: string);
    function NextToken: TToken;
  end;

implementation

uses
  SysUtils;

{ TLexer }

constructor TLexer.Create(const Source: string);
begin
  FSource := Source;
  FPosition := 1;
  FLine := 1;
  FColumn := 1;
  if Length(FSource) > 0 then
    FCurrentChar := FSource[FPosition]
  else
    FCurrentChar := #0;
end;

procedure TLexer.Advance;
begin
  if FPosition > Length(FSource) then
  begin
    FCurrentChar := #0; // End of file
    Exit;
  end;

  if FCurrentChar = #10 then // Newline
  begin
    Inc(FLine);
    FColumn := 1;
  end
  else
  begin
    Inc(FColumn);
  end;

  Inc(FPosition);
  if FPosition > Length(FSource) then
    FCurrentChar := #0
  else
    FCurrentChar := FSource[FPosition];
end;

function TLexer.Peek: char;
var
  PeekPos: integer;
begin
  PeekPos := FPosition + 1;
  if PeekPos > Length(FSource) then
    Result := #0
  else
    Result := FSource[PeekPos];
end;

procedure TLexer.SkipWhitespace;
begin
  while (FCurrentChar <> #0) and (FCurrentChar <= ' ') do
    Advance;
end;

procedure TLexer.SkipComment;
begin
  if FCurrentChar = '{' then
  begin
    while FCurrentChar <> '}' do
      Advance;
    Advance; // Skip the closing '}'
    Exit;
  end;

  if (FCurrentChar = '/') and (Peek = '/') then
  begin
    while (FCurrentChar <> #10) and (FCurrentChar <> #0) do
      Advance;
  end;
end;

function TLexer.IntegerLiteral: TToken;
var
  Lexeme: string;
begin
  Result.Line := FLine;
  Result.Column := FColumn;
  Result.TokenType := ttIntegerLiteral;
  Lexeme := '';
  while (FCurrentChar <> #0) and CharInSet(FCurrentChar, ['0'..'9']) do
  begin
    Lexeme := Lexeme + FCurrentChar;
    Advance;
  end;
  Result.Lexeme := Lexeme;
end;

function TLexer.StringLiteral: TToken;
var
  Lexeme: string;
begin
  Result.Line := FLine;
  Result.Column := FColumn;
  Result.TokenType := ttStringLiteral;
  Lexeme := '';
  Advance; // Skip opening '
  while (FCurrentChar <> #0) and (FCurrentChar <> '''') do
  begin
    Lexeme := Lexeme + FCurrentChar;
    Advance;
  end;
  Advance; // Skip closing '
  Result.Lexeme := Lexeme;
end;

function TLexer.GetKeywordTokenType(const AIdentifier: string): TTokenType;
begin
  if AIdentifier = 'contract' then Result := ttContract
  else if AIdentifier = 'var' then Result := ttVar
  else if AIdentifier = 'procedure' then Result := ttProcedure
  else if AIdentifier = 'function' then Result := ttFunction
  else if AIdentifier = 'begin' then Result := ttBegin
  else if AIdentifier = 'end' then Result := ttEnd
  else if AIdentifier = 'if' then Result := ttIf
  else if AIdentifier = 'then' then Result := ttThen
  else if AIdentifier = 'else' then Result := ttElse
  else if AIdentifier = 'for' then Result := ttFor
  else if AIdentifier = 'to' then Result := ttTo
  else if AIdentifier = 'do' then Result := ttDo
  else if AIdentifier = 'while' then Result := ttWhile
  else if AIdentifier = 'repeat' then Result := ttRepeat
  else if AIdentifier = 'until' then Result := ttUntil
  else if AIdentifier = 'case' then Result := ttCase
  else if AIdentifier = 'of' then Result := ttOf
  else if AIdentifier = 'type' then Result := ttType
  else if AIdentifier = 'event' then Result := ttEvent
  else if AIdentifier = 'emit' then Result := ttEmit
  else if AIdentifier = 'modifier' then Result := ttModifier
  else if AIdentifier = 'constructor' then Result := ttConstructor
  else Result := ttIdentifier;
end;

function TLexer.Identifier: TToken;
var
  Lexeme: string;
begin
  Result.Line := FLine;
  Result.Column := FColumn;
  Lexeme := '';
  while (FCurrentChar <> #0) and (CharInSet(FCurrentChar, ['a'..'z', 'A'..'Z', '0'..'9', '_'])) do
  begin
    Lexeme := Lexeme + FCurrentChar;
    Advance;
  end;
  Result.Lexeme := Lexeme;
  Result.TokenType := GetKeywordTokenType(lowercase(Lexeme));
end;

function TLexer.NewToken(ATokenType: TTokenType; ALexeme: string): TToken;
begin
  Result.TokenType := ATokenType;
  Result.Lexeme := ALexeme;
  Result.Line := FLine;
  Result.Column := FColumn;
end;


function TLexer.NextToken: TToken;
begin
  while FCurrentChar <> #0 do
  begin
    if FCurrentChar <= ' ' then
    begin
      SkipWhitespace;
      Continue;
    end;

    if (FCurrentChar = '{') or ((FCurrentChar = '/') and (Peek = '/')) then
    begin
      SkipComment;
      Continue;
    end;

    if CharInSet(FCurrentChar, ['0'..'9']) then
      Exit(IntegerLiteral);

    if FCurrentChar = '''' then
      Exit(StringLiteral);

    if CharInSet(FCurrentChar, ['a'..'z', 'A'..'Z', '_']) then
      Exit(Identifier);

    // Delimiters
    case FCurrentChar of
      '+': Result := NewToken(ttPlus, '+');
      '-': Result := NewToken(ttMinus, '-');
      '*': Result := NewToken(ttMultiply, '*');
      '/': Result := NewToken(ttDivide, '/');
      '(': Result := NewToken(ttLParen, '(');
      ')': Result := NewToken(ttRParen, ')');
      '[': Result := NewToken(ttLBracket, '[');
      ']': Result := NewToken(ttRBracket, ']');
      ',': Result := NewToken(ttComma, ',');
      ';': Result := NewToken(ttSemicolon, ';');
      ':':
        if Peek = '=' then
        begin
          Advance;
          Result := NewToken(ttAssign, ':=');
        end
        else
          Result := NewToken(ttColon, ':');
      '.':
        if Peek = '.' then
        begin
          Advance;
          Result := NewToken(ttDotDot, '..');
        end
        else
          Result := NewToken(ttDot, '.');
      '=': Result := NewToken(ttEqual, '=');
      '<':
        if Peek = '>' then
        begin
          Advance;
          Result := NewToken(ttNotEqual, '<>');
        end
        else if Peek = '=' then
        begin
          Advance;
          Result := NewToken(ttLessThanOrEqual, '<=');
        end
        else
          Result := NewToken(ttLessThan, '<');
      '>':
        if Peek = '=' then
        begin
          Advance;
          Result := NewToken(ttGreaterThanOrEqual, '>=');
        end
        else
          Result := NewToken(ttGreaterThan, '>');
    end;
    Advance;
    Exit(Result);

  end;

  Result.TokenType := ttEOF;
  Result.Lexeme := '';
end;

end.