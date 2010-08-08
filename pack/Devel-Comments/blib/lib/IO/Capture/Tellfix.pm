package IO::Capture::Tellfix;

use strict;
#use warnings;
use feature 'say';
use IO::Capture::Tie_STDx;

# test to see if the lack of TELL has been fixed
my $messages	;
my $good_tell	;
my $evalerr		;
tie  *STDOUT, "IO::Capture::Tie_STDx";
@$messages 		= <STDOUT>;

print 'foo';	# should move the tell up to 3

$good_tell	= eval{
	tell(*STDOUT)
};
$evalerr		= $@;
untie *STDOUT;

#print 'good_tell: >', $good_tell, '<, evalerr: >', $evalerr, '<', "\n";

if ( $good_tell != 3 or $evalerr ) {		# didn't work, must fix
	
	*IO::Capture::Tie_STDx::TELL = sub { 
		my $self = shift;
		return length ( join q{}, @$self );
	};
};

1;
__END__

=head1 Usage

	BEGIN { use_ok('IO::Capture::Stderr') };
	use lib qw{ lib ../lib ../../lib };
	BEGIN { use_ok('IO::Capture::Tellfix') };

=end
