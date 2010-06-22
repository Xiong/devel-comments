#!/run/bin/perl 

use lib qw{
	      lib
	   ../lib
	../../lib
};

use Test::More tests => 1;

#----------------------------------------------------------------------------#

# Allow testing of various modules with one test script.
BEGIN {
	%::MUDH	= (
		1		=> 'Smart::Comments::Any',
		2		=> 'Smart::Comments',
		
	);
	$::MUDH{0}	= $::MUDH{1};	# we're not fussy
}

# Catch fatal errors and report them. 
BEGIN {
	$SIG{__DIE__}	= sub {
		warn @_;
		BAIL_OUT( q[Couldn't use module; can't continue.] );	
	};
}	

# Decide which module to load.
# Choose module number with: prove [-options] [dirs|files] :: 2 
BEGIN {
	if ($ARGV[0]) 	{ $::MUDX	= $::MUDH{$ARGV[0]} } 
	else 			{ $::MUDX	= $::MUDH{0} };
	
	$::MUD		= $::MUDX;		# save original string for report and symref
	$::MUDX		=~ s{::}{/}g;	# replace pathpart separators !UNIX ONLY SORRY!
	$::MUDX		.= q{.pm};		# append standard perl module file extension
}

# Conditional use
use if $::MUD eq 'Smart::Comments::Any', Smart::Comments::Any, '###', '#####';
use if $::MUD eq 'Smart::Comments', Smart::Comments, '###', '#####';

#~ # Simulate use().
#~ BEGIN {
#~ 	require $::MUDX;			
#~ 	import  $::MUDX;			# empty list supresses import or supply a list
#~ }

# NOTE (Camel): 
# use() eq BEGIN { require MODULE; import MODULE LIST; }

#----------------------------------------------------------------------------#

### borkborkbork
#### borkborkbork-bork
##### borkborkbork-borkbork

# Getting this far is a pass. 
pass(  q[load-module] );
diag( qq[Testing $::MUD ${"$::MUD\::VERSION"}] );	# comment out if more testing


