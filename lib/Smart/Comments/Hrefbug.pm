	package Smart::Comments::Hrefbug;	# CHOPPED ::Hrefbug FOR DEBUG - DO NOT USE
	
	######## use section ########
	use 5.008;
	use strict;
	use warnings;
	use version; our $VERSION = qv('1.0.4');
	
	# original S::C (originally used here)
#~ 	use Carp;
#~ 	use List::Util qw(sum);
	use Filter::Simple;
	
	# collected S::C (originally distributed in code)
#~ 	use Text::Balanced 				# Extract delimited text sequences from strings
#~ 		qw( extract_variable extract_multiple );
#~ 		
#~ 	use Data::Dumper 'Dumper';
	
	# debug only
	use feature 'say';				# disable in production; debug only
#~ 	use Smart::Comments '###';		# playing with fire;     debug only
	
	######## / use ########
	
	## ::Hrefbug stuff
	# "Outside" caller must be available anywhere while filtering
	my %filter_caller	= (
		-name				=> '',		# 'Caller::Module'
		-file				=> '',		# '../lib/Caller/Module.pm'
		-line				=> 0		# 273
	);
	
	# Store per-use (per-caller) state info 
	#	for access by external routines called by replacement code
	my %state_of			;
	#	SomeCaller		=> {			# caller name is primary key
	#		-outfh						# desired output filehandle
	#		-tell			=> {		# stored tell() of...
	#			-outfh					# ... $outfh for real
	#			-stdout					# ... *STDOUT
	#		},
	#		-caller			=> {		# stored caller()...
	#			-name					# ...[0] (= 'SomeCaller')
	#			-file					# ...[1]
	#			-line					# ...[2]
	#		},
	#	},
	#	AnotherCaller...
	
	######## / pseudo-global variables ########
	
	#----------------------------------------------------------------------------#
	
	
	
	######## INTERNAL ROUTINE ########
	#
	#	_set_filter_caller();		# set %filter_caller to "outside" caller
	#		
	# Purpose  : Get caller in an invariant fashion
	# Parms    : none
	# Reads    : caller()
	# Returns  : 1
	# Writes   : %filter_caller
	# Throws   : never
	# See also : _prefilter()
	# 
	# Because builtin caller() sees the stack starting at its previous call, 
	#	_set_filter_caller() should only be called once, 
	#	from _prefilter, and not again. 
	# Note that old S::C code hits caller() directly, 
	#	which may be best when its call is from within replacement code. (???)
	# 
	sub _set_filter_caller {
		# frame
		#	0		_prefilter
		#	1		FILTER
		#	2		Filter::Simple
		#	3		actual use-line caller
		my $frame						= 3;	
		my @info						= caller($frame);
		@filter_caller{ -name, -file, -line }	= @info;
		
	#	for my $frame (0..4) {
	#		my @caller_info		= caller $frame;
	#		no warnings;
	#		say "($frame): ", join "\t\n", 
	#			$caller_info[0], $caller_info[1], $caller_info[2], ;
	#		use warnings;
	#	};
		
		return 1;
	};
	######## /_set_filter_caller ########
	
	######## INTERNAL ROUTINE ########
	#
	#	my $outfh		= _get_outfh($caller_name);	# retrieve from %state_of
	#		
	# Purpose  : Retrieve output filehandle associated with some caller
	# Parms    : $caller_name (optional)
	# Reads    : %state_of, %filter_caller
	# Returns  : stored filehandle for all output
	# Writes   : none
	# Throws   : never
	# See also : _set_filter_caller(), 
	# 
	# If called with no args, defaults to the pseudo-global %filter_caller.
	# 
	sub _get_outfh {
		my $caller_name		= shift || $filter_caller{-name};
		return $state_of{$caller_name}{-outfh};
		
	};
	######## /_do_ ########
	
	######## INTERNAL ROUTINE ########
	#
	#	_init_state($outfh);		# initialize $state_of filter_caller
	#		
	# Purpose  : Initialize state; store $outfh and avoid warnings later
	# Parms    : $outfh
	# Reads    : %filter_caller
	# Returns  : 1
	# Writes   : %state_of
	# Throws   : never
	# See also : _prefilter(), _set_state()
	# 
	# ____
	# 
	sub _init_state {
		my $outfh			= shift;
		my $caller_name		= $filter_caller{-name};
		my $caller_file		= $filter_caller{-file};
		my $caller_line		= $filter_caller{-line};
		
	#say $outfh '... Entering _init_state() ...';
	#say $outfh '... @filter_caller: ', 			     "\n"
	#		,  '...                 ', $caller_name, "\n"
	#		,  '...                 ', $caller_file, "\n" 
	#		,  '...                 ', $caller_line, "\n" 
	#		;
	#say $outfh '$outfh: ', $outfh;	
		
		# Stash $outfh as caller-dependent state info
		$state_of{$caller_name}{-outfh}			= $outfh;
		
		# It may not matter *what* you initialize these to...	
		$state_of{$caller_name}{-tell}{-outfh}	= tell $outfh;
		$state_of{$caller_name}{-tell}{-stdout}	= tell (*STDOUT);
		$state_of{$caller_name}{-caller}{-file}	= $caller_file;
		$state_of{$caller_name}{-caller}{-line}	= $caller_line;
		
	#### Leaving _init_state():
	#### %state_of	
	#my $varref = \%state_of;
	#local $Data::Dumper::Quotekeys = 0;
	#local $Data::Dumper::Sortkeys  = 1;
	#local $Data::Dumper::Indent	= 2;
	#my $dumped = Dumper $varref;
	#say $outfh 'Leaving _init_state():';
	#say $outfh $dumped;
		
		
		return 1;
		
	};
	######## /_init_state ########
	
	######## INTERNAL ROUTINE ########
	#
	#	$intro		= _prefilter(@_);		# Handle arguments to FILTER
	#		
	# Purpose  : Handle arguments and do pseudo-global setup
	# Parms    : @_
	# Reads    : %ENV
	# Returns  : $intro		(or 0 to abort filtering entirely)
	# Writes   : %filter_caller, %state_of
	# Throws   : carp() if passed a bad arg in @_
	# See also : ____
	# 
	# Don't want to be fussy about the order of args passed on the use line, 
	#	so each bit roots through all of them looking for what it wants. 
	# 
	sub _prefilter {
		
		shift;							# Don't need our own package name
		s/\r\n/\n/g;  					# Handle win32 line endings
		
		_set_filter_caller();			# set %filter_caller to "outside" caller
			
		# Default introducer pattern...
		my $intro 		= qr/#{3,}/;
		my @intros		;
		
		## Handle the ::Hrefbug setup
		
		my $fh_seen			= 0;			# no filehandle seen yet
		my $outfh			= *STDERR;		# default
		my $out_filename	= "$0.log";		# default
		my $arg				;				# trial from @_
		my %packed_args		;				# possible args packed into a hashref
		
		# Dig through the args to see if one is a hashref
		GETHREF:
		for my $i ( 0..$#_ ) {			# will need the index in a bit
			$arg			= $_[$i];	# look but don't take
			
			if ( ref $arg ) {				# some kind of reference
				my $stringy		= sprintf $arg;
				if ( $stringy =~ /HASH/ ) {	# looks like a hash ref
					%packed_args	= %$arg;
					if ( defined $packed_args{-file} ) {
						$out_filename	= $packed_args{-file};
					};	# else if undef, use default
					splice @_, $i;			# remove the parsed arg
	#say '$out_filename: ', $out_filename;		
					open $outfh, '>', $out_filename
						or die "Smart::Comments::Hrefbug: " 
							,  "Can't open $out_filename to write."
							, $!
							;
	say $outfh '... Just after opening $outfh ...';
	say $outfh '$outfh: ', $outfh;	
				};
			};
		
return 0;	
		};		# /GETHREF
		
	};
	######## /_prefilter ########
	
	######## EXTERNAL SUB CALL ########
	#
	# Purpose  : Rewrite caller's smart comments into code
	# Parms    : @_		: The split use line, with $_[0] being *this* package
	# 		   : $_		: Caller's entire source code to be filtered
	# Reads    : %ENV, %state_of
	# Returns  : $_		: Filtered code
	# Writes   : %filter_caller, %state_of
	# Throws   : never
	# See also : Filter::Simple, _prefilter()
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
	sub FILTERx;	# dummy sub only to appear in editor's symbol table
	#
	FILTER {
		### @_
		### $_
		
		
		my $intro		= _prefilter(@_);		# Handle arguments to FILTER
		return 0 if !$intro;   					# i.e. if no filtering ABORT
		
	}; 
	######## /FILTER ########
	
	1;
	__END__
