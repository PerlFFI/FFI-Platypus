use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free );

foreach my $api (0,1,2)
{

  subtest "api => $api" => sub {

    our $ffi = FFI::Platypus->new( api => $api, lib => [undef], experimental => ($api >=2 ? $api : undef));

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
  };
}

done_testing;
