use Test2::V0 -no_srand => 1;
use FFI::Platypus;

subtest 'only load as needed' => sub {

  my $ffi = FFI::Platypus->new;

  ok( !  FFI::Platypus->can('_package') );

  $ffi->package;

  ok( !! FFI::Platypus->can('_package') );

};

done_testing;
