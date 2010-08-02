use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Devel::Comments',
    license             => 'perl',
    dist_author         => 'Xiong Changnian <XIONG@cpan.org>',
    dist_version_from   => 'lib/Devel/Comments.pm',
    requires => {
        'perl'           => 5.008,
        'version'        => 0.77,
        'Text::Balanced' => 2.0,
        'Data::Dumper'   => 0,
        'Filter::Simple' => 0.80,
        'List::Util'     => 0,
    },
    build_requires => {
        'Test::More'     => 0.94,
    },
    add_to_cleanup      => [ 'Devel-Comments-*' ],
    meta_merge => {
        resources=> {
            repository => 'http://github.com/Xiong/devel-comments',
        },
        keywords => [
            'source filter', 
            'smart comments',
            'perl debugging',
            'development'
        ],
    },
);

$builder->create_build_script();

