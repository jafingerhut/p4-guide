# Steps

Versions of p4c and behavioral-model source code used:

```bash
$ git log -n 1 | head -n 3
commit 5676f51a46a2aad26acbb2c9ef30d7c6d66d6bf8
Author: Mihai Budiu <mbudiu@vmware.com>
Date:   Wed Mar 13 13:50:00 2019 -0700

$ git log -n 1 | head -n 3
commit edce7af460b2c7f8565f2b3eab59e5ce5f5de027
Author: Antonin Bas <antonin@barefootnetworks.com>
Date:   Wed Mar 6 17:07:58 2019 -0800
```

Compiling `v1model-demo.p4`:

```bash
$ p4c --target bmv2 --arch v1model v1model-demo.p4
```

Produced the file `v1model-demo.json` in this directory.  I have run
packets using that JSON file and `simple_switch`, and it works as I
expect.

I copied it to `v1model-demo.hand-edited.json` and made some
modifications to it by hand, adding one entry to the `"field_aliases"`
section, and changing references to the original name to use the alias
instead, in the ingress pipeline.

You can look at [`v1model-demo.json.diff`](v1model-demo.json.diff) for
the hand-edits I made.

When I try to run `simple_switch` using that, I get:

```bash
$ simple_switch --log-console v1model-demo.hand-edited.json 
Calling target program-options parser
Invalid reference to object of type 'header' with name 'ig'
```
