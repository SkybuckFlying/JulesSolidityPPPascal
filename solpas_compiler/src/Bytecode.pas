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
    opJumpIfFalse, // Pop a value from the stack, if it's false (0), jump to a new location
    opJump,        // Unconditionally jump to a new location
    opEmit,        // Emit an event
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
    procedure Patch(Offset: integer; Value: TByte);
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

procedure TChunk.Patch(Offset: integer; Value: TByte);
begin
  if (Offset >= 0) and (Offset < Length(FCode)) then
    FCode[Offset] := Value;
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