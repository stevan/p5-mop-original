# A prototype of the MOP for Perl 5

**NOTE: This is still _VERY_ much a work in progress**

This is a prototype of the proposed MOP for Perl 5. The
main purpose of this prototypes is to work out a few
of key things; the syntax/semantics of the object
system, the underlying MOP API and the extensibility
of the MOP itself.

Ideally this will also provide the starts of a test
suite that can be ported to the final implementation.

This prototype, for the most part, accurately
reflects the proposed syntax/semanitics of the object
system, however the implementation is another story.
Basically, any implementation found in these folders
should *NEVER* be considered a proposal for a *specific*
implementation technique. In fact, much of what you might
find in here will likely use scary and tricky techniques
to accomplish desired behaviors, and it would be
expected that a real implementation would *NOT* use
such scary and tricky techniques.
