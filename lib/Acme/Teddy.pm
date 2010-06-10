package Acme::Teddy;

use warnings;
use strict;
use Carp;

our $VERSION = '1.001_001';

use Smart::Comments		# Enable special comments for debugging and reporting
	q{###}, 			# 3 or more active
#	q{####},			# 4 or more active
;

use feature qw(switch say state);

#use Frobnitz::Blowhard;			# attempt to use nonexistant module

use Perl6::Export::Attrs;		# Export subroutines from modules

use Readonly;			# Creates read-only scalars, arrays, and hashes
#	Readonly $foo	=> 'bar';

#use Memoize				# Subroutine return value caching
#	memoize('slow_function');		# literal, sub name, no &

#use List::MoreUtils		# Additional list-processing utilities
#	qw(any all none notall true false firstidx first_index
#		lastidx last_index insert_after insert_after_string
#		apply after after_incl before before_incl indexes
#		firstval first_value lastval last_value each_array
#		each_arrayref pairwise natatime mesh zip uniq minmax);

my $usage		= "\nUsage: ./prime.pl 42 \n"
				. "# Parameter must be an integer greater than 1.\n";

Readonly my @easy_primes	=> ( 2, 3, 5, 7 );	
my @primes					=    @easy_primes;	


my $max		= 2**1;

sub exercise_loop {
	for (0..$max) {			### Acme::Teddy::for2 |===[%]    |
		sleep(1);
	};
};

sub just_hello {
	### Hello!
	return 1;
};






######## EXPORTED ROUTINE ########
#
#	report( $param );			# report on $param
#	
# This is just a wrapper for the internal function _is_prime. 
# It sanitizes its input, checks to see if it is prime, 
#  and reports the outcome. 
#	
sub report :Export( :DEFAULT ) {
#sub report {
	my $param			= shift;

	#### @primes
	
	# first a blank line; i just prefer it this way
	print "\n";
	
	# sanity checks
	croak "No parameter given. $usage" if ( not defined $param );
	croak "$param is not greater than one. $usage" if ( $param <= 1 );
	croak "$param is not an integer. $usage" if ( not $param == int $param );
	
	if ( _is_prime( $param ) ) {
		say "$param is prime!";
		return 1;
	} 
	else {
		say "$param is not prime.";	
		return 0;	
	};
	
	#### @primes
	
};
######## ########

######## INTERNAL FUNCTION ########
#
#	$bool = _is_prime( $integer );		# true if $integer is prime
#		
# comment
#	
sub _is_prime :Export( :internal ) {
#sub _is_prime {
	my $integer_in		= shift;
	
#	# test the easy cases quickly, first
#	return 1 if $integer_in == 2;
#	return 1 if $integer_in == 3;
#	return 1 if $integer_in == 5;
#	return 0 if not $integer_in % 2;
#	return 0 if not $integer_in % 3;
#	return 0 if not $integer_in % 5;
	
	# set a $ceiling (only need to test up to square root)
	my $ceiling			= sqrt $integer_in;
	
	##### @primes
	TEST_ARRAY:
	foreach my $prime (@primes) {
		last TEST_ARRAY if $prime > $ceiling;
		return 1 if $integer_in == $prime;
		return 0 if not $integer_in % $prime;	
	};
	
	# we may have run out of @primes before hitting $ceiling
	my $possible_divisor	= $primes[-1];		# last, largest prime we have
	while ($possible_divisor <= $ceiling) {
		$possible_divisor++;
		if ( _is_prime( $possible_divisor ) ) {
			push @primes, $possible_divisor;
			return 0 if not $integer_in % $possible_divisor;
		};
		
	};
	
	# we hit the ceiling for sure, without finding a divisor
	return 1;
};
######## ########



#############################
######## END MODULE #########
1;
__END__

