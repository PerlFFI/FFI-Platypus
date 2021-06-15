use Test2::V0 -no_srand => 1;
use FFI::CheckLib;
use FFI::Platypus;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest ASM => sub {
  my $ffi = FFI::Platypus->new(lang => 'ASM');
  $ffi->lib($libtest);

  eval { $ffi->type('int') };
  isnt $@, '', 'int is not an okay type';
  note $@;
  eval { $ffi->type('foo_t') };
  isnt $@, '', 'foo_t is not an okay type';
  note $@;
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';

  is $ffi->find_symbol('UnMangled::Name(int i)'), undef, 'unable to find unmangled name';

};

done_testing;
