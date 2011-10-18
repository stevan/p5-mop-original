# TODO

* consider locking the method and attribute hashes when
  they are returned from the Class methods
    * can this also be done with the superclass list?
* add &clone methods to all the elements of the MOP
    * specifically methods and attributes
* build out an instance protocol

# Things to ponder

* adding support for @foo and %bar with `has`
    * this could get really messy, i don't like it