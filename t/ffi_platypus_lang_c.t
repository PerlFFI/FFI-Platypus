use strict;
use warnings;
use Test::More;
use FFI::CheckLib;
use FFI::Platypus;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest C => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  eval { $ffi->type('int') };
  is $@, '', 'int is an okay type';
  eval { $ffi->type('foo_t') };
  isnt $@, '', 'foo_t is not an okay type';
  note $@;
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';

  is $ffi->find_symbol('UnMangled::Name(int i)'), undef, 'unable to find unmangled name';

};

done_testing;
