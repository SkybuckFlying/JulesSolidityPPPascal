unit CodeGenerator;

{$MODE OBJFPC}{$H+}

interface

uses
  AST, SymbolTable, Bytecode, Generics.Collections;

type
  TVariableMap = specialize TDictionary<string, integer>;

  TCodeGenerator = class
  private
    FChunk: TChunk;
    FVariables: TVariableMap;
    FVarCount: integer;
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
  public
    constructor Create;
    destructor Destroy; override;
    function Generate(ATree: TASTNode): TChunk;
  end;

implementation

uses
  SysUtils;

{ TCodeGenerator }

constructor TCodeGenerator.Create;
begin
  inherited Create;
  FChunk := TChunk.Create;
  FVariables := TVariableMap.Create;
  FVarCount := 0;
end;

destructor TCodeGenerator.Destroy;
begin
  FChunk.Free;
  FVariables.Free;
  inherited;
end;

function TCodeGenerator.Generate(ATree: TASTNode): TChunk;
begin
  Visit(ATree);
  Result := FChunk;
end;

procedure TCodeGenerator.Visit(ANode: TASTNode);
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
  else
    raise Exception.Create('Unsupported AST node type for code generation');
end;

procedure TCodeGenerator.VisitContractNode(ANode: TContractNode);
var
  Declaration: TASTNode;
begin
  for Declaration in ANode.Declarations do
    Visit(Declaration);
end;

procedure TCodeGenerator.VisitVariableDeclarationNode(ANode: TVariableDeclarationNode);
begin
  FVariables.Add(ANode.Name, FVarCount);
  Inc(FVarCount);
end;

procedure TCodeGenerator.VisitEventDeclarationNode(ANode: TEventDeclarationNode);
begin
  // Not generating code for event declarations themselves.
end;

procedure TCodeGenerator.VisitProcedureDeclarationNode(ANode: TProcedureDeclarationNode);
var
  Statement: TStatementNode;
begin
  for Statement in ANode.Body do
    Visit(Statement);
  FChunk.WriteOp(opHalt);
end;

procedure TCodeGenerator.VisitFunctionDeclarationNode(ANode: TFunctionDeclarationNode);
var
  Statement: TStatementNode;
begin
  for Statement in ANode.Body do
    Visit(Statement);
  FChunk.WriteOp(opHalt);
end;

procedure TCodeGenerator.VisitConstructorDeclarationNode(ANode: TConstructorDeclarationNode);
begin
  // Not generating constructor code yet.
end;

procedure TCodeGenerator.VisitTypeDeclarationNode(ANode: TTypeDeclarationNode);
begin
  // Type declarations don't generate executable code.
end;

procedure TCodeGenerator.VisitAssignmentStatementNode(ANode: TAssignmentStatementNode);
var
  VarIndex: integer;
begin
  Visit(ANode.Expression);
  if not FVariables.TryGetValue(ANode.Variable.Name, VarIndex) then
    raise Exception.CreateFmt('CodeGen: Undeclared identifier %s', [ANode.Variable.Name]);
  FChunk.WriteOp(opStore);
  FChunk.Write(VarIndex);
end;

procedure TCodeGenerator.VisitVariableReferenceNode(ANode: TVariableReferenceNode);
var
  VarIndex: integer;
begin
  if not FVariables.TryGetValue(ANode.Name, VarIndex) then
    raise Exception.CreateFmt('CodeGen: Undeclared identifier %s', [ANode.Name]);
  FChunk.WriteOp(opLoad);
  FChunk.Write(VarIndex);
end;

procedure TCodeGenerator.VisitIntegerLiteralNode(ANode: TIntegerLiteralNode);
begin
  FChunk.WriteOp(opPush);
  FChunk.Write(ANode.Value);
end;

procedure TCodeGenerator.VisitBooleanLiteralNode(ANode: TBooleanLiteralNode);
begin
  FChunk.WriteOp(opPush);
  if ANode.Value then
    FChunk.Write(1)
  else
    FChunk.Write(0);
end;

procedure TCodeGenerator.VisitIfStatementNode(ANode: TIfStatementNode);
var
  JumpAddress, EndAddress: integer;
  Statement: TStatementNode;
begin
  Visit(ANode.Condition);
  FChunk.WriteOp(opJumpIfFalse);
  JumpAddress := FChunk.Count;
  FChunk.Write(0);
  for Statement in ANode.ThenBranch do
    Visit(Statement);
  EndAddress := FChunk.Count;
  FChunk.Patch(JumpAddress, EndAddress);
end;

procedure TCodeGenerator.VisitEmitStatementNode(ANode: TEmitStatementNode);
var
  Arg: TExpressionNode;
begin
  for Arg in ANode.Arguments do
    Visit(Arg);

  FChunk.WriteOp(opEmit);
  FChunk.Write(ANode.Arguments.Count);
end;

procedure TCodeGenerator.VisitMemberAccessNode(ANode: TMemberAccessNode);
begin
  // For now, this is a placeholder. A real implementation would handle
  // different objects (like 'msg') and members (like 'sender').
  // We'll just push a placeholder value (0) for now.
  FChunk.WriteOp(opPush);
  FChunk.Write(0);
end;

end.