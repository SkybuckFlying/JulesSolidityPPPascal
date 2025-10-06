unit Token;

{$MODE OBJFPC}{$H+}

interface

type
  TTokenType = (
    // Keywords
    ttContract,
    ttVar,
    ttProcedure,
    ttFunction,
    ttBegin,
    ttEnd,
    ttIf,
    ttThen,
    ttElse,
    ttFor,
    ttTo,
    ttDo,
    ttWhile,
    ttRepeat,
    ttUntil,
    ttCase,
    ttOf,
    ttType,
    ttEvent,
    ttEmit,
    ttModifier,
    ttConstructor,

    // Identifiers
    ttIdentifier,

    // Literals
    ttIntegerLiteral,
    ttStringLiteral,

    // Operators and Delimiters
    ttPlus,
    ttMinus,
    ttMultiply,
    ttDivide,
    ttAssign,
    ttEqual,
    ttNotEqual,
    ttLessThan,
    ttGreaterThan,
    ttLessThanOrEqual,
    ttGreaterThanOrEqual,
    ttLParen,
    ttRParen,
    ttLBracket,
    ttRBracket,
    ttComma,
    ttSemicolon,
    ttColon,
    ttDot,
    ttDotDot,

    // End of File
    ttEOF
  );

  TToken = record
    TokenType: TTokenType;
    Lexeme: string;
    Line: integer;
    Column: integer;
  end;

implementation

end.