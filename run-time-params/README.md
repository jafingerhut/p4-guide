The latest p4test as of 2017-Aug-17 gives an error when attempting to
compile these files:

- parsers.p4 demonstrates an attempt to pass a parser as a run-time
  parameter to another parser.

- controls.p4 demonstrates an attempt to pass a control as a run-time
  parameter to another control.

- control-variable1.p4 control-variable2.p4 control-variable3.p4
  demonstrate three different attempts to declare a variable with a
  type that is a control, or to assign different values to a such a
  variable or instance name at run time.  All give errors from the
  open source p4test compiler, probably by design.

See this links for more discussion:

- https://github.com/p4lang/p4-spec/issues/364
- https://github.com/p4lang/p4-spec/issues/361#issuecomment-318768783

