package Foo;

use strict;
use warnings;
use FFI::Platypus;

{
  my $ffi = FFI::Platypus->new( api => 1 );

  $ffi->type('object(Foo)' => 'foo_t');
  $ffi->mangler(sub {
    my $name = shift;
    $name =~ s/^/foo__/;
    $name;
  });

  $ffi->bundle;

  $ffi->attach( new =>     [ 'string', 'string', 'int' ] => 'foo_t'  );
  $ffi->attach( name =>    [ 'foo_t' ]                   => 'string' );
  $ffi->attach( value =>   [ 'foo_t' ]                   => 'int'    );
  $ffi->attach( DESTROY => [ 'foo_t' ]                   => 'void'   );
}

1;
