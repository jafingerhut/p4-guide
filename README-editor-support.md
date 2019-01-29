# Editing P4 programs


## Color highlighting and auto-indenting

P4 is close enough in syntax to C/C++ that Emacs `c++-mode` works
pretty well for color highlighting, and auto-indentation of code with
the TAB key.  See below for something more tailored to P4.


## LSP implementation for P4

[P4LS](https://github.com/dmakarov/p4ls) is a Language Server Protocol
([LSP](https://microsoft.github.io/language-server-protocol/specification))
server for P4.  I have not used it personally, but am listing it here
in case others find it useful.


## Vim color highlighting and auto-indenting

To change the mode for the current file being edited:

```vim
:set syntax=c RET
```

To cause all files with a suffix of `.p4` in their file name to
automatically use C/C++ mode when loaded, add lines like the following
in your `$HOME/.vimrc` file:

```vim
augroup filetypedetect
  au BufRead,BufNewFile *.p4 setfiletype c
  " associate *.p4 with c filetype
augroup END
```


## Emacs color highlighting and auto-indenting

To change the mode for the current file being edited:

```
M-x c++-mode RET
```

To cause all files with a suffix of `.p4` in their file name to
automatically use C/C++ mode when loaded, add lines like the following
in your `$HOME/.emacs.d/init.el` file:

```elisp
(setq auto-mode-alist (cons '("\\.p4$" . c++-mode) auto-mode-alist))
```

If you want better P4-specific features in Emacs, thanks to Vladimir
Gurevich you may copy these files to your `$HOME/.emacs.d` directory:

* [editor-support/p4_16-mode.el](editor-support/p4_16-mode.el)
* [editor-support/p4_14-mode.el](editor-support/p4_14-mode.el)

Then add lines like these to your `$HOME/.emacs.d/init.el` file:

```elisp
(require 'p4_16-mode)
(require 'p4_14-mode)

;; Both P4_14 and P4_16 programs typically use a file name suffix of
;; '.p4', so it is not easy for Emacs to automatically determine from
;; the file name alone which mode to use.

;; If you put one of the lines below as the first line of your P4
;; program (with the ';;' Emacs Lisp comment characters removed),
;; Emacs will use that to choose the mode:

;; /* -*- mode: P4_16 -*- */
;; /* -*- mode: P4_14 -*- */

;; For files that do not have a line like that in them, the following
;; Emacs Lisp code can do a reasonable job of picking the right mode
;; based upon the file name, for files in the repository
;; https://github.com/p4lang/p4c

(setq auto-mode-alist
      (append '(
		("p4_14.*[.]p4" . p4_14-mode)
		("p4_16.*[.]p4" . p4_16-mode)
		;; Use p4_14-mode on the next line if most of your .p4
		;; files use P4_14.
		(".*[.]p4"      . p4_16-mode))
	      auto-mode-alist))
```


## cscope

While the [`cscope`](http://cscope.sourceforge.net/) program was
originally written for C/C++ programs, it works quite well on P4
programs, too.  To install it on Ubuntu Linux:

    sudo apt-get install cscope

The first command below creates a file `cscope.files` that contains a
list of names of all files with suffixes `.p4` and `.h` in the current
directory and all subdirectories.  The second command reads that list
of file names, and builds an index file `cscope.out` of symbols in
those files.

    find . -name '*.p4' -o -name '*.h' > cscope.files
    cscope -bk

If the links below do not help you using cscope in your chosen editor,
check the [`cscope` page](http://cscope.sourceforge.net/) for more.

* Vim: One page found by Google search for the terms "vim cscope"
  [here](http://cscope.sourceforge.net/cscope_vim_tutorial.html)
* Emacs: `xcscope` is an Emacs package that makes it straightforward
  to use the cscope search capabilities from inside of Emacs.


## Tags

[Exuberant ctags](http://ctags.sourceforge.net/) can be configured to
create tags for Emacs, Vim, and many other text editors for quickly
finding definitions of some symbols, such as actions, control flow
functions, and headers.  On Ubuntu Linux, it can be installed with:

    sudo apt-get install exuberant-ctags

On macOS with MacPorts installed, you can install Exuberant ctags
with:

    sudo port install ctags

To create a tags file for a collection of files containing a single P4
program, first edit your `$HOME/.ctags` to add lines like the ones in
the file [`dot-ctags-for-p4-14.txt`](editor-support/dot-ctags-for-p4-14.txt) or
[`dot-ctags-for-p4-16.txt`](editor-support/dot-ctags-for-p4-16.txt).

To create a TAGS file for use with Emacs, for all source files with a
`.p4` or `.h` suffix in the current directory and all sub-directories,
use this command:

    ctags-exuberant -e -R

Remove the '-e' command line option if you want to generate a 'tags'
file for Vim.

You can also give an explicit list of file names instead of the -R
option, if there are some files you do not wish to include.  The
following command achieves a similar effect as the one above, but may
be more easily modified to include or exclude the files you want:

    find . -name '*.p4' -o -name '*.h' | xargs ctags-exuberant -e

Instructions for using 'tags' file to navigate source code:

* Vim: http://vim.wikia.com/wiki/Browsing_programs_with_tags
* Emacs: https://www.emacswiki.org/emacs/EmacsTags
