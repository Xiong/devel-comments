#!/run/bin/perl 

use lib qw{
	      lib
	   ../lib
	../../lib
};

use Test::More tests => 1;

BEGIN {
	$SIG{__DIE__}	= sub {
		warn @_;
		BAIL_OUT( q[Couldn't use module; can't continue.] );	
		
	};
}	

BEGIN {
	use Smart::Comments::Any;
}

pass( 'Load module.' );
diag( "Testing Smart::Comments::Any $Smart::Comments::Any::VERSION" );



