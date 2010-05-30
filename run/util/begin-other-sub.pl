#!/run/bin/perl
#       begin-other-sub.pl
#       =  Copyright 2010 Xiong Changnian <xiong@sf-id.com>  =
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

BEGIN 
{
	say q{I'm doing stuff in a BEGIN block.};
	
	_do_other();
	
	say q{I'm done with the BEGIN block.};
	
}


sub _do_other {
	say q{I'm _do_other!};	
};

__DATA__

Output: 


__END__
