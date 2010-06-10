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

use Smart::Comments '###';	# Enable special comments for debugging
#use Smart::Comments::Any;	

my $data_structure 	= {
    a => [ 1, 2, 3 ],
};
my $scalar			= 42;

my %very			;
my $index			= 18;
$very{long}{thing}[$index] = 'main';
#### $very{long}{thing}[18]

#	no strict 'refs';		# disable complaint about symbolic reference
#	no warnings 'once';		# disable complaint about var only used once
#	${ *{"${caller_ns}\::smart-comments-outfh"} }	= 'toejam';
#	### ${ *{"${caller_ns}\::smart-comments-outfh"} }
	
#	use warnings;
#	use strict;

######## INTERNAL ROUTINE ########
#
#	_do_();		# short
#		
# comment
#	
sub _do_ {
	
	
	
};
######## /_do_ ########

####### 7
###### 6
##### 5
#### 4
### 3
## 2
# 1

### This is a comment.
### <now> I'm happy.
#### $data_structure
#### $scalar

#my $max		= 2**4;
my $max		= 2**1;

#for (0..$max) {			### for1...			done
#	sleep(1);
#};

#for (0..$max) {			### for2 |===[%]    |
#	sleep(1);
#};

#for (0..$max) {			### outer |===[%]    |
#	for (0..$max) {			### inner |===[%]    |
#		sleep(1);
#	};
#};

#use Acme::Teddy;
#for (0..$max) {			### outer |===[%]    |
#	Acme::Teddy::exercise_loop();
#};


### This comment is smart.

no Smart::Comments;

### This comment is dumb.

use Smart::Comments;

### This comment is also smart.

no Smart::Comments;

### This comment is also dumb.

use Acme::Teddy;
Acme::Teddy::just_hello();

### This comment is still dumb.

use Smart::Comments;

### This comment is still smart.


__END__

