unit SymbolTable;

{$MODE OBJFPC}{$H+}

interface

uses
  Generics.Collections, AST;

type
  TSymbol = class
  private
    FName: string;
    FType: TASTNode; // Can be a type specifier or other declaration nodes
  public
    constructor Create(AName: string; AType: TASTNode);
    property Name: string read FName;
    property SymbolType: TASTNode read FType;
  end;

  TSymbolDictionary = specialize TDictionary<string, TSymbol>;

  TSymbolTable = class
  private
    FSymbols: TSymbolDictionary;
    FParent: TSymbolTable;
  public
    constructor Create(AParent: TSymbolTable = nil);
    destructor Destroy; override;
    function Define(ASymbol: TSymbol): boolean;
    function Resolve(AName: string): TSymbol;
    property Parent: TSymbolTable read FParent;
  end;

implementation

uses
  SysUtils;

{ TSymbol }

constructor TSymbol.Create(AName: string; AType: TASTNode);
begin
  inherited Create;
  FName := AName;
  FType := AType;
end;

{ TSymbolTable }

constructor TSymbolTable.Create(AParent: TSymbolTable);
begin
  inherited Create;
  FSymbols := TSymbolDictionary.Create;
  FParent := AParent;
end;

destructor TSymbolTable.Destroy;
var
  Symbol: TSymbol;
begin
  for Symbol in FSymbols.Values do
    Symbol.Free;
  FSymbols.Free;
  inherited;
end;

function TSymbolTable.Define(ASymbol: TSymbol): boolean;
begin
  if FSymbols.ContainsKey(ASymbol.Name) then
  begin
    Result := false;
    Exit;
  end;
  FSymbols.Add(ASymbol.Name, ASymbol);
  Result := true;
end;

function TSymbolTable.Resolve(AName: string): TSymbol;
begin
  if FSymbols.TryGetValue(AName, Result) then
    Exit;

  if Assigned(FParent) then
    Result := FParent.Resolve(AName)
  else
    Result := nil;
end;

end.