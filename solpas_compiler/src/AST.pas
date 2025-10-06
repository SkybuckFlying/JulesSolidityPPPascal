unit AST;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

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
    // Add parameters, return type, and body later
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TEventDeclarationNode = class(TASTNode)
  private
    FName: string;
    // Add parameters later
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TProcedureDeclarationNode = class(TASTNode)
  private
    FName: string;
    // Add parameters and body later
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TConstructorDeclarationNode = class(TASTNode)
  public
    // Add parameters and body later
    constructor Create;
  end;

  TTypeDeclarationNode = class(TASTNode)
  private
    FName: string;
    // For now, we don't parse the structure of the type, just its name
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

{$IFDEF FPC}
  TASTNodeList = specialize TList<TASTNode>;
{$ELSE}
  TASTNodeList = TList<TASTNode>;
{$ENDIF}

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

constructor TFunctionDeclarationNode.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TEventDeclarationNode }

constructor TEventDeclarationNode.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TProcedureDeclarationNode }

constructor TProcedureDeclarationNode.Create(AName: string);
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