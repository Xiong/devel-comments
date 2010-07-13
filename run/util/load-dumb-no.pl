#!/run/bin/perl

use lib qw{
	      lib
	   ../lib
	../../lib
};
$DB::single=1;
# NOT YET.
use Smart::Comments::Any;
#~ use Smart::Comments;
# RIGHT.

### Right.

#~ STOP
no Smart::Comments::Any;
no Smart::Comments;
# WRONG!

### Wrong.
