#!/run/bin/perl -l
use strict;
use warnings;

my $ns = 'Teddy::';

${ $::{$ns}{foo} } = 'cheese';
print '$Teddy::foo: ', $Teddy::foo;

# or the other way round
$Teddy::foo = 'bar';
print '${ $::{$ns}{foo} }: ', ${ $::{$ns}{foo} };

__END__
$Teddy::foo: cheese
${ $::{$ns}{foo} }: bar

