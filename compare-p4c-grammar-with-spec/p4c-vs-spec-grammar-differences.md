# Introduction

The differences below were last determined from a comparison of the
specification vs. p4c language grammars on 2025-Mar-27.

[SPEC] means the P4_16 specification grammar, found in this file:
+ https://github.com/p4lang/p4-spec/blob/main/p4-16/spec/grammar.adoc

[P4C] means the p4c reference compiler grammar, found in this file:
+ https://github.com/p4lang/p4c/blob/main/frontends/parsers/p4/p4parser.ypp

See this directory for scripts that can produce modified versions of
those files, easier for a human to use `diff`-based tools and examine
much shorter output:
+ https://github.com/p4lang/p4-spec/tree/main/p4-16/spec/scripts


## annotation in P4C has extra production rule for `@pragma` annotations

This extra production rule exists in [P4C] that is not present in [SPEC]:
```
annotation
    | PRAGMA annotationName annotationBody END_PRAGMA
```

Example use of this rule:
+ https://github.com/p4lang/p4c/blob/main/testdata/p4_16_samples/pragmas.p4#L20
+ Other examples can be found by searching for string `@pragma`
  throughout the p4c repo.

An early version of this rule was added with this commit to the p4c
repo:
```
commit 68dea2b31beb8a6e527ae375d05356ea7fc12145
Author: Jed Liu <jed-github.com@uma.litech.org>
Date:   Tue Dec 4 17:08:19 2018 -0500
```

The comment for that commit includes this text that appears relevant:
```
Backwards compatibility with P4₁₄-style pragmas is also added as an
experimental feature.
    
On the initial parsing pass, annotation bodies are parsed as a
sequence of tokens in a new field, `Annotation::body`. After the
initial parse, `Annotation::expr` and `Annotation::kv` are
empty. P4₁₄-style pragmas are translated by the parser into P4₁₆
annotations: `@pragma name body` is translated into `@name(body)`.
```


## externDeclaration in P4C has extra production rule for forward declarations of externs

This extra production rule exists in [P4C] that is not present in [SPEC]:
```
externDeclaration
    | optAnnotations EXTERN name ";"
```

I did not find any examples of this in any of these directories in a
few minutes of looking:
+ testdata/p4_16_samples
+ backends/tofino/bf-p4c/p4include

Teis grammar rule was added with this commit to the p4c repo:

```
commit aa88d998c31e357b8a3e217d4e39626e70ddf2f7
Author: Chris Dodd <chris@barefootnetworks.com>
Date:   Mon Jun 5 08:08:10 2017 -0700
```

It has the comment "forward declaration" in [P4C].


## grammar.adoc file for [SPEC] is missing rule for declaring abstract methods

This extra production rule exists in [P4C] that is not present in [SPEC]:
```
methodPrototype
    | optAnnotations ABSTRACT functionPrototype ";"
```

However, it _is_ present in the body of the spec, but not in the
`grammar.adoc` file.

The language spec grammar has had this production rule for a while
now, since the following commit in the p4-spec repo:
```
commit ec2f2e105d59e003ab39d8f9d645e73b78a18fd6
Author: mbudiu-vmw <mbudiu@vmware.com>
Date:   Wed Jul 10 17:39:44 2019 -0700
```

However, it seems to have been neglected to add it to the
`grammar.adoc` file (formerly the `grammar.mdk` file).

This PR is intended to fix this minor issue:
+ https://github.com/p4lang/p4-spec/pull/1367



## statementOrDeclaration in P4C has extra production rule for instantiations, to give clearer error message

This extra production rule exists in [P4C] that is not present in [SPEC]:
```
statementOrDeclaration
    | instantiation
```

The earliest p4c commit I found that added this rule to the grammar
was:
```
commit f8e3df3d1d3432cf5f07c03f691af54e0cad2067
Author: Seth Fowler <seth@blackhail.net>
Date:   Thu May 4 11:08:46 2017 -0700
```

With this commit to the p4c repo:
```
commit cfb32104304888489236a14998a6e819cdf907b5
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Tue Aug 22 02:56:56 2023 -0400
```

the following comment was added to [P4C]:

```
     // The transition to instantiation below is not required by the
     // languge spec, but it does help p4c give a more clear error
     // message if one erroneously attempts to perform an
     // instantiation inside of a block.
     | instantiation            { $$ = $1; }
```


## 

This extra production rule exists in [P4C] that is not present in [SPEC]:
```
forCollectionExpr
    | typeRef
```

This has been added to both [P4C] and [SPEC] in 2024 by Chris Dodd.

TODO: Check with Chris what the intent is here.
