#!/run/bin/perl
#       prime.pl
#       = Copyright 2010 Xiong Changnian <xiong@xuefang.com> =
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

use lib qw{
	lib/
	../lib/
	../../lib/
};

#use Smart::Comments::Any 'STDOUT', '###', '####';
use Smart::Comments::Any '###', '####';
#use Smart::Comments '###', '####';

### This is a comment in prime.pl
### another
### 
### line1
### line2
###
### line3

use Acme::Prime;

Acme::Prime::report( $ARGV[0] );

exit(0);
__DATA__

Output: 


__END__
