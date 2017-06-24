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

* action - yes, done.  keyword in p4_16-mode.el
* apply - keyword in p4_16-mode.el
* bit - no - type in p4_16-mode.el
* bool - no - type in p4_16-mode.el
* const - yes, done (not sure if I have all characters that can appear in type name) - attribute in p4_16-mode.el
* control - yes, done - keyword in p4_16-mode.el
* default - no - keyword in p4_16-mode.el
* else - no - keyword in p4_16-mode.el
* enum - keyword in p4_16-mode.el
* error - type in p4_16-mode.el
* extern - keyword in p4_16-mode.el
* exit - no - keyword in p4_16-mode.el
* false - no - constant in p4_16-mode.el
* header - yes, done - keyword in p4_16-mode.el
* header_union - yes, done - keyword in p4_16-mode.el
* if - no - keyword in p4_16-mode.el
* in - no - attribute in p4_16-mode.el
* inout - no - attribute in p4_16-mode.el
* int - no - type in p4_16-mode.el
* match_kind - keyword in p4_16-mode.el
* out - no - attribute in p4_16-mode.el
* package - yes, done - keyword in p4_16-mode.el
* parser - yes, done - keyword in p4_16-mode.el
* return - no - keyword in p4_16-mode.el
* select - no - keyword in p4_16-mode.el
* state - yes, done - keyword in p4_16-mode.el
* struct - yes, done - keyword in p4_16-mode.el
* switch - no - keyword in p4_16-mode.el
* table - yes, done - keyword in p4_16-mode.el
* transition - no - keyword in p4_16-mode.el
* true - no - constant in p4_16-mode.el
* tuple - keyword in p4_16-mode.el
* typedef - yes, although syntax parsing of type name might not be 100% accurate. - keyword in p4_16-mode.el
* varbit - no - type in p4_16-mode.el
* verify - no - keyword in p4_16-mode.el
* void - no - type in p4_16-mode.el


Not P4_16 keywords, but some standard and some extension table
attribute names:

* key - attribute in p4_16-mode.el
* actions - attribute in p4_16-mode.el
* default_action - attribute in p4_16-mode.el
* entries - attribute in p4_16-mode.el
* implementation - attribute in p4_16-mode.el
* counters - attribute in p4_16-mode.el
* meters - attribute in p4_16-mode.el

P4_16 common variable names:

* packet_in - variable in p4_16-mode.el
* packet_out - variable in p4_16-mode.el

P4_16 operations:

* &&& - operation in p4_16-mode.el
* .. - operation in p4_16-mode.el
* ++ - operation in p4_16-mode.el
* ? - operation in p4_16-mode.el
* : - operation in p4_16-mode.el

P4_16 constants:

* _ - constant in p4_16-mode.el
