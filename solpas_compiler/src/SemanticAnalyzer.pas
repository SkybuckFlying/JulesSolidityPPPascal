unit SemanticAnalyzer;

{$MODE OBJFPC}{$H+}

interface

uses
  AST, SymbolTable;

type
  TSemanticAnalyzer = class
  private
    FCurrentScope: TSymbolTable;
    procedure Visit(ANode: TASTNode);
    procedure VisitContractNode(ANode: TContractNode);
    procedure VisitVariableDeclarationNode(ANode: TVariableDeclarationNode);
    procedure VisitEventDeclarationNode(ANode: TEventDeclarationNode);
    procedure VisitProcedureDeclarationNode(ANode: TProcedureDeclarationNode);
    procedure VisitFunctionDeclarationNode(ANode: TFunctionDeclarationNode);
    procedure VisitConstructorDeclarationNode(ANode: TConstructorDeclarationNode);
    procedure VisitTypeDeclarationNode(ANode: TTypeDeclarationNode);
    procedure VisitAssignmentStatementNode(ANode: TAssignmentStatementNode);
    procedure VisitVariableReferenceNode(ANode: TVariableReferenceNode);
    procedure VisitIntegerLiteralNode(ANode: TIntegerLiteralNode);
    procedure VisitBooleanLiteralNode(ANode: TBooleanLiteralNode);
    procedure VisitIfStatementNode(ANode: TIfStatementNode);
    procedure VisitEmitStatementNode(ANode: TEmitStatementNode);
    procedure VisitMemberAccessNode(ANode: TMemberAccessNode);
    procedure VisitParameterNode(ANode: TParameterNode);

  public
    constructor Create;
    destructor Destroy; override;
    procedure Analyze(ATree: TASTNode);
  end;

implementation

uses
  SysUtils, StrUtils;

{ TSemanticAnalyzer }

constructor TSemanticAnalyzer.Create;
var
  BuiltInTypeSymbol: TSymbol;
begin
  // Global scope
  FCurrentScope := TSymbolTable.Create;
  // Define built-in types
  BuiltInTypeSymbol := TSymbol.Create('cardinal', nil);
  FCurrentScope.Define(BuiltInTypeSymbol);
  BuiltInTypeSymbol := TSymbol.Create('integer', nil);
  FCurrentScope.Define(BuiltInTypeSymbol);
  BuiltInTypeSymbol := TSymbol.Create('string', nil);
  FCurrentScope.Define(BuiltInTypeSymbol);
  BuiltInTypeSymbol := TSymbol.Create('boolean', nil);
  FCurrentScope.Define(BuiltInTypeSymbol);
  BuiltInTypeSymbol := TSymbol.Create('address', nil);
  FCurrentScope.Define(BuiltInTypeSymbol);
  BuiltInTypeSymbol := TSymbol.Create('TDictionary', nil);
  FCurrentScope.Define(BuiltInTypeSymbol);
  BuiltInTypeSymbol := TSymbol.Create('msg', nil); // Special global object
  FCurrentScope.Define(BuiltInTypeSymbol);
end;

destructor TSemanticAnalyzer.Destroy;
begin
  if Assigned(FCurrentScope) then
  begin
    Assert(FCurrentScope.Parent = nil);
    FCurrentScope.Free;
  end;
  inherited;
end;

procedure TSemanticAnalyzer.Analyze(ATree: TASTNode);
begin
  Visit(ATree);
end;

procedure TSemanticAnalyzer.Visit(ANode: TASTNode);
begin
  if not Assigned(ANode) then
    Exit;

  if ANode is TContractNode then
    VisitContractNode(TContractNode(ANode))
  else if ANode is TVariableDeclarationNode then
    VisitVariableDeclarationNode(TVariableDeclarationNode(ANode))
  else if ANode is TEventDeclarationNode then
    VisitEventDeclarationNode(TEventDeclarationNode(ANode))
  else if ANode is TProcedureDeclarationNode then
    VisitProcedureDeclarationNode(TProcedureDeclarationNode(ANode))
  else if ANode is TFunctionDeclarationNode then
    VisitFunctionDeclarationNode(TFunctionDeclarationNode(ANode))
  else if ANode is TConstructorDeclarationNode then
    VisitConstructorDeclarationNode(TConstructorDeclarationNode(ANode))
  else if ANode is TTypeDeclarationNode then
    VisitTypeDeclarationNode(TTypeDeclarationNode(ANode))
  else if ANode is TAssignmentStatementNode then
    VisitAssignmentStatementNode(TAssignmentStatementNode(ANode))
  else if ANode is TVariableReferenceNode then
    VisitVariableReferenceNode(TVariableReferenceNode(ANode))
  else if ANode is TIntegerLiteralNode then
    VisitIntegerLiteralNode(TIntegerLiteralNode(ANode))
  else if ANode is TBooleanLiteralNode then
    VisitBooleanLiteralNode(TBooleanLiteralNode(ANode))
  else if ANode is TIfStatementNode then
    VisitIfStatementNode(TIfStatementNode(ANode))
  else if ANode is TEmitStatementNode then
    VisitEmitStatementNode(TEmitStatementNode(ANode))
  else if ANode is TMemberAccessNode then
    VisitMemberAccessNode(TMemberAccessNode(ANode))
  else if ANode is TParameterNode then
    VisitParameterNode(TParameterNode(ANode))
  else
    raise Exception.Create('Unsupported AST node type');
end;

procedure TSemanticAnalyzer.VisitContractNode(ANode: TContractNode);
var
  Declaration: TASTNode;
  ContractScope: TSymbolTable;
