use strict;
use warnings;
use Test::More tests => 14;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub );

BEGIN {
  my $config = FFI::TestLib->config;
  my $testlib = ffi_lib $config->{lib};

  ffi_sub [$testlib], integer_pointer_in =>   [ ffi_type c => 'int',     ffi_type c => '*int'    ];
  ffi_sub [$testlib], double_pointer_in  =>   [ ffi_type c => 'double',  ffi_type c => '*double' ];
  ffi_sub [$testlib], integer_pointer_out =>  [ ffi_type c => 'void',    ffi_type c => '*int'    ];
  ffi_sub [$testlib], double_pointer_out =>   [ ffi_type c => 'void',    ffi_type c => '*double' ];
  ffi_sub [$testlib], integer_pointer_ret =>  [ ffi_type c => '*int',    ffi_type c => 'int'     ];
  ffi_sub [$testlib], double_pointer_ret =>   [ ffi_type c => '*double', ffi_type c => 'double'  ];
  ffi_sub [$testlib], int_to_int_ptr =>       [ ffi_type c => '*void',   ffi_type c => 'int'     ];
  ffi_sub [$testlib], double_to_double_ptr => [ ffi_type c => '*void',   ffi_type c => 'double'  ];
}

is integer_pointer_in(undef), 4242, 'int    undef    => NULL';
is integer_pointer_in(0),     4242, 'int    0        => NULL';
is integer_pointer_in(\42),     43, 'int    42       => 42';
is double_pointer_in(undef), 12.34, 'double undef    => NULL';
is double_pointer_in(0),     12.34, 'double 0        => NULL';
is double_pointer_in(\1.50),  1.50, 'double 1.50     => 1.50';

is integer_pointer_in(int_to_int_ptr(100)), 101, 'pointer argument (integer)';
is double_pointer_in(double_to_double_ptr(2.50)), 2.50, 'pointer argument (double)';


my $foo = 50;
integer_pointer_out(\$foo);
is $foo, 51, 'integer pointer out';

$foo = 12.34;
double_pointer_out(\$foo);
is $foo, -12.34, 'double pointer out';

my $ptr = integer_pointer_ret(42);
is ref($ptr), 'SCALAR', 'is a scalar ref';
is $$ptr, 42, 'ptr = 42';

$ptr = double_pointer_ret(12.34);
is ref($ptr), 'SCALAR', 'is a scalar ref';
is $$ptr, 12.34, 'ptr = 12.34';
