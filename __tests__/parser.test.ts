import fs from 'fs';
import path from 'path';
import { parse as parseSchema } from '../parser/ott-schema';
import { parse as parseRequest } from '../parser/ott-request';
import { parse as parseResponse } from '../parser/ott-response';
import { expect, test, describe } from 'bun:test';

// Define types for our parser outputs
interface Location {
  source: string;
  start: Position;
  end: Position;
}

interface Position {
  offset: number;
  line: number;
  column: number;
}

// Schema AST Types
type SchemaAST = (ModelDefinition | UnionTypeDefinition)[];

interface ModelDefinition {
  type: 'ModelDefinition';
  name: string;
  values: string[];
  extends: string | null;
  attributes: AttributeNode[];
  actions: ActionNode[];
}

interface UnionTypeDefinition {
  type: 'UnionTypeDefinition';
  name: string;
  values: string[];
}

interface AttributeNode {
  name: string;
  type: string;
  required: boolean;
  default: string | number | boolean | null;
}

interface ActionNode {
  name: string;
  params: ParamNode[];
  returnType: string;
}

interface ParamNode {
  name: string;
  type: string;
  optional: boolean;
}

// Request AST Types
interface RequestAST {
  model: string;
  filters: RequestFilter[];
  chain: RequestChain[];
  location?: Location;
}

interface RequestFilter {
  key: string;
  value: string | number | boolean;
  location?: Location;
}

interface RequestChain {
  relation: string;
  filters: RequestFilter[];
  method: string | null;
  location?: Location;
}

// Response AST Types
interface ResponseAST {
  type: string;
  fields: ResponseField[];
  location?: Location;
}

interface ResponseField {
  key: string;
  value: string | number | boolean | null;
  location?: Location;
}

