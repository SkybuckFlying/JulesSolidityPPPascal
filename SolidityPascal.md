# Solidity Pascal Language Specification

## 1. Introduction

Solidity Pascal is a new smart contract language that combines the power and security of Solidity with the clear, readable syntax of Pascal/Delphi. This document outlines the initial specification for the language.

## 2. Contract Structure

A contract is the fundamental building block of a Solidity Pascal application. It is declared using the `contract` keyword, followed by the contract name. The body of the contract is enclosed in a `begin...end.` block.

```pascal
contract SimpleStorage;
var
  storedData: cardinal; // 'cardinal' is an unsigned integer

procedure set(x: cardinal);
begin
  storedData := x;
end;

function get(): cardinal;
begin
  result := storedData;
end;

end.
```

## 3. State Variables

State variables are declared within the `var` block of a contract. They represent the data stored on the blockchain.

```pascal
contract MyContract;
var
  owner: address;
  isActive: boolean;
  name: string;
  balances: TDictionary<address, cardinal>;
```

## 4. Data Types

Solidity Pascal supports the following data types:

*   **Integer Types:** `integer`, `cardinal` (unsigned integer), `smallint`, `bigint`.
*   **Address:** `address` (20-byte Ethereum address).
*   **Boolean:** `boolean` (`true` or `false`).
*   **String:** `string`.
*   **Fixed-size byte arrays:** `bytes1`, `bytes2`, ..., `bytes32`.
*   **Mappings:** `TDictionary<TKey, TValue>`.

## 5. Functions

Functions are declared using the `procedure` (for functions that don't return a value) and `function` (for functions that do) keywords.

Visibility specifiers are placed after the function declaration:

*   `public`: Accessible from any other contract or externally.
*   `private`: Only accessible from within the contract.
*   `internal`: Accessible from within the contract and derived contracts.
*   `external`: Only accessible externally (not from within the contract).

```pascal
contract FunctionExample;

var
  value: cardinal;

procedure setValue(newValue: cardinal); public;
begin
  value := newValue;
end;

function getValue(): cardinal; public;
begin
  result := value;
end;

procedure internalFunction; internal;
begin
  // ...
end;

end.
```

## 6. Modifiers

Modifiers are used to change the behavior of functions. They are declared using the `modifier` keyword. The special identifier `continue` is used to indicate where the modified function's code should be executed.

```pascal
contract ModifierExample;
var
  owner: address;

modifier onlyOwner;
begin
  if msg.sender <> owner then
    raise Exception.Create('Not the owner');
  continue;
end;

procedure changeOwner(newOwner: address); public; onlyOwner;
begin
  owner := newOwner;
end;

end.
```

## 7. Events

Events allow for logging to the Ethereum blockchain. They are declared using the `event` keyword.

```pascal
contract EventExample;

event ValueChanged(oldValue: cardinal; newValue: cardinal);

var
  value: cardinal;

procedure setValue(newValue: cardinal); public;
var
  oldValue: cardinal;
begin
  oldValue := value;
  value := newValue;
  emit ValueChanged(oldValue, newValue);
end;

end.
```

## 8. Control Structures

Solidity Pascal supports standard Pascal control structures:

*   `if-then-else`
*   `for-to-do`
*   `while-do`
*   `repeat-until`
*   `case-of`

## 9. Example: SimpleStorage

Here is a complete example of a `SimpleStorage` contract in Solidity Pascal:

```pascal
contract SimpleStorage;

var
  storedData: cardinal;

event DataStored(newValue: cardinal);

procedure set(x: cardinal); public;
begin
  storedData := x;
  emit DataStored(x);
end;

function get(): cardinal; public;
begin
  result := storedData;
end;

end.
```