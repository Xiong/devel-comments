use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::Comments',
    AUTHOR              => 'Xiong Changnian <xiong@sf-id.com>',
    VERSION_FROM        => 'lib/Devel/Comments.pm',
    ABSTRACT_FROM       => 'lib/Devel/Comments.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-Comments-*' },
);
