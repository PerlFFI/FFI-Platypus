use strict;
use warnings;
use Test::More tests => 3;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub );

BEGIN {
  my $float  = ffi_type c => 'float';
  my $double = ffi_type c => 'double';
  my $long   = ffi_type c => 'long double';

  my $config = FFI::TestLib->config;
  my $testlib = ffi_lib $config->{lib};
  
  ffi_sub [$testlib], 'pass_thru_float', [$float, $float];
  ffi_sub [$testlib], 'pass_thru_double', [$double, $double];
  ffi_sub [$testlib], 'pass_thru_long_double', [$long, $long];
}

is pass_thru_float(0.0), 0.0, 'pass_thru_float';
is pass_thru_double(12.34), 12.34, 'pass_thru_double';

SKIP: {

  if(ffi_type(c => 'long double')->size > 8)
  {
    diag "long double not yet supported!";
    skip "long double not yet supported!", 1;
  }

is pass_thru_long_double(1.0), 1.0, 'pass_thru_long_double';

}
