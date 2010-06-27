#!/run/bin/perl

use lib qw{
	      lib
	   ../lib
	../../lib
	 hump/lib
	      run/t
	   ../run/t
	../../run/t
	 hump/run/t
};

#use Smart::Comments '###';

use Test::More tests => 6;
use Test::Deep;

use Devel::Hump::Base;

ok( 
	$obj		= Devel::Hump::Base->new(),
	'dh-base-new-empty' 
);

@good_args		= ( 'foo', 'bar' );
$expected		= bless( { foo => 'bar' }, 'Devel::Hump::Base' );

ok( 
	$obj		= Devel::Hump::Base->new( @good_args ),
	'dh-base-new-good' 
);

$got			= $obj;

#### $got
cmp_deeply( 
	$got, $expected,
	'dh-base-new-got'
);

@bad_args		= ( 'foo', 'bar', 'baz' );

eval {
		$obj		= Devel::Hump::Base->new( @bad_args )
};

ok( $@,
	'dh-base-new-bad' 
);

package Devel::Hump::Base::Acme;
use parent qw{ Devel::Hump::Base };

package main;
#use Devel::Hump::Base::Acme;

@good_args		= ( 'foo', 'bar' );
$expected		= bless( { foo => 'bar' }, 'Devel::Hump::Base::Acme' );

ok( 
	$obj		= Devel::Hump::Base::Acme->new( @good_args ),
	'dh-base-new-subclass' 
);

$got			= $obj;

#### $got
cmp_deeply( 
	$got, $expected,
	'dh-base-new-subclass-got'
);



