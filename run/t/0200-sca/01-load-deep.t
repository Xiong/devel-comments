#!/run/bin/perl

use strict;
use warnings;
use feature 'say';
use Carp;

use lib qw{
	      lib
	   ../lib
	../../lib
};

use Test::More 0.94;
use Test::Deep;
use Try::Tiny;

use IO::Capture::Stdout::Extended;
use IO::Capture::Stderr::Extended;
use IO::Capture::Sayfix;
use IO::Capture::Tellfix;



# passed to done_testing() after all subtests are run
my $test_counter	= 0;

# temp for actual calls to Test::More, Test::Deep, and friends
my $regex			;
my $got				;
my $expected		;
my $subname			;

#----------------------------------------------------------------------------#

# Allow testing of various modules with one test script.
BEGIN {
	%::MUDH	= (
		1		=> 'Smart::Comments::Any',
		2		=> 'Smart::Comments',
		
	);
	$::MUDH{0}	= $::MUDH{1};	# we're not fussy
}

#~ # Catch fatal errors and report them. 
#~ BEGIN {
#~ 	$SIG{__DIE__}	= sub {
#~ 		warn @_;
#~ 		BAIL_OUT( q[Couldn't use module; can't continue.] );	
#~ 	};
#~ }	

# Decide which module to load.
# Choose module number with: prove [-options] [dirs|files] :: 2 
BEGIN {
	if ($ARGV[0]) 	{ $::MUDX	= $::MUDH{$ARGV[0]} } 
	else 			{ $::MUDX	= $::MUDH{0} };
	
	$::MUD		= $::MUDX;		# save original string for report and symref
	$::MUDX		=~ s{::}{/}g;	# replace pathpart separators !UNIX ONLY SORRY!
	$::MUDX		.= q{.pm};		# append standard perl module file extension
	
	no strict 'refs';
	note( qq[Testing $::MUD ]);#${"$::MUD\::VERSION"}] );
	use strict 'refs';
}

#~ # Simulate use().
#~ BEGIN {
#~ 	require $::MUDX;			
#~ #	import  $::MUDX	();			# empty list supresses import or supply a list
#~ }

# NOTE (Camel): 
# use() eq BEGIN { require MODULE; import MODULE LIST; }

#----------------------------------------------------------------------------#

# Set up test box.
my $name			= $0;
my $self			= {};

$self->{-capture}{-stdout}	= IO::Capture::Stdout::Extended->new();
$self->{-capture}{-stderr}	= IO::Capture::Stderr::Extended->new();


# Execute code within test box
$self->{-capture}{-stdout}->start();		# STDOUT captured
$self->{-capture}{-stderr}->start();		# STDERR captured
{
	try {
		my $outfh	= *STDERR;
		say $outfh '#-1';
		# Simulate use().
		BEGIN {
			require $::MUDX;			
			no strict 'refs';
			&{"$::MUD\::import"}('foo');	# empty list supresses import or supply a list
			use strict 'refs';
		}
		say $outfh '#-2';
		### foobar
		say $outfh '#-3';
		no Smart::Comments::Any;
		no Smart::Comments;
		say $outfh '#-4';
		### bazfiend
		say $outfh '#-5';
	}
	catch {
		$self->{-got}{-evalerr}	= $_;
	};
	
}
$self->{-capture}{-stdout}->stop();			# not captured
$self->{-capture}{-stderr}->stop();			# not captured

# End of test box.
#----------------------------------------------------------------------------#

# Test for and report any eval error
$subname		= join q{}, $name, q{-evalerr};
$test_counter++;
ok( !$self->{-got}{-evalerr}, $subname );
diag("Eval error: $self->{-got}{-evalerr}") if $self->{-got}{-evalerr};

# Define subtester
sub do_is_string	{					# exact string Test::More::is()
	my $iswhat		= shift;			# what to test?
	$got			= $self->{-got}{$iswhat}{-string}
					= join q{}, $self->{-capture}{$iswhat}->read;
	$expected		= $self->{-want}{$iswhat}{-string};
	$subname		= join q{}, $name, $iswhat, q{-string};
	$test_counter++;
	is( $got, $expected, $subname );
};
	
# Do subtests
my $iswhat			;

$iswhat			= q{-stdout};
$self->{-want}{$iswhat}{-string}	
	= q{};			# exactly empty, thank you
do_is_string($iswhat);

$iswhat			= q{-stderr};
$self->{-want}{$iswhat}{-string}	
	= q{#-1}		. qq{\n}
										# use
	. q{#-2}		. qq{\n}
										# foobar
	. qq{\n}. qq{\n}
	. q{### foobar}	. qq{\n}
	. qq{\n}
	. q{#-3}		. qq{\n}
										# no
	. q{#-4}		. qq{\n}
										# foobar
	. q{#-5}		. qq{\n}
	
	;
do_is_string($iswhat);

#	# character-by-character testing
#	my $obtained	= $self->{-got}{$iswhat}{-string};
#	my $want		= $self->{-want}{$iswhat}{-string};
#	my $length		= length $want;
#	foreach my $i (0..$length) {
#		$got			= substr $obtained, $i, 1;
#		$expected		= substr $want,     $i, 1;
#		$subname		= join q{}, $name, $iswhat, , q{-}, $i;
#		$test_counter++;
#		is( $got, $expected, $subname );
#	};


done_testing($test_counter);



