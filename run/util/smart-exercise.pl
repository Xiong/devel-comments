#!/run/bin/perl

use strict;
use warnings;
use feature 'say';

use lib qw{
          lib
       ../lib
    ../../lib
          run/t
       ../run/t
    ../../run/t
};

#~ use Smart::Comments '###';   # Enable special comments for debugging
#~ use Smart::Comments ;        # Enable special comments for debugging
#~ use Smart::Comments::Any;    
#~ use Smart::Comments::Any *STDOUT;    

#~ BEGIN { $::out_filename      = '/home/xiong/projects/smartlog/file/test.log' }
#~ BEGIN{           # set to a temporary hard disk file
#~  open my $outfh, '>', $::out_filename
#~      or die 'Failed to open temporary test file for writing. ', $!;
#~  $::outfh    = $outfh;
#~ }
#~ use Smart::Comments::Any '###', $::outfh;    

#~ BEGIN { $::out_filename     = '/home/xiong/projects/smartlog/file/test.log' }
#~ use Smart::Comments::Any ({ -file => $::out_filename });


### One
### Two

#~ my @caller = Smart::Comments::Any::_get_caller();
#~ ### @caller

my $data_structure  = {
    a => [ 1, 2, 3 ],
};
my $scalar          = 42;   ### $scalar

my %very            ;
my $index           = 18;
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

#my $max        = 2**4;
my $max     = 2**16;

        my $outfh   = *STDERR;
        use Smart::Comments;
#~         use Smart::Comments::Any;
        say $outfh '#-2';
        my $count = 0;
        while ($count < 99) {    ### Simple while loop:===|   done
            $count++;
            for (0..$max) {         
                sleep(0);               ### I'm not really sleeping.
            };
        }
        say $outfh '#-3';
        no Smart::Comments;
#~         no Smart::Comments::Any;


#~ for (0..$max) {         
#~     sleep(0);               ### I'm not really sleeping.
#~ };

#~ for (0..$max) {            ### for1...         done
#~    sleep(1);
#~ };

#~ for (0..$max) {          ### for2 |===[%]    |
#~  sleep(1);
#~ };

#for (0..$max) {            ### outer |===[%]    |
#   for (0..$max) {         ### inner |===[%]    |
#       sleep(1);
#   };
#};

#use Acme::Teddy;
#for (0..$max) {            ### outer |===[%]    |
#   Acme::Teddy::exercise_loop();
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

