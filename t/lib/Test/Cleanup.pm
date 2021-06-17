package Test::Cleanup;

use strict;
use warnings;
use Exporter qw( import );
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
