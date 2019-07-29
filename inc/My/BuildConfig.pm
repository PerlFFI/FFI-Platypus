package My::BuildConfig;

use strict;
use warnings;
use base qw( My::ConfigPl );

sub dir  { File::Spec->catdir( qw( _mm ))                    }
sub file { File::Spec->catfile( shift->dir, qw( config.pl )) }

1;
