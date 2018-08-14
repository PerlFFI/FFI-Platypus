use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;

BEGIN {
  plan skip_all => 'Test requires support for double complex'
    unless FFI::Platypus::_have_type('complex_double');
}

use FFI::Platypus::Declare
  'complex_double', 'double', 'string';

lib find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

attach ['complex_double_get_real' => 'creal'] => [complex_double] => double;
attach ['complex_double_get_imag' => 'cimag'] => [complex_double] => double;
attach ['complex_double_to_string' => 'to_string'] => [complex_double] => string;

subtest 'standard argument' => sub {
  subtest 'with a real number' => sub {
    note "to_string(10.5) = ", to_string(10.5);
    is creal(10.5), 10.5, "creal(10.5) = 10.5";
    is cimag(10.5), 0.0,  "cimag(10.5) = 0.0";
  };
  
  subtest 'with an array ref' => sub {
    note "to_string([10.5,20.5]) = ", to_string([10.5,20.5]);
    is creal([10.5,20.5]), 10.5, "creal([10.5,20.5]) = 10.5";
    is cimag([10.5,20.5]), 20.5, "cimag([10.5,20.5]) = 20.5";
  };
  
  subtest 'with Math::Complex' => sub {
    plan skip_all => 'test requires Math::Complex'
      unless eval q{ use Math::Complex (); 1 };
    my $c = Math::Complex->make(10.5, 20.5);
    note "to_string(\$c) = ", to_string($c);
    is creal($c), 10.5, "creal(\$c) = 10.5";
    is cimag($c), 20.5, "cimag(\$c) = 20.5";
  };
};

done_testing;
