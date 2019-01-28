use strict;
use warnings;
use Test::More;
use FFI::Platypus::Lang::Rust;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus;

my $types = FFI::Platypus::Lang::Rust->native_type_map;

foreach my $rust_type (sort keys %$types)
{
  note sprintf "%-10s %s\n", $rust_type, $types->{$rust_type};
}

subtest 'Foo constructor' => sub {
  my $ffi = FFI::Platypus->new(lang => 'Rust');
  
  eval { $ffi->type('int') };
  isnt $@, '', 'int is not an okay type';
  note $@;
  eval { $ffi->type('i32') };
  is $@, '', 'i32 is an okay type';
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';
  
  is $ffi->sizeof('i16'), 2, 'sizeof i16 = 2';
  is $ffi->sizeof('u32'), 4, 'sizeof u32 = 4';
  
};

subtest 'attach' => sub {
  my $libtest = find_lib lib => 'rusty', libpath => 't/ffi/rusty/target/debug';
  plan skip_all => 'test requires a rust compiler'
    unless $libtest;

  plan tests => 1;

  my $ffi = FFI::Platypus->new;
  $ffi->lang('Rust');
  $ffi->lib($libtest);

  $ffi->attach(i32_sum => ['i32', 'i32'] => 'i32');

  is i32_sum(1,2), 3, 'i32_sum(1,2) = 3';

};

done_testing;
