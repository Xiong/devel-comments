#!/run/bin/perl
#       namespace.pl
#       =  Copyright 2010 Xiong Changnian <xiong@sf-id.com>  =
#       = Free Software = Artistic License 2.0 = NO WARRANTY =

use strict;
use warnings;
use feature 'say';

{
	package Teddy::Yum;
	sub say_caller {
		my $caller = caller;
		say '    $caller: ',	$caller;
	};
}

package main;
my $ns					= 'Teddy::Yum::';
my $sym					= 'foo';
Teddy::Yum::say_caller;

{
	say '$Teddy::Yum::foo: ', 	$Teddy::Yum::foo;

	my $cram				= 'cheese';
	say '      $cram: ',	$cram;

#	${ $::{$ns}{foo} }		= $cram;
	${ $::{$ns}{$sym} }		= $cram;
	say '$Teddy::Yum::foo: ', 	$Teddy::Yum::foo;
}

{
	my $yank				= ${ $::{$ns}{foo} };
	say '      $yank: ',	$yank;
}

__DATA__

Output: 

      $glob: *Teddy::Yum::foo
Use of uninitialized value $Teddy::Yum::foo in say...
$Teddy::Yum::foo: 
      $cram: cheese
$Teddy::Yum::foo: cheese
      $yank: cheese

__END__
