# Introduction

A tiny example demonstrating a feature of VScode that can highlight
lines of code in a C program in different colors, based upon which C
preprocessor symbols are defined, or not.  This can be useful for more
quickly and easily seeing which code is active for a given set of
preprocessor symbol settings, vs. which code is inactive or "dead".

This feature can also be used for P4 programs that use the C
preprocessor, although right now I do not know how to configure VScode
to do this for file names with a suffix of `.p4`, only for file names
with a suffix of `.c`, so right now I only know how to do this if you
rename your P4 program source files.  If anyone knows how to configure
VScode to do this for files with a suffix of `.p4`, please let me
know.


# Steps to follow for a new project on Ubuntu Linux

These steps have been tested on these versions of Ubuntu Linux

+ 24.04


## Installing C development tools and VScode

Install C/C++ compiler, gdb, and VScode:
```bash
sudo apt-get install build-essential gdb
sudo snap install --classic code
```

Clone the p4-guide repo if you have not already:
```bash
git clone https://github.com/jafingerhut/p4-guide
cd p4-guide/vscode-preproc-highlighting
```


## Starting VScode for the first time, and adding some extensions

Start VScode in this directory:
```bash
code .
```

If a window pops up asking "Do you trust the authors of the files in
this folder?", click on the button "Yes, I trust the authors".

If the main pane says "Get Started with VS Code", here are the
settings that I selected:

+ Clicked on theme "Dark Modern"

Scrolled down to find the link "Mark Done", and clicked on that.

In the left column near the top were 5 icons in a column.  Hovering
over the bottom of those 5 icons said it was called "Extensions".  I
clicked on that.

In the search box, I typed: C/C++

In the list of choices below the search box, I clicked on the one
named "C/C++" published by Microsoft.  In the main pane the version of
the extension that I saw was "v1.20.5".  I clicked on the "Install"
button.  Waited for the install to finish, which took about a minute.


## Opening program hello.c

In the left column of 5 icons, the top of those 5 hovering over it
showed it was called "Explorer".  Clicked on that.

A directory named "c-helloworld" appeared in the left pane, with an
icon ">" before it.  Clicked on the ">" to change it to "V" and expand
to show the contents of the directory.

Clicked on the file named "hello.c" beneath "c-helloworld" to open it.

A pop-up window near the bottom right suggested I install the package
"C/C++ Extension Pack".  I clicked "Install" to do so.  When it was
finished installing, I repeated the steps immediately above to go back
to the file "hello.c".

I selected menu item Help -> About to see what version of VScode I was
using.  It showed version 1.91.0.  I do not know what range of
versions these isntructions are applicable for.

The program is very short, and is just the familiar "Hello, world!" C
program, except with #ifdef's for showing the message "Hello, world!"
in one of three languages: English, Esperanto, or French, depending
upon the value of 3 preprocessor symbols.

Different colors are used for `#ifdef` and `#endif`, vs. strings,
vs. function names, but note that the color of all three `#ifdef`
sections is the same as each other.  We are going to change some
configuration to change that.


## Enabling inactive region colorization

Choose menu item Help -> Show All Commands

In the text box, type the word: inactive

One of the top choices beneath that should be:

+ C/C++: Toggle Inactive Region Colorization

Click on that line.  The side effect should be that it created a
directory `.vscode`, and inside of there a file named `settings.json`,
which now contains this:

```json
{
    "C_Cpp.dimInactiveRegions": false
}
```

Actually, we want that value to be true, so if it says "false", repeat
the steps above to toggle the setting again, until the `settings.json`
file shows the value `true`.


## Modify which preprocessor symbols are defined, for the purposes of inactive region colorization

Now we need to tell VScode which preprocessor symbols should be
considered defined, for the purposes of inactive region colorization.

Note: These settings used for inactive region colorization are
_independent_ of the settings used to compile your C program.
Strange, but probably sometimes useful, as long as you know these
settings are not one and the same, but configured separately.

Choose menu item Help -> Show All Commands

In the text box, type the text: C/C++ edit

One of the top choices beneath that should be:

+ C/C++: Edit Configurations (UI)

Click on that line.

The main pane shows "IntelliSense Configurations" with a lot of text
boxes and other things below it, spanning for several vertical
windowfuls.  It also created a file `.vscode/c_cpp_properties.json`.

In the main pane, scroll down until you see a section titled
"Defines".

In the text box, enter this text on the first line: LANG_ENGLISH

Go back to viewing "hello.c", and hopefully you should see that the
color of the text for these lines:

```c
    printf("Saluton mondo!\n");
    printf("Bonjour le monde!\n");
```

should be slightly dimmer than the color of the text for this line:

```c
    printf("Hello, world!\n");
```


## Modifying the font color used to display inactive regions

To make the contrast even more obvious, you can change the color used
to display parts of the program that are considered inactive.

Near the bottom left of the window should be an icon that looks like a
gear shape.  Hovering over it should show the text "Manage".  Click on
that icon.  A window should appear.  Click on the entry "Settings".

There is a text box near the top of the main pane that says "Search
settings".

Click there and type the text: font

Part of the column of results should be:

```
V Extensions
  V C/C++
      IntelliSense
```

Click on the line that says "IntelliSense".

The biggest part of the pane should now contain text like this, with a
text box below it:

```
C_Cpp: Inactive Region Foreground Color

Controls the font coloring of inactive preprocessor blocks.
Input is in the form a hexadecimal color code or a valid
Theme Color.  If not set, this defaults to the syntax coloring
scheme of the editor.  This setting only applies when inactive
region dimming is enabled.
```

In the text box, enter the following text: #404040

This should be a fairly dark gray color.

If you go back to view "hello.c" again, now the inactive lines should
be quite dark gray on a slightly darker gray background, with quite
low contrast.


## Experiment!

You can repeat the steps in the section above titled "Modify which
preprocessor symbols are defined, ..." and change the preprocessor
symbol that is defined from `LANG_ENGLISH` to whatever you want.

For example, try changing it to `LANG_FRENCH`, and the inactive
regions should change when displaying the contents of `hello.c`.


## A hack to use this feature when viewing P4 programs

If you rename your P4 source files to have a suffix of `.c` instead of
`.p4` and view them in VScode after the setup above, the inactive
region colorization feature should work there as well.

Steps I took to verify this:

```bash
git clone https://github.com/sonic-net/sonic-pins
cd sonic-pins/sai_p4/instantiations/google
mkdir renamed-p4-files
for j in *.p4
do
    cp -p $j renamed-p4-files/`basename $j .p4`.c
done
cd renamed-p4-files
code .
```

In VScode window, as before I clicked the "I trust the authors" button.

Opened the file `tor.c`

I repeated the following steps, because the `.vscode` directory is
different for each "project", and these steps are treating the
directory `renamed-p4-files` as a different project than the hello.c
program.

Repeated the steps in the "Modify which preprocessor symbols are
defined, ..." above, except I used the preprocessor symbol:
`SAI_INSTANTIATION_TOR`

Repeated the steps in the "Modifying the font color used to display
inactive regions" action above.

Now open the file `acl_egress.c`.  In the version of the file I
examined, lines 37 through 50 contained some sections with `#ifdef
SAI_INSTANTIATION_FABRIC_BORDER_ROUTER` and `#endif` around them.
Their contents were highlighted as dark gray because they were
inactive.

There was another section with `#if defined(SAI_INSTANTIATION_TOR)`
and `#endif` around it, and that text was highlighted normally,
because it was active.
