package Smart::Comments::Any;

######## use section ########
use 5.008;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.4');

# original S::C (originally used here)
use Carp;
use List::Util qw(sum);
use Filter::Simple;

# collected S::C (originally distributed in code)
use Text::Balanced              # Extract delimited text sequences from strings
    qw( extract_variable extract_multiple );
    
use Data::Dumper 'Dumper';

# debug only

$DB::single=1;
use feature 'say';              # disable in production; debug only
#~ use Smart::Comments '###';       # playing with fire;     debug only
#~ use Smart::Comments '#####';     # playing with fire;     debug only

######## / use ########

#~ say '---| Smart::Comments::Any at line ', __LINE__;

######## pseudo-constants section ########

# time and space constants
my $maxwidth            = 69;   # Maximum width of display
my $showwidth           = 35;   # How wide to make the indicator
my $showstarttime       = 6;    # How long before showing time-remaining estimate
my $showmaxtime         = 10;   # Don't start estimate if less than this to go
my $whilerate           = 30;   # Controls the rate at which while indicator grows
my $minfillwidth        = 5;    # Fill area must be at least this wide
my $average_over        = 5;    # Number of time-remaining estimates to average
my $minfillreps         = 2;    # Minimum size of a fill and fill cap indicator
my $forupdatequantum    = 0.01; # Only update every 1% of elapsed distance

# Synonyms for asserts and requirements...
my $require             = qr/require|ensure|assert|insist/;
my $check               = qr/check|verify|confirm/;

# Horizontal whitespace...
my $hws                 = qr/[^\S\n]/;

# Optional colon...
my $optcolon            = qr/$hws*;?/;

# Automagic debugging as well...    (perl -d debugger)
# Someone has to tell me why *two* assignments here (??)
my $DBX                 = '$DB::single = $DB::single = 1;';

# Recognize progress bars...
my @progress_pats = (
   #    left     extending                 end marker of bar      right
   #    anchor   bar ("fill")               |    gap after bar    anchor
   #    ======   =======================   === =================  ====
   qr{^(\s*.*?) (\[\]\[\])                 ()    \s*               (\S?.*)}x,
   qr{^(\s*.*?) (\(\)\(\))                 ()    \s*               (\S?.*)}x,
   qr{^(\s*.*?) (\{\}\{\})                 ()    \s*               (\S?.*)}x,
   qr{^(\s*.*?) (\<\>\<\>)                 ()    \s*               (\S?.*)}x,
   qr{^(\s*.*?) (?>(\S)\2{$minfillreps,})  (\S+) \s{$minfillreps,} (\S.*)}x,
   qr{^(\s*.*?) (?>(\S)\2{$minfillreps,})  ()    \s{$minfillreps,} (\S.*)}x,
   qr{^(\s*.*?) (?>(\S)\2{$minfillreps,})  (\S*)                   (?=\s*$)}x,
   qr{^(\s*.*?) ()                         ()                      () \s*$ }x,
);

# for ::Any
my $join_up             = qq{ };    # used to join replacement code strings

######## / pseudo-constants ########

######## pseudo-global variables section ########

## original S::C stuff

# Unique ID assigned to each loop; incremented when assigned
#   See: for_progress, while_progress
my $ID                  = 0;

#   See: for_progress
my %started             ;

#   See: _moving_average
my %moving              ;

# State information for various progress bars...
#   See: for_progress, while_progress
my (%count, %max, %prev_elapsed, %prev_fraction, %showing);

#   See: while_progress
my $prev_length = -1;


## ::Any stuff

# Unique ID assigned to each use of S::C::Any
#   (strictly, per-import)
#
# Note that since source filtering is applied from use line down to EOF 
#   or (perhaps) no S::C::Any, a given filter application is neither
#   strictly per-package nor per-file.
#
# See _get_new_caller_id()
#
my $new_caller_id   = 1;            # Will be assigned to "this" use

# Store per-use (per-fileish) state info 
#   for access by external routines called by replacement code
my %state_of            ;
#   SomeCaller      => {            # $caller_id is primary key
#       -outfh                      # desired output filehandle
#       -tell           => {        # stored tell() of...
#           -outfh                  # ... $outfh
#           -stdout                 # ... *STDOUT
#       },
#       -caller         => {        # stored caller()...
#           -name                   # ...[0] (= 'SomeCaller')
#           -file                   # ...[1]
#           -line                   # ...[2]
#       },
#   },
#   AnotherCaller...

######## / pseudo-global variables ########

#----------------------------------------------------------------------------#


######## INTERNAL ROUTINE ########
#
#   my $caller_id   = _get_new_caller_id();     # unique per-use
#       
# Purpose   : Assign a unique ID to each filtering operation
# Parms     : none
# Reads     : $new_caller_id
# Returns   : $caller_id        scalar integer
# Writes    : $new_caller_id
# Throws    : never
# See also  : %state_of
# 
# Called once per use line by _prefilter(). Thereafter, $caller_id is either 
#   passed along or interpolated and inserted into client code. 
# Strictly, $caller_id is unique neither to calling package nor file;
#   it is assigned whenever Filter::Simple::FILTER calls _prefilter(), 
#   which should happen once per use. So, its scope within client code is: 
#       from: use Smart::Comments::Any
#         to:  no Smart::Comments::Any
#   ...possibly crossing package boundaries.
# 
sub _get_new_caller_id {
    return $new_caller_id++;
};
######## /_get_new_caller_id ########


#= ######## INTERNAL ROUTINE ########
#= #
#= #    _set_filter_caller();       # set %filter_caller to "outside" caller
#= #        
#= # Purpose  : Set @filter_caller consistently
#= # Parms    : none
#= # Reads    : caller()
#= # Returns  : 1
#= # Writes   : %filter_caller
#= # Throws   : never
#= # See also : _prefilter()
#= # 
#= # Because builtin caller() sees the stack starting at its previous call, 
#= #    _set_filter_caller() should only be called once, 
#= #    from _prefilter, and not again. 
#= # Note that old S::C code hits caller() directly, 
#= #    which may be best when its call is from within replacement code. (???)
#= # 
#= sub _set_filter_caller {
#=  # frame
#=  #   0       _prefilter
#=  #   1       FILTER
#=  #   2       Filter::Simple
#=  #   3       actual use-line caller
#=  my $frame                       = 3;    
#=  my @caller_info                         = caller($frame);
#=  @filter_caller{ -name, -file, -line }   = @caller_info;
#=  
#=  for $frame (0..4) {
#=      @caller_info        = caller $frame;
#=      no warnings;
#=      say "($frame): ", join "\t\n", 
#=          $caller_info[0], $caller_info[1], $caller_info[2], ;
#=      use warnings;
#=  };
#=  
#=  return 1;
#= };
#= ######## /_set_filter_caller ########

######## INTERNAL ROUTINE ########
#
#   my $outfh       = _get_outfh($caller_id);   # retrieve from %state_of
#       
# Purpose  : Retrieve output filehandle associated with some caller
# Parms    : $caller_id
# Reads    : %state_of
# Returns  : stored filehandle for all smart output
# Writes   : none
# Throws   : dies if no arg passed
# See also : _put_outfh(), _get_new_caller_id()
# 
sub _get_outfh {
    my $caller_id       = shift 
        or die   q{Smart::Comments::Any: }  # called with no arg
            ,    q{Internal error: }
            ,    q{_get_outfh called with no or false arg. }
            ,    $!
            ;
    defined $state_of{$caller_id}
        or die   q{Smart::Comments::Any: }  # called with bad id
            ,    q{Internal error: }
            ,   qq{$caller_id not defined in }
            ,    q{%state_of. }
            ,    $!
            ;
    
    defined $state_of{$caller_id}{-outfh}
        or die   q{Smart::Comments::Any: }  # no $outfh found
            ,    q{Internal error: }
            ,    q{No output filehandle found in %state_of }
            ,   qq{for $caller_id. }
            ,    $!
            ;
    
    return $state_of{$caller_id}{-outfh};
    
};
######## /_do_ ########

