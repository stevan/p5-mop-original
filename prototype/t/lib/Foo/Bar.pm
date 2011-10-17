# NOTE:
# the following 3 lines and
# the BEGIN block shouldn't
# be neccessary and really
# should be implied.
# - SL
use strict;
use warnings;
use mop;
BEGIN {
    class Foo::Bar {}
}

1;
