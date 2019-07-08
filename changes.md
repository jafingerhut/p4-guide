# Change log

This is a very selective description of changes.  The git commit log
is the complete source for all changes.


## 2019-Jul-08

Made a few small additions to these files:

* `p4-16-allowed-constructs.dot`
* `p4-16-allowed-constructs.txt`

Added 'if' explicitly as something not allowed inside a parser state
to the figure.  The text version has had that for a while now, but it
seemed prudent to add it to the figure version, since 'if' statements
are commonly desired statements when writing programs, and I went to
the trouble to investigate where the language spec allows and does not
allow 'if' statements.

Added 'if' as something explicitly allowed inside a function
definition.

Added note on 'if' inside of action declaration that the language spec
explicitly allows implementations not to support 'if' inside of
actions.

Added edge from 'switch' statement to the box representing allowed
statements inside of blocks.