begin
  ContractScope := TSymbolTable.Create(FCurrentScope);
  FCurrentScope := ContractScope;

  for Declaration in ANode.Declarations do
    Visit(Declaration);

  FCurrentScope := FCurrentScope.Parent;
  ContractScope.Free;
end;

procedure TSemanticAnalyzer.VisitVariableDeclarationNode(ANode: TVariableDeclarationNode);
var
  Symbol: TSymbol;
  FullTypeName: string;
  BaseTypeName: string;
begin
  FullTypeName := ANode.VarType.Name;
  BaseTypeName := FullTypeName;

  if Pos('<', FullTypeName) > 0 then
    BaseTypeName := LeftStr(FullTypeName, Pos('<', FullTypeName) - 1);

  if FCurrentScope.Resolve(BaseTypeName) = nil then
    raise Exception.CreateFmt('Unknown type: %s', [BaseTypeName]);

  Symbol := TSymbol.Create(ANode.Name, ANode.VarType);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);
end;

procedure TSemanticAnalyzer.VisitEventDeclarationNode(ANode: TEventDeclarationNode);
var
  Symbol: TSymbol;
begin
  Symbol := TSymbol.Create(ANode.Name, ANode);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);
end;

procedure TSemanticAnalyzer.VisitProcedureDeclarationNode(ANode: TProcedureDeclarationNode);
var
  Symbol: TSymbol;
  Statement: TStatementNode;
  ParamNode: TParameterNode;
  ProcScope: TSymbolTable;
begin
  Symbol := TSymbol.Create(ANode.Name, ANode);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);

  ProcScope := TSymbolTable.Create(FCurrentScope);
  FCurrentScope := ProcScope;

  for ParamNode in ANode.Params do
    Visit(ParamNode);

  for Statement in ANode.Body do
    Visit(Statement);

  FCurrentScope := FCurrentScope.Parent;
  ProcScope.Free;
end;

procedure TSemanticAnalyzer.VisitFunctionDeclarationNode(ANode: TFunctionDeclarationNode);
var
  Symbol: TSymbol;
  Statement: TStatementNode;
  ParamNode: TParameterNode;
  FuncScope: TSymbolTable;
begin
  Symbol := TSymbol.Create(ANode.Name, ANode);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);

  FuncScope := TSymbolTable.Create(FCurrentScope);
  FCurrentScope := FuncScope;

  for ParamNode in ANode.Params do
    Visit(ParamNode);

  for Statement in ANode.Body do
    Visit(Statement);

  FCurrentScope := FCurrentScope.Parent;
  FuncScope.Free;
end;

procedure TSemanticAnalyzer.VisitConstructorDeclarationNode(ANode: TConstructorDeclarationNode);
var
  Statement: TStatementNode;
  ParamNode: TParameterNode;
  ConstructorScope: TSymbolTable;
begin
  ConstructorScope := TSymbolTable.Create(FCurrentScope);
  FCurrentScope := ConstructorScope;

  for ParamNode in ANode.Params do
    Visit(ParamNode);

  for Statement in ANode.Body do
    Visit(Statement);

  FCurrentScope := FCurrentScope.Parent;
  ConstructorScope.Free;
end;

procedure TSemanticAnalyzer.VisitTypeDeclarationNode(ANode: TTypeDeclarationNode);
var
  Symbol: TSymbol;
begin
  Symbol := TSymbol.Create(ANode.Name, ANode);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);
end;

procedure TSemanticAnalyzer.VisitAssignmentStatementNode(ANode: TAssignmentStatementNode);
begin
  Visit(ANode.Variable);
  Visit(ANode.Expression);
  // Type checking would go here in a real compiler
end;

procedure TSemanticAnalyzer.VisitVariableReferenceNode(ANode: TVariableReferenceNode);
begin
  if FCurrentScope.Resolve(ANode.Name) = nil then
    raise Exception.CreateFmt('Undeclared identifier: %s', [ANode.Name]);
end;

procedure TSemanticAnalyzer.VisitIntegerLiteralNode(ANode: TIntegerLiteralNode);
begin
  // No analysis needed for a literal
end;

procedure TSemanticAnalyzer.VisitBooleanLiteralNode(ANode: TBooleanLiteralNode);
begin
  // No analysis needed for a literal
end;

procedure TSemanticAnalyzer.VisitIfStatementNode(ANode: TIfStatementNode);
var
  Statement: TStatementNode;
begin
  Visit(ANode.Condition);
  for Statement in ANode.ThenBranch do
    Visit(Statement);
end;

procedure TSemanticAnalyzer.VisitEmitStatementNode(ANode: TEmitStatementNode);
var
  Symbol: TSymbol;
  Arg: TExpressionNode;
begin
  Symbol := FCurrentScope.Resolve(ANode.EventName);
  if Symbol = nil then
    raise Exception.CreateFmt('Undeclared event: %s', [ANode.EventName]);

  if not (Symbol.SymbolType is TEventDeclarationNode) then
    raise Exception.CreateFmt('%s is not an event', [ANode.EventName]);

  for Arg in ANode.Arguments do
    Visit(Arg);
end;

procedure TSemanticAnalyzer.VisitMemberAccessNode(ANode: TMemberAccessNode);
begin
  Visit(ANode.Obj);
  // In a real compiler, we would check if Obj has the member MemberName.
end;

procedure TSemanticAnalyzer.VisitParameterNode(ANode: TParameterNode);
var
  Symbol: TSymbol;
begin
  // In a real compiler, we would check the parameter's type.
  Symbol := TSymbol.Create(ANode.Name, ANode.ParamType);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate parameter identifier: %s', [ANode.Name]);
end;

end.