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

  TExpressionList = specialize TList<TExpressionNode>;

  TEmitStatementNode = class(TStatementNode)
  private
    FEventName: string;
    FArguments: TExpressionList;
  public
    constructor Create(AEventName: string; AArguments: TExpressionList);
    destructor Destroy; override;
    property EventName: string read FEventName;
    property Arguments: TExpressionList read FArguments;
  end;

  TStatementList = specialize TList<TStatementNode>;

  TVariableReferenceNode = class(TExpressionNode)
  private
    FName: string;
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TDictionaryAccessNode = class(TExpressionNode)
  private
    FDictionary: TExpressionNode;
    FKey: TExpressionNode;
  public
    constructor Create(ADictionary, AKey: TExpressionNode);
    destructor Destroy; override;
    property Dictionary: TExpressionNode read FDictionary;
    property Key: TExpressionNode read FKey;
  end;

  TMemberAccessNode = class(TExpressionNode)
  private
    FObject: TExpressionNode;
    FMemberName: string;
  public
    constructor Create(AObject: TExpressionNode; AMemberName: string);
    destructor Destroy; override;
    property Obj: TExpressionNode read FObject;
    property MemberName: string read FMemberName;
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

  TIfStatementNode = class(TStatementNode)
  private
    FCondition: TExpressionNode;
    FThenBranch: TStatementList;
    // FElseBranch: TStatementList will be added later
  public
    constructor Create(ACondition: TExpressionNode; AThenBranch: TStatementList);
    destructor Destroy; override;
    property Condition: TExpressionNode read FCondition;
    property ThenBranch: TStatementList read FThenBranch;
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

  TParameterNode = class(TASTNode)
  private
    FName: string;
    FType: TTypeSpecifierNode;
  public
    constructor Create(AName: string; AType: TTypeSpecifierNode);
    destructor Destroy; override;
    property Name: string read FName;
    property ParamType: TTypeSpecifierNode read FType;
  end;

  TParameterList = specialize TList<TParameterNode>;

  TFunctionDeclarationNode = class(TASTNode)
  private
    FName: string;
    FParams: TParameterList;
    FReturnType: TTypeSpecifierNode;
    FVisibility: string;
    FBody: TStatementList;
  public
    constructor Create(AName: string; AParams: TParameterList; AReturnType: TTypeSpecifierNode; AVisibility: string; ABody: TStatementList);
    destructor Destroy; override;
    property Name: string read FName;
    property Params: TParameterList read FParams;
    property ReturnType: TTypeSpecifierNode read FReturnType;
    property Visibility: string read FVisibility;
    property Body: TStatementList read FBody;
  end;

  TProcedureDeclarationNode = class(TASTNode)
  private
    FName: string;
    FParams: TParameterList;
    FVisibility: string;
    FBody: TStatementList;
  public
    constructor Create(AName: string; AParams: TParameterList; AVisibility: string; ABody: TStatementList);
    destructor Destroy; override;
    property Name: string read FName;
    property Params: TParameterList read FParams;
    property Visibility: string read FVisibility;
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
  private
    FParams: TParameterList;
    FBody: TStatementList;
  public
    constructor Create(AParams: TParameterList; ABody: TStatementList);
    destructor Destroy; override;
    property Params: TParameterList read FParams;
    property Body: TStatementList read FBody;
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

{ TDictionaryAccessNode }

constructor TDictionaryAccessNode.Create(ADictionary, AKey: TExpressionNode);
begin
  inherited Create;
  FDictionary := ADictionary;
  FKey := AKey;
end;

destructor TDictionaryAccessNode.Destroy;
begin
  FDictionary.Free;
  FKey.Free;
  inherited;
end;

{ TMemberAccessNode }

constructor TMemberAccessNode.Create(AObject: TExpressionNode; AMemberName: string);
begin
  inherited Create;
  FObject := AObject;
  FMemberName := AMemberName;
end;

destructor TMemberAccessNode.Destroy;
begin
  FObject.Free;
  inherited;
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

{ TIfStatementNode }

constructor TIfStatementNode.Create(ACondition: TExpressionNode; AThenBranch: TStatementList);
begin
  inherited Create;
  FCondition := ACondition;
  FThenBranch := AThenBranch;
end;

destructor TIfStatementNode.Destroy;
var
  Node: TStatementNode;
begin
  FCondition.Free;
  for Node in FThenBranch do
    Node.Free;
  FThenBranch.Free;
  inherited;
end;

{ TEmitStatementNode }

constructor TEmitStatementNode.Create(AEventName: string; AArguments: TExpressionList);
begin
  inherited Create;
  FEventName := AEventName;
  FArguments := AArguments;
end;

destructor TEmitStatementNode.Destroy;
var
  Node: TExpressionNode;
begin
  for Node in FArguments do
    Node.Free;
  FArguments.Free;
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

{ TParameterNode }

constructor TParameterNode.Create(AName: string; AType: TTypeSpecifierNode);
begin
  inherited Create;
  FName := AName;
  FType := AType;
end;

destructor TParameterNode.Destroy;
begin
  FType.Free;
  inherited;
end;

{ TFunctionDeclarationNode }

constructor TFunctionDeclarationNode.Create(AName: string; AParams: TParameterList; AReturnType: TTypeSpecifierNode; AVisibility: string; ABody: TStatementList);
begin
  inherited Create;
  FName := AName;
  FParams := AParams;
  FReturnType := AReturnType;
  FVisibility := AVisibility;
  FBody := ABody;
end;

destructor TFunctionDeclarationNode.Destroy;
var
  Node: TStatementNode;
  ParamNode: TParameterNode;
begin
  for ParamNode in FParams do
    ParamNode.Free;
  FParams.Free;

  if Assigned(FReturnType) then
    FReturnType.Free;

  for Node in FBody do
    Node.Free;
  FBody.Free;
  inherited;
end;

{ TProcedureDeclarationNode }

constructor TProcedureDeclarationNode.Create(AName: string; AParams: TParameterList; AVisibility: string; ABody: TStatementList);
begin
  inherited Create;
  FName := AName;
  FParams := AParams;
  FVisibility := AVisibility;
  FBody := ABody;
end;

destructor TProcedureDeclarationNode.Destroy;
var
  Node: TStatementNode;
  ParamNode: TParameterNode;
begin
  for ParamNode in FParams do
    ParamNode.Free;
  FParams.Free;

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

constructor TConstructorDeclarationNode.Create(AParams: TParameterList; ABody: TStatementList);
begin
  inherited Create;
  FParams := AParams;
  FBody := ABody;
end;

destructor TConstructorDeclarationNode.Destroy;
var
  ParamNode: TParameterNode;
  Node: TStatementNode;
begin
  for ParamNode in FParams do
    ParamNode.Free;
  FParams.Free;

  for Node in FBody do
    Node.Free;
  FBody.Free;
  inherited;
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