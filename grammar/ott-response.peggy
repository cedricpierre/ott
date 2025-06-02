Start = _ EntryList _

EntryList
  = head:Entry tail:(_ "," _ Entry)* ","?
  {
    return [head, ...tail.map(t => t[3])];
  }

Entry
  = type:Identifier _ "(" _ fields:FieldList? _ ")"
  {
    return {
      type,
      fields: fields || []
    };
  }

FieldList
  = head:Field tail:(_ "," _ Field)* ","?
  {
    return [head, ...tail.map(t => t[3])];
  }

Field
  = key:Identifier _ "=" _ value:(Literal / ArrayLiteral)
  {
    return { key, value };
  }

ArrayLiteral
  = "[" _ elements:ElementList? _ "]"
  {
    return elements || [];
  }

ElementList
  = head:Entry tail:(_ "," _ Entry)* ","?
  {
    return [head, ...tail.map(t => t[3])];
  }

Literal
  = StringLiteral / NumberLiteral / BooleanLiteral

StringLiteral  = "\"" chars:$([^"]*) "\"" { return chars; }
NumberLiteral  = digits:$([0-9]+) { return parseInt(digits, 10); }
BooleanLiteral = "true" / "false"

Identifier = $([a-zA-Z_][a-zA-Z0-9_]*)
_ = [ \t\n\r]*