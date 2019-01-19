use strict;
use warnings;
use Test::More;
use FFI::Platypus::Function;
use FFI::Platypus;
use FFI::CheckLib;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest 'built in type' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
  my $wrapper  = sub {
    my($xsub, $arg1) = @_;
    $xsub->( $arg1 * 2 );
  };
  my $function = eval { $ffi->function('f0', [ 'uint8' ] => 'uint8', $wrapper ) };
  is $@, '', 'ffi.function(f0, [uint8] => uint8)';
  isa_ok $function, 'FFI::Platypus::Function';
  isa_ok $function, 'FFI::Platypus::Function::Wrapper';
  is $function->call(22), 44, 'function.call(22) = 44';
  is $function->(22), 44, 'function.(22) = 44';

  $function->attach('baboon');
  is( baboon(11), 22, "baboon(11) = 22" );
};

done_testing;
