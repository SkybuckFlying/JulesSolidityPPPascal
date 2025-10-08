program solpas_compiler;

{$APPTYPE CONSOLE}
{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  Classes,
  Lexer in 'src/Lexer.pas',
  Token in 'src/Token.pas',
  AST in 'src/AST.pas',
  Parser in 'src/Parser.pas',
  SemanticAnalyzer in 'src/SemanticAnalyzer.pas',
  CodeGenerator in 'src/CodeGenerator.pas',
  Bytecode in 'src/Bytecode.pas';

var
  SourceCode: string;
  TheLexer: TLexer;
  TheParser: TParser;
  TheAST: TASTNode;
  Analyzer: TSemanticAnalyzer;
  Generator: TCodeGenerator;
  Chunk: TChunk;
  FilePath, OutputFilePath: string;
  StringList: TStringList;
  FileStream: TFileStream;
begin
  try
    if ParamCount < 1 then
    begin
      writeln('Usage: solpas_compiler <input_file>');
      Exit;
    end;

    FilePath := ParamStr(1);
    writeln('Compiling: ', FilePath);

    StringList := TStringList.Create;
    try
      StringList.LoadFromFile(FilePath);
      SourceCode := StringList.Text;
    finally
      StringList.Free;
    end;

    TheLexer := TLexer.Create(SourceCode);
    TheParser := TParser.Create(TheLexer);
    TheAST := TheParser.Parse;
    writeln('Parsing successful.');

    Analyzer := TSemanticAnalyzer.Create;
    try
      Analyzer.Analyze(TheAST);
      writeln('Semantic analysis successful.');
    finally
      Analyzer.Free;
    end;

    Generator := TCodeGenerator.Create;
    try
      Chunk := Generator.Generate(TheAST);
      writeln('Code generation successful.');

      if Chunk.Count > 0 then
      begin
        OutputFilePath := ChangeFileExt(FilePath, '.spb');
        FileStream := TFileStream.Create(OutputFilePath, fmCreate);
        try
          FileStream.WriteBuffer(Chunk.GetCode[0], Chunk.Count);
          writeln('Bytecode written to: ', OutputFilePath);
        finally
          FileStream.Free;
        end;
      end
      else
      begin
        writeln('No executable code generated.');
      end;

    finally
      Generator.Free;
    end;

    writeln('Compilation finished.');

  except
    on E: Exception do
      writeln(E.ClassName, ': ', E.Message);
  end;
end.