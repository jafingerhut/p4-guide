# Creating new Golang modules

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


## Additional notes on modules in private repositories

The above seemed to be sufficient for modules in a public repository
of https://github.com

For a private repository, the following additional steps helped me get
to a working module.

In this example, the private repository was at this URL:

+ https://wwwin-github.cisco.com/jafinger/msic

From this page:

+ https://go.dev/doc/faq#git_https

I got the idea of adding these lines to my `$HOME/.gitconfig` file:

```
[url "ssh://git@wwwin-github.cisco.com/"]
    insteadOf = https://wwwin-github.cisco.com/
```

That seemed to help, but I still saw errors when trying to do `go get
wwwin-github.com/jafinger/misc/<modulepath>`, like these:

```bash
$ go mod tidy
go: finding module for package wwwin-github.cisco.com/jafinger/misc/puntpktprocessor/ringbuf
go: finding module for package wwwin-github.cisco.com/jafinger/misc/puntpktprocessor/pktsource
go: finding module for package wwwin-github.cisco.com/jafinger/misc/puntpktprocessor/ringbufhandler
go: wwwin-github.cisco.com/jafinger/misc/puntpkthandler imports
	wwwin-github.cisco.com/jafinger/misc/puntpktprocessor/pktsource: no matching versions for query "latest"
go: wwwin-github.cisco.com/jafinger/misc/puntpkthandler imports
	wwwin-github.cisco.com/jafinger/misc/puntpktprocessor/ringbufhandler: no matching versions for query "latest"
go: wwwin-github.cisco.com/jafinger/misc/puntpkthandler/ringbufhandler imports
	wwwin-github.cisco.com/jafinger/misc/puntpktprocessor/ringbuf: no matching versions for query "latest"
```

Some instructions from this page seemed to help:

+ https://go.dev/blog/publishing-go-modules

In particular, I did these things to add a version number to a
particular version of the repository:

```bash
$ git tag v0.1.1
$ git push origin v0.1.1
```

I _think_ that might have been sufficient to make a command like the
following work without errors:

```bash
$ go get wwwin-github.cisco.com/jafinger/misc/puntpktprocessor/ringbuf@v0.1.1
```

Note that you will still get errors if there are obsolete/wrong
package path names in import statements of the Go source files.
