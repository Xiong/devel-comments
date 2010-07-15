use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Smart::Comments::Any',
    license             => 'perl',
    dist_author         => 'Xiong Changnian <xiong@sf-id.com>',
    dist_version_from   => 'lib/Smart/Comments/Any.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Smart-Comments-Any-*' ],
);

$builder->create_build_script();
