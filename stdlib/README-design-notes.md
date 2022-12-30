# Introduction

## Why use `typedef` rather than serializable enums for protocol values?

Types such as these _could_ be defined using a P4 serialiable enum
type, e.g. `enum bit<16> etype_t { ... }`:

+ `etype_t` in file `etype.p4`
+ `ipproto_t` in file `ipproto.p4`
+ `ipport_t` in file `ipport.p4`

However, this would have the disadvantage that the P4 language does
not provide developers any way to define new values of an enum type,
unless they modify the source file containing the definition of the
enum type.

By defining types like `etype_t` using `typedef`, and values of that
type as individual `const` named values, any P4 developer can define
new constants of this type in whatever source file they wish, without
modifying files such as `etype.p4`.
