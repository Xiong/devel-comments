use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Devel::Comments',
    license             => 'perl',
    dist_author         => 'Xiong Changnian <xiong@sf-id.com>',
    dist_version_from   => 'lib/Devel/Comments.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Devel-Comments-*' ],
);

$builder->create_build_script();
