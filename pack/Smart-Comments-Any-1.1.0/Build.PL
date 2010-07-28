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




use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Smart::Comments::Any',
    license             => 'perl',
    dist_author         => 'Xiong Changnian <xiong@sf-id.com>',
    dist_version_from   => 'lib/Smart/Comments.pm',
    requires => {
        'version'        => 0,
        'Text::Balanced' => 2.0,
        'Data::Dumper'   => 0,
        'Filter::Simple' => 0.80,
        'List::Util'     => 0,
        'Carp'           => 0,
        'perl'           => 5.008,
    },
    build_requires => {
        'Test::More'     => 0,
    },
    meta_merge => {
        resources=> {
            repository => 'http://github.com/chorny/smart-comments/tree/master',
        },
        keywords => ['Smart comments','perl debugging','development'],
    },
);

$builder->create_build_script();
