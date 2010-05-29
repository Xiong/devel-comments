#!/run/bin/perl

use strict;
use warnings;

use lib qw{
	      lib
	   ../lib
	../../lib
	      run/t
	   ../run/t
	../../run/t
};

use Smart::Comments;	# Enable special comments for debugging and reporting
#use Smart::Comments::Any;	

my $data_structure = {
    a => [ 1, 2, 3 ],
};

### This is a comment.
### <now>
### $data_structure

my $max		= 2**3;
my $idle	;

for (0..$max) {			### for...			done
	sleep(1);
};

__END__

