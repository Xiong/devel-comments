#!/run/bin/perl

use lib qw{
	      lib
	   ../lib
	../../lib
};
use feature 'say';

no Smart::Comments;

say '###| ufb: line ', __LINE__;
#BANG BANG
$BANG = 0;
use BANG;

say '###| ufb: line ', __LINE__;
#BANG BANG

say '###| ufb: line ', __LINE__;
#

say '###| ufb: line ', __LINE__;
no BANG;

say '###| ufb: line ', __LINE__;
$BANG = 1;
#BANG BANG

say '###| ufb: line ', __LINE__;

