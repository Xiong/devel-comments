#!/run/bin/perl
#       bug57.pl
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
	my $outfh			= *STDERR;		# default
	my $out_filename	= "$0.log";		# default
	
	$out_filename		= '/home/xiong/projects/smartlog/file/href.log';

	open $outfh, '>', $out_filename
		or die "bug57.pl: " 
			,  "Can't open $out_filename to write."
			, $!
			;
	say $outfh '... Just after opening $outfh ...';
	say $outfh '$outfh: ', $outfh;	
	
	
	

__DATA__

Output: 


__END__
