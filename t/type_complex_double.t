use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::TypeParser;
use FFI::CheckLib;

BEGIN {
  plan skip_all => 'Test requires support for double complex'
    unless FFI::Platypus::TypeParser->have_type('complex_double');
}

foreach my $api (0, 1)
{

  subtest "api = $api" => sub {

    local $SIG{__WARN__} = sub {
        my $message = shift;
        return if $message =~ /^Subroutine main::.* redefined/;
        warn $message;
    };

    my $ffi = FFI::Platypus->new( api => $api, experimental => 1 );
    $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');

    $ffi->attach(['complex_double_get_real' => 'creal'] => ['complex_double'] => 'double');
    $ffi->attach(['complex_double_get_imag' => 'cimag'] => ['complex_double'] => 'double');
    $ffi->attach(['complex_double_to_string' => 'to_string'] => ['complex_double'] => 'string');

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

    $ffi->attach(['complex_double_ptr_get_real' => 'creal_ptr'] => ['complex_double *'] => 'double');
    $ffi->attach(['complex_double_ptr_get_imag' => 'cimag_ptr'] => ['complex_double *'] => 'double');
    $ffi->attach(['complex_double_ptr_set' => 'complex_set'] => ['complex_double *','double','double'] => 'void');

    subtest 'pointer argument' => sub {
      subtest 'with a real number' => sub {
        note "to_string(10.5) = ", to_string(10.5);
        is creal_ptr(\10.5), 10.5, "creal_ptr(\\10.5) = 10.5";
        is cimag_ptr(\10.5), 0.0,  "cimag_ptr(\\10.5) = 0.0";
      };

      subtest 'with an array ref' => sub {
        note "to_string([10.5,20.5]) = ", to_string([10.5,20.5]);
        is creal_ptr(\[10.5,20.5]), 10.5, "creal_ptr(\\[10.5,20.5]) = 10.5";
        is cimag_ptr(\[10.5,20.5]), 20.5, "cimag_ptr(\\[10.5,20.5]) = 20.5";
      };

      subtest 'with Math::Complex' => sub {
        plan skip_all => 'test requires Math::Complex'
          unless eval q{ use Math::Complex (); 1 };
        my $c = Math::Complex->make(10.5, 20.5);
        note "to_string(\$c) = ", to_string($c);
        is creal_ptr(\$c), 10.5, "creal_ptr(\\$c) = 10.5";
        is cimag_ptr(\$c), 20.5, "cimag_ptr(\\$c) = 20.5";
      };

      subtest 'values set on out (array)' => sub {
        my @c;
        complex_set(\\@c, 1.0, 2.0);
        note "to_string(\\\@c) = ", to_string(\@c);
        is_deeply \@c, [ 1.0, 2.0 ];
      };

      subtest 'values set on out (object)' => sub {
        plan skip_all => 'test requires Math::Complex'
          unless eval q{ use Math::Complex (); 1 };
        my $c = Math::Complex->make(0.0, 0.0);
        complex_set(\$c, 1.0, 2.0);
        is_deeply( [ $c->Re, $c->Im ], [1.0,2.0] );
      };

      subtest 'values set on out (other)' => sub {
        my $c;
        complex_set(\$c, 1.0, 2.0);
        is_deeply( $c, [1.0, 2.0]);
      };

    };

    $ffi->attach(['pointer_null' => 'complex_null'] => [] => 'complex_double*');
    $ffi->attach(['complex_double_ret' => 'complex_ret'] => ['double','double'] => 'complex_double');
    $ffi->attach(['complex_double_ptr_ret' => 'complex_ptr_ret'] => ['double','double'] => 'complex_double*');

    subtest 'return value' => sub {

      is_deeply(complex_ret(1.0,2.0),       [1.0,2.0], 'standard');
      is_deeply(complex_ptr_ret(1.0,2.0),  \[1.0,2.0], 'pointer');
      is_deeply([complex_null()],             [],     'null');

    };
  };
}

done_testing;
