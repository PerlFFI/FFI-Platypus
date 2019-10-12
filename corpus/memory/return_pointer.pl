use strict;
use warnings;
use lib 't/lib';
use Test::FauxAttach;
use FFI::Platypus;
use Test::More;
use Test::LeakTrace qw( no_leaks_ok );
use FFI::Platypus::Memory qw( malloc free memset strdup );

my $ptr = malloc(400);
memset($ptr, 0, 400);

my @types = map { "$_*" } ( 'float', 'double', 'longdouble',
            map { ( "sint$_" , "uint$_" ) }
            qw( 8 16 32 64 ));

foreach my $type (@types)
{
  subtest $type => sub {
    my $ffi = FFI::Platypus->new;
    my $f = $ffi->function(0 => [ 'opaque' ] => $type );
    no_leaks_ok { $f->call($ptr)  };
    no_leaks_ok { $f->call(undef) };
  }
}

subtest 'opaque' => sub {
  my $ffi    = FFI::Platypus->new;
  my $f      = $ffi->function(0 => [ 'opaque' ] => 'opaque*' );

  no_leaks_ok { $f->call($ptr) };
  no_leaks_ok { $f->call(undef) };

  my $f2     = $ffi->function(0 => [ 'opaque*' ] => 'opaque*' );
  no_leaks_ok { $f2->call(\$ptr) };
};

subtest 'string' => sub {
  my $ffi = FFI::Platypus->new;
  my $f = $ffi->function(0 => [ 'opaque' ] => 'string*' );

  my $ptr = strdup("hello world");
  
  no_leaks_ok { $f->call($ptr) };
  no_leaks_ok { $f->call(undef) };

  free $ptr;
};

subtest 'complex' => sub {

  foreach my $type (qw( complex_float* complex_double* ))
  {
    subtest $type => sub {
      my $ffi = FFI::Platypus->new;
      my $f = $ffi->function(0 => [ 'opaque' ] => $type );

      no_leaks_ok { $f->call($ptr) };
    };
  }

};

free $ptr;

done_testing;
