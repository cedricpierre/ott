Start        = _ ModelDefinitionList _

ModelDefinitionList = (ModelDefinition _)*

ModelDefinition
  = name:Identifier _ base:("&" _ Identifier)? _ "(" _ attrs:AttributeList _ ")" _ actions:ActionBlock?
  {
    return {
      name,
      extends: base ? base[2] : null,
      attributes: attrs,
      actions: actions || []
    };
  }
  / name:Identifier _ "(" _ types:UnionType _ ")"
  {
    return {
      name,
      extends: null,
      attributes: [],
      actions: [],
      unionType: types
    };
  }

AttributeList
  = head:Attribute tail:(_ ";"? _ Attribute)* ";"?
  {
    return [head, ...tail.map(t => t[3])];
  }

Attribute
  = name:Identifier _ ":" _ type:Type initial:DefaultValue? optional:OptionalMarker?
  {
    return {
      name,
      type,
      optional: optional !== null,
      default: initial ? initial[1] : null
    };
  }

DefaultValue = _ "=" _ value:Literal { return value; }
OptionalMarker = "?"

ActionBlock
  = "{" _ actions:(ActionDef _)* "}"
  { return actions.map(([a]) => a); }

ActionDef
  = name:Identifier _ "(" _ params:ParamList? _ ")" _ ":" _ returnType:Type
  {
    return { name, params: params || [], returnType };
  }

ParamList
  = head:Param tail:(_ "," _ Param)* ","?
  {
    return [head, ...tail.map(t => t[3])];
  }

Param
  = name:Identifier _ optional:OptionalMarker? ":" _ type:Type
  {
    return {
      name,
      type,
      optional: optional !== null
    };
  }

Type
  = UnionType / Identifier / "void"

UnionType
  = first:Identifier rest:(_ "|" _ (Identifier / StringLiteral))*
  {
    return [first, ...rest.map(t => t[3])];
  }

Literal
  = StringLiteral / NumberLiteral / BooleanLiteral

StringLiteral  = "\"" chars:$([^"]*) "\"" { return chars; }
NumberLiteral  = digits:$([0-9]+) { return parseInt(digits, 10); }
BooleanLiteral = "true" / "false"

Identifier = $([a-zA-Z_][a-zA-Z0-9_]*)
_ = [ \t\n\r]*