######## INTERNAL ROUTINE ########
#
#   _init_state({               # initialize $state_of this caller
#       -outfh          => $outfh,
#       -caller_id      => $caller_id, 
#   }); 
#       
# Purpose   : Initialize state; store $outfh and avoid warnings later
# Parms     : hashref
#           :   -caller_id      $caller_id
#           :   -outfh          $outfh
# Reads     : none
# Returns   : 1
# Writes    : %state_of
# Throws    : never
# See also  : _prefilter(), _put_state()
# 
# Call once per use from _prefilter() only. 
# This is important, lest we get confused about which stack frame is wanted. 
# 
sub _init_state {
    my $href        = shift;
    
    my $caller_id       = $href->{-caller_id}
        or die   q{Smart::Comments::Any: }  # called with no -caller_id
            ,    q{Internal error: }
            ,    q{-caller_id not passed in call to _init_state(). }
            ,    $!
            ;
    
    my $outfh           = $href->{-outfh}
        or die   q{Smart::Comments::Any: }  # called with no -outfh
            ,    q{Internal error: }
            ,    q{-outfh not passed in call to _init_state(). }
            ,    $!
            ;
        
    # frame
    #   0       _prefilter
    #   1       FILTER
    #   2       Filter::Simple
    #   3       actual use-line caller
    my $frame           = 3;    
    my @caller          = caller($frame);
    
#   my $caller_name     = $caller[0];
    my $caller_file     = $caller[1];
    my $caller_line     = $caller[2];
    my $caller_sub      = $caller[3];   # TODO?: Test if we have the right caller...
    
    # Stash $outfh as $caller_id-dependent state info
    $state_of{$caller_id}{-outfh}           = $outfh;
    
    # It may not matter *what* you initialize these to...   
    $state_of{$caller_id}{-tell}{-outfh}    = tell $outfh;
    $state_of{$caller_id}{-tell}{-stdout}   = tell (*STDOUT);
    $state_of{$caller_id}{-caller}{-file}   = $caller_file;
    $state_of{$caller_id}{-caller}{-line}   = $caller_line;
    
#~ ### ...Leaving _init_state()...
#~ ### %state_of
    
    return 1;
};
######## /_init_state ########

######## INTERNAL ROUTINE ########
#
#   $prefilter      = _prefilter(@_);       # Handle arguments to FILTER
#       
# Purpose   : Handle arguments and do pseudo-global and per-use setup
# Parms     : @_
# Reads     : %ENV
# Returns   : hashref       (or 0 to abort filtering entirely)
#           :   -intro          $intro
#           :   -caller_id      $caller_id
# Writes    : %state_of
# Throws    : carp() if passed a bad arg in @_
# See also  : ____
# 
# Don't want to be fussy about the order of args passed on the use line, 
#   so each bit roots through all of them looking for what it wants. 
# 
sub _prefilter {
    
#~ say '---| Smart::Comments::Any at line ', __LINE__;
    
    shift;                          # Don't need our own package name
    s/\r\n/\n/g;                    # Handle win32 line endings
    
    my $caller_id       = _get_new_caller_id();     # unique per-use
    
    # Default introducer pattern...
    my $intro       = qr/#{3,}/;
    my @intros      ;
    
    ## Handle the ::Any setup
    
    my $fh_seen         = 0;            # no filehandle seen yet
    my $outfh           = undef;        # don't assign it first; see open()
    my $out_filename    = "$0.log";     # default
    my $arg             ;               # trial from @_
    my %packed_args     ;               # possible args packed into a hashref
    
    # Dig through the args to see if one is a hashref
    GETHREF:
    for my $i ( 0..$#_ ) {          # will need the index in a bit
        $arg            = $_[$i];   # look but don't take
        
        if ( ref $arg ) {               # some kind of reference
            my $stringy     = sprintf $arg;
            if ( $stringy =~ /HASH/ ) { # looks like a hash ref
                %packed_args    = %$arg;
                if ( defined $packed_args{-file} ) {
                    $out_filename   = $packed_args{-file};
                };  # else if undef, use default
                splice @_, $i;          # remove the parsed arg
#say '$out_filename: ', $out_filename;      
                open $outfh, '>', $out_filename
                    or die "Smart::Comments::Any: " 
                        ,  "Can't open $out_filename to write."
                        , $!
                        ;
                # Autoflush $outfh
                my $prev_fh         = select $outfh;
                local $|            = 1;                # autoflush
                select $prev_fh;

                
                
#say $outfh '... Just after opening $outfh ...';
#say $outfh '$outfh: ', $outfh; 
            };
        };
    
#return 0;  
    };      # /GETHREF
    
    # Dig through the args to see if one is a filehandle
    SETFH:
    for my $i ( 0..$#_ ) {          # will need the index in a bit
        $arg            = $_[$i];   # look but don't take
        
        # Is $arg defined by vanilla Smart::Comments?
        if ( $arg eq '-ENV' || (substr $arg, 0, 1) eq '#' ) {
            next SETFH;             # not ::Any arg, keep looking
        };
#       print 'Mine: >', $arg, "<\n";
        
        # Vanilla doesn't want to see it, so remove from @_
        splice @_, $i;
        
        # Is it a writable filehandle?
        if ( not -w $arg ) {
            carp   q{Not a writable filehandle: }
                . qq{$arg} 
                .  q{ in call to 'use Smart::Comments::Any'.}
                ;
        }                           # and keep looking
        else {
            $outfh      = $arg;
            last SETFH;             # found, so we're done looking
        };
    };      # /SETFH
    
    if (!$outfh) {
        $outfh          = *STDERR;      # default
    };
    
#~ say STDERR '... About to _init_state() ...';
#~ say STDERR '$outfh: ', $outfh;   
    _init_state({               # initialize $state_of this caller
        -outfh          => $outfh,
        -caller_id      => $caller_id, 
    }); 
    
#### ...In prefilter()...
#### %state_of
    
    ## done with the ::Any setup
    
    
    # Handle intros and env args...
    while (@_) {
        my $arg = shift @_;

        if ($arg =~ m{\A -ENV \Z}xms) {
            my $env =  $ENV{Smart_Comments} || $ENV{SMART_COMMENTS}
                    || $ENV{SmartComments}  || $ENV{SMARTCOMMENTS}
                    ;

            return 0 if !$env;   # i.e. if no filtering ABORT

            if ($env !~ m{\A \s* 1 \s* \Z}xms) {
                unshift @_, split m{\s+|\s*:\s*}xms, $env;
            }
        }
        else {
            push @intros, $arg;
        }
    }

    if (my @unknowns = grep {!/$intro/} @intros) {
        croak "Incomprehensible arguments: @unknowns\n",
              "in call to 'use Smart::Comments::Any'";
    }

    # Make non-default introducer pattern...
    if (@intros) {
        $intro = '(?-x:'.join('|',@intros).')(?!\#)';
    }

#say $outfh '... Leaving _prefilter() ...';
    return { 
        -intro          => $intro,
        -caller_id      => $caller_id,
    };
};
######## /_prefilter ########

sub import;     # FORWARD

