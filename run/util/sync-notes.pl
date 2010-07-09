#!/run/bin/perl
#       sync-notes.pl
#       = Copyright 2010 Xiong Changnian <xiong@xuefang.com> =
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
#~ use Smart::Comments '###', '####';

#
my $base_dirabs     = q{/home/xiong/projects/smartlog/};
my $main_dirrel     = q{notes};
my $perm_prefix     = q{.};
my $perm_dirrel     = $perm_prefix . $main_dirrel;
my $main_dirabs     = $base_dirabs . $main_dirrel;
my $perm_dirabs     = $base_dirabs . $perm_dirrel;

### $main_dirabs
### $perm_dirabs

my $rsync_cmd       = q{rsync};
#~ my $rsync_opts      = q{-nrutv};        # dry run
my $rsync_opts      = q{-rutv};         # recursive; update; keep times; verbose
my $bash_allfiles  = q{/*};             # plain dir1 dir2 makes a new dir2/dir1 

my $perm_to_main    = join q{ }, 
    $rsync_cmd, 
    $rsync_opts, 
    $perm_dirabs . $bash_allfiles,
    $main_dirabs,
    ;

my $main_to_perm    = join q{ }, 
    $rsync_cmd, 
    $rsync_opts, 
    $main_dirabs . $bash_allfiles,
    $perm_dirabs,
    ;

### $perm_to_main
### $main_to_perm

say qq{$0: Synching now...};
say q{--------------------------------------------------------};
say qq{$0: perm_to_main};
say      `$perm_to_main`;
say q{--------------------------------------------------------};
say qq{$0: main_to_perm};
say      `$main_to_perm`;
say q{};

__DATA__

Output: 


__END__
