#!/run/bin/perl
#       namespace.pl
#       =  Copyright 2010 Xiong Changnian <xiong@sf-id.com>  =
#       = Free Software = Artistic License 2.0 = NO WARRANTY =

use strict;
use warnings;
use feature 'say';

{
	package Teddy;
}

package main;
no strict 'refs';

my $ns					= 'Teddy';
my $glob				= *{${ns} . '::foo'};
say '      $glob: ',	$glob;
say '$Teddy::foo: ', 	$Teddy::foo;

my $cram				= 'cheese';
say '      $cram: ',	$cram;

${ *{${ns} . '::foo'} }	= $cram;
say '$Teddy::foo: ', 	$Teddy::foo;

my $yank				= ${ *{"${ns}\::foo"} };
say '      $yank: ',	$yank;


__DATA__

Output: 

      $glob: *Teddy::foo
Use of uninitialized value $Teddy::foo in say...
$Teddy::foo: 
      $cram: cheese
$Teddy::foo: cheese
      $yank: cheese

__END__
