use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use Math::Complex;
use Test::LeakTrace qw( no_leaks_ok );

my @types = map { "$_" } ( 'float', 'double',
            map { ( "sint$_" , "uint$_" ) }
            qw( 8 16 32 64 ));

foreach my $type (@types)
{
  subtest $type => sub {
    my $ffi = FFI::Platypus->new;
    $ffi->custom_type( foo_t => {
      native_type         => $type,
      native_to_perl      => sub { $_[0] },
      perl_to_native      => sub { $_[0] },
      perl_to_native_post => sub { $_[0] },
    });
    my $f = $ffi->function(0 => [ "foo_t" ] => 'void' );
    no_leaks_ok { $f->call(129) };
  }
}

subtest 'opaque' => sub {
  my $ffi    = FFI::Platypus->new( lib => [undef] );
  my $malloc = $ffi->function( malloc => [ 'size_t' ] => 'opaque' );
  my $free   = $ffi->function( free => [ 'opaque' ] => 'void' );
  my $ptr    = $malloc->call(200);

  $ffi->custom_type( foo_t => {
    native_type         => 'opaque',
    native_to_perl      => sub { $_[0] },
    perl_to_native      => sub { $_[0] },
    perl_to_native_post => sub { $_[0] },
  });

  my $f      = $ffi->function(0 => [ 'foo_t' ] => 'void' );

  no_leaks_ok { $f->call($ptr) };
  $free->call($ptr);
  no_leaks_ok { $f->call(undef) };
};

done_testing;
