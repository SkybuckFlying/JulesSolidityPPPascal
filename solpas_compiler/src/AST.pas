unit AST;

{$MODE OBJFPC}{$H+}

interface

uses
  Generics.Collections;

type
  TASTNode = class
  public
    // Base class for all AST nodes
  end;

  TExpressionNode = class(TASTNode);
  TStatementNode = class(TASTNode);

  TStatementList = specialize TList<TStatementNode>;

  TVariableReferenceNode = class(TExpressionNode)
  private
    FName: string;
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TIntegerLiteralNode = class(TExpressionNode)
  private
    FValue: integer;
  public
    constructor Create(AValue: integer);
    property Value: integer read FValue;
  end;

  TBooleanLiteralNode = class(TExpressionNode)
  private
    FValue: boolean;
  public
    constructor Create(AValue: boolean);
    property Value: boolean read FValue;
  end;

  TAssignmentStatementNode = class(TStatementNode)
  private
    FVariable: TVariableReferenceNode;
    FExpression: TExpressionNode;
  public
    constructor Create(AVariable: TVariableReferenceNode; AExpression: TExpressionNode);
    destructor Destroy; override;
    property Variable: TVariableReferenceNode read FVariable;
    property Expression: TExpressionNode read FExpression;
  end;

  TTypeSpecifierNode = class(TASTNode)
  private
    FName: string;
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TVariableDeclarationNode = class(TASTNode)
  private
    FName: string;
    FType: TTypeSpecifierNode;
  public
    constructor Create(AName: string; AType: TTypeSpecifierNode);
    destructor Destroy; override;
    property Name: string read FName;
    property VarType: TTypeSpecifierNode read FType;
  end;

  TFunctionDeclarationNode = class(TASTNode)
  private
    FName: string;
    FBody: TStatementList;
  public
    constructor Create(AName: string; ABody: TStatementList);
    destructor Destroy; override;
    property Name: string read FName;
    property Body: TStatementList read FBody;
  end;

  TProcedureDeclarationNode = class(TASTNode)
  private
    FName: string;
    FBody: TStatementList;
  public
    constructor Create(AName: string; ABody: TStatementList);
    destructor Destroy; override;
    property Name: string read FName;
    property Body: TStatementList read FBody;
  end;

  TEventDeclarationNode = class(TASTNode)
  private
    FName: string;
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TConstructorDeclarationNode = class(TASTNode)
  public
    constructor Create;
  end;

  TTypeDeclarationNode = class(TASTNode)
  private
    FName: string;
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TASTNodeList = specialize TList<TASTNode>;

  TContractNode = class(TASTNode)
  private
    FName: string;
    FDeclarations: TASTNodeList;
  public
    constructor Create(AName: string);
    destructor Destroy; override;
    procedure AddDeclaration(ADeclaration: TASTNode);
    property Name: string read FName;
    property Declarations: TASTNodeList read FDeclarations;
  end;


implementation

uses SysUtils;

{ TVariableReferenceNode }

constructor TVariableReferenceNode.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TIntegerLiteralNode }

constructor TIntegerLiteralNode.Create(AValue: integer);
begin
  inherited Create;
  FValue := AValue;
end;

{ TBooleanLiteralNode }

constructor TBooleanLiteralNode.Create(AValue: boolean);
begin
  inherited Create;
  FValue := AValue;
end;

{ TAssignmentStatementNode }

constructor TAssignmentStatementNode.Create(AVariable: TVariableReferenceNode; AExpression: TExpressionNode);
begin
  inherited Create;
  FVariable := AVariable;
  FExpression := AExpression;
end;

destructor TAssignmentStatementNode.Destroy;
begin
  FVariable.Free;
  FExpression.Free;
  inherited;
end;

{ TTypeSpecifierNode }

constructor TTypeSpecifierNode.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TVariableDeclarationNode }

constructor TVariableDeclarationNode.Create(AName: string; AType: TTypeSpecifierNode);
begin
  inherited Create;
  FName := AName;
  FType := AType;
end;

destructor TVariableDeclarationNode.Destroy;
begin
  FType.Free;
  inherited;
end;

{ TFunctionDeclarationNode }

constructor TFunctionDeclarationNode.Create(AName: string; ABody: TStatementList);
begin
  inherited Create;
  FName := AName;
  FBody := ABody;
end;

destructor TFunctionDeclarationNode.Destroy;
var
  Node: TStatementNode;
begin
  for Node in FBody do
    Node.Free;
  FBody.Free;
  inherited;
end;

{ TProcedureDeclarationNode }

constructor TProcedureDeclarationNode.Create(AName: string; ABody: TStatementList);
begin
  inherited Create;
  FName := AName;
  FBody := ABody;
end;

destructor TProcedureDeclarationNode.Destroy;
var
  Node: TStatementNode;
begin
  for Node in FBody do
    Node.Free;
  FBody.Free;
  inherited;
end;

{ TEventDeclarationNode }

constructor TEventDeclarationNode.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TConstructorDeclarationNode }

constructor TConstructorDeclarationNode.Create;
begin
  inherited Create;
end;

{ TTypeDeclarationNode }

constructor TTypeDeclarationNode.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TContractNode }

constructor TContractNode.Create(AName: string);
begin
  inherited Create;
  FName := AName;
  FDeclarations := TASTNodeList.Create;
end;

destructor TContractNode.Destroy;
var
  Node: TASTNode;
begin
  for Node in FDeclarations do
    Node.Free;
  FDeclarations.Free;
  inherited;
end;

procedure TContractNode.AddDeclaration(ADeclaration: TASTNode);
begin
  FDeclarations.Add(ADeclaration);
end;

end.