#!/run/bin/perl

use lib qw{
	      lib
	   ../lib
	../../lib
};

use Test::More tests => 1;

BEGIN {
	use_ok( 'Smart::Comments::Any' );
}

diag( "Testing Smart::Comments::Any $Smart::Comments::Any::VERSION" );

# RIGHT.

### foo

# STOP.
no Smart::Comments;
no Smart::Comments::Any;
# WRONG!

### bar
