The program `typedef-test1.p4` contains a simple header type
definition `ethernet_t` with four fields.  Three of those four fields
are the same as each other in the underlying `bit<48>` type:

+ field `addr0` has a type named `Eth0_t` declared using `typedef`
+ field `addr1` has a type named `Eth1_t` declared using `type`, with
  no annotations
+ field `addr2` has a type named `Eth2_t` declared using `type`, with
  a `@p4runtime_translation` annotation

If you run the p4c command in the script `compile.sh`, it generates
the P4Info file `typedef-test1.p4info.txtpb`, as well as the P4_16
code at the end of all front-end passes (file name
`tmp/typedef-test1-0002-FrontEnd_70_FrontEndLast.p4`), and at the end
of all mid-end passes (file name
`tmp/typedef-test1-0003-P4::BMV2::SimpleSwitchMidEnd_44_MidEndLast.p4`).

Both of those preserve the `typedef` declaration of `Eth0_t`, but only
the `FrontEndLast` file preserves the type of field `addr0` as
`Eth0_t` in these places:

+ the type of the first field `addr0` of header type `ethernet_t`
+ the first parameter of action `set_headers`

Thus it seems that p4c does not erase the existence, nor the uses, of
the `typedef` `Eth0_t`, until somewhere in a midend pass.


# Experiment #1

File `experiment1.patch` is a diff that I tried locally as an
experiment, applied to this version of p4c source code:

```
commit 98a34fead058ed7ff09026de6e9b4abe9fb9e15d (HEAD -> master, upstream/master, origin/master, origin/HEAD)
Author: Mihai Budiu <mbudiu@vmware.com>
Date:   Fri Apr 10 10:25:22 2020 -0700
```

The output from when I ran the `compile.sh` script with this command:

```bash
$ ./compile.sh >& experiment1-compile-out.txt
```

is in the file `experiment1-compile-out.txt`.  There you can see that field
`addr1` has type `Eth1_t`, and field `addr2` has type `Eth2_t`, which
are declared using `type` declarations, but whatever C++ calls are
being used there for the field `addr0` only show the underlying type
`bit<48>`, not the typedef `Eth0_t`.

Are there other C++ calls that could be made there to find the typedef
type `Eth0_t` for field `addr0`, both as an action parameter as a
table key field?

I am trying these experiments because they might lead to changes in
the P4Info generation that could use `@p4runtime_translation`
annotations, and in the future perhaps other annotations, on `typedef`
declarations, similar to how they are used on types declared via
`type` declarations today.

See this comment:

+ https://github.com/p4lang/p4-spec/issues/815#issuecomment-608196454

about how one might change the P4_16 language spec to enable
annotations on `typedef` declarations.  I am not sure yet, but it
seems that perhaps there would be no changes to the language spec
required for this, only to p4c.


# Experiment #2

Based on feedback on this issue that I created about experiment #1:

+ https://github.com/p4lang/p4c/issues/2310

and in particular these two comments with suggested code changes to
try:

+ https://github.com/p4lang/p4c/issues/2310#issuecomment-613014526
+ https://github.com/p4lang/p4c/issues/2310#issuecomment-613049589

I tried applying the changes in `experiment2.patch` to the same
version of p4c described for experiment #1 above.

Even when using that C++ code to try to get the type of field `addr0`
in a header, declared as `typedef bit<48> Eth0_t`, that code finds a
type of `bit<48>`, not `Eth0_t`.

Output of this command is in the file shown in the command:

```bash
$ ./compile.sh >& experiment2-compile-out.txt
```


# Places where a typedef type should perhaps matter for propagating the `@p4runtime_translation` annotation

+ Fields in a header or struct declared as typedef
+ Action parameters declared as typedef
+ Local variables in a control or parser declared as typedef
+ Elements of a list where element type is a typedef?
+ Table key expressions
  + If the expression has a (typedef) cast at the "top level" of the
    expression.
  + If the expression is "simple", i.e. it is just a local variable or
    struct/header member.  In this case, look up whether it is
    declared as typedef.
