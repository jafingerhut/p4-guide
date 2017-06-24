## Notes on P4_16 keywords

Listed below are P4_16 reserved keywords, followed by whether I think
the keyword ought to cause entries to be created in tags files for
navigating withing P4 source code using vim/emacs/etc.

First the list of things that would be nice to improve tags creation
for:

* enum - yes for enum name, but not sure how to implement tags for the values inside the enumeration.
* error - there is no name for the error declaration as a whole, but similar to enums, it would be nice to have tags for the individual error names enumerated within.
* extern - yes, done, at least for the extern name as a whole.  How to do it for functions declared within the extern, though?
* match_kind - no name for the match_kind declaration as a whole, but similar to enums and errors, it would be nice to have tags for the individual match_kind names enumerated within.
* tuple - would be nice, but not sure how to specify syntax with exuberant ctags accurately, since what can follow keyword 'tuple' before the name of the tuple defined can have nested angle brackets that should balance.


Now the list of things that I believe are fairly accurately done
already:

* action - yes, done
* apply
* bit - no
* bool - no
* const - yes, done (not sure if I have all characters that can appear in type name)
* control - yes, done
* default - no
* else - no
* exit - no
* false - no
* header - yes, done
* if - no
* in - no
* inout - no
* int - no
* out - no
* package - yes, done
* parser - yes, done
* return - no
* select - no
* state - yes, done
* struct - yes, done
* switch - no
* table - yes, done
* transition - no
* true - no
* typedef - yes, although syntax parsing of type name might not be 100% accurate.
* varbit - no
* verify - no
* void - no
