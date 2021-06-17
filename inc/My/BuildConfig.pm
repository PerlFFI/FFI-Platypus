package My::BuildConfig;

use strict;
use warnings;
use File::Spec ();
use parent qw( My::ConfigPl );

sub dir  { File::Spec->catdir( qw( _mm ))                    }
sub file { File::Spec->catfile( shift->dir, qw( config.pl )) }

1;
