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
  // Events are handled by the runtime, not directly in bytecode for now.
end;

procedure TCodeGenerator.VisitProcedureDeclarationNode(ANode: TProcedureDeclarationNode);
var
  Statement: TStatementNode;
begin
  // In a real compiler, we would handle function entry/exit, parameters, etc.
  for Statement in ANode.Body do
    Visit(Statement);
  FChunk.WriteOp(opHalt);
end;

procedure TCodeGenerator.VisitFunctionDeclarationNode(ANode: TFunctionDeclarationNode);
begin
  // For now, treat as a procedure.
  VisitProcedureDeclarationNode(TProcedureDeclarationNode(ANode));
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
  // Generate code for the expression first, which will leave its value on the stack.
  Visit(ANode.Expression);

  // Then, generate code to store the value.
  if not FVariables.TryGetValue(ANode.Variable.Name, VarIndex) then
    raise Exception.CreateFmt('CodeGen: Undeclared identifier %s', [ANode.Variable.Name]);

  FChunk.WriteOp(opStore);
  FChunk.Write(VarIndex); // Write the variable's "address" (slot index).
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
  FChunk.Write(ANode.Value); // For now, assumes values fit in a single byte.
end;

end.