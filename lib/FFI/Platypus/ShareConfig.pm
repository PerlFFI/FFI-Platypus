package FFI::Platypus::ShareConfig;

use strict;
use warnings;
use File::Spec;

# VERSION

sub dist_dir ($)
{
  my($dist_name) = @_;

  my @pm = split /-/, $dist_name;
  $pm[-1] .= ".pm";

  foreach my $inc (@INC)
  {
    if(-f File::Spec->catfile($inc, @pm))
    {
      my $share = File::Spec->catdir($inc, qw( auto share dist ), $dist_name );
      if(-d $share)
      {
        return File::Spec->rel2abs($share);
      }
      last;
    }
  }
  Carp::croak("unable to find dist share directory for $dist_name");
}

sub get
{
  my(undef, $name) = @_;
  my $config;

  unless($config)
  {
    my $fn = File::Spec->catfile(dist_dir('FFI-Platypus'), 'config.pl');
    $fn = File::Spec->rel2abs($fn) unless File::Spec->file_name_is_absolute($fn);
    local $@;
    unless($config = do $fn)
    {
      die "couldn't parse configuration $fn $@" if $@;
      die "couldn't do $fn $!"                  if $!;
      die "bad or missing config file $fn";
    };
  }

  defined $name ? $config->{$name} : $config;
}

1;
