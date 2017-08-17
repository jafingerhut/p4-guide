The latest p4test as of 2017-Aug-17 gives an error when attempting to
compile these files:

- parsers.p4 demonstrates an attempt to pass a parser as a run-time
  parameter to another parser.

- controls.p4 demonstrates an attempt to pass a parser as a run-time
  parameter to another parser.

- control-variable.p4 demonstrates an attempt to declare a variable
  with a type that is a control.  There is no error declaring variable
  c0 of type C1, but that is uninitialized and not good for much.  The
  later declaration for variable c1 with an initializer expression of
  MyC1() gives an error because the compiler expects a method call in
  the initializer expression.  The same error occurs if you try to
  assign a value to c1 inside a control apply block.

See this links for more discussion:

- https://github.com/p4lang/p4-spec/issues/364
- https://github.com/p4lang/p4-spec/issues/361#issuecomment-318768783

