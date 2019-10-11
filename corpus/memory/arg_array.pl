use strict;
use warnings;
use FFI::Platypus;
use Test::More;
use Math::Complex;
use Test::LeakTrace qw( no_leaks_ok );

my @types = map { "${_}[2]" } ( 'float', 'double', 'longdouble',
            map { ( "sint$_" , "uint$_" ) }
            qw( 8 16 32 64 ));

foreach my $type (@types)
{
  subtest $type => sub {
    my $ffi = FFI::Platypus->new;
    my $f = $ffi->function(0 => [ $type ] => 'void' );
    no_leaks_ok { $f->call([1,2]) };
  }
}

subtest 'opaque' => sub {
  my $ffi    = FFI::Platypus->new( lib => [undef] );
  my $malloc = $ffi->function( malloc => [ 'size_t' ] => 'opaque' );
  my $free   = $ffi->function( free => [ 'opaque' ] => 'void' );
  my $ptr    = $malloc->call(200);
  my $f      = $ffi->function(0 => [ 'opaque[2]' ] => 'void' );

  no_leaks_ok { $f->call([$ptr, undef]) };
  $free->call($ptr);
};

subtest 'string' => sub {
  my $ffi = FFI::Platypus->new;
  my $f = $ffi->function(0 => [ 'string[2]' ] => 'void' );
  no_leaks_ok { $f->call(["hello world",undef]) };
  my $str = "hello world";
  no_leaks_ok { $f->call([$str,undef]) };
};

subtest 'complex' => sub {

  foreach my $type (qw( complex_float[2] complex_double[2] ))
  {
    subtest $type => sub {
      my $ffi = FFI::Platypus->new;
      my $f = $ffi->function(0 => [ $type ] => 'void' );
      my $c = Math::Complex->make(1.0,2.0);
      no_leaks_ok { $f->call([[1.0,2.0],[3.0,4.0]]) };
      no_leaks_ok { $f->call([$c,$c]) };
      no_leaks_ok { $f->call(undef) };
    };
  }

};

done_testing;
