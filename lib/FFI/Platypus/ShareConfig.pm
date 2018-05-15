package FFI::Platypus::ShareConfig;

use strict;
use warnings;
use File::ShareDir qw( dist_dir );
use File::Spec;
use JSON::PP qw( decode_json );

# VERSION

sub get
{
  my(undef, $name) = @_;
  my $config;

  unless($config)
  {
    my $fn = File::Spec->catfile(dist_dir('FFI-Platypus'), 'config.pl');
    $fn = File::Spec->rel2abs($fn) unless File::Spec->file_name_is_absolute($fn);
    $config = do $fn;
  }
  
  unless($config)
  {
    my $fn = File::Spec->catfile(dist_dir('FFI-Platypus'), 'config.json');
    my $fh;
    open $fh, '<', $fn;
    my $raw = do { local $/; <$fh> };
    close $fh;
    $config = decode_json $raw;
  }
  
  $config->{$name};
}

1;
