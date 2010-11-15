#!/run/bin/perl
#       hump.pl
#       =  Copyright 2010 Xiong Changnian <xiong@sf-id.com>  =
#       = Free Software = Artistic License 2.0 = NO WARRANTY =

use strict;
use warnings;
our $VERSION = '0.000_004';

use lib qw { ../lib };
use Devel::Hump;

use Smart::Comments		# Enable special comments for debugging and reporting
	q{###}, 			# 3 or more active
#	q{####},			# 4 or more active
;

# bash convention exit status: 0 = success, 1 = failure
my $exit			= 0;			# failure until success

$exit = Devel::Hump::main();		# run

$exit = ( $exit +1 ) %2;			# 1 for 0, 0 for 1
### $exit
exit($exit);
__END__

=head1 NAME

hump - Perl project manager and command line valet

=head1 VERSION

This documentation refers to hump version 0.0.4

=head1 DOCUMENTATION

Main documentation is stored in L<Devel::Hump::Pod>.

=head1 AUTHOR

Xiong Changnian <xiong@sf-id.com>

=head1 LICENSE

Copyright 2010 Xiong Changnian

Free Software = Artistic License 2.0 = NO WARRANTY
