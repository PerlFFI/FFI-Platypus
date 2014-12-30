package My::AutoConf;

use strict;
use warnings;
use Config::AutoConf;
use Config;
use File::Spec;
use FindBin;

my $root = $FindBin::Bin;

sub build_configure
{
  my($mb) = @_;
  
  my $ac = Config::AutoConf->new;

  $ac->check_cc;
  $ac->check_header('dlfcn.h');
  foreach my $lib (map { s/^-l//; $_ } split /\s+/, $Config{perllibs})
  {
    if($ac->check_lib($lib, 'dlopen'))
    {
      last;
    }
  }
  $ac->write_config_h( File::Spec->rel2abs( File::Spec->catfile( 'xs', 'ffi_platypus_config.h' )));
}

1;
