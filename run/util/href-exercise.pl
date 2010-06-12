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

#~ use Smart::Comments '###';	# Enable special comments for debugging
#~ use Smart::Comments ;		# Enable special comments for debugging
#~ use Smart::Comments::Hrefbug;	
#~ use Smart::Comments::Hrefbug *STDOUT;	

#~ BEGIN { $::out_filename		= '/home/xiong/projects/smartlog/file/test.log' }
#~ BEGIN{ 			# set to a temporary hard disk file
#~ 	open my $outfh, '>', $::out_filename
#~ 		or die 'Failed to open temporary test file for writing. ', $!;
#~ 	$::outfh	= $outfh;
#~ }
#~ use Smart::Comments::Hrefbug '###', $::outfh;	

BEGIN { $::out_filename		= '/home/xiong/projects/smartlog/file/href.log' }
use Smart::Comments::Hrefbug ({ -file => $::out_filename });
# jest be
no Smart::Comments::Hrefbug;

__END__

