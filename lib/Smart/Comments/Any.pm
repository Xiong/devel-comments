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
use Text::Balanced 				# Extract delimited text sequences from strings
	qw( extract_variable extract_multiple );
	
use Data::Dumper 'Dumper';

# debug only
use feature 'say';				# disable in production; debug only
#use Smart::Comments '###';		# playing with fire;     debug only

######## / use ########

######## pseudo-constants section ########

# time and space constants
my $maxwidth		  	= 69;  	# Maximum width of display
my $showwidth		  	= 35;  	# How wide to make the indicator
my $showstarttime	  	= 6;   	# How long before showing time-remaining estimate
my $showmaxtime			= 10;  	# Don't start estimate if less than this to go
my $whilerate		  	= 30;  	# Controls the rate at which while indicator grows
my $minfillwidth	   	= 5;   	# Fill area must be at least this wide
my $average_over	   	= 5;   	# Number of time-remaining estimates to average
my $minfillreps			= 2;   	# Minimum size of a fill and fill cap indicator
my $forupdatequantum   	= 0.01;	# Only update every 1% of elapsed distance

# Synonyms for asserts and requirements...
my $require 			= qr/require|ensure|assert|insist/;
my $check   			= qr/check|verify|confirm/;

# Horizontal whitespace...
my $hws	 				= qr/[^\S\n]/;

# Optional colon...
my $optcolon 			= qr/$hws*;?/;

# Automagic debugging as well...
my $DBX 				= '$DB::single = $DB::single = 1;';

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

######## / pseudo-constants ########

######## pseudo-global variables section ########

## original S::C stuff

# Unique ID assigned to each loop; incremented when assigned
# 	See: _for_progress, _while_progress
my $ID 					= 0;

#	See: _for_progress
my %started				;

#	See: _moving_average
my %moving				;

# State information for various progress bars...
#	See: _for_progress, _while_progress
my (%count, %max, %prev_elapsed, %prev_fraction, %showing);

#	See: _while_progress
my $prev_length = -1;

#	See: _Dump
my $prev_STDOUT = 0;
my $prev_STDERR = 0;
my %prev_caller = ( file => q{}, line => 0 );


## ::Any stuff
# Current "outside" caller must be available anywhere
my %caller		= (
	-name			=> '',			# 'Caller::Module'
	-file			=> '',			# '../lib/Caller/Module.pm'
	-line			=> 0			# 273
);

# Store per-use state info
my %state_of			;			# $caller{-name} is primary key

######## / pseudo-global variables ########

#----------------------------------------------------------------------------#



######## INTERNAL ROUTINE ########
#
#	_set_caller();		# set %caller to "outside" caller
#		
# Purpose  : Get caller in an invariant fashion
# Parms    : none
# Reads    : caller()
# Returns  : 1
# Writes   : %caller
# Throws   : never
# See also : _prefilter()
# 
# Because builtin caller() sees the stack starting at its previous call, 
#	_set_caller() should only be called once, from _prefilter, and not again. 
# 
# 
sub _set_caller {
	my $frame						= 3;
	my @info						= caller($frame);
	@caller{ -name, -file, -line }	= @info;
	
#	for my $frame (0..4) {
#		my @caller_info		= caller $frame;
#		no warnings;
#		say "($frame): ", join "\t\n", 
#			$caller_info[0], $caller_info[1], $caller_info[2], ;
#		use warnings;
#	};
	
	return 1;
};
######## /_set_caller ########

######## INTERNAL ROUTINE ########
#
#	my $outfh		= _get_outfh();		# retrieve from %state_of
#		
# Purpose  : Retrieve output filehandle
# Parms    : none
# Reads    : %state_of, %caller
# Returns  : stored filehandle for all output
# Writes   : none
# Throws   : ____
# See also : _set_caller(), 
# 
# ____
# 
sub _get_outfh {
	return $state_of{ $caller{-name} }{ -outfh };
	
};
######## /_do_ ########

