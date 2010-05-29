package Acme::Prime;

use warnings;
use strict;
use Carp;

our $VERSION = '1.001_001';

#use Smart::Comments		# Enable special comments for debugging and reporting
#	q{###}, 			# 3 or more active
##	q{####},			# 4 or more active
#;

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

=head1 NAME

Acme::Prime - Exotic reports on prime numbers


=head1 VERSION

This document describes Acme::Prime version 1.1.1


=head1 SYNOPSIS

    use Acme::Prime;

=head1 SYNOPSIS

	use Acme::Prime;
    report( $param );					# report on $param
    
	use Acme::Prime qw{ :internal };
    $bool = _is_prime( $integer );		# true if $integer is prime
  

=head1 DESCRIPTION

Calculating prime numbers is a basic exercise of the programming student. 
This is my contribution. 

=head1 SUBROUTINES/METHODS

This module has one routine, C<report()>, which is exported by default. 
This routine takes one parameter, sanitizes it, checks to see if it is prime, 
and reports the result to STDOUT. 

The internal function _is_prime can be exported on demand but does no 
checking of its argument. 


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Usage: ./prime.pl 42
# Parameter must be an integer greater than 1. >>

The usage note is appended to all error messages. It is assumed that a script 
was used to call this module and that a parameter was (or should have been) 
passed in from the command line. The example parameter, B<42>, 
is, in this case, not the answer but the question. 

A number is mathematically prime if it has no divisors except itself and one. 
A number B<Q> has a divisor B<P> if: 
a) Both B<Q> and B<P> are integers (e.g., 42, not 22/7, not PI); and
b) B<Q> divided by B<P> has no remainder (i.e., C< Q % P == 0 >).
 
The special case of B<one> is defined to be neither prime nor composite. 
Mathematical primeness is not defined for zero or for negative integers.
Mathematical primeness is not defined for non-integers.

=item C<< No parameter given. >>

C<report()> was called without a parameter to examine. If a script 
was used to invoke this module, then perhaps no parameter was given on 
the command line. 

=item C<< $param is not greater than one. >>

Mathematical primeness is not defined for zero or for negative integers. 
The special case of B<one> is defined to be neither prime nor composite. 
C<report()> was called with an unacceptable parameter. 

=item C<< $param is not an integer. >>

Mathematical primeness is not defined for non-integers. 
C<report()> was called with an unacceptable parameter. 

=item C<< Another error message here >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Acme::Prime requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

use autodie;			# Builtins throw exceptions on failure

use version 0.77; 

require 5.008_008;		

use Smart::Comments		# Enable special comments for debugging and reporting

use Perl6::Say;

use Perl6::Export::Attrs;		# Export subroutines from modules

=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

This module may be intentionally buggy. There is no point in reporting bugs. 

=head1 AUTHOR

Xiong Changnian  C<< <xiong@xuefang.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Xiong Changnian C<< <xiong@xuefang.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
