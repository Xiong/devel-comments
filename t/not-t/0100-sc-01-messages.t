#!/run/bin/perl

use strict;
use warnings;
use feature 'say';
use Carp;

use lib qw{
	      lib
	   ../lib
	../../lib
	      run/t
	   ../run/t
	../../run/t
};

use Test::More 0.94;
use Test::Deep;
use Try::Tiny;

use IO::Capture::Stdout::Extended;
use IO::Capture::Stderr::Extended;
use IO::Capture::Sayfix;
use IO::Capture::Tellfix;











#BEGIN {
#	use_ok( q{Smart::Comments::Any '###'} );
#}

#diag( "Testing Smart::Comments::Any $Smart::Comments::Any::VERSION" );
