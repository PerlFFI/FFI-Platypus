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
  foreach my $item (@cleanup)
  {
    if(ref $item eq 'CODE')
    {
      $item->();
    }
    else
    {
      rmtree("$item", { verbose => 0 });
    }
  }
}

1;
