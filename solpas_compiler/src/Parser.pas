unit Parser;

{$MODE OBJFPC}{$H+}

interface

uses
  Lexer, Token, AST;

type
  TParser = class
  private
    FLexer: TLexer;
    FCurrentToken: TToken;
    procedure Eat(ATokenType: TTokenType);
    function ParseTypeSpecifier: TTypeSpecifierNode;
    procedure ParseVarBlock(AContract: TContractNode);
    procedure ParseTypeBlock(AContract: TContractNode);
    function ParseEventDeclaration: TEventDeclarationNode;
    procedure SkipBlock;
    function ParseProcedureDeclaration: TProcedureDeclarationNode;
    function ParseFunctionDeclaration: TFunctionDeclarationNode;
    function ParseConstructorDeclaration: TConstructorDeclarationNode;
    procedure ParseDeclarations(AContract: TContractNode);
    function ParseContract: TContractNode;
  public
    constructor Create(ALexer: TLexer);
    function Parse: TASTNode; // Returns the root of the AST
  end;

implementation

uses
  SysUtils, TypInfo;

{ TParser }

constructor TParser.Create(ALexer: TLexer);
begin
  FLexer := ALexer;
  FCurrentToken := FLexer.NextToken;
end;

procedure TParser.Eat(ATokenType: TTokenType);
begin
  if FCurrentToken.TokenType = ATokenType then
    FCurrentToken := FLexer.NextToken
  else
    raise Exception.CreateFmt('Expected token %s but got %s at line %d, col %d', [GetEnumName(TypeInfo(TTokenType), Ord(ATokenType)), GetEnumName(TypeInfo(TTokenType), Ord(FCurrentToken.TokenType)), FCurrentToken.Line, FCurrentToken.Column]);
end;

function TParser.ParseTypeSpecifier: TTypeSpecifierNode;
var
  Token: TToken;
  TypeName: string;
begin
  Token := FCurrentToken;
  Eat(ttIdentifier);
  TypeName := Token.Lexeme;

  if FCurrentToken.TokenType = ttLessThan then
  begin
    TypeName := TypeName + '<';
    Eat(ttLessThan);

    while (FCurrentToken.TokenType <> ttGreaterThan) and (FCurrentToken.TokenType <> ttEOF) do
    begin
        TypeName := TypeName + FCurrentToken.Lexeme;
        FCurrentToken := FLexer.NextToken;
    end;

    TypeName := TypeName + '>';
    Eat(ttGreaterThan);
  end;

  Result := TTypeSpecifierNode.Create(TypeName);
end;

procedure TParser.ParseVarBlock(AContract: TContractNode);
var
  VarName: string;
  VarType: TTypeSpecifierNode;
begin
  Eat(ttVar);
  while FCurrentToken.TokenType = ttIdentifier do
  begin
    VarName := FCurrentToken.Lexeme;
    Eat(ttIdentifier);
    Eat(ttColon);
    VarType := ParseTypeSpecifier;
    AContract.AddDeclaration(TVariableDeclarationNode.Create(VarName, VarType));
    Eat(ttSemicolon);
  end;
end;

procedure TParser.ParseTypeBlock(AContract: TContractNode);
var
  TypeName: string;
begin
    Eat(ttType);
    while FCurrentToken.TokenType = ttIdentifier do
    begin
        TypeName := FCurrentToken.Lexeme;
        Eat(ttIdentifier);
        Eat(ttEqual);
        // For now, we are not parsing the complex type definition, just skipping to the end.
        while (FCurrentToken.TokenType <> ttSemicolon) and (FCurrentToken.TokenType <> ttEOF) do
        begin
            FCurrentToken := FLexer.NextToken;
        end;
        AContract.AddDeclaration(TTypeDeclarationNode.Create(TypeName));
        Eat(ttSemicolon);
    end;
end;

function TParser.ParseEventDeclaration: TEventDeclarationNode;
var
  EventName: string;