describe('OTT Parsers', () => {
  // Helper function to read test files
  const readTestFile = (filename: string): string => {
    return fs.readFileSync(path.join(__dirname, filename), 'utf-8');
  };

  describe('Schema Parser', () => {
    const schemaContent = readTestFile('../ott/schema.ott');

    test('should parse basic model definitions into AST', () => {
      const ast = parseSchema(schemaContent) as SchemaAST;
      
      expect(ast).toBeDefined();
      
      // Test User model
      const userModel = ast.find((node) : node is ModelDefinition => 
        node.name === 'User'
      );
      expect(userModel).toBeDefined();
      if (!userModel) throw new Error('User model not found');
      
      expect(userModel.extends).toBe('Model');
      expect(userModel.attributes).toHaveLength(4);
      expect(userModel.actions).toHaveLength(5);
      
      // Test attributes
      const idAttr = userModel.attributes.find(a => a.name === 'id');
      expect(idAttr).not.toBeUndefined();
      if (!idAttr) throw new Error('id attribute not found');
      
      expect(idAttr.type).toBe('string');
      expect(idAttr.required).toBe(true);
      expect(idAttr.default).toBeNull();
      
      // Test actions
      const getAction = userModel.actions.find(a => a.name === 'get');
      expect(getAction).not.toBeUndefined();
      if (!getAction) throw new Error('get action not found');
      
      expect(getAction.params).toHaveLength(0);
      expect(getAction.returnType).toBe('User');
      
      const createAction = userModel.actions.find(a => a.name === 'create');
      expect(createAction).not.toBeUndefined();
      if (!createAction) throw new Error('create action not found');
      
      expect(createAction.params).toHaveLength(2);
      expect(createAction.returnType).toBe('User');

      const deleteAction = userModel.actions.find(a => a.name === 'delete');
      expect(deleteAction).not.toBeUndefined();
      if (!deleteAction) throw new Error('delete action not found');
      
      expect(deleteAction.params).toHaveLength(0);
      expect(deleteAction.returnType).toBe('void');
    });

    test('should parse union types into AST', () => {
      const ast = parseSchema(schemaContent) as SchemaAST;
      const genderType = ast.find((node) : node is UnionTypeDefinition => 
        node.name === 'Gender' && node.type === 'UnionTypeDefinition'
      );
      expect(genderType).not.toBeUndefined();
      if (!genderType) throw new Error('Gender type not found');
      expect(genderType.type).toBe('UnionTypeDefinition');
      expect(genderType.values).toEqual(['male', 'female']);
      expect(genderType.name).toBe('Gender');
    });

    test('should parse model inheritance into AST', () => {
      const ast = parseSchema(schemaContent) as SchemaAST;
      const inheritedModel = ast.find((node) : node is ModelDefinition => 
        node.name === 'User' && node.extends === 'Model'
      );
      expect(inheritedModel).not.toBeUndefined();
      if (!inheritedModel) throw new Error('Inherited model not found');
      
      expect(inheritedModel.extends).toBe('Model');
      expect(inheritedModel.actions).toHaveLength(5);
    });

    test('should handle default values in AST', () => {
      const ast = parseSchema(schemaContent) as SchemaAST;
      const userModel = ast.find((node) : node is ModelDefinition => 
        node.name === 'User'
      );
      expect(userModel).not.toBeUndefined();
      if (!userModel) throw new Error('User model not found');
      
      const genderAttr = userModel.attributes.find(a => a.name === 'gender');
      expect(genderAttr).not.toBeUndefined();
      if (!genderAttr) throw new Error('gender attribute not found');
      
      expect(genderAttr.default).toBe('male');
    });

    test('should throw on invalid syntax', () => {
      expect(() => parseSchema('Invalid Model {')).toThrow();
    });
  });

  describe('Request Parser', () => {
    const requestContent = readTestFile('../ott/request.ott');

    test('should parse request into AST', () => {
      const ast = parseRequest(requestContent) as RequestAST;
      expect(ast).toBeDefined();
      expect(ast.model).toBe('User');
      expect(ast.chain).toHaveLength(2);
      
      // Test model filters
      expect(ast.filters).toHaveLength(1);
      const idFilter = ast.filters[0];
      expect(idFilter).not.toBeUndefined();
      if (!idFilter) throw new Error('id filter not found');
      
      expect(idFilter.key).toBe('id');
      expect(idFilter.value).toBe('123');
      
      // Test first chain (posts)
      const postsChain = ast.chain[0];
      expect(postsChain).not.toBeUndefined();
      if (!postsChain) throw new Error('posts chain not found');
      
      expect(postsChain.relation).toBe('posts');
      expect(postsChain.filters).toEqual([
        { key: 'type', value: 'image' },
        { key: 'status', value: 'published' }
      ]);
      
      // Test second chain (get)
      const getChain = ast.chain[1];
      expect(getChain).not.toBeUndefined();
      if (!getChain) throw new Error('get chain not found');
      
      expect(getChain.relation).toBe('get');
      expect(getChain.filters).toHaveLength(0);
      expect(getChain.method).toBeNull();
    });

//     test('should include location information in request AST', () => {
//       const ast = parseRequest(requestContent) as RequestAST;
//       expect(ast.location).toBeDefined();
//       if (ast.location) {
//         expect(ast.location.start.line).toBeGreaterThan(0);
//         expect(ast.location.start.column).toBeGreaterThan(0);
//         expect(ast.location.end.line).toBeGreaterThan(0);
//         expect(ast.location.end.column).toBeGreaterThan(0);
//       }
//     });

//     test('should throw on invalid request syntax', () => {
//       expect(() => parseRequest('Invalid().get()')).toThrow();
//     });
//   });

//   describe('Response Parser', () => {
//     const responseContent = readTestFile('../ott/response.ott');

//     test('should parse response into AST', () => {
//       const ast = parseResponse(responseContent) as ResponseAST;
//       expect(ast).toBeDefined();
//       expect(ast.type).toBeDefined();
//       expect(Array.isArray(ast.fields)).toBe(true);
//       // Add specific assertions based on your response.ott content
//     });

//     test('should include location information in response AST', () => {
//       const ast = parseResponse(responseContent) as ResponseAST;
//       expect(ast.location).toBeDefined();
//       if (ast.location) {
//         expect(ast.location.start.line).toBeGreaterThan(0);
//         expect(ast.location.start.column).toBeGreaterThan(0);
//         expect(ast.location.end.line).toBeGreaterThan(0);
//         expect(ast.location.end.column).toBeGreaterThan(0);
//       }
//     });

//     test('should throw on invalid response syntax', () => {
//       expect(() => parseResponse('{invalid}')).toThrow();
//     });
  });
});
