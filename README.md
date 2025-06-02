# 📄 RFC: OpenTypedTransport v1

## Title: OpenTypedTransport (OTT) — A Typed & Fluid Universal API Format  
**Status**: Draft  
**Version**: 1.0.0  
**Author**: Cedric Pierre  
**Created**: 2025-05-30

---

## 1. Introduction

**OpenTypedTransport (OTT)** is a typed, declarative, and human-readable API protocol. It defines schemas, requests, and responses in a unified text-based format, offering a simpler alternative to REST/JSON and GraphQL/SDL.

OTT aims to be readable, strongly typed, portable across languages, and easy to implement with minimal tooling.

---

## 🔰 OTT-Lang vs JSON, GraphQL, gRPC, tRPC

| Feature                       | 🟢 OTT-Lang | 🔵 JSON/REST | 🟣 GraphQL | 🟠 gRPC | 🟡 tRPC |
|------------------------------|-------------|--------------|------------|---------|----------|
| **Strong type system**       | ✅           | ❌           | ✅          | ✅       | ✅        |
| **Unified schema file**      | ✅           | ❌           | ✅          | ✅       | ✅        |
| **Text-based queries**       | ✅           | ❌           | ⚠️          | ❌       | ✅        |
| **Custom actions**           | ✅           | ⚠️           | ⚠️          | ✅       | ✅        |
| **Nested relationships**     | ✅           | ⚠️           | ✅          | ❌       | ✅        |
| **Transport-agnostic**       | ✅           | ⚠️           | ❌          | ❌       | ⚠️        |
| **Pagination support**       | ✅           | ✅           | ✅          | ⚠️       | ✅        |
| **Client runtime parsing**   | ✅           | ❌           | ⚠️          | ❌       | ✅        |
| **Code generation**          | ✅           | ⚠️           | ✅          | ✅       | ⚠️        |
| **Human readable**           | ✅           | ⚠️           | ✅          | ❌       | ✅        |
| **Client discoverable**      | ✅           | ❌           | ✅          | ❌       | ✅        |

> ⚠️ = Possible but not standardized or requires additional setup

## 2. Motivation

Existing protocols have limitations:

- **JSON** is untyped and verbose.
- **OpenAPI** is powerful but complex and static.
- **GraphQL** introduces unnecessary complexity in many projects.
- **REST** lacks expressiveness for actions and relationships.

**OTT provides:**

- One format for schema, queries, and responses.
- Type safety, enums, and unions (`string | number`).
- A clean, minimal response format.
- Full transport-independence.
- One unified endpoint.

---

## 3. File Types and Syntax

### 3.1. `.ott` — Schema

```ott
User(id: string; email: string; data: string | number; gender: Gender = male) {
  get(),
  create(name: string, gender?: Gender): User,
  update(name?: string): User,
  delete(),
  ban(): void,
}

Gender(male | female)

Pagination(current: number; total:number; data: User[])
```

#### 3.1.1 Extends type

```ott
Model(id: string) {
    delete(): void,
    create(): Model,
    get(): Model,
}

User & Model (id: string, email: string, data: string | number, gender: male) {
  create(name: string, gender?: Gender): User,
  update(name?: string): User,
  ban(): void
}

Gender(male | female)
```

### 3.2 Requests

**Simple request**

Get a User with id 123

```ott
User(id="123").get()
```

**Complex request**

Get a user with all his posts

```ott
User(id="123").posts(type="image", status="published").get()
```

Get all posts where User has id 123 and post type is image and status is published

```ott
Post(User(id="123"),type="image", status="published").get()
```

### 3.3 Responses

**List nested results**

```ott
User(
  id="123",
  email="john@example.com",
  gender="male",
  posts=[Post(id=456),Post(id=789)]
)
```

## 4. Grammar

OTT defines three independent PEG grammars:

- ott-schema.peg — for .ott schema parsing
- ott-request.peg — for request parsing
- ott-response.peg — for response parsing

## 5. Features

✅ Strong Typing
Supports primitives (string, number, boolean), enums, optional fields (?), default values, and type unions (string | number).

✅ Relational Queries
Reverse and nested queries with filters:

```ott
Post(author=User(id=1), published=true).all()
```

✅ Inline Custom Actions in definition

```
User(id:string) {
  ban(): void,
  setRole(role: string | number): boolean,
}
```

✅ Single Endpoint

All requests are sent to /ott as plain-text .ott-request.

✅ Pure Data Response

.ott-response only includes data, not pagination or metadata.

## 6. Transport Agnosticism

OTT is transport-agnostic. It works over:
- HTTP (POST to /ott)
- WebSockets
- gRPC
- or any other stream/message protocol

Transport configuration is handled on the client side, not in the schema.

## 7. Codegen

The .ott schema can be parsed into:
- TypeScript types
- DTOs for validation
- JSON Schema if needed

Unions are included in all generated types.

## 8. Use Cases
- Frontend SDKs with full typing
- Server-to-server communication
- Backend services without REST or GraphQL overhead
- Low-code and visual builders

## 9. Workflow

1. Load schema from schema.ott
2. Client parses it using provided tools or use of automatic codegen for example to create .ott > types.d.ts
3. Send .ott-request to /ott
4. Receive .ott-response (pure data)

---

MIT License. Contributions welcome.
