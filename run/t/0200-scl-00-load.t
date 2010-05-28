#!/run/bin/perl

use lib qw{
	      lib
	   ../lib
	../../lib
	 hump/lib
	      run/t
	   ../run/t
	../../run/t
	 hump/run/t
};

use IO::Capture::Sayfix;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Hump' );
}

diag( "Testing Test::Hump $Test::Hump::VERSION" );
