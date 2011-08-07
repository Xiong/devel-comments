#!/run/bin/perl
#       defined-sub-foo.pl
#       = Copyright 2011 Xiong Changnian <xiong@cpan.org> =
#       = Free Software = Artistic License 2.0 = NO WARRANTY =

use strict;
use warnings;

use Readonly;
use feature qw(switch say state);
use Perl6::Junction qw( all any none one );
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use File::Spec;
use File::Spec::Functions qw(
    catdir
    catfile
    catpath
    splitpath
    curdir
    rootdir
    updir
    canonpath
);
use Cwd;
use Smart::Comments '###', '####';

#

sub foo { return; };

my $ding = defined foo;

say $ding ? 'defined' : 'undef';

__DATA__

Output: 


__END__
