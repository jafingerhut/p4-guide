I was using go version 1.22.4 while writing these notes.  I do not
know whether recommendations have changed across go versions.

It seems to be recommended to have one module per revision-controlled
repository, e.g. per Github repository.

There should be a single `go.mod` and `go.sum` file in the root
directory of the repository.

Such a repository can have many separate programs, each with their own
main package, preferably in different directories of the repo.

To create the initial `go.mod` file for the repository, after Go is
installed on the system so you can run `go` commands, change to the
root directory of the repository and run this command:

```bash
go mod init wwwin-github.cisco.com/jafinger/misc
```

Replace the URL with the URL of your repository.  Omit any `https://`
or `http://` prefix, and any `.git` suffix.
