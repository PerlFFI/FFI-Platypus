use strict;
use warnings;
use Test::More tests => 5;
use FFI::Platypus;
use FFI::CheckLib;

my $lib = find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

note "lib=$lib";

subtest 'ignore_not_found=undef' => sub {
  plan tests => 4;

  my $ffi = FFI::Platypus->new;
  $ffi->lib($lib);
  
  my $f1 = eval { $ffi->function(f1 => [] => 'void') };
  is $@, '', 'no exception';
  ok ref($f1), 'returned a function';
  note "f1 isa ", ref($f1);
  
  my $f2 = eval { $ffi->function(bogus => [] => 'void') };
  isnt $@, '', 'function exception';
  note "exception=$@";
  
  eval { $ffi->attach(bogus => [] => 'void') };
  isnt $@, '', 'attach exception';
  note "exception=$@";
  
};

subtest 'ignore_not_found=0' => sub {
  plan tests => 4;

  my $ffi = FFI::Platypus->new;
  $ffi->lib($lib);
  $ffi->ignore_not_found(0);
  
  my $f1 = eval { $ffi->function(f1 => [] => 'void') };
  is $@, '', 'no exception';
  ok ref($f1), 'returned a function';
  note "f1 isa ", ref($f1);
  
  my $f2 = eval { $ffi->function(bogus => [] => 'void') };
  isnt $@, '', 'function exception';
  note "exception=$@";
  
  eval { $ffi->attach(bogus => [] => 'void') };
  isnt $@, '', 'attach exception';
  note "exception=$@";
};

subtest 'ignore_not_found=0 (constructor)' => sub {
  plan tests => 4;

  my $ffi = FFI::Platypus->new( ignore_not_found => 0 );
  $ffi->lib($lib);
  
  my $f1 = eval { $ffi->function(f1 => [] => 'void') };
  is $@, '', 'no exception';
  ok ref($f1), 'returned a function';
  note "f1 isa ", ref($f1);
  
  my $f2 = eval { $ffi->function(bogus => [] => 'void') };
  isnt $@, '', 'function exception';
  note "exception=$@";
  
  eval { $ffi->attach(bogus => [] => 'void') };
  isnt $@, '', 'attach exception';
  note "exception=$@";
};

subtest 'ignore_not_found=1' => sub {
  plan tests => 5;

  my $ffi = FFI::Platypus->new;
  $ffi->lib($lib);
  $ffi->ignore_not_found(1);
  
  my $f1 = eval { $ffi->function(f1 => [] => 'void') };
  is $@, '', 'no exception';
  ok ref($f1), 'returned a function';
  note "f1 isa ", ref($f1);
  
  my $f2 = eval { $ffi->function(bogus => [] => 'void') };
  is $@, '', 'function no exception';
  is $f2, undef, 'f2 is undefined';

  eval { $ffi->attach(bogus => [] => 'void') };
  is $@, '', 'attach no exception';
  
};

subtest 'ignore_not_found=1 (constructor)' => sub {
  plan tests => 5;

  my $ffi = FFI::Platypus->new( ignore_not_found => 1 );
  $ffi->lib($lib);
  
  my $f1 = eval { $ffi->function(f1 => [] => 'void') };
  is $@, '', 'no exception';
  ok ref($f1), 'returned a function';
  note "f1 isa ", ref($f1);
  
  my $f2 = eval { $ffi->function(bogus => [] => 'void') };
  is $@, '', 'function no exception';
  is $f2, undef, 'f2 is undefined';
  
  eval { $ffi->attach(bogus => [] => 'void') };
  is $@, '', 'attach no exception';
};
