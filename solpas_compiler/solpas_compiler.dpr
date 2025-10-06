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
  CodeGenerator in 'src/CodeGenerator.pas';

var
  SourceCode: string;
  TheLexer: TLexer;
  TheParser: TParser;
  TheAST: TASTNode;
  Analyzer: TSemanticAnalyzer;
  Generator: TCodeGenerator;
  FilePath: string;
  StringList: TStringList;
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
      Generator.Generate(TheAST);
    finally
      Generator.Free;
    end;

    writeln('Compilation successful.');

  except
    on E: Exception do
      writeln(E.ClassName, ': ', E.Message);
  end;
end.