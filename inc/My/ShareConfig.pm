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
  bless \%data, __PACKAGE__;
}

sub get
{
  my($self, $name) = @_;
  $self->{$name};
}

sub set
{
  my($self, $name, $value) = @_;
  $self->{$name} = $value;
  my %data = %$self;
  my $data = JSON::PP->new->pretty->encode(\%data);
  my $fh;
  open($fh, '>', 'share/config.json');
  print $fh $data;
  close $fh;
}

1;
