package My::AutoConf;

use strict;
use warnings;
use Config::AutoConf;
use Config;
use File::Spec;
use FindBin;

my $root = $FindBin::Bin;

my $prologue = <<EOF;
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#endif
EOF

sub build_configure
{
  my($mb) = @_;
  
  my $ac = Config::AutoConf->new;

  $ac->check_prog_cc;
  $ac->check_header('dlfcn.h');
  
  if($ac->check_decl('RTLD_LAZY', { prologue => $prologue }))
  {
    $ac->define_var( HAVE_RTLD_LAZY => 1 );
  }
  
  foreach my $lib (map { s/^-l//; $_ } split /\s+/, $Config{perllibs})
  {
    if($ac->check_lib($lib, 'dlopen'))
    {
      $ac->define_var( 'HAVE_dlopen' => 1 );
      last;
    }
  }
  $ac->write_config_h( File::Spec->rel2abs( File::Spec->catfile( 'xs', 'ffi_platypus_config.h' )));
}

1;
