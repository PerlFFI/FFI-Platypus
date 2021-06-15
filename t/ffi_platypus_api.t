use Test2::V0 -no_srand => 1;
use FFI::Platypus::API;

subtest 'basic' => sub {

  {
    package FFI::Platypus::Type::C1;

    sub ffi_custom_type_api_1
    {
      return {
        native_type => 'sint8',
        perl_to_native => sub { $_[0] * 2 },
      }
    }
  }

  my $ffi = FFI::Platypus->new;
  $ffi->load_custom_type('::C1' => 'c1');
  is(
    $ffi->function( 0 => ['c1'] => 'sint8' )->call(10),
    20,
  );

};

done_testing;
