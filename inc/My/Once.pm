package My::Once;

use strict;
use warnings;

my $step;

sub check
{
  (undef, $step) = @_;
  exit if -f "_mm/$step";
}

sub done
{
  mkdir "_mm" unless -d "_mm";
  my $fh;
  open $fh, '>>', "_mm/$step";
  close $fh;
}

1;
