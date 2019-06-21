use strict;
use warnings;
use Test::More;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus;
use Carp ();

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');

subtest 'attached function' => sub {

  $ffi->attach( f0 => ['uint8'] => 'uint8' => sub {
    package Foo::Bar;
    my($xsub, $arg) = @_;
    Carp::croak "here";
    $xsub->($arg);
  });

  local $@ = '';
  eval { f0(1) }; my $line = __LINE__;
  like "$@", qr/^here .*gh129\.t line \Q$line\E\./;

};

subtest 'dynamic function' => sub {

  my $f0 = $ffi->function( f0 => ['uint8'] => 'uint8' => sub {
    package Foo::Bar;
    my($xsub, $arg) = @_;
    Carp::croak "here";
    $xsub->($arg);
  });

  local $@ = '';
  eval { $f0->call(1) }; my $line = __LINE__;
  like "$@", qr/^here .*gh129\.t line \Q$line\E\./;

};

done_testing;