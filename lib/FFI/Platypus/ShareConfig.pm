package FFI::Platypus::ShareConfig;

use strict;
use warnings;
use File::ShareDir qw( dist_dir );
use File::Spec;

# VERSION

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
  
  $config->{$name};
}

1;
