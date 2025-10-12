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
    function ParseStatementList: TStatementList;
    function ParseStatement: TStatementNode;
    function ParseAssignmentStatement: TAssignmentStatementNode;
    function ParseIfStatement: TIfStatementNode;
    function ParseEmitStatement: TEmitStatementNode;
    function ParseParameterList: TParameterList;
    function ParseExpression: TExpressionNode;
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
  SysUtils, TypInfo, strutils;

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

function TParser.ParseExpression: TExpressionNode;
var
  Token: TToken;
  Node: TExpressionNode;
  MemberName: string;
begin
  Result := nil;
  Token := FCurrentToken;
  case Token.TokenType of
    ttIntegerLiteral:
      begin
        Eat(ttIntegerLiteral);
        Node := TIntegerLiteralNode.Create(StrToInt(Token.Lexeme));
      end;
    ttTrue:
      begin
        Eat(ttTrue);
        Node := TBooleanLiteralNode.Create(true);
      end;
    ttFalse:
      begin
        Eat(ttFalse);
        Node := TBooleanLiteralNode.Create(false);
      end;
    ttIdentifier:
      begin
        Eat(ttIdentifier);
        Node := TVariableReferenceNode.Create(Token.Lexeme);
      end;
  else
    raise Exception.CreateFmt('Unexpected token in expression: %s', [Token.Lexeme]);
  end;

  while (FCurrentToken.TokenType = ttDot) or (FCurrentToken.TokenType = ttLBracket) do
  begin
    if FCurrentToken.TokenType = ttDot then
    begin
      Eat(ttDot);
      MemberName := FCurrentToken.Lexeme;
      Eat(ttIdentifier);
      Node := TMemberAccessNode.Create(Node, MemberName);
    end
    else if FCurrentToken.TokenType = ttLBracket then
    begin
      Eat(ttLBracket);
      Node := TDictionaryAccessNode.Create(Node, ParseExpression);
      Eat(ttRBracket);
    end
    else
      break;
  end;

  Result := Node;
end;

function TParser.ParseAssignmentStatement: TAssignmentStatementNode;
var
  VarRef: TVariableReferenceNode;
  Expr: TExpressionNode;
begin
  VarRef := TVariableReferenceNode.Create(FCurrentToken.Lexeme);
  Eat(ttIdentifier);
  Eat(ttAssign);
  Expr := ParseExpression;
  Result := TAssignmentStatementNode.Create(VarRef, Expr);
end;

function TParser.ParseStatement: TStatementNode;
begin
  Result := nil;
  case FCurrentToken.TokenType of
    ttIdentifier:
      Result := ParseAssignmentStatement;
    ttIf:
      Result := ParseIfStatement;
    ttEmit:
      Result := ParseEmitStatement;
  else
    raise Exception.CreateFmt('Unexpected token in statement: %s', [FCurrentToken.Lexeme]);
  end;
end;

function TParser.ParseEmitStatement: TEmitStatementNode;
var
  EventName: string;
  Args: TExpressionList;
begin
  Eat(ttEmit);
  EventName := FCurrentToken.Lexeme;
  Eat(ttIdentifier);

  Args := TExpressionList.Create;
  Eat(ttLParen);
  if FCurrentToken.TokenType <> ttRParen then
  begin
    Args.Add(ParseExpression);
    while FCurrentToken.TokenType = ttComma do
    begin
      Eat(ttComma);
      Args.Add(ParseExpression);
    end;
  end;
  Eat(ttRParen);

  Result := TEmitStatementNode.Create(EventName, Args);
end;

function TParser.ParseIfStatement: TIfStatementNode;
var
  Condition: TExpressionNode;
  ThenBranch: TStatementList;
begin
  Eat(ttIf);
  Condition := ParseExpression;
  Eat(ttThen);
  ThenBranch := ParseStatementList;
  Result := TIfStatementNode.Create(Condition, ThenBranch);
end;

function TParser.ParseStatementList: TStatementList;
begin
  Result := TStatementList.Create;
  Eat(ttBegin);
  while FCurrentToken.TokenType <> ttEnd do
  begin
    Result.Add(ParseStatement);
    Eat(ttSemicolon);
  end;
  Eat(ttEnd);
end;

function TParser.ParseParameterList: TParameterList;
var
  ParamName: string;
  ParamType: TTypeSpecifierNode;
begin
  Result := TParameterList.Create;
  Eat(ttLParen);
  if FCurrentToken.TokenType <> ttRParen then
  begin
    ParamName := FCurrentToken.Lexeme;
    Eat(ttIdentifier);
    Eat(ttColon);
    ParamType := ParseTypeSpecifier;
    Result.Add(TParameterNode.Create(ParamName, ParamType));

    while FCurrentToken.TokenType = ttSemicolon do
    begin
      Eat(ttSemicolon);
      ParamName := FCurrentToken.Lexeme;
      Eat(ttIdentifier);
      Eat(ttColon);
      ParamType := ParseTypeSpecifier;
      Result.Add(TParameterNode.Create(ParamName, ParamType));
    end;
  end;
  Eat(ttRParen);
end;

function TParser.ParseProcedureDeclaration: TProcedureDeclarationNode;
var
  ProcName: string;
  Params: TParameterList;
  Visibility: string;
  Body: TStatementList;
begin
  Eat(ttProcedure);
  ProcName := FCurrentToken.Lexeme;
  Eat(ttIdentifier);

  if FCurrentToken.TokenType = ttLParen then
    Params := ParseParameterList
  else
    Params := TParameterList.Create;

  Visibility := '';
  if FCurrentToken.TokenType = ttIdentifier then
  begin
    Visibility := FCurrentToken.Lexeme;
    Eat(ttIdentifier);
  end;

  Eat(ttSemicolon);
  Body := ParseStatementList;
  Result := TProcedureDeclarationNode.Create(ProcName, Params, Visibility, Body);
  Eat(ttSemicolon);
end;

function TParser.ParseFunctionDeclaration: TFunctionDeclarationNode;
var
  FuncName: string;
  Params: TParameterList;
  Visibility: string;
  Body: TStatementList;
begin
  Eat(ttFunction);
  FuncName := FCurrentToken.Lexeme;
  Eat(ttIdentifier);

  if FCurrentToken.TokenType = ttLParen then
    Params := ParseParameterList
  else
    Params := TParameterList.Create;

  // Optional: visibility specifier
  Visibility := '';
  if FCurrentToken.TokenType = ttIdentifier then
  begin
    Visibility := FCurrentToken.Lexeme;
    Eat(ttIdentifier);
  end;

  Eat(ttSemicolon);
  Body := ParseStatementList;
  Result := TFunctionDeclarationNode.Create(FuncName, Params, Visibility, Body);
  Eat(ttSemicolon);
end;

function TParser.ParseConstructorDeclaration: TConstructorDeclarationNode;
var
  Params: TParameterList;
  Body: TStatementList;
begin
  Eat(ttConstructor);

  if FCurrentToken.TokenType = ttIdentifier then
    Eat(ttIdentifier);

  if FCurrentToken.TokenType = ttLParen then
    Params := ParseParameterList
  else
    Params := TParameterList.Create;

  Eat(ttSemicolon);

  Body := ParseStatementList;

  Result := TConstructorDeclarationNode.Create(Params, Body);
  Eat(ttSemicolon);
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