######## EXTERNAL SUB CALL ########
#
# Purpose  : Rewrite caller's smart comments into code
# Parms    : @_     : The split use line, with $_[0] being *this* package
#          : $_     : Caller's entire source code to be filtered
# Reads    : %ENV, %state_of
# Returns  : $_     : Filtered code
# Writes   : %state_of
# Throws   : never
# See also : Filter::Simple, _prefilter()
# 
# Implement comments-to-code source filter. 
#
# This is not a subroutine but a call to Filter::Simple::FILTER
#   with its single argument being its following block. 
# 
# The block may be thought of as an import routine 
#   which is passed @_ and $_ and must return the filtered code in $_
#
# Note (if our module is invoked properly via use): 
# From caller's viewpoint, use operates as a BEGIN block, 
#   including all our-module inline code and this call to FILTER;
#       while filtered-in calls to our-module subs take place at run time. 
# From our viewpoint, our inline code, including FILTER, 
#   is run after any BEGIN or use in our module;
#       and filtered-in subs may be viewed 
#       as if they were externally called subs in a normal module. 
# Because FILTER is called as part of a constructed import routine, 
#   it executes every time our module is use()-ed, 
#   although other inline code in our module only executes one time only, 
#   when first use()-ed. 
# 
# See "How it works" in Filter::Simple's POD. 
# 
sub FILTERx {}; # dummy sub only to appear in editor's symbol table
#
FILTER {
    ##### |--- Start of filter ---|
    ##### @_
    ##### $_
#~ say "---| Source to be filtered:\n", $_, '|--- END SOURCE CODE';
    
    my $prefilter       = _prefilter(@_);       # Handle arguments to FILTER
    return 0 if !$prefilter;                    # i.e. if no filtering ABORT
    
    my $intro           = $prefilter->{-intro};         # introducer pattern
    my $caller_id       = $prefilter->{-caller_id};     # unique per-use

    # Preserve DATA handle if any...
    if (s{ ^ __DATA__ \s* $ (.*) \z }{}xms) {
        no strict qw< refs >;
        my $DATA = $1;
        open *{caller(1).'::DATA'}, '<', \$DATA or die "Internal error: $!";
    }
    
#~ say '---| Smart::Comments::Any at line ', __LINE__;
    
    # Progress bar on a for loop...
    # Calls _decode_for()
    s{ ^ $hws* ( (?: [^\W\d]\w*: \s*)? for(?:each)? \s* (?:my)? \s* (?:\$ [^\W\d]\w*)? \s* ) \( ([^;\n]*?) \) \s* \{
            [ \t]* $intro \s (.*) \s* $
     }
     { _decode_for($caller_id, $1, $2, $3) }egmx;

    # Progress bar on a while loop...
    # Calls _decode_while()
    s{ ^ $hws* ( (?: [^\W\d]\w*: \s*)? (?:while|until) \s* \( .*? \) \s* ) \{
            [ \t]* $intro \s (.*) \s* $
     }
     { _decode_while($caller_id, $1, $2) }egmx;

    # Progress bar on a C-style for loop...
    # Calls _decode_while()
    s{ ^ $hws* ( (?: [^\W\d]\w*: \s*)? for \s* \( .*? ; .*? ; .*? \) \s* ) \{
            $hws* $intro $hws (.*) $hws* $
     }
     { _decode_while($caller_id, $1, $2) }egmx;

    # Requirements...
    # Calls _decode_assert()
    s{ ^ $hws* $intro [ \t] $require : \s* (.*?) $optcolon $hws* $ }
     { _decode_assert($caller_id, $1,"fatal") }egmx;

    # Assertions...
    # Calls _decode_assert()
    s{ ^ $hws* $intro [ \t] $check : \s* (.*?) $optcolon $hws* $ }
     { _decode_assert($caller_id, $1) }egmx;

    # Any other smart comment is a simple dump.
    # The replacement code in each case consists mainly 
    #   of a call to Dump_for(). 
    # But WATCH OUT for subtle differences!
    
    # Dump a raw scalar (the varname is used as the label)...
    s{ ^ $hws* $intro [ \t]+ (\$ [\w:]* \w) $optcolon $hws* $ }
     { join $join_up,
        qq* Smart::Comments::Any::Dump_for(                                 *,
        qq*    -caller_id   => $caller_id,                                  *,
        qq*    -prefix      =>  q{$1:},                                     *,
        qq*    -varref      =>   [$1],                                      *,
        qq* );$DBX                                                          *,
     }egmx;

    # Dump a labelled scalar...
    s{ ^ $hws* $intro [ \t] (.+ :) [ \t]* (\$ [\w:]* \w) $optcolon $hws* $ }
     { join $join_up,
        qq* Smart::Comments::Any::Dump_for(                                 *,
        qq*     -caller_id  => $caller_id,                                  *,
        qq*     -prefix     =>  q{$1},                                      *,
        qq*     -varref     =>   [$2],                                      *,
        qq* );$DBX                                                          *,
     }egmx;

    # Dump a raw hash or array (the varname is used as the label)...
    s{ ^ $hws* $intro [ \t]+ ([\@%] [\w:]* \w) $optcolon $hws* $ }
     { join $join_up,
        qq* Smart::Comments::Any::Dump_for(                                 *,
        qq*    -caller_id   => $caller_id,                                  *,
        qq*    -prefix      =>  q{$1:},                                     *,
        qq*    -varref      => [\\$1],                                      *,
        qq* );$DBX                                                          *,
     }egmx;

    # Dump a labelled hash or array...
    s{ ^ $hws* $intro [ \t]+ (.+ :) [ \t]* ([\@%] [\w:]* \w) $optcolon $hws* $ }
     { join $join_up,
        qq* Smart::Comments::Any::Dump_for(                                 *,
        qq*    -caller_id   => $caller_id,                                  *,
        qq*    -prefix      =>  q{$1},                                      *,
        qq*    -varref      => [\\$2],                                      *,
        qq* );$DBX                                                          *,
     }egmx;

    # Dump a labelled expression...
    s{ ^ $hws* $intro [ \t]+ (.+ :) (.+) }
     { join $join_up,
        qq* Smart::Comments::Any::Dump_for(                                 *,
        qq*    -caller_id   => $caller_id,                                  *,
        qq*    -prefix      =>  q{$1},                                      *,
        qq*    -varref      =>   [$2],                                      *,
        qq* );$DBX                                                          *,
     }egmx;

    # Dump an 'in progress' message
    s{ ^ $hws* $intro $hws* (.+ [.]{3}) $hws* $ }
     { join $join_up,
        qq* Smart::Comments::Any::Dump_for(                                 *,
        qq*    -caller_id   => $caller_id,                                  *,
        qq*    -prefix      => qq{$1},                                      *,
        qq* );$DBX                                                          *,
     }egmx;

    # Dump an unlabelled expression (the expression is used as the label)...
    # Note inserted call to quiet_eval()
    s{ ^ $hws* $intro $hws* (.*) $optcolon $hws* $ }
     { join $join_up,
        qq* Smart::Comments::Any::Dump_for(                                 *,
        qq*    -caller_id   => $caller_id,                                  *,
        qq*    -prefix      =>  q{$1:},                                     *,
        qq*    -varref      => Smart::Comments::Any::quiet_eval( q{[$1]} ), *,
        qq* );$DBX                                                          *,
     }egmx;

# This doesn't work as expected, don't know why
# It can't help to warn instead of print
#   # An empty comment dumps an empty line...
#   # Inserts call to warn()
#   s{ ^ $hws* $intro [ \t]+ $ }
#    {warn qq{\n};}gmx;

# This is never needed; for some reason it's caught by "unlabeled expression"
# Strictly speaking, it's an undocumented feature
#   # Anything else is a literal string to be printed...
#   # Inserts call to Dump_for()
#   s{ ^ $hws* $intro $hws* (.*) }
#    {Smart::Comments::Any::Dump_for(-prefix=>q{$1});$DBX}gmx;

    ##### |--- End of filter ---|
    ##### @_
    ##### $_
#~ say "---| Source after filtering:\n", $_, '|--- END SOURCE CODE';

};
######## /FILTER ########

######## IMPORT ROUTINE ########
#       
# Purpose  : dummy for now
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# The "normal" import routine must be declared 
#   *before* the call to FILTER. 
# However, Filter::Simple will call import()
#   *after* applying FILTER to caller's source code. 
#   
sub import {
    
#~ say '---| Smart::Comments::Any at line ', __LINE__;
    
};
######## /import ########

#============================================================================#

######## EXTERNAL ROUTINE ########
#
#   $return     = quiet_eval($codestring);      # string eval, no errors
#       
# Purpose  : String eval some code and suppress any errors
# Parms    : $codestring    : Arbitrary client code
# Reads, Returns, Writes    : Whatever client code does
# Throws   : never, ever
# See also : FILTER # Dump an unlabelled expression
#   
sub quiet_eval {
    local $SIG{__WARN__} = sub{};
    return scalar eval shift;
};
######## /quiet_eval ########

######## INTERNAL ROUTINE ########
#
#   $quantity   = _uniq(@list);     # short
#       
# Purpose  : ____
# Parms    : any @list
# Reads    : none
# Returns  : scalar quantity of unique elements
# Writes   : none
# Throws   : never
# See also : _decode_assert
# 
#   
sub _uniq { 
    my %seen; 
    grep { !$seen{$_}++ } @_ 
};
######## /_uniq ########

######## REPLACEMENT CODE GENERATOR ########
#
#   $codestring     = _decode_assert( $caller_id, $assertion, $signal_flag);
#       
# Purpose   : Converts an assertion to the equivalent Perl code.
# Parms     : $caller_id
#           : $assertion    : text of assertion
#           : $signal_flag  : TRUE to die
# Reads     : %state_of
# Returns   : Replacement code string
# Writes    : none
# Throws    : never itself but generated code may die
# See also  : FILTER # Requirements, # Assertions
#
# Generates three snippets of code (in reverse order): 
#   $signal_code                # real die or sim warn
#   @vardump_code_lines         # Dumped variable(s)
#   $report_code                # entire replacement codestring, 
#                                   including previous two and $assertion
#   
sub _decode_assert {
    my $caller_id       = shift;
    my $assertion       = shift;
    my $signal_flag     = shift;
    
    my $frame           = 1;
    
    my $Dump_for    = 'Smart::Comments::Any::Dump_for';
    my $Print_for   = 'Smart::Comments::Any::Print_for';
    my $Warn_for    = 'Smart::Comments::Any::Warn_for';

    # Choose the right signalling mechanism
    #   after Warn_for()...
    my $signal_code 
        = $signal_flag 
        ?  q* die "\n"                          *   # ...then real die
        : qq* $Print_for( $caller_id, "\n" )    *   # ...then newline
        ;

    # Extract variables from assertion and enreference any arrays or hashes...
    my @vardump_code_lines 
        = map { 
              /^$hws*[%\@]/                     # sigil found
            ?   join $join_up,
                    qq* $Dump_for(                          *,
                    qq*     -caller_id  => $caller_id,      *,
                    qq*     -prefix     => q{    $_ was:},  *,
                    qq*     -varref     => [\\$_],          *,  # enreference
                    qq*     -no_newline => 1                *,
                    qq* );                                  *,
            :   join $join_up,
                    qq* $Dump_for(                          *,
                    qq*     -caller_id  => $caller_id,      *,
                    qq*     -prefix     => q{    $_ was:},  *,
                    qq*     -varref     => [$_],            *,  # don't enref
                    qq*     -no_newline => 1                *,
                    qq* );                                  *,
            ;   
        }   
        _uniq extract_multiple($assertion, [\&extract_variable], undef, 1)
        ## end of map expression
    ;
    ## end of assignment
    
    # Generate the test-and-report code...
    my $report_code     = join $join_up,
        qq* unless($assertion) {                    *,
        qq*     $Warn_for(                          *,
        qq*         $caller_id,                     *,  # $caller_id
        qq*         $frame,                         *,  # $frame
        qq*         "\\n",                          *,  # @text to print
        qq*         q{### $assertion was not true}  *,  #   more @text
        qq*     );                                  *,  #   more @text
        qq*     @vardump_code_lines;                *,  # call Dump_for
        qq*     $signal_code                        *,  # maybe die
        qq* }                                       *,
    ;
    ## end of assignment
 $DB::single=1;   
    return $report_code;
};
######## /_decode_assert ########

######## REPLACEMENT CODE GENERATOR ########
#
#   $codestring     = _decode_for($for, $range, $mesg);
#       
# Purpose  : Generate progress-bar code for a Perlish for loop.
# Parms    : $for   : 
#          : $range : 
#          : $mesg  : 
# Reads    : ____
# Returns  : Replacement code string
# Writes   : $ID
# Throws   : never
# See also : for_progress()
# 
sub _decode_for {
    my $caller_id       = shift;
    my $for             = shift;
    my $range           = shift;
    my $mesg            = shift;

    # Give the loop a unique ID...
    $ID++;

    # Rewrite the loop with a progress bar as its first statement...
    my $report_code     = join qq{\n},
        qq* my \$not_first__$ID;                                    *,
        qq* $for (my \@SmartComments__range__$ID = $range) {        *,
        qq*     Smart::Comments::Any::for_progress( $caller_id,     *,
        qq*         qq{$mesg},                                      *,
        qq*         \$not_first__$ID,                               *,
        qq*         \\\@SmartComments__range__$ID                   *,
        qq*     );                                                  *,
            # closing brace found somewhere in client code
    ;
    ## end of assignment

### _decode_for code : $report_code 
    return $report_code;
};
######## /_decode_for ########

######## REPLACEMENT CODE GENERATOR ########
#
#   _decode_while($while, $mesg);       # short
#       
# Purpose   : Generate progress-bar code for a Perlish while loop.
# Parms     : $while :
#           : $mesg  :
# Reads     : ____
# Returns  : Replacement code string
# Writes    : $ID
# Throws    : ____
# See also  : while_progress()
# 
sub _decode_while {
    my $caller_id       = shift;
    my $while           = shift;
    my $mesg            = shift;

    # Give the loop a unique ID...
    $ID++;

    # Rewrite the loop with a progress bar as its first statement...
    my $report_code     = join qq{\n},
        qq* my \$not_first__$ID;                                    *,
        qq* $while {                                                *,
        qq*     Smart::Comments::Any::while_progress( $caller_id,   *,
        qq*         qq{$mesg},                                      *,
        qq*         \\\$not_first__$ID                              *,
        qq*     );                                                  *,
            # closing brace found somewhere in client code
    ;
    ## end of assignment
    
### _decode_while code : $report_code   
    return $report_code;
};
######## /_decode_while ########

######## INTERNAL ROUTINE ########
#
#   _desc_time();       # short
#       
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# Generate approximate time descriptions...
#   
sub _desc_time {
    my ($seconds) = @_;
    my $hours = int($seconds/3600); $seconds -= 3600*$hours;
    my $minutes = int($seconds/60); $seconds -= 60*$minutes;
    my $remaining;

    # Describe hours to the nearest half-hour (and say how close to it)...
    if ($hours) {
        $remaining =
          $minutes < 5   ? "about $hours hour".($hours==1?"":"s")
        : $minutes < 25  ? "less than $hours.5 hours"
        : $minutes < 35  ? "about $hours.5 hours"
        : $minutes < 55  ? "less than ".($hours+1)." hours"
        :                 "about ".($hours+1)." hours";
    }
    # Describe minutes to the nearest minute
    elsif ($minutes) {
        $remaining = "about $minutes minutes";
        chop $remaining if $minutes == 1;
    }
    # Describe tens of seconds to the nearest ten seconds...
    elsif ($seconds > 10) { 
        $seconds = int(($seconds+5)/10);
        $remaining = "about ${seconds}0 seconds";
    }
    # Never be more accurate than ten seconds...
    else {  
        $remaining = "less than 10 seconds";
    }
    return $remaining;
};
######## /_desc_time ########

######## INTERNAL ROUTINE ########
#
#   _moving_average();      # short
#       
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# Update the moving average of a series given the newest measurement...
#   
sub _moving_average {
    my ($context, $next) = @_;
    my $moving = $moving{$context} ||= [];
    push @$moving, $next;
    if (@$moving >= $average_over) {
        splice @$moving, 0, $#$moving-$average_over;
    }
    return sum(@$moving)/@$moving;
};
######## /_moving_average ########

######## INTERNAL ROUTINE ########
#
#   _prog_pat();        # short
#       
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# Clean up components of progress bar (inserting defaults)...
#   
sub _prog_pat {
    for my $pat (@progress_pats) {
        $_[0] =~ $pat or next;
        return ($1, $2||"", $3||"", $4||""); 
    }
    return;
};
######## /_prog_pat ########

######## EXTERNAL ROUTINE ########
#
#   for_progress();     # short
#       
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : $_[2] ($not_first__$ID in caller's code
# Throws   : ____
# See also : _decode_for
# 
# Animate the progress bar of a for loop...
#   
sub for_progress {
### ...In for_progress...
    
    my $caller_id       = $_[0];    # per-use id of this caller
    my $mesg            = $_[1];    # 
    my $not_first       = $_[2];    # will be altered so don't shift it off
    my $data            = $_[3];    # 
    
    my $at              ;           # 
    my $max             ;           # 
    my $elapsed         ;           # 
    my $remaining       ;           # 
    my $fraction        ;           # 
    
    # Update progress bar...
    if ($not_first) {
    ### for_progress- if not first
        # One more iteration towards the maximum...
        $at = ++$count{$data};
        $max = $max{$data};

        # How long now (both absolute and relative)...
        $elapsed = time - $started{$data};
        $fraction = $max>0 ? $at/$max : 1;

        # How much change occurred...
        my $motion = $fraction - $prev_fraction{$data};

        # Don't update if count wrapped (unlikely) or if finished
        # or if no visible change...
        return unless $not_first < 0
                   || $at == $max
                   || $motion > $forupdatequantum;

        # Guestimate how long still to go...
        $remaining = _moving_average $data,
                                    $fraction ? $elapsed/$fraction-$elapsed
                                              : 0;
    }
    
    # If first iteration...
    else {
    ### for_progress- else first
        # Start at the beginning...
        $at = $count{$data} = 0;

        # Work out where the end will be...
        $max = $max{$data} = $#$data;

        # Start the clock...
        $started{$data} = time;
        $elapsed = 0;
        $fraction = 0;

        # After which, it will no longer be the first iteration.
        $_[2] = 1;  # $not_first
    }

    # Remember the previous increment fraction...
    $prev_fraction{$data} = $fraction;

    # Now draw the progress bar (if it's a valid one)...
    if (my ($left, $fill, $leader, $right) = _prog_pat($mesg)) {
        # Insert the percentage progress in place of a '%'...
        s/%/int(100*$fraction).'%'/ge for ($left, $leader, $right);

        # Work out how much space is available for the bar itself...
        my $fillwidth = $showwidth - length($left) - length($right);

        # But no less than the prespecified minimum please...
        $fillwidth = $minfillwidth if $fillwidth < $minfillwidth;

        # Make enough filler...
        my $totalfill = $fill x $fillwidth;

        # How big is the end of the bar...
        my $leaderwidth = length($leader);

        # Truncate where?
        my $fillend = $at==$max ? $fillwidth 
                    :            $fillwidth*$fraction-$leaderwidth;
        $fillend = 0 if $fillend < 0;

        # Now draw the bar, using carriage returns to overwrite it...
        Print_for( $caller_id,  
            qq{\r}, 
             q{ } x $maxwidth,
            qq{\r}, 
            $left,
            sprintf("%-${fillwidth}s",
                   substr($totalfill, 0, $fillend)
                 . $leader),
            $right,
        );

        # Work out whether to show an ETA estimate...
        if (
               $elapsed >= $showstarttime 
            && $at < $max 
            && ($showing{$data} || $remaining && $remaining >= $showmaxtime)
        ) {
            Print_for( $caller_id,
                q{  (}, 
                _desc_time($remaining), 
                q{ remaining)},
            );
            $showing{$data} = 1;
        }

        # Close off the line, if we're finished...
        Print_for( $caller_id,
            qq{\r}, 
             q{ } x $maxwidth,
            qq{\n}, 
            ) if $at >= $max;
    }
};
######## /for_progress ########

######## EXTERNAL ROUTINE ########
#
#   while_progress();       # short
#       
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# Animate the progress bar of a while loop...
#   
sub while_progress {
    my $caller_id       = shift;    # per-use id of this caller
    my $mesg            = shift;    # 
    my $not_first_ref   = shift;    # 
    
    my $at              ;           #

    # If we've looped this one before, recover the current iteration count...
    if ($$not_first_ref) {
        $at = ++$count{$not_first_ref};
    }
    # Otherwise set the iteration count to zero...
    else {
        $at = $count{$not_first_ref} = 0;
        $$not_first_ref = 1;
    }

    # Extract the components of the progress bar...
    if (my ($left, $fill, $leader, $right) = _prog_pat($mesg)) {
        # Replace any '%' with the current iteration count...
        s/%/$at/ge for ($left, $leader, $right);

        # How much space is there for the progress bar?
        my $fillwidth = $showwidth - length($left) - length($right);

        # Make it at least the prespecified minimum amount...
        $fillwidth = $minfillwidth if $fillwidth < $minfillwidth;

        # How big is the end of the bar?
        my $leaderwidth = length($leader);

        # How big does that make the bar itself (use reciprocal growth)...
        my $length = int(($fillwidth-$leaderwidth)
                           *(1-$whilerate/($whilerate+$at))+0.000000000001);

        # Don't update if the picture would look the same...
        return
            if length $fill && $prev_length == $length;

        # Otherwise, remember where we got to...
        $prev_length = $length;

        # And print the bar...
        Print_for( $caller_id,  
            qq{\r}, 
             q{ } x $maxwidth,
            qq{\r}, 
            $left,
            sprintf("%-${fillwidth}s",
                   substr($fill x $fillwidth, 0, $length)
                 . $leader),
            $right,
        );
    }
};
######## /while_progress ########


######## EXTERNAL ROUTINE ########
#
#   Print_for( $caller_id, @args );     # short
#       
# Purpose   : Print @args to caller's chosen $outfh
# Parms     : $caller_id    : identify which caller
#           : $frame        : we may be called directly or by proxy
#           : @args         : any printable list
# Reads     : %state_of
# Returns   : 1
# Writes    : to $outfh
# Throws    : dies if print fails
# See also  : _get_new_caller_id(), Warn_for(), _decode_assert(), Dump()
# 
# Call this only from within replacement code. 
# If called by another our-module routine, it will get the wrong stack frame. 
# 
sub Print_for {
    my $caller_id       = shift;
    my $outfh           = _get_outfh($caller_id);   # get from %state_of
    
    print {$outfh} @_
        or die   q{Smart::Comments::Any: }  # print failure
            ,    q{Filesystem IO error: }
            ,   qq{Failed to print to output filehandle for $caller_id }
            ,    $!
            ;
    
    return 1;
};
######## /Print_for ########

######## EXTERNAL ROUTINE ########
#
#   Warn_for( $caller_id, $frame, @args );      # short
#       
# Purpose   : Print @args *and* $file, $line to caller's chosen $outfh
#           :    as if it were warn().
# Parms     : $caller_id    : identify which caller
#           : $frame        : we may be called directly or by proxy
#           : @args         : any printable list
# Reads     : %state_of
# Returns   : 1
# Writes    : to $outfh
# Throws    : dies if print fails
# See also  : _get_new_caller_id(), Print_for(), _decode_assert()
# 
# This can be called from within replacement code or from S::C;
#   but either way, $frame must be passed in. 
sub Warn_for {
    my $caller_id       = shift;
    my $frame           = shift;
    
    my @caller          = caller($frame);
    
#   my $caller_name     = $caller[0];
    my $caller_file     = $caller[1];
    my $caller_line     = $caller[2];
    
    Print_for( $caller_id, @_, " at $caller_file line $caller_line.\n" );
    return 1;
};
######## /Warn_for ########

######## INTERNAL ROUTINE ########
#
#   _put_state( $caller_id, @caller );      # short
#       
# Purpose   : Store current state info
# Parms     : $caller_id    : to put %state_of previous state
#           : @caller       : current state (maybe)
# Reads     : %state_of
# Returns   : 1
# Writes    : %state_of
# Throws    : dies if called with unknown caller
# See also  : _spacer_required(), Dump_for()
# 
# This stores not $outfh itself 
#   but the initial state of output to it, sort of. 
# 
sub _put_state {
    my $caller_id       = shift;
    my @caller          = @_;
    my $caller_name     = $caller[0];
    my $caller_file     = $caller[1];
    my $caller_line     = $caller[2];
    
    die "Smart::Comments::Any: Fatal Error (_put_state): ",
        "No state_of $caller_id.", 
        $!      if ( !defined $state_of{$caller_id} );
    
    my $outfh           = _get_outfh($caller_id);
    
    $state_of{$caller_id}{-tell}{-outfh}    = tell $outfh;
    $state_of{$caller_id}{-tell}{-stdout}   = tell (*STDOUT);
    $state_of{$caller_id}{-caller}{-file}   = $caller_file;
    $state_of{$caller_id}{-caller}{-line}   = $caller_line;
    
    return 1;
    
};
######## /_put_state ########

######## INTERNAL ROUTINE ########
#
#   $flag       = _spacer_required( $caller_id, @caller );  # newline before?
#       
# Purpose   : Ensure the smart output starts flush left.
# Parms     : $caller_id    : key %state_of for previous state
#           : @caller       : current state (maybe)
# Reads     : %state_of
# Returns   : Boolean: TRUE to prepend a newline to output
# Writes    : ____
# Throws    : ____
# See also  : Dump_for(), %state_of
# 
# Vanilla S::C compared both previous tell()-s of STDOUT and STDERR
#   before deciding to print a prophylactic newline, even though Vanilla
#   only ever printed to STDERR. One might assume Conway does this 
#   on *his* assumption that both are connected to the same output device, 
#   namely a terminal window or console. 
# This may or may not be wise but we preserve the exact Vanilla behavior;
#   while output to disk files contains fewer newlines.  
# Since we make no explicit check of which or what kind of filehandle, 
#   I cannot explain why this is so. 
# The missing newlines are not going to STDOUT, STDERR, or the screen anyway. 
# 
# TODO: Vanilla outputs a gratuitous newline 
#   if $caller_line has changed by more than one line.
#   This may result in rather "loose" output. 
#   TODO: Accept a "tighten" arg in use line.
# 
sub _spacer_required {
    my $caller_id       = shift;
    my @caller          = @_;
    my $caller_name     = $caller[0];
    my $caller_file     = $caller[1];
    my $caller_line     = $caller[2];
    
    my $outfh       = _get_outfh($caller_id);   # retrieve from %state_of
    
#say '$outfh: ', $outfh;    
    my $prev_tell_outfh     = $state_of{$caller_id}{-tell}{-outfh};
    my $prev_tell_stdout    = $state_of{$caller_id}{-tell}{-stdout};
    my $prev_caller_file    = $state_of{$caller_id}{-caller}{-file};
    my $prev_caller_line    = $state_of{$caller_id}{-caller}{-line};
        
    my $flag            ;
    
# This test is *not* needed, oddly enough!
# Intent was to preserve Vanilla behavior by requiring newline
#   if tell STDOUT had changed when printing to STDERR. 
# But with this paragraph disabled, Vanilla is preserved 
#   and also 'use Smart::Comments::Any *STDOUT' yields the same output.
# Yet when given a hard disk $fh, fewer gratuitous newlines are output, 
#   which is desired. 
# I cannot figure out why. Let us consider this a blessing. 
#   
#   # You might not think you can compare filehandles, but you can...
#   # ... but only if they're identical, not if they're equivalent...
#   # ... *STDERR ne \*STDERR   # although most io routines will accept either
#   if    ( $outfh eq *STDERR ) {   # STDERR chosen, vanilla behavior
#       # newline if STDOUT has been printed to since last smart output
#       $flag   ||= $prev_tell_stdout   != tell(*STDOUT);
#say 'I Vanillaed.';
#   };
    
    # newline if $outfh has been printed to
    $flag       ||= $prev_tell_outfh    != tell $outfh;
### 1311 : $flag
    
    # newline if $caller_file has changed (???)
    $flag       ||= $prev_caller_file   ne $caller_file;
### 1315 : $flag
    
    # TODO: if $tighten do not...
    # newline if $caller_line has changed by more or less than 1
    $flag       ||= $prev_caller_line   != $caller_line -1;
### 1320 : $flag
        
#   say 'Doing the newline.' if $flag;
#   return 0;           # never do the newline 
    return $flag;
};
######## /_spacer_required ########

######## EXTERNAL ROUTINE ########
#
#   Dump_for();     # short
#       
# Purpose  : Dump a variable (any variable?)
# Parms    : flat list (assigned to hash)
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : Data::Dumper, FILTER # Any other smart comment is a simple dump
# 
# Dump a variable and then reformat the resulting string more prettily...
#   
sub Dump_for {
    
    my %hash        = @_;
    my $caller_id       = $hash{-caller_id}
        or die   q{Smart::Comments::Any: }  # called with no -caller_id
            ,    q{Replacement code error: }
            ,    q{-caller_id not passed in call to Dump(). }
            ,    $!
            ;
    
    my $prefix          = $hash{-prefix};
    my $defined_varref  = defined $hash{-varref};   # save test
    my $varref          = $hash{-varref};
    my $no_newline      = $hash{-no_newline};
    
    my @caller          = caller;       # called by replacement code
#   my $caller_name     = $caller[0];
    my $caller_file     = $caller[1];
    my $caller_line     = $caller[2];
    my $outfh           = _get_outfh($caller_id);   # retrieve from %state_of

    my $spacer_required ;               # TRUE to prepend a newline to output
    
#~ say $outfh '... Entering Dump_for() ...';
#~ ### ... Entering Dump_for()
#~ ### %state_of
    
    # Handle timestamps...
    $prefix =~ s/<(?:now|time|when)>/scalar localtime()/ge;
    $prefix =~ s/<(?:here|place|where)>/"$caller_file", line $caller_line/g;

    # Add a newline?
    if ($no_newline) {
        $spacer_required    = 0;
    } 
    else {
        $spacer_required    = _spacer_required( $caller_id, @caller );
    };
#~ ### $spacer_required 
    # Handle a prefix with no actual variable...
    if ($prefix && !$defined_varref) {
        $prefix =~ s/:$//;
        Print_for( $caller_id, "\n" ) if $spacer_required;
        Print_for( $caller_id, "### $prefix\n" );
        _put_state( $caller_id, @caller );
        return 1;                   # ...abort if not defined $varref
    }
    
    # or continue...    
    
    # Set Data::Dumper up for a tidy dump and do the dump...
    local $Data::Dumper::Quotekeys      = 0;
    local $Data::Dumper::Sortkeys       = 1;
    local $Data::Dumper::Indent         = 2;
    my $dumped                          = Dumper $varref;

    # Clean up the results...
    $dumped =~ s/\$VAR1 = \[\n//;
    $dumped =~ s/\s*\];\s*$//;
    $dumped =~ s/\A(\s*)//;

    # How much to shave off and put back on each line...
    my $indent  = length $1;
    my $outdent = q{ } x (length($prefix) + 1);

    # Report "inside-out" and "flyweight" objects more cleanly...
    $dumped =~ s{bless[(] do[{]\\[(]my \$o = undef[)][}], '([^']+)' [)]}
                {<Opaque $1 object (blessed scalar)>}g;

    # Adjust the indents...
    $dumped =~ s/^[ ]{$indent}([ ]*)/### $outdent$1/gm;

    # Print the message...
    Print_for( $caller_id, "\n" ) if $spacer_required;
    Print_for( $caller_id, "### $prefix $dumped\n" );
    _put_state( $caller_id, @caller );

    return 1;
};
######## /Dump_for ########

#~ say '---| Smart::Comments::Any at line ', __LINE__;

#############################
######## END MODULE #########
1;
__END__

=head1 NAME

Smart::Comments::Any - Smart Comments that print anywhere


=head1 VERSION

This document describes Smart::Comments::Any version 1.0.4


=head1 SYNOPSIS

    use Smart::Comments::Any LOG, '###';        # recommended

    use Smart::Comments::Any ({                 # if you want the filehandle
        -fh             => $::outfh,            # undefined package scalar
        -log            => 1,                   # appends to "$0.log"
        -level          => 3,                   # same as '###'
    });     

    use Smart::Comments::Any;                   # acts just like Smart::Comments
    use Smart::Comments::Any '###';             # acts just like Smart::Comments
    use Smart::Comments::Any *STDERR, '###';    # same thing
    
    use Smart::Comments::Any $fh;               # prints to $fh instead
    use Smart::Comments::Any *FH;               # prints to FH instead

    use Smart::Comments::Any 'my/log.txt';      # opens file and prints to it
    use Smart::Comments::Any LOG;               # appends to "$0.log"
    
    use Smart::Comments::Any ({                 # hashref call
        -fh             => *STDERR,             # filehandle
        -file           => 'my/log',            # filename
        -log            => 1,                   # appends to "$0.log"
        -env            => 1,                   # heed $ENV{Smart_Comments}
        -level          => 3,                   # same as '###'
        -level          => [3, 5],              # same as '###', '#####'
        -append         => 1,                   # appends instead of truncating
    }); 
    
      
=head1 DESCRIPTION

L<Smart::Comments> works well for those who debug with print statements. 
However, it always prints to STDERR. This doesn't work so well when STDERR 
is being captured and tested. Besides, you might want a more permanent log of 
smart output. 

Smart::Comments::Any acts like Smart::Comments, except that 
output can be sent to other destinations. 

Please see L<Smart::Comments> for major documentation. 
Smart::Comments::Any version 1.0.4 is a modification 
of the same version of Smart::Comments. 

=head1 INTERFACE 

=head2 The C<use> Line Flat List

Because this is a source filter, most work is done at the time the module is
loaded via use C<Smart::Comments::Any>. If called with vanilla Smart::Comments 
arguments, ::Any will behave the same; it's a drop-in replacement. 

Besides the vanilla C<'###'>, etc. and C<-ENV> arguments, ::Any accepts 
filehandles, filenames, and a hashref supplying any or all argument values. 

=head3 $fh, *FH

I<see -fh>

The use statement accepts an open, writable filehandle as an argument. 
Caller must do whatever is needed to manage that filehandle, 
such as opening and perhaps closing it. 

Note that modules are used, effectively, within a BEGIN block. 
Therefore, your filehandle must be opened within a BEGIN block prior to 
(or including) the use line. If caller needs 
to do anything else with that filehandle, it might as well be stored 
in a package variable (since source filtering is global anyway). Otherwise, 
you can enclose the open and the use line in the same BEGIN block. 

The filehandle must be opened, obviously, in some writable mode.  

    BEGIN {                             # one way to get $fh open early enough
        my $filename    = 'mylog.txt';
        open my $fh, '>', $filename
            or die "Couldn't open $filename to write", $!;
        use Smart::Comments::Any $fh;
    }
      
    BEGIN {                             # or store $::fh for later use
        my $filename    = 'mylog.txt';
        open my $::fh, '>', $filename
            or die "Couldn't open $filename to write", $!;
    }
    use Smart::Comments::Any $::fh;
    {...}   # do some work
    ### $some_variable
    print {$::fh} 'Some message...';
    close $::fh;                        # only after the last smart comment

=head3 $filename

I<see -file>

You can pass a filename as an argument. Smart::Comments::Any will open the 
file for you and direct smart output to it. There's an issue here in that
a filename might be just about any string; so we assume any 
otherwise-unrecognized argument to be a filename. Also, if you've 
chosen a peculiar filename such as '###' or '-ENV', there's going to be confusion. 

=head3 ###, ####, #####, etc.

I<see -level>

As they do in vanilla Smart::Comments, these arguments set the number of 
octothorpes that may precede a smart comment. If no octothorpes appear on the 
use line and C<-level> is undefined, then B<all> initial sequences of 3 or more
octothorpes will introduce a smart comment. 

=head3 LOG

I<see -log>

Pass this in the flat list to print smart output to a file named C<"$0.log">, 
where C<$0> (might be) is the name of your script.  

=head2 The C<use> Line Hashref

Alternatively, you can pass in a reference to a hash, with keys literal 
and values corresponding to various arguments. Hash keys are introduced 
by a single dash: 

=head3 -file

Value can be any filename or path, relative or fully qualified. The file will 
be created if it doesn't exist, truncated by default, opened for writing, 
and set to autoflush. All directory components must exist. 

Until your entire program ends, there's no way to be sure that caller won't 
come into scope (say, a sub called from some other script or module). So ::Any 
can't do an explicit close(). That shouldn't be a problem, since Perl will 
close the filehandle when program terminates. If you need to do something 
differently, supply a filehandle and manage it yourself. 

=head3 -append

Flag; if true, the smart output file will be opened in append mode ('>>') 
instead of being truncated. Use this with a supplied filename. Ignored if only 
a filehandle is passed. Reset to a false value to open the file in 
truncate-then-write mode ('>'); this is the default except when C<-log> is set. 

=head3 -log

Flag; if true, equivalent to C<{file => $0.log, -append => 1}>. You might want 
to do this in conjunction with, somewhere early in your script: 

    ### <now><here>

=head3 -fh

Value must be acceptable as a filehandle: 

    $fh         # indirect filehandle (perhaps IO::File object); recommended.
    \*FH        # reference to a typeglob
    *FH         # typeglob
    "FH"        # please don't do this; probably won't work as expected.

Except for C<*STDOUT> you should probably avoid the typeglob notation. 
(No need to specify STDERR explicitly.) ::Any will try to work with a typeglob 
but there are risks. You'd better localize the typeglob; a lexical may not work. 
(See L<Perl Cookbook Recipie 7.16>.) Passing a string will probably fail. 

You don't need to load IO::file to open an indirect filehandle; this is fine: 

    open my $fh, '>', $filename
        or die "Couldn't open $filename to write", $!;

So long as $fh is undefined beforehand, it will contain afterward a reference 
to an anonymous filehandle. It's okay to use a lexical variable for this; 
just be sure it's opened and in scope when the C<use Smart::Comments::Any> 
line comes around (at "compile time"), 
which probably means to do this in a BEGIN block. 

If no filename is also supplied, then the filehandle must be opened for writing. 
::Any will not do anything special to the filehandle 
but will print all smart output to it. 

If a filename is supplied as well as a filehandle, then the supplied filehandle
will be associated with the file, so you can do stuff yourself with the filehandle: 

    BEGIN {                             # "exports"
        my $filename    = 'mylog.txt';
        my $::fh;
        use Smart::Comments::Any ({
            -file   => $filename,
            -fh     => $::fh;
        });
    }
    {...}   # do some work
    ### $some_variable
    print {$::fh} 'Some message...';
    close $::fh;                        # only after the last smart comment

=head3 -level

Vanilla accepts arguments like '###', '####', and so forth. If none are given, 
then all comments introduced with 3 or more octothorpes are considered smart. 
Otherwise, only those comments introduced with a matching quantity are smart: 

    use Smart::Comments::Any '###', '#####'; 
    ### This is smart.
    #### This is dumb.
    ##### This is also smart. 

::Any will do this too. Or, you can pass an integer or a list of integers: 
    
    use Smart::Comments::Any ({-level => [3, 5] }); 
    ### This is smart.
    #### This is dumb.
    ##### This is also smart. 
    
If you define C<-level => 0>, to C<[0]>, or to C<[]>, then all comments will 
be dumb. But if C<-level => undef> or doesn't exist at all, then all comments 
(introduced by 3 or more) will be smart. Remember, though, that multiple level 
specifications are cummulative. 

A level of 1 or 2 simply doesn't work. So don't do that. 

=head3 -env

Yet another way of specifying arguments (besides as a list or hashref 
in the use line) is to pass them in the environment variable 
C<$ENV{Smart_Comments}>. But to enable this, you must pass C<-ENV> in the use line 
or define C<-env> in a hashref passed in the use line. 

Don't try to pass a hashref inside of the environment variable; 
you won't like the result.

=head2 Mixed and Redefined Calling

If you manage to pass different values for the same thing more than once, 
the last of these will override: 

=over

=item *

Passed in a hashref value

=item *

Passed in the use line flat list (overrides hashref)

=item *

Passed in the environment variable (overrides hashref and flat list)

=back

The overriding will be complete, except in the case that the output level is 
set more than once ('###' or -level syntax); then all of the levels specified 
will be smart (logical OR). 

=head1 SCOPE, STATE, OUTPUT REGIMES

::Any may be called more than once in the same program, e.g., from two 
different loaded modules. As does Vanilla, ::Any has effect until the end of 
the file or a C<no Smart::Comments::Any> line (which must be the first thing 
on its line). If used again, ::Any will parse the new use line and apply it to 
your source code from there on out. 

This required no special logic in Vanilla; the filter is applied once per use 
and although multiple modules might call S::C routines from within filtered 
code, all output went to STDERR. But multiple uses of ::Any may choose 
different output regimes. So state information is stored for each caller. 

If you supply a filehandle (other than STDOUT or STDERR), your (filtered) 
code will need that later to print smart output where you want it to go. If you 
supply a package variable as an indirect filehandle (such as C<$My::Module::fh>), 
then all is well. If you supply a lexical (C<my>) variable, ::Any will still 
work, even after it goes out of scope in your package, because a reference is 
stored in ::Any's namespace. But by the same token, don't expect it to be 
garbage-collected. You may as well use a package "global" variable, since 
source filtering is pretty much a global operation anyway. 

If you pass a filename but no filehandle, you'll get smart output but you won't
have any way to write directly to the file (should you take that notion). Not 
recommended to open the file again within your script, although that might work. 

If you supply a filename I<and> a filehandle, then your filehandle will be 
associated with the file. Peculiar things may happen if that filehandle is 
previously defined; you were warned. Recommended to pass an undefined scalar, 
which you can use, if you choose, to print directly from within your script. 

You might well reuse the same file for smart output from several modules; if so, 
you probably want to preserve it from use to use. 
So C<use Smart::Comments::Any ({-file => 'my/log', -append => 1});> in each,
or simply C<use Smart::Comments::Any LOG>. 

=head1 ASSERTIONS

Assertions defined with one of the words C<[require|assert|ensure|insist]> 
will C<die()> under both Vanilla and ::Any. Assertions defined with 
C<[check|confirm|verify]> raise a warning in Vanilla, which of course prints 
to STDERR. In ::Any, these print to whatever's been chosen for smart output 
and the C<warn()> is simulated. 

=head1 PROGRESS BARS

Progress bars can be generated by putting certain types of smart comment 
trailing the first line of some loops: 

    use Smart::Comments::Any;    ### praying...       done
    foreach (@monk) {
        pray($_);
    };

Both Vanilla and ::Any animate the progress bar by printing the C<"\r"> 
character and wiping the line with spaces. This is unchanged when smart output
goes to a disk file. Depending on your method of reading that file, you may see
multiple lines or nothing at all. But if, for some reason, the loop aborts, you 
may see how far along it got. 

=head1 DIAGNOSTICS

=over

=item C<< Bad filehandle: %s in call to 'use Smart::Comments::Any', defaulting to STDERR >>

You loaded the module and passed it a filehandle that couldn't be written to. 
Note that you'd better open the filehandle for writing in a BEGIN block
before loading Smart::Comments::Any. 

=back

=head1 CONFIGURATION AND ENVIRONMENT



=head1 DEPENDENCIES

The module requires the following modules:

=over

=item *

Filter::Simple

=item *

version.pm

=item *

List::Util

=item *

Data::Dumper

=item *

Text::Balanced

=back

=head1 INCOMPATIBILITIES

None reported. This module is probably even relatively safe with other
Filter::Simple modules since it is very specific and limited in what
it filters.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

This module has all the grace and effect of Smart::Comments. If it works, 
credit goes to Damian Conway. If it fails when Smart::Comments works, 
blame me. 

Before reporting any bug, please be sure it's specific to 
Smart::Comments::Any by testing with vanilla Smart::Comments. 

Please report any bugs or feature requests to
C<< <xiong@xuefang.com> >>.


=head1 AUTHOR

Xiong Changnian  C<< <xiong@xuefang.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Xiong Changnian  C<< <xiong@xuefang.com> >>. All rights reserved.

Based almost entirely on Smart::Comments, 
Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
