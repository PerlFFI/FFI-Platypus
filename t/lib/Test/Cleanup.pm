package Test::Cleanup;

use strict;
use warnings;
use base qw( Exporter );
use File::Path qw( rmtree );

our @EXPORT = qw( cleanup );

my @cleanup;

sub cleanup
{
  push @cleanup, @_;
}

END
{
  foreach my $dir (@cleanup)
  {
    rmtree($dir, { verbose => 0 });
  }
}

1;
