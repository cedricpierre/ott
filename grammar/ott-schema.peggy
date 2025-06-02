{
  function flatten(arr) {
    return Array.isArray(arr) ? arr.flat(Infinity) : arr;
  }
  
  const interfaces = new Map();
  
  function getInterface(name) {
    return interfaces.get(name);
  }
  
  function registerInterface(def) {
    interfaces.set(def.name, def);
    return def;
  }

  function mergeAttributes(baseAttrs, derivedAttrs) {
    const result = [...(derivedAttrs || [])];
    const existingNames = new Set(result.map(attr => attr.name));
    
    for (const baseAttr of (baseAttrs || [])) {
      if (!existingNames.has(baseAttr.name)) {
        result.push(baseAttr);
      }
    }
    
    return result;
  }

  function mergeActions(baseActions, derivedActions) {
    const result = [...(derivedActions || [])];
    const existingNames = new Set(result.map(action => action.name));
    
    for (const baseAction of (baseActions || [])) {
      if (!existingNames.has(baseAction.name)) {
        result.push(baseAction);
      }
    }
    
    return result;
  }
}

start
  = _ definitions:(definition _)+ {
      return definitions.map(d => d[0]);
    }

definition
  = model
  / interface
  / enumDef

model
  = "Model" _ "(" _ id:identifier _ ":" _ "string" _ ")" _ "{" _ actions:methodList _ "}" {
      return registerInterface({
        name: "Model",
        type: "Model",
        id,
        attributes: [{
          name: id,
          type: "string",
          required: true,
          default: null
        }],
        actions
      });
    }

interface
  = name:identifier _ base:extendsList? _ "(" _ attrs:argList? _ ")" _ "{" _ actions:methodList _ "}" {
      const baseInterface = base ? getInterface(base) : null;
      if (base && !baseInterface) {
        throw new Error(`Base interface/model "${base}" not found. Make sure it is defined before use.`);
      }
      const baseAttrs = baseInterface ? baseInterface.attributes || [] : [];
      const baseActions = baseInterface ? baseInterface.actions || [] : [];
      return registerInterface({
        name,
        type: baseInterface?.type || "Interface",
        extends: base,
        attributes: mergeAttributes(baseAttrs, attrs),
        actions: mergeActions(baseActions, actions)
      });
    }

extendsList
  = _ "&" _ baseName:identifier {
      return baseName;
    }

enumDef
  = name:identifier _ "=" _ values:enumValues {
      return {
        type: "UnionType",
        name,
        values
      };
    }

enumValues
  = first:enumValue rest:(_ "|" _ enumValue)* {
      return [first, ...rest.map(r => r[3])];
    }

enumValue
  = "\"" val:$([a-zA-Z0-9_]+) "\"" { return val; }

methodList
  = methods:(method (_ ","? _)?)* {
      return methods.map(m => m[0]);
    }

method
  = name:identifier _ "(" _ params:argList? _ ")" _ ":" _ returnType:type {
      return {
        name,
        params: params || [],
        returnType
      };
    }

argList
  = head:argument tail:(_ "," _ argument)* {
      return [head, ...tail.map(t => t[3])];
    }

argument
  = name:identifier _ opt:"?"? _ ":" _ type:type defaultVal:(_ "=" _ literal)? {
      return {
        name,
        required: !opt,
        type,
        default: defaultVal ? defaultVal[3] : null
      };
    }

type
  = unionType

unionType
  = head:simpleType tail:(_ "|" _ simpleType)* {
      return tail.length > 0 ? [head, ...tail.map(t => t[3])].join(" | ") : head;
    }

simpleType
  = identifier

literal
  = stringLiteral / numberLiteral

stringLiteral
  = "\"" chars:[^"]* "\"" { return chars.join(""); }

numberLiteral
  = digits:[0-9]+ { return parseInt(digits.join(""), 10); }

identifier
  = $([a-zA-Z_][a-zA-Z0-9_]*)

_ "whitespace"
  = [ \t\n\r]*