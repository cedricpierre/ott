Start = _ Query _

Query
  = root:ModelInstance chain:("." _ SubQuery)* {
    return [root, ...chain.map(x => x[2])];
  }

ModelInstance
  = name:Identifier _ "(" _ filters:FilterList? _ ")" {
    return { model: name, filters: filters || [] };
  }

SubQuery
  = name:Identifier _ "(" _ filters:FilterList? _ ")"? _ method:("." Identifier)? {
    return {
      relation: name,
      filters: filters || [],
      method: method ? method[1] : null
    };
  }

FilterList
  = head:Filter tail:(_ "," _ Filter)* ","?
  {
    return [head, ...tail.map(t => t[3])];
  }

Filter
  = key:Identifier _ "=" _ value:Literal
  {
    return { key, value };
  }

Literal
  = StringLiteral / NumberLiteral / BooleanLiteral

StringLiteral  = "\"" chars:$([^"]*) "\"" { return chars; }
NumberLiteral  = digits:$([0-9]+) { return parseInt(digits, 10); }
BooleanLiteral = "true" / "false"

Identifier = $([a-zA-Z_][a-zA-Z0-9_]*)
_ = [ \t\n\r]*