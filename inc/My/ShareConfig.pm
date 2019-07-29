package My::ShareConfig;

use strict;
use warnings;
use base qw( My::ConfigPl );

sub dir  { File::Spec->catdir( qw( blib lib auto share dist FFI-Platypus )) }
sub file { File::Spec->catfile( shift->dir, qw( config.pl ))                }

1;
