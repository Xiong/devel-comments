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

### One
### Two


my $data_structure 	= {
    a => [ 1, 2, 3 ],
};
my $scalar			= 42;	### $scalar

my %very			;
my $index			= 18;
#~ $very{long}{thing}[$index] = 'ratass';
$very{long}{thing}[$index] = 99;
#~ ### verylongthing : $very{long}{thing}[18]
#~ ### $very{long}{thing}[18]
#~ ### '' . $very{long}{thing}[18]
#~ ### 0 + $very{long}{thing}[18]
#~ ### 2 + 3

#~ ### foo
#~ ### 
#~ ### foobar
#~ 
#~ ###
#~ 
#~ ### rebar
#~ ###
#~ 
#~ ### yootoob
#~ 
#~ ###
#~ ### yoomomma


####### 7
###### 6
##### 5
#### 4
### 3
## 2
# 1

#~ ### This is a comment.
#~ ### <now> I'm happy.
#~ #### $data_structure
#~ #### $scalar

#my $max		= 2**4;
my $max		= 2**1;

for (0..$max) {			
	sleep(0);				### I'm not really sleeping.
};

#for (0..$max) {			### for1...			done
#	sleep(1);
#};

#~ for (0..$max) {			### for2 |===[%]    |
#~ 	sleep(1);
#~ };

#for (0..$max) {			### outer |===[%]    |
#	for (0..$max) {			### inner |===[%]    |
#		sleep(1);
#	};
#};

#use Acme::Teddy;
#for (0..$max) {			### outer |===[%]    |
#	Acme::Teddy::exercise_loop();
#};


#~ ### This comment is smart.
#~ 
#~ no Smart::Comments;
#~ 
#~ ### This comment is dumb.
#~ 
#~ use Smart::Comments;
#~ 
#~ ### This comment is also smart.
#~ 
#~ no Smart::Comments;
#~ 
#~ ### This comment is also dumb.
#~ 
#~ use Acme::Teddy;
#~ Acme::Teddy::just_hello();
#~ 
#~ ### This comment is still dumb.
#~ 
#~ use Smart::Comments;
#~ 
#~ ### This comment is still smart.


__END__