begin
  Eat(ttEvent);
  EventName := FCurrentToken.Lexeme;
  Eat(ttIdentifier);
  // For now, skip parameters
  if FCurrentToken.TokenType = ttLParen then
  begin
    Eat(ttLParen);
    while (FCurrentToken.TokenType <> ttRParen) and (FCurrentToken.TokenType <> ttEOF) do
      FCurrentToken := FLexer.NextToken;
    Eat(ttRParen);
  end;
  Eat(ttSemicolon);
  Result := TEventDeclarationNode.Create(EventName);
end;

procedure TParser.SkipBlock;
var
  level: integer;
begin
  Eat(ttBegin);
  level := 1;
  while level > 0 do
  begin
    case FCurrentToken.TokenType of
      ttBegin: Inc(level);
      ttEnd: Dec(level);
      ttEOF: raise Exception.Create('Unterminated block');
    end;
    // Consume the token we just inspected
    FCurrentToken := FLexer.NextToken;
  end;
end;

function TParser.ParseProcedureDeclaration: TProcedureDeclarationNode;
var
  ProcName: string;
begin
  Eat(ttProcedure);
  ProcName := FCurrentToken.Lexeme;
  Eat(ttIdentifier);

  // Skip signature (params and visibility)
  while (FCurrentToken.TokenType <> ttBegin) and (FCurrentToken.TokenType <> ttEOF) do
  begin
      FCurrentToken := FLexer.NextToken;
  end;

  SkipBlock;
  Eat(ttSemicolon);

  Result := TProcedureDeclarationNode.Create(ProcName);
end;

function TParser.ParseFunctionDeclaration: TFunctionDeclarationNode;
var
  FuncName: string;
begin
  Eat(ttFunction);
  FuncName := FCurrentToken.Lexeme;
  Eat(ttIdentifier);

  // Skip signature
  while (FCurrentToken.TokenType <> ttBegin) and (FCurrentToken.TokenType <> ttEOF) do
  begin
      FCurrentToken := FLexer.NextToken;
  end;

  SkipBlock;
  Eat(ttSemicolon);

  Result := TFunctionDeclarationNode.Create(FuncName);
end;

function TParser.ParseConstructorDeclaration: TConstructorDeclarationNode;
begin
  Eat(ttConstructor);

  // Skip signature
  while (FCurrentToken.TokenType <> ttBegin) and (FCurrentToken.TokenType <> ttEOF) do
  begin
      FCurrentToken := FLexer.NextToken;
  end;

  SkipBlock;
  Eat(ttSemicolon);

  Result := TConstructorDeclarationNode.Create;
end;

procedure TParser.ParseDeclarations(AContract: TContractNode);
begin
  while (FCurrentToken.TokenType <> ttEnd) and (FCurrentToken.TokenType <> ttEOF) do
  begin
    case FCurrentToken.TokenType of
      ttVar: ParseVarBlock(AContract);
      ttType: ParseTypeBlock(AContract);
      ttEvent: AContract.AddDeclaration(ParseEventDeclaration);
      ttProcedure: AContract.AddDeclaration(ParseProcedureDeclaration);
      ttFunction: AContract.AddDeclaration(ParseFunctionDeclaration);
      ttConstructor: AContract.AddDeclaration(ParseConstructorDeclaration);
    else
      raise Exception.CreateFmt('Unexpected token in declarations section: %s at line %d, col %d', [GetEnumName(TypeInfo(TTokenType), Ord(FCurrentToken.TokenType)), FCurrentToken.Line, FCurrentToken.Column]);
    end;
  end;
end;

function TParser.ParseContract: TContractNode;
var
  ContractName: string;
  ContractNode: TContractNode;
begin
  Eat(ttContract);
  ContractName := FCurrentToken.Lexeme;
  Eat(ttIdentifier);
  Eat(ttSemicolon);

  ContractNode := TContractNode.Create(ContractName);

  ParseDeclarations(ContractNode);

  Eat(ttEnd);
  Eat(ttDot);

  Result := ContractNode;
end;

function TParser.Parse: TASTNode;
begin
  Result := ParseContract;
  if FCurrentToken.TokenType <> ttEOF then
    raise Exception.Create('Extra characters at the end of the file.');
end;

end.