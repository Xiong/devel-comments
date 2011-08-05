#!/run/bin/perl

use lib qw{
          lib
       ../lib
    ../../lib
};

use Devel::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $scalar = 728;
my @array = (1..3);
my %hash  = ('a'..'d');


close *STDERR;
$STDERR = q{};
open *STDERR, '>', \$STDERR;

### scalar728: $scalar

my $expected = <<"END_MESSAGES";

#\## scalar728: 728
END_MESSAGES

is $STDERR, $expected      => 'Labelled expressions work';
