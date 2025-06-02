{
  function toFilter(key, value) {
    return { key, value };
  }

  function toChain(relation, filters, method) {
    return {
      relation,
      filters: filters || [],
      method: method || null
    };
  }

  function toAST(model, filters, chain) {
    return {
      model,
      filters: filters || [],
      chain: chain || []
    };
  }
}

start
  = _ request:request _ { return request; }

request
  = model:modelExpr chain:chainExpr* {
      return toAST(model.name, model.filters, chain);
    }

modelExpr
  = name:identifier "(" _ filters:filterList? _ ")" {
      return { name, filters: filters || [] };
    }

chainExpr
  = "." relation:identifier filters:filterArgs? method:methodCall? {
      return toChain(relation, filters, method);
    }

filterArgs
  = "(" _ filters:filterList? _ ")" { return filters || []; }

filterList
  = head:filter tail:(_ "," _ filter)* {
      return [head, ...tail.map(([, , , f]) => f)];
    }

filter
  = key:identifier _ "=" _ value:(string / number) {
      return toFilter(key, value);
    }

methodCall
  = "." name:identifier "(" _ ")" { return name; }

identifier
  = $([a-zA-Z_][a-zA-Z0-9_]*)

string
  = "\"" chars:$([^"]*) "\"" { return chars; }

number
  = digits:$([0-9]+) { return parseInt(digits, 10); }

_ = [ \t\n\r]*