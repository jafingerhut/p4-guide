# Introduction


## Notes on structure of Python test code

A PTF test file like `p4-guide/demo1/ptf/demo1.py` imports these
Python packages:

```python
import ptf
import ptf.testutils as tu
from ptf.base_tests import BaseTest
import p4runtime_sh.shell as sh
import p4runtime_shell_utils as p4rtutil
```

The `ptf` package by itself contains NO dependency on P4Runtime APIs.
You can write tests with PTF that do not use P4Runtime APIs to
configure a network device.  For example, Intel often uses PTF tests
that use TDI or the Barefoot Runtime API to configure a network
device, with no use of P4Runtime API at all.  Intel also sometimes
writes PTF tests that use the P4Runtime API, too.

`ptf` by itself does have functions defined for sending packets to a
device and expecting particular packets to be sent as output packets
by the device.  Those are common to any packet-processing based device
being tested, independent of what control plane API is used to
configure it.

Older versions of the PTF tests in this repository (they can be found
in the git history before they were updated early in 2023-Jan) used a
package called `base_test`.  The `base_test` package contains a
significant amount of code that is specific to using the P4Runtime
API.  `base_test` is also written in a way that requires using PTF's
test classes, e.g. it imports and uses class `BaseTest` from package
`ptf.base_tests`.  Thus if one wanted to write a P4Runtime controller
(also known as a P4Runtime client) in Python that was _not_ part of a
PTF test, it was either difficult or impossible to do so using
`base_test`, because of how `base_test` was intertwined with the PTF
package.

In 2023-Jan, I was considering restructing `base_test` into 2 or more
packages:

+ one that provided useful P4Runtime API functionality, but could be
  used just as easily from code that was not a PTF test.
+ another that provided useful features for writing PTF tests.

However, I realized that the [p4runtime-shell
project](https://github.com/p4lang/p4runtime-shell) could perhaps
serve as the first part.  I spent several days experimenting with it,
and found that I could update all of the PTF tests to use
`p4runtime-shell` and achieve most of the desired functionality that
`base_test` provided.  `p4runtime-shell` also includes some features
that `base_test` did not have.  Except for a small fraction of
functions in `base_test.py` that I have adapted and added to a new
package `p4runtime_shell_utils`, `base_test` is not used in this
repository any longer.


## Versions of the file base_test.py

There are several different open source versions of a Python file
called `base_test.py` that have been published.  I believe they all
originated with this version:

+ File `proto/ptf/base_test.py` in the repository
  https://github.com/p4lang/PI

Another published version with some changes from the one above is:

+ File `tests/ptf/base_test.py` in the repository
  https://github.com/opennetworkinglab/fabric-p4test

The ones above were written for Python2.  The version in this
directory is adapted from those, with some changes, including:

+ only intended to work with Python3.  No attempt will be made to test
  it with Python2.


## Steps to create the file `base_test.py` here

Started by copying the first file above from commit SHA
4961fb9fb7a03b8fe7f1511f05fc7a0238b1d88c of repository
https://github.com/p4lang/PI

That commit SHA is for a commit made 2021-Mar-11.  There have been no
changes to file `proto/ptf/base_test.py` in the `p4lang/PI` repository
after then, up to 2023-Jan-01.
