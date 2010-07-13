#!/run/bin/perl

use strict;
use warnings;

use Smart::Comments;	# Enable special comments for debugging and reporting

my $data_structure = {
    a => [ 1, 2, 3 ],
    b => [
        { X => 1, Y => 2 },
        {
            X => [ 1, 2, 3 ],
            Y => [ 4, 5, 6 ],
            Z => [ 7, 8, 9 ]
        },
    ],
};

						### $data_structure
__END__

=for output

### $data_structure: {
###                    a => [
###                           1,
###                           2,
###                           3
###                         ],
###                    b => [
###                           {
###                             X => 1,
###                             Y => 2
###                           },
###                           {
###                             X => [
###                                    1,
###                                    2,
###                                    3
###                                  ],
###                             Y => [
###                                    4,
###                                    5,
###                                    6
###                                  ],
###                             Z => [
###                                    7,
###                                    8,
###                                    9
###                                  ]
###                           }
###                         ]
###                  }

=cut
