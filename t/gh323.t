use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free );

skip_all 'test requires variadic function support'
  unless eval { FFI::Platypus->new( lib => [undef] )->function(
    sprintf => ['opaque', 'string'] => ['float'] ) };

foreach my $api (0,1,2)
{

  subtest "api => $api" => sub {

    our $ffi = FFI::Platypus->new( api => $api, lib => [undef], experimental => ($api > 2 ? $api : undef));

    $ffi->type('float' => 'my_float');

    sub callit
    {
      my($type) = @_;

      my $ptr = malloc 1024;
      $ffi->function( sprintf => ['opaque','string'] => [$type] )->call($ptr, "%f", 3.14);
      my $string = $ffi->cast('opaque' => 'string', $ptr);
      free $ptr;
      return $string;
    }

    my $double = callit('double');
    my $float  = callit('float');
    note "double = $double";
    note "float  = $float";
    is $float, $double;

    $float  = callit('my_float');
    note "my_float = $float";
    is $float, $double;

  };
}

done_testing;
