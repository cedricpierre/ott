{
  function toArray(item) {
    return item ? [item] : [];
  }

  function mergeModelDefinitions(baseModel, derivedModel) {
    if (!baseModel) return derivedModel;
    
    // Merge attributes, with derived model attributes taking precedence
    const mergedAttributes = [...baseModel.attributes];
    for (const attr of derivedModel.attributes) {
      const existingIndex = mergedAttributes.findIndex(a => a.name === attr.name);
      if (existingIndex >= 0) {
        mergedAttributes[existingIndex] = attr; // Override with derived attribute
      } else {
        mergedAttributes.push(attr);
      }
    }

    // Merge actions, with derived model actions taking precedence
    const mergedActions = [...baseModel.actions];
    for (const action of derivedModel.actions) {
      const existingIndex = mergedActions.findIndex(a => a.name === action.name);
      if (existingIndex >= 0) {
        mergedActions[existingIndex] = action; // Override with derived action
      } else {
        mergedActions.push(action);
      }
    }

    return {
      ...derivedModel,
      attributes: mergedAttributes,
      actions: mergedActions
    };
  }
}

Start
  = _ declarations:(Declaration (_ Declaration)*)? _ {
      const models = declarations ? [declarations[0], ...declarations[1].map(d => d[1])] : [];
      
      // Create a map of all models for easy lookup
      const modelMap = new Map();
      for (const model of models) {
        if (model.type === "ModelDefinition") {
          modelMap.set(model.name, model);
        }
      }
      
      // Process inheritance and merge attributes/actions
      for (const model of models) {
        if (model.type === "ModelDefinition" && model.extends) {
          const baseModel = modelMap.get(model.extends);
          if (baseModel) {
            const mergedModel = mergeModelDefinitions(baseModel, model);
            Object.assign(model, mergedModel);
          }
        }
      }
      
      return models;
    }

Declaration
  = UnionTypeDefinition
  / ModelDefinition

ModelDefinition
  = name:Identifier _ base:Inheritance? _ "(" _ attributes:AttributeList? _ ")" _ "{" _ actions:ActionList? _ "}" {
      return {
        type: "ModelDefinition",
        name,
        extends: base || null,
        attributes: attributes || [],
        actions: actions || []
      };
    }

Inheritance
  = "&" _ base:Identifier { return base; }

AttributeList
  = first:Attribute rest:(_ ";" _ Attribute)* ";"? {
      return [first, ...rest.map(r => r[3])];
    }

Attribute
  = name:Identifier optional:"?"? _ ":" _ type:Type _ initial:DefaultValue? {
      return {
        name,
        type,
        default: initial || null,
        required: !optional
      };
    }

DefaultValue
  = _ "=" _ val:(StringLiteral / BooleanLiteral / NumberLiteral / Identifier) {
      return val;
    }

ActionList
  = first:Action rest:(_ Action)* {
      return [first, ...rest.map(r => r[1])];
    }

Action
  = name:Identifier _ "(" _ params:ParamList? _ ")" _ ":" _ returnType:Type {
      return {
        name,
        params: params || [],
        returnType
      };
    }

ParamList
  = first:Parameter rest:(_ "," _ Parameter)* {
      return [first, ...rest.map(r => r[3])];
    }

Parameter
  = name:Identifier _ ":" _ type:Type {
      return { name, type, required: true };
    }
  / name:Identifier _ "?" _ ":" _ type:Type {
      return { name, type, required: false };
    }

UnionTypeDefinition
  = name:Identifier _ "(" _ values:EnumValues _ ")" {
      return {
        type: "UnionTypeDefinition",
        name,
        values
      };
    }

EnumValues
  = first:Identifier rest:(_ "|" _ Identifier)* {
      return [first, ...rest.map(r => r[3])];
    }

Type
  = UnionType

UnionType
  = first:PrimaryType rest:(_ "|" _ PrimaryType)* {
      return rest.length > 0 ? { 
        type: "UnionTypeDefinition", 
        name: "Union", 
        values: [first, ...rest.map(r => r[3])] 
      } : first;
    }

PrimaryType
  = Identifier

Identifier
  = $([a-zA-Z_][a-zA-Z0-9_]*)

StringLiteral
  = '"' chars:([^"]*) '"' { return chars.join(""); }

BooleanLiteral
  = val:("true" / "false") { return val === "true"; }

NumberLiteral
  = $([0-9]+ ("." [0-9]+)?) { return parseFloat(text()); }

_ = [ \t\r\n]*