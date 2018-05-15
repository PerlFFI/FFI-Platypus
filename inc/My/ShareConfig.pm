package My::ShareConfig;

use strict;
use warnings;
use Data::Dumper ();

sub new
{
  my $data;
  if(-e 'share/config.pl')
  {
    $data = do "./share/config.pl";
  }
  bless { data => $data }, __PACKAGE__;
}

sub get
{
  my($self, $name) = @_;
  $self->{data}->{$name};
}

sub set
{
  my($self, $name, $value) = @_;
  $self->{data}->{$name} = $value;

  my $dd = Data::Dumper->new([$self->{data}])
    ->Indent(1)
    ->Terse(1)
    ->Sortkeys(1)
    ->Dump;

  my $fh;
  open($fh, '>', 'share/config.pl') || die "error writing share/config.pl";
  print $fh $dd;
  close $fh;
}

1;
