Date: 2023-Nov-27

Future plan: Have another meeting on this topic some time in the last
half of Jan 2024.

The purpose of this meeting is to share the results of the survey on
loops in P4 (see below), and to discuss next steps.

I sent out a list of survey questions early in 2023-Nov.  The link
below contains the raw answers (no names or identifying information
was recorded from those who responded), and summaries of counts of
yes/no answers:

https://docs.google.com/spreadsheets/d/1ydux5_sJ13Fsjd4QD3Lswh789plcLjXujs9MqYOyvms

I do not think language designers should necessarily slavishly follow
such survey results, but they may find it interesting in knowing what
kinds of language features some people desire.

If we reject a preprocessor approach, at least we should describe why.

Advantages of _some_ preprocessor approach (e.g. GNU C preprocessor
CPP, Boost preprocessor, Jinja/Inja):

+ no changes required to the P4 language spec
+ the implementation is already done and ready to use

Disadvantages:

+ Less readable syntax (even for Jinja, but Jinja nicer than Boost pp).
+ New external dependency.
+ Error messages when you mess it up can be challenging to debug.
  + Alan: My experience is that this is also a disadvantage for Jinja, too.

If we go for something "built into P4", there are many use cases where
it is currently convenient to concatenate strings to make new
identifiers.

For example, tables, actions, and extern instances need names in order
to use them via a control plane API like P4Runtime API.  There is no
obvious way to make them anonymous/unnamed, and yet still
control-plane configurable.

Thus if you want to have compile-time loops in P4 that can create one
or more table instances, actions, or extern instances per iteration
through the loop, there needs to be a way to give each of them a
distinct name.

One way to do this is the way the GNU C preprocessor supports, which
is to have an something like its `##` operator that enables one to
create identifier strings that are concatenations of multiple strings,
e.g. `my_table_ ## loop_variable_name`, where `loop_variable_name`'s
value is converted to a string that is the numeric value's decimal
representation.

Possible approaches:

+ string concatenation that creates new identifiers during
  compile-time loop expansion, e.g. perhaps with syntax like `<string1>
  ## <string2>` similar to CPP
+ define arrays of such objects, e.g. actions, tables, extern instances
  + Are there tricky issues to solve here?
  + What should runtime API name be?
    + Perhaps the strings "t[1]", "t[2]", "t[3]", etc.
      + Note: the P4Runtime API numeric IDs for each object need not
        be consecutive, i.e. they could be hashes of "t[1]", "t[2]",
        etc.
    + Or you need arrays of those object types in P4Runtime API
+ Do not support creation of these object types inside of a loop body
  until a better motivation given.


AR Andy: Send email follow-up to survey asking if anyone who answered
yes to these cases is willing to publish an open-source example that
they consider compelling?


One idea discussed was the following possible enumerator syntax:

{ <expr containing i> : i in {1, ..., 10} }

For example, for repetitive table definitions, if we had arrays of
tables:

{ table foo[i] {
      key = { /* keys here */ }
      actions = ...
  }
  : i in {1, ..., 10} }

The syntax above is a strawman proposal.

Jonathan: Having an expression representing a function that produces
tables that has parameters would be one way to design this.

And this should generalize to any other language construct that we
want to "loop".

Compile-time expansion guarantee has the nice property that an
implementation can be in an early phase of p4c, where all steps after
that phase have _no_ loops in the IR any more.
