#!/run/bin/perl
#       pack-stash.pl
#       =  Copyright 2010 Xiong Changnian <xiong@sf-id.com>  =
#       = Free Software = Artistic License 2.0 = NO WARRANTY =

use strict;
use warnings;
use feature 'say';

{
	package Teddy::Bear;
}

package main;
no strict 'refs';

my $ns						= 'Teddy::Bear';
my $glob					= *{${ns} . '::foo'};
say '            $glob: ',	$glob;
say '$Teddy::Bear::foo: ', 	$Teddy::Bear::foo;

my $cram					= 'cheese';
say '            $cram: ',	$cram;

${ *{${ns} . '::foo'} }		= $cram;
say '$Teddy::Bear::foo: ', 	$Teddy::Bear::foo;

my $yank					= ${ *{"${ns}\::foo"} };
say '            $yank: ',	$yank;


__DATA__

Output: 

      $glob: *Teddy::foo
Use of uninitialized value $Teddy::foo in say...
$Teddy::foo: 
      $cram: cheese
$Teddy::foo: cheese
      $yank: cheese

__END__
