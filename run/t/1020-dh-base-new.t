#!/run/bin/perl
#
#	Testing: Devel::Hump::Base::new(), init()

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

use Smart::Comments '###';
use Readonly;

# Test::More 0.94 or later required for subtest().
use Test::More 0.94;			# test plan declared after the fact, at end
my $test_counter		= 0;

use Test::Hump;			# my automatic subtester
my $test_obj			= Test::Hump->new();		
#### $test_obj

# load module under test
use Devel::Hump::Base;
Readonly my $MUD	=> Devel::Hump::Base;

# $MUD is an abstract class, so to test it, we need to subclass it
package Acme::Hump;					# joke module
use parent Devel::Hump::Base;

sub make_pee {
	my $code_string	= shift;
	my $pee			= sub {				# this will do anything it's asked
		my @parms		= @_;
#		print "pee: parms: @_\n";
#		my $lenparms	= scalar @parms;
#		print "pee: lenparms: $lenparms\n";
#		print "pee: eval: qq{ $code_string( @parms ) }\n";
		eval qq{ $code_string( \@parms ) };
	};
	return $pee;
};

sub acme_pee {
	my $code_string	= shift;
	return make_pee( $code_string );
};

package main;

my $acme		= q{Acme::Hump};
my $pee_new		= Acme::Hump::make_pee( qq{return $acme->new} );

# declare test inputs and expected outputs
#
#	(normal) -return is perl convention; hump.pl inverts when it exits
#
# %want structure contents
#
#	KEY					MEANING							DEFAULT
#
#	-basename			1st part of subtest name		undef
#	-name				2nd part of subtest name		undef
#
#	-skip				don't test if 1					undef
#
#	-inparms			parms passed to sub under test	empty list ()
#	-argv				@ARGV set before call			untouched
#	-env				%ENV  set before call			untouched
#
#	-return				return from sub under test		1
#	
#	-stdout				STDOUT							don't test
#		-string				exact string eq
#		-regex				regex against
#		-matches			number of regex matches		1
#		-lines				number of lines captured
#	
#	-stderr				STDERR							don't test
#		
#	-evalerr			eval error $@					0 (no error)
#	
my @test_data		= (
# set sub to test
	{
		-coderef	=> $pee_new,
		-basename	=> 'DH::Base::new',			# make new object
		-name		=> 'set -coderef',
		-stdout		=> 0,							# expect exactly nothing
		-stderr		=> 0,							# expect exactly nothing

		-skip		=> 1,					# don't test, just set values
	},
	
	# new empty object
	{
		-name		=> 'empty',	
		-inparms	=> [ 						],	# no args
		-return		=> bless( {
						}, $acme ),
#		-dump 		=> 1,
	},
	
	# new object with good stuff in it
	{
		-name		=> 'goodinit',	
		-inparms	=> [ 'foo', 1, 'bar', 2,	],	# even number of args
		-return		=> bless( {
							foo => 1, bar => 2,
						}, $acme ),
#		-dump 		=> 1,
	},
	

# # # ABORT TESTING # # # #	#
	{						#
		-last		=> 1	#
	},						#
# # # # # # # # # # # # # #	#
	
	
);
######## /test_data ########

# do testing
TEST:
foreach my $want (@test_data) {
	last TEST if $want->{-last};
	
	$test_counter++;		# all subtests run by check() count as one test
	$test_obj->check( $want );
	
	if ( $want->{-dump} ) {
		### $test_obj
	};
	
};

done_testing($test_counter);
