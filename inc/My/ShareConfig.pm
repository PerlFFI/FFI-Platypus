package My::ShareConfig;

use strict;
use warnings;
use JSON::PP;

sub new
{
  my %data;
  if(-e 'share/config.json')
  {
    %data = %{
      JSON::PP->new->decode(do {
        local $/;
        my $fh;
        open $fh, '<', 'share/config.json';
        my $data = <$fh>;
        close $fh;
        $data;
      })
    };
  }
  bless { data => \%data }, __PACKAGE__;
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

  my $json = JSON::PP->new->canonical->pretty->encode($self->{data});
  my $fh;
  open($fh, '>', 'share/config.json');
  print $fh $json;
  close $fh;
}

1;
