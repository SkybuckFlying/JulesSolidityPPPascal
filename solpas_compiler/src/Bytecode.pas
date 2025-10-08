unit Bytecode;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils;

type
  TOpCode = (
    opPush,   // Push a value onto the stack
    opStore,  // Pop a value from the stack and store it in a variable
    opLoad,   // Load a variable's value onto the stack
    opHalt    // Stop execution
  );
  TByte = Byte;
  TByteArray = specialize TArray<TByte>;

  TChunk = class
  private
    FCode: TByteArray;
  public
    constructor Create;
    procedure Write(AByte: TByte);
    procedure WriteOp(AnOpCode: TOpCode);
    function Count: integer;
    function GetCode: TByteArray;
  end;

implementation

{ TChunk }

constructor TChunk.Create;
begin
  SetLength(FCode, 0);
end;

procedure TChunk.Write(AByte: TByte);
begin
  SetLength(FCode, Length(FCode) + 1);
  FCode[Length(FCode) - 1] := AByte;
end;

procedure TChunk.WriteOp(AnOpCode: TOpCode);
begin
  Write(Ord(AnOpCode));
end;

function TChunk.Count: integer;
begin
  Result := Length(FCode);
end;

function TChunk.GetCode: TByteArray;
begin
  Result := FCode;
end;

end.