use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Smart::Comments::Any',
    AUTHOR              => 'Xiong Changnian <xiong@sf-id.com>',
    VERSION_FROM        => 'lib/Smart/Comments/Any.pm',
    ABSTRACT_FROM       => 'lib/Smart/Comments/Any.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Smart-Comments-Any-*' },
);
