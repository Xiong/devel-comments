#!/run/bin/perl

use lib qw{
          lib
       ../lib
    ../../lib
};

use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $scalar  = 728;
my $empty   = '';
my $zero    = 0;
my @array   = (1..3);
my %hash    = ('a'..'d');


close *STDERR;
$STDERR = q{};
open *STDERR, '>', \$STDERR;

### scalar728: $scalar
### empty: $empty
### undef: $undef
### zero: $zero
sub foo { return; }
### foo: foo()

my $expected = <<"END_MESSAGES";

#\## scalar728: 728
#\## empty: ''
#\## undef: undef
#\## zero: 0

#\## foo: undef
END_MESSAGES

is $STDERR, $expected      => 'Labelled expressions work';
