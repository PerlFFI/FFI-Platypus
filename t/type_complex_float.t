use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;

BEGIN {
  plan skip_all => 'test requires support for float complex'
    unless FFI::Platypus::_have_type('complex_float');
}

use FFI::Platypus::Declare
  'complex_float', 'float';

plan tests => 1;

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach ['complex_float_get_real' => 'creal'] => [complex_float] => float;
attach ['complex_float_get_imag' => 'cimag'] => [complex_float] => float;

subtest 'standard argument' => sub {
  plan tests => 2;

  subtest 'with a real number' => sub {
    plan tests => 2;
    is creal(10.5), 10.5, "creal(10.5) = 10.5";
    is cimag(10.5), 0.0,  "cimag(10.5) = 0.0";
  };
  
  subtest 'with an array ref' => sub {
    plan tests => 2;
    is creal([10.5,20.5]), 10.5, "creal([10.5,20.5]) = 10.5";
    is cimag([10.5,20.5]), 20.5, "cimag([10.5,20.5]) = 20.5";
  };
};
