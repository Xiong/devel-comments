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

sub _do_one {
	say q{I'm _do_one!};	
};

sub _do_last;	# FORWARD

BEGIN 
{
	say q{I'm doing stuff in a BEGIN block.};
	
	_do_one();
#~ 	_do_other();
	_do_last();
	
	say q{I'm done with the BEGIN block.};
	
}


sub _do_other {
	say q{I'm _do_other!};	
};

sub _do_last {
	say q{I'm _do_last!};	
};

__DATA__

The moral of this story is that if you call a sub from within a BEGIN block, 
	you'd better both declare *and* define it first. 

Output: 

I'm doing stuff in a BEGIN block.
I'm _do_one!
Undefined subroutine &main::_do_last called at util/begin-other-sub.pl line 41.
BEGIN failed--compilation aborted at util/begin-other-sub.pl line 45.


__END__
