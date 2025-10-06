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

  // Handle generic types like TDictionary<address, cardinal>
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
  // For now, just register the event name
  Symbol := TSymbol.Create(ANode.Name, ANode);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);
end;

procedure TSemanticAnalyzer.VisitProcedureDeclarationNode(ANode: TProcedureDeclarationNode);
var
  Symbol: TSymbol;
begin
  // For now, just register the procedure name
  Symbol := TSymbol.Create(ANode.Name, ANode);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);
end;

procedure TSemanticAnalyzer.VisitFunctionDeclarationNode(ANode: TFunctionDeclarationNode);
var
  Symbol: TSymbol;
begin
  // For now, just register the function name
  Symbol := TSymbol.Create(ANode.Name, ANode);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);
end;

procedure TSemanticAnalyzer.VisitConstructorDeclarationNode(ANode: TConstructorDeclarationNode);
begin
  // For now, we don't need to do anything special.
  // In the future, we would analyze the constructor's body.
end;

procedure TSemanticAnalyzer.VisitTypeDeclarationNode(ANode: TTypeDeclarationNode);
var
  Symbol: TSymbol;
begin
  // Register the new type in the current scope.
  Symbol := TSymbol.Create(ANode.Name, ANode);
  if not FCurrentScope.Define(Symbol) then
    raise Exception.CreateFmt('Duplicate identifier: %s', [ANode.Name]);
end;

end.