######## INTERNAL ROUTINE ########
#
#	$intro		= _prefilter(@_);		# Handle arguments to FILTER
#		
# Purpose  : Handle arguments and do pseudo-global setup
# Parms    : @_
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# ____
# 
sub _prefilter {
	
	shift;		# Don't need our own package name
	s/\r\n/\n/g;  # Handle win32 line endings
	
	_set_caller();		# set %caller to "outside" caller
		
	# Default introducer pattern...
	my $intro = qr/#{3,}/;
	my @intros;
	
	
	## Handle the ::Any setup
	
	my $fh_seen		= 0;			# no filehandle seen yet
	my $outfh		= *STDERR;		# default
	my $arg			;				# trial from @_
	
	# Dig through the args to see if one is a filehandle
	SETFH:
	for my $i ( 0..$#_ ) {			# will need the index in a bit
		$arg			= $_[$i];
		
		# Is $arg defined by vanilla Smart::Comments?
		if ( $arg eq '-ENV' || (substr $arg, 0, 1) eq '#' ) {
			next SETFH;				# not ::Any arg, keep looking
		};
#		print 'Mine: >', $arg, "<\n";
		
		# Vanilla doesn't want to see it, so remove from @_
		splice @_, $i;
		
		# Is it a writable filehandle?
		if ( not -w $arg ) {
			carp   q{Not a writable filehandle: }
				. qq{$arg} 
				.  q{ in call to 'use Smart::Comments::Any'.}
				;
		}							# and keep looking
		else {
			$outfh		= $arg;
			last SETFH;				# found, so we're done looking
		};
	};
	
	# Stash $outfh as caller-dependent state info
	$state_of{ $caller{-name} }{ -outfh }	= $outfh;
	
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

	return $intro;
};
######## /_prefilter ########

sub import;		# FORWARD

######## EXTERNAL SUB CALL ########
#
# Purpose  : Rewrite caller's smart comments into code
# Parms    : 
#			 @_		: The split use line, with $_[0] being *this* package
# 			 $_		: Caller's entire source code to be filtered
# Reads    : ____
# Returns  : $_		: Filtered code
# Writes   : ____
# Throws   : ____
# See also : Filter::Simple
# 
# Implement comments-to-code source filter. 
#
# This is not a subroutine but a call to Filter::Simple::FILTER
#	with its single argument being its following block. 
# 
# The block may be thought of as an import routine 
#	which is passed @_ and $_ and must return the filtered code in $_
#
# Note (if our module is invoked properly via use): 
# From caller's viewpoint, use operates as a BEGIN block, 
# 	including all our-module inline code and this call to FILTER;
# 		while filtered-in calls to our-module subs take place at run time. 
# From our viewpoint, our inline code, including FILTER, 
#	is run after any BEGIN or use in our module;
#		and filtered-in subs may be viewed 
#		as if they were externally called subs in a normal module. 
# Because FILTER is called as part of a constructed import routine, 
#	it executes every time our module is use()-ed, 
# 	although other inline code in our module only executes one time only, 
#	when first use()-ed. 
# 
# See "How it works" in Filter::Simple's POD. 
# 
FILTER {
	#### @_
	#### $_
	
	
	my $intro		= _prefilter(@_);		# Handle arguments to FILTER
	return 0 if !$intro;   # i.e. if no filtering ABORT
	
	my $outfh		= _get_outfh();		# retrieve from %state_of

	# Preserve DATA handle if any...
	if (s{ ^ __DATA__ \s* $ (.*) \z }{}xms) {
		no strict qw< refs >;
		my $DATA = $1;
		open *{caller(1).'::DATA'}, '<', \$DATA or die "Internal error: $!";
	}
	
	# Progress bar on a for loop...
	s{ ^ $hws* ( (?: [^\W\d]\w*: \s*)? for(?:each)? \s* (?:my)? \s* (?:\$ [^\W\d]\w*)? \s* ) \( ([^;\n]*?) \) \s* \{
			[ \t]* $intro \s (.*) \s* $
	 }
	 { _decode_for($1, $2, $3) }xgem;

	# Progress bar on a while loop...
	s{ ^ $hws* ( (?: [^\W\d]\w*: \s*)? (?:while|until) \s* \( .*? \) \s* ) \{
			[ \t]* $intro \s (.*) \s* $
	 }
	 { _decode_while($1, $2) }xgem;

	# Progress bar on a C-style for loop...
	s{ ^ $hws* ( (?: [^\W\d]\w*: \s*)? for \s* \( .*? ; .*? ; .*? \) \s* ) \{
			$hws* $intro $hws (.*) $hws* $
	 }
	 { _decode_while($1, $2) }xgem;

	# Requirements...
	s{ ^ $hws* $intro [ \t] $require : \s* (.*?) $optcolon $hws* $ }
	 { _decode_assert($1,"fatal") }gemx;

	# Assertions...
	s{ ^ $hws* $intro [ \t] $check : \s* (.*?) $optcolon $hws* $ }
	 { _decode_assert($1) }gemx;

	# Any other smart comment is a simple dump.
	# Dump a raw scalar (the varname is used as the label)...
	s{ ^ $hws* $intro [ \t]+ (\$ [\w:]* \w) $optcolon $hws* $ }
	 {Smart::Comments::Any::_Dump(pref=>q{$1:},var=>[$1]);$DBX}gmx;

	# Dump a labelled scalar...
	s{ ^ $hws* $intro [ \t] (.+ :) [ \t]* (\$ [\w:]* \w) $optcolon $hws* $ }
	 {Smart::Comments::Any::_Dump(pref=>q{$1},var=>[$2]);$DBX}gmx;

	# Dump a raw hash or array (the varname is used as the label)...
	s{ ^ $hws* $intro [ \t]+ ([\@%] [\w:]* \w) $optcolon $hws* $ }
	 {Smart::Comments::Any::_Dump(pref=>q{$1:},var=>[\\$1]);$DBX}gmx;

	# Dump a labelled hash or array...
	s{ ^ $hws* $intro [ \t]+ (.+ :) [ \t]* ([\@%] [\w:]* \w) $optcolon $hws* $ }
	 {Smart::Comments::Any::_Dump(pref=>q{$1},var=>[\\$2]);$DBX}gmx;

	# Dump a labelled expression...
	s{ ^ $hws* $intro [ \t]+ (.+ :) (.+) }
	 {Smart::Comments::Any::_Dump(pref=>q{$1},var=>[$2]);$DBX}gmx;

	# Dump an 'in progress' message
	s{ ^ $hws* $intro $hws* (.+ [.]{3}) $hws* $ }
	 {Smart::Comments::Any::_Dump(pref=>qq{$1});$DBX}gmx;

	# Dump an unlabelled expression (the expression is used as the label)...
	s{ ^ $hws* $intro $hws* (.*) $optcolon $hws* $ }
	 {Smart::Comments::Any::_Dump(pref=>q{$1:},var=>Smart::Comments::Any::_quiet_eval(q{[$1]}));$DBX}gmx;

# This doesn't work as expected, don't know why
#	# An empty comment dumps an empty line...
#	s{ ^ $hws* $intro [ \t]+ $ }
#	 {warn qq{\n};}gmx;

# This is never needed; for some reason it's caught by "unlabeled expression"
#	# Anything else is a literal string to be printed...
#	s{ ^ $hws* $intro $hws* (.*) }
#	 {Smart::Comments::Any::_Dump(pref=>q{$1});$DBX}gmx;
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
#	*before* the call to FILTER. 
# However, Filter::Simple will call import()
#	*after* applying FILTER to caller's source code. 
#	
sub import {
	
#	say 'Smart::Comments::Any::import().';
	
};
######## /import ########

#============================================================================#

######## REPLACEMENT CODE ########
#
#	_Dump( _quiet_eval($codestring) );		# string eval, no errors
#		
# Purpose  : String eval some code and suppress any errors
# Parms    : $codestring	: Arbitrary client code
# Reads, Returns, Writes  	: Whatever client code does
# Throws   : nothing, ever
# See also : FILTER # Dump an unlabelled expression
#	
sub _quiet_eval {
	local $SIG{__WARN__} = sub{};
	return scalar eval shift;
};
######## /_quiet_eval ########

######## INTERNAL ROUTINE ########
#
#	_uniq();		# short
#		
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : _decode_assert
# 
#	
sub _uniq { 
	my %seen; 
	grep { !$seen{$_}++ } @_ 
};
######## /_uniq ########

######## REPLACEMENT CODE ########
#
#	_decode_assert();		# short
#		
# Purpose  : Converts an assertion to the equivalent Perl code.
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : FILTER # Requirements, # Assertions
# 
#	
sub _decode_assert {
	my ($assertion, $signal_flag) = @_;

	# Choose the right signalling mechanism...
	my $signal_code = $signal_flag ? 'die "\n"' : 'warn "\n"';

	my $dump = 'Smart::Comments::Any::_Dump';

	# Extract variables from assertion and enreference any arrays or hashes...
	my @vars = map { /^$hws*[%\@]/ ? "$dump(pref=>q{    $_ was:},var=>[\\$_], nonl=>1);"
								   : "$dump(pref=>q{    $_ was:},var=>[$_],nonl=>1);"
				   }
				_uniq extract_multiple($assertion, [\&extract_variable], undef, 1);

	# Generate the test-and-report code...
	return 	qq<unless($assertion)>
		.	qq<{>
		.		qq<warn "\\n", q{### $assertion was not true};>
		.		qq<@vars;>
		.		qq<$signal_code>
		.	qq<}>
		;
};
######## /_decode_assert ########

######## REPLACEMENT CODE ########
#
#	_decode_for();		# short
#		
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# Generate progress-bar code for a Perlish for loop...
#	
sub _decode_for {
	my ($for, $range, $mesg) = @_;

	# Give the loop a unique ID...
	$ID++;

	# Rewrite the loop with a progress bar as its first statement...
	return 	qq<my \$not_first__$ID;>
		.	qq<$for (my \@SmartComments__range__$ID = $range)>
		.	qq<{>		# closing brace found somewhere in client code
		.	qq<Smart::Comments::Any::_for_progress(>
		.		qq<qq{$mesg},>
		.		qq<\$not_first__$ID,>
		.		qq<\\\@SmartComments__range__$ID>
		.	qq<);>
		;
};
######## /_decode_for ########

######## REPLACEMENT CODE ########
#
#	_decode_while();		# short
#		
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# Generate progress-bar code for a Perlish while loop...
#	
sub _decode_while {
	my ($while, $mesg) = @_;

	# Give the loop a unique ID...
	$ID++;

	# Rewrite the loop with a progress bar as its first statement...
	return 	qq<my \$not_first__$ID;>
		.	qq<$while>
		.	qq<{>		# closing brace found somewhere in client code
		.	qq<Smart::Comments::Any::_while_progress(>
		.		qq<qq{$mesg},>
		.		qq<\\\$not_first__$ID>
		.	qq<);>
		.	qq<>
		;
};
######## /_decode_while ########

######## INTERNAL ROUTINE ########
#
#	_desc_time();		# short
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
	my $hours = int($seconds/3600);	$seconds -= 3600*$hours;
	my $minutes = int($seconds/60);	$seconds -= 60*$minutes;
	my $remaining;

	# Describe hours to the nearest half-hour (and say how close to it)...
	if ($hours) {
		$remaining =
		  $minutes < 5   ? "about $hours hour".($hours==1?"":"s")
		: $minutes < 25  ? "less than $hours.5 hours"
		: $minutes < 35  ? "about $hours.5 hours"
		: $minutes < 55  ? "less than ".($hours+1)." hours"
		:				  "about ".($hours+1)." hours";
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
#	_moving_average();		# short
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
#	_prog_pat();		# short
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

######## INTERNAL ROUTINE ########
#
#	_for_progress();		# short
#		
# Purpose  : ____
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : ____
# 
# Animate the progress bar of a for loop...
#	
sub _for_progress {
	my ($mesg, $not_first, $data) = @_;
	my ($at, $max, $elapsed, $remaining, $fraction);

	# Update progress bar...
	if ($not_first) {
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
		# Start at the beginning...
		$at = $count{$data} = 0;

		# Work out where the end will be...
		$max = $max{$data} = $#$data;

		# Start the clock...
		$started{$data} = time;
		$elapsed = 0;
		$fraction = 0;

		# After which, it will no longer be the first iteration.
		$_[1] = 1;  # $not_first
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
					:			 $fillwidth*$fraction-$leaderwidth;
		$fillend = 0 if $fillend < 0;

		# Now draw the bar, using carriage returns to overwrite it...
		print STDERR "\r", " "x$maxwidth,
					 "\r", $left,
					 sprintf("%-${fillwidth}s",
							   substr($totalfill, 0, $fillend)
							 . $leader),
					 $right;

		# Work out whether to show an ETA estimate...
		if ($elapsed >= $showstarttime &&
			$at < $max &&
			($showing{$data} || $remaining && $remaining >= $showmaxtime)
		) {
			print STDERR "  (", _desc_time($remaining), " remaining)";
			$showing{$data} = 1;
		}

		# Close off the line, if we're finished...
		print STDERR "\r", " "x$maxwidth, "\n" if $at >= $max;
	}
};
######## /_for_progress ########

######## INTERNAL ROUTINE ########
#
#	_while_progress();		# short
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
sub _while_progress {
	my ($mesg, $not_first_ref) = @_;
	my $at;
#say '$prev_length: ', $prev_length;
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
		print STDERR "\r", " "x$maxwidth,
					 "\r", $left,
					 sprintf("%-${fillwidth}s", substr($fill x $fillwidth, 0, $length) . $leader),
					 $right;
	}
};
######## /_while_progress ########

######## INTERNAL ROUTINE ########
#
#	_Dump();		# short
#		
# Purpose  : Dump a variable (any variable?)
# Parms    : ____
# Reads    : ____
# Returns  : ____
# Writes   : ____
# Throws   : ____
# See also : Data::Dumper, FILTER # Any other smart comment is a simple dump
# 
# Dump a variable and then reformat the resulting string more prettily...
#	
sub _Dump {
	
	my $outfh		= _get_outfh();		# retrieve from %state_of
	
	my %args = @_;
	my ($pref, $varref, $nonl) = @args{qw(pref var nonl)};

	# Handle timestamps...
	my (undef, $file, $line) = caller;
	$pref =~ s/<(?:now|time|when)>/scalar localtime()/ge;
	$pref =~ s/<(?:here|place|where)>/"$file", line $line/g;

	# Add a newline?
	my @caller = caller;
	my $spacer_required
		=  $prev_STDOUT != tell(*STDOUT)
		|| $prev_STDERR != tell(*STDERR)
		|| $prev_caller{file} ne $caller[1]
		|| $prev_caller{line} != $caller[2]-1;
	$spacer_required &&= !$nonl;
	@prev_caller{qw<file line>} = @caller[1,2];

	# Handle a prefix with no actual variable...
	if ($pref && !defined $varref) {
		$pref =~ s/:$//;
		print $outfh "\n" if $spacer_required;
		print $outfh "### $pref\n";
		$prev_STDOUT = tell(*STDOUT);
		$prev_STDERR = tell(*STDERR);
		return;
	}

	# Set Data::Dumper up for a tidy dump and do the dump...
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Sortkeys  = 1;
	local $Data::Dumper::Indent	= 2;
	my $dumped = Dumper $varref;

	# Clean up the results...
	$dumped =~ s/\$VAR1 = \[\n//;
	$dumped =~ s/\s*\];\s*$//;
	$dumped =~ s/\A(\s*)//;

	# How much to shave off and put back on each line...
	my $indent  = length $1;
	my $outdent = " " x (length($pref) + 1);

	# Report "inside-out" and "flyweight" objects more cleanly...
	$dumped =~ s{bless[(] do[{]\\[(]my \$o = undef[)][}], '([^']+)' [)]}
				{<Opaque $1 object (blessed scalar)>}g;

	# Adjust the indents...
	$dumped =~ s/^[ ]{$indent}([ ]*)/### $outdent$1/gm;

	# Print the message...
	print $outfh "\n" if $spacer_required;
	print $outfh "### $pref $dumped\n";
	$prev_STDERR = tell(*STDERR);
	$prev_STDOUT = tell(*STDOUT);
};
######## /_Dump ########


#############################
######## END MODULE #########
1;
__END__

=head1 NAME

Smart::Comments::Any - Smart comments that print to any filehandle


=head1 VERSION

This document describes Smart::Comments::Any version 1.0.4


=head1 SYNOPSIS

	use Smart::Comments::Any;					# acts just like Smart::Comments
	use Smart::Comments::Any '###';				# acts just like Smart::Comments
	use Smart::Comments::Any *STDERR, '###';	# same thing
	
	use Smart::Comments::Any $fh, '###';		# prints to $fh instead
	use Smart::Comments::Any *FH, '###';		# prints to FH instead
	
	BEGIN {								# one way to get $fh open early enough
		my $filename	= 'mylog.txt';
		open my $fh, '>', $filename
			or die "Couldn't open $filename to write", $!;
		use Smart::Comments::Any $fh;
	}
	  
	BEGIN {								# or store $::fh for later use
		my $filename	= 'mylog.txt';
		open my $::fh, '>', $filename
			or die "Couldn't open $filename to write", $!;
	}
	use Smart::Comments::Any $::fh;
	{...}	# do some work
	close $::fh;
	  
=head1 DESCRIPTION

L<Smart::Comments> works well for those who debug with print statements. 
However, it always prints to STDERR. This doesn't work so well when STDERR 
is being captured and tested. 

Smart::Comments::Any acts like Smart::Comments, except that 
if a filehandle is passed in the use statement, output will go there instead. 

Please see L<Smart::Comments> for major documentation. 
Smart::Comments::Any version x.x.x is a modified copy 
of the same version of Smart::Comments. 

=head1 INTERFACE 

=head2 $fh, *FH

The use statement accepts a valid filehandle as its first argument. 
Caller must do whatever is needed to manage that filehandle, 
such as opening and perhaps closing it. 

Note that this module, being a source filter, does its work when 
it is used: effectively, within a BEGIN block. Therefore, this filehandle
must be opened within a BEGIN block prior to the use line. If caller needs 
to do anything else with that filehandle, it might as well be stored 
in a package variable (since source filtering is global anyway). Otherwise, 
enclose the open and the use line in the same BEGIN block. 

The filehandle must be opened, obviously, in some writable mode.  


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
