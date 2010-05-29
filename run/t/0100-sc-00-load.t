#!/run/bin/perl

use lib qw{
	      lib
	   ../lib
	../../lib
	      run/t
	   ../run/t
	../../run/t
};

use Test::More tests => 1;

BEGIN {
use_ok( 'Smart::Comments' );
}

diag( "Testing Smart::Comments $Smart::Comments::VERSION" );
