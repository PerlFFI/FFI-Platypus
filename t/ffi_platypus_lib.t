use strict;
use warnings;
use Test::More;
use File::Spec;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;

my($lib) = find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
ok -e $lib, "exists $lib";

eval { $ffi->lib($lib) };
is $@, '', 'ffi.lib (set)';

is_deeply [eval { $ffi->lib }], [$lib], 'ffi.lib (get)';

subtest 'undef' => sub {

  subtest 'baseline' => sub {
    
    my $ffi = FFI::Platypus->new;
    is_deeply([$ffi->lib], []);
    
  };
  
  subtest 'lib => [undef]' => sub {
  
    my $ffi = FFI::Platypus->new(lib => [undef]);
    is_deeply([$ffi->lib], [undef]);
  
  };
  
  subtest 'lib => undef' => sub {

    my $ffi = FFI::Platypus->new(lib => undef);
    is_deeply([$ffi->lib], [undef]);
  
  };

};

done_testing;
