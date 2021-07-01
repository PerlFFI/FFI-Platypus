use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::TypeParser;
use FFI::CheckLib;
use Data::Dumper qw( Dumper );

BEGIN {
  skip_all 'Test requires support for float complex'
    unless FFI::Platypus::TypeParser->have_type('complex_float');
}

foreach my $api (0, 1, 2)
{

  subtest "api = $api" => sub {

    local $SIG{__WARN__} = sub {
      my $message = shift;
      return if $message =~ /^Subroutine main::.* redefined/;
      warn $message;
    };

    my $ffi = FFI::Platypus->new( api => $api, experimental => ($api >=2 ? $api : undef) );
    $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');

    $ffi->attach(['complex_float_get_real' => 'creal'] => ['complex_float'] => 'float');
    $ffi->attach(['complex_float_get_imag' => 'cimag'] => ['complex_float'] => 'float');
    $ffi->attach(['complex_float_to_string' => 'to_string'] => ['complex_float'] => 'string');

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
        skip_all 'test requires Math::Complex'
          unless eval q{ use Math::Complex (); 1 };
        my $c = Math::Complex->make(10.5, 20.5);
        note "to_string(\$c) = ", to_string($c);
        is creal($c), 10.5, "creal(\$c) = 10.5";
        is cimag($c), 20.5, "cimag(\$c) = 20.5";
      };
    };

    $ffi->attach(['complex_float_ptr_get_real' => 'creal_ptr'] => ['complex_float *'] => 'float');
    $ffi->attach(['complex_float_ptr_get_imag' => 'cimag_ptr'] => ['complex_float *'] => 'float');
    $ffi->attach(['complex_float_ptr_set' => 'complex_set'] => ['complex_float *','float','float'] => 'void');

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
        skip_all 'test requires Math::Complex'
          unless eval q{ use Math::Complex (); 1 };
        my $c = Math::Complex->make(10.5, 20.5);
        note "to_string(\$c) = ", to_string($c);
        is creal_ptr(\$c), 10.5, "creal_ptr(\\$c) = 10.5";
        is cimag_ptr(\$c), 20.5, "cimag_ptr(\\$c) = 20.5";
      };

      subtest 'values set on out (array)' => sub {
        my @c;
        complex_set(\\@c, 1.0, 2.0);
        is \@c, [ 1.0, 2.0 ];
      };

      subtest 'values set on out (object)' => sub {
        skip_all 'test requires Math::Complex'
          unless eval q{ use Math::Complex (); 1 };
        my $c = Math::Complex->make(0.0, 0.0);
        complex_set(\$c, 1.0, 2.0);
        is( [ $c->Re, $c->Im ], [1.0,2.0] );
      };

      subtest 'values set on out (other)' => sub {
        my $c;
        complex_set(\$c, 1.0, 2.0);
        is( $c, [1.0, 2.0]);
      };

    };

    $ffi->attach(['pointer_null' => 'complex_null'] => [] => 'complex_float*');
    $ffi->attach(['complex_float_ret' => 'complex_ret'] => ['float','float'] => 'complex_float');
    $ffi->attach(['complex_float_ptr_ret' => 'complex_ptr_ret'] => ['float','float'] => 'complex_float*');

    subtest 'return value' => sub {

      is(complex_ret(1.0,2.0),       [1.0,2.0], 'standard');
      is(complex_ptr_ret(1.0,2.0),  \[1.0,2.0], 'pointer');
      is([complex_null()],             $api >= 2 ? [undef] : [],     'null');

    };

    subtest 'complex array arg' => sub {

      my $f = $ffi->function(complex_float_array_get => ['complex_float[]','int'] => 'complex_float' );

      my @a = ([0.0,0.0], [1.0,2.0], [3.0,4.0]);
      my $ret;
      is( $ret = $f->call(\@a, 0), [0.0,0.0] )
        or diag Dumper($ret);
      is( $ret = $f->call(\@a, 1), [1.0,2.0] )
        or diag Dumper($ret);
      is( $ret = $f->call(\@a, 2), [3.0,4.0] )
        or diag Dumper($ret);

    };

    subtest 'complex array arg' => sub {

      skip_all 'for api >= 2 only' unless $api >= 2;

      my $f = $ffi->function(complex_float_array_get => ['complex_float*','int'] => 'complex_float' );

      my @a = ([0.0,0.0], [1.0,2.0], [3.0,4.0]);
      my $ret;
      is( $ret = $f->call(\@a, 0), [0.0,0.0] )
        or diag Dumper($ret);
      is( $ret = $f->call(\@a, 1), [1.0,2.0] )
        or diag Dumper($ret);
      is( $ret = $f->call(\@a, 2), [3.0,4.0] )
        or diag Dumper($ret);

    };

    subtest 'complex array arg set' => sub {

      my $f = $ffi->function(complex_float_array_set => ['complex_float[]','int','float','float'] => 'void' );

      my @a = ([0.0,0.0], [1.0,2.0], [3.0,4.0]);
      $f->call(\@a, 1, 5.0, 6.0);
      is(\@a, [[0.0,0.0], [5.0,6.0], [3.0,4.0]]);

    };

    subtest 'complex array arg set' => sub {

      skip_all 'for api >= 2 only' unless $api >= 2;

      my $f = $ffi->function(complex_float_array_set => ['complex_float*','int','float','float'] => 'void' );

      my @a = ([0.0,0.0], [1.0,2.0], [3.0,4.0]);
      $f->call(\@a, 1, 5.0, 6.0);
      is(\@a, [[0.0,0.0], [5.0,6.0], [3.0,4.0]]);

    };

    subtest 'complex array ret' => sub {

      my $f = $ffi->function(complex_float_array_ret => [] => 'complex_float[3]' );

      my @a = ([0.0,0.0], [1.0,2.0], [3.0,4.0]);
      my $ret;

      is(
        $ret = $f->call( \@a ),
        \@a,
      ) or diag Dumper($ret);

    };
  };
}

done_testing;
