package BANG;

use strict;
use warnings;
use feature 'say';

use Filter::Simple;

FILTER {
	say STDERR '---| BANG: line ', __LINE__;
	say STDERR "---| Source to be filtered:\n", $_, '|--- END SOURCE CODE';
	
	s/#\s*BANG\s+BANG/die 'BANG' if \$BANG;/g;
}
#~ ;
#~ qr/^#$/m;
#~ { terminator	=> '#' };
#~ { terminator	=> qr/#/ };
{ terminator	=> qr/^#$/ };

sub import {
	say STDERR '---| BANG: import(): ';
	say STDERR '---| BANG: line ', __LINE__;
	
};

1;
