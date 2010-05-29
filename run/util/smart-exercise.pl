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

#use Smart::Comments;	# Enable special comments for debugging and reporting
use Smart::Comments::Any;	

my $data_structure = {
    a => [ 1, 2, 3 ],
#    b => [
#        { X => 1, Y => 2 },
#        {
#            X => [ 1, 2, 3 ],
#            Y => [ 4, 5, 6 ],
#            Z => [ 7, 8, 9 ]
#        },
#    ],
};

### This is a comment.
### $data_structure


__END__

