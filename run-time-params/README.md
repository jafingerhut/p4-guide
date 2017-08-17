The latest p4test as of 2017-Aug-17 gives an error when attempting to
compile these files:

- parsers.p4 demonstrates an attempt to pass a parser as a run-time
  parameter to another parser.

- controls.p4 demonstrates an attempt to pass a parser as a run-time
  parameter to another parser.

See this links for more discussion:

- https://github.com/p4lang/p4-spec/issues/364
- https://github.com/p4lang/p4-spec/issues/361#issuecomment-318768783
