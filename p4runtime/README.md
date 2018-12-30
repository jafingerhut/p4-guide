# P4Runtime Protobuf messages and their relationships

This directory contains some mostly auto-generated drawings of the
P4Runtime Protobuf message types, and the relationships between them.

First, some entirely auto-generated files were created on an Ubuntu
18.04 Linux system by running these scripts:

```bash
% cd $HOME
% git clone https://github.com/p4lang/p4runtime
% git clone https://github.com/jafingerhut/p4-guide
% ./p4-guide/bin/install-protodot.sh
% ./p4-guide/bin/run-protodot.sh
```

Then I renamed the files with a `.dot` suffix and hand edited them.

The version of the `p4runtime` Git repository that the `.proto` files
were used had this commit as the most recent one:

```
commit d88c4ab58b1b60f952f9523085bf160890ab3c82 (HEAD -> master, origin/master, origin/HEAD)
Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
Date:   Wed Dec 26 19:36:49 2018 -0800
```

Both of the file `p4info-and-p4types.hand-edited.dot` and
`p4runtime-and-p4data.hand-edited.dot` were edited to add new nodes
with names ending with " copy <number>", which are intended to be
"references" to the auto-generated node with that name.  The main
reason these nodes were added is so that many edges ended up being
significantly shorter, and the remaining edges are much easier to
follow.

The file `p4runtime-and-p4data.hand-edited.dot` started with a copy of
all nodes and edges in the file `p4info-and-p4types.hand-edited.dot`,
but I wanted two smaller drawings rather than one larger one, so I
deleted all nodes and edges from
`p4runtime-and-p4data.hand-edited.dot` that appeared in the other one,
except perhaps for a few minor ones like `google.protobuf.Any`.

The `.pdf` and `.svg` files were completely auto-generated from the
hand-edited `.dot` files using the GraphViz `dot` commands:

```bash
% dot -Tpdf p4info-and-p4types.hand-edited.dot > p4info-and-p4types.hand-edited.pdf
% dot -Tsvg p4info-and-p4types.hand-edited.dot > p4info-and-p4types.hand-edited.svg
% dot -Tpdf p4runtime-and-p4data.hand-edited.dot > p4runtime-and-p4data.hand-edited.pdf
% dot -Tsvg p4runtime-and-p4data.hand-edited.dot > p4runtime-and-p4data.hand-edited.svg
```
