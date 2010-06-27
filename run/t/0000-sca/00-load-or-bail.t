#!/run/bin/perl 

use lib qw{
	      lib
	   ../lib
	../../lib
};

use Test::More tests => 1;

#~ BEGIN {
#~ #= 	eval { use_ok( 'Smart::Comments::Any' ) };
#~ 	use_ok( 'Smart::Comments::Any' );
#~ }
#~ 
#~ BEGIN {
#~ 	eval { use Smart::Comments::Any; };
#~ }
#~ 
#~ BEGIN {
#~ 	BAIL_OUT( q[Couldn't use module; can't continue.] ) if $@;
#~ }

BEGIN {
	$SIG{__DIE__}	= sub {
		warn @_;
		BAIL_OUT( q[Couldn't use module; can't continue.] );	
		
	};
}	

BEGIN {
	use Smart::Comments::Any;
#~ 	use_ok( 'Smart::Comments::Any' );
}

pass( 'Load module.' );

#~ eval { use Smart::Comments::Any; };
#~ BAIL_OUT( q[Couldn't use module; can't continue.] ) if $@;
diag( "Testing Smart::Comments::Any $Smart::Comments::Any::VERSION" );

#= BEGIN {
#= #~ 	use Smart::Comments;
#= 	use_ok( 'Smart::Comments' );
#= }
#= 
#= 
#= #~ eval { use Smart::Comments; };
#= BAIL_OUT( q[Couldn't use module; can't continue.] ) if $@;
#= diag( "Testing Smart::Comments $Smart::Comments::VERSION" );


