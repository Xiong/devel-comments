package IO::Capture::Sayfix;

use strict;
use warnings;
use feature 'say';
use IO::Capture::Stdout;

my $capture 		= IO::Capture::Stdout->new();

$capture->start();
say 1;
$capture->stop();

if ( $capture->read() ne "1\n" ){		# bug found, work around
	no warnings 'redefine'; 
		
	*IO::Capture::Tie_STDx::PRINT = sub { 
		my $self = shift;
		push @$self, 
			join ( defined($,) ? $, : '', @_ ) 
			. ( defined($\) ? $\ : '' )
		;
		
	use warnings;
	};
};


1;
__END__

=head1 Usage

	BEGIN { use_ok('IO::Capture::Stderr') };
	use lib qw{ lib ../lib ../../lib };
	BEGIN { use_ok('IO::Capture::Sayfix') };

=end
