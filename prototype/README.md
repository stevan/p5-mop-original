# A prototype of the MOP for Perl 5

**NOTE: This is still _VERY_ much a work in progress**

This is a _very rough_ prototype of the proposed MOP
for Perl 5. The main purpose of these prototypes are
to work out the MOP API as well as some key functionality.
Ideally this might also provide the starts of a test
suite that can be ported to the final implementation.

This prototype should in no way be taken as
an accurate portrayal of the code or syntax of the
final proposal, it is mearly a sandbox for testing
out the ideas and will most certainly contain some
ugly weird hacks to make things work correctly in
Pure Perl 5.

Additionally any implementation found in these folders
should *NEVER* be considered a proposal for a specific
implementation technique. In fact, much of what you might
find in here will likely use scary and tricky techniques
to accomplish desired behaviors, and it would be
expected that a real implementation would *NOT* use
such scary and tricky techniques.

# TODO

* consider locking the method and attribute hashes when
  they are returned from the Class methods
    * can this also be done with the superclass list?
* add &clone methods to all the elements of the MOP
    * specifically methods and attributes
* build out an instance protocol
* implement DEMOLISH

# Things to ponder

* moving the "call all BUILD methods" to the internals::class module
    * same with handling DEMOLISH
    * or perhaps this belongs in the DISPATCHER?
* adding support for @foo and %bar with `has`
    * this could get really messy