package FFI::Platypus::Constant;

use strict;
use warnings;
use constant 1.32 ();
use FFI::Platypus;

# ABSTRACT: Define constants in C space for Perl
# VERSION

=head1 SYNOPSIS

C<ffi/foo.c>:

 #include <ffi_platypus_bundle.h>
 
 void
 ffi_pl_bundle_constant(const char *package, ffi_platypus_constant_t *c)
 {
   c->set_str("FOO", "BAR");       /* sets $package::FOO to "BAR" */
   c->set_str("ABC::DEF", "GHI");  /* sets ABC::DEF to GHI        */
 }

C<lib/Foo.pm>:

 package Foo;
 
 use strict;
 use warnings;
 use FFI::Platypus;
 use base qw( Exporter );
 
 my $ffi = FFI::Platypus->new;
 # sets constatns Foo::FOO and ABC::DEF from C
 $ffi->bundle;
 
 1;

=head1 DESCRIPTION

The Platypus bundle interface (see L<FFI::Platypus::Bundle>) has an entry point
C<ffi_pl_bundle_constant> that lets you define constants in Perl space from C.

 void ffi_pl_bundle_constant(const char *package, ffi_platypus_constant_t *c);

The first argument C<package> is the name of the Perl package.  The second argument
C<c> is a struct with function pointers that lets you define constants of different
types.  The first argument for each function is the name of the constant and the
second is the value.  If C<::> is included in the constant name then it will be
defined in that package space.  If it isn't then the constant will be defined in
whichever package called C<bundle>.

=over 4

=item set_str

 c->set_str(name, value);

Sets a string constant.

=item set_sint

 c->set_sint(name, value);

Sets a 64-bit signed integer constant.

=item set_uint

 c->set_uint(name, value);

Sets a 64-bit unsigned integer constant.

=item set_double

 c->set_double(name, value);

Sets a double precision floating point constant.

=back

=head2 Example

Suppose you have a header file C<myheader.h>:

# EXAMPLE: examples/bundle-const/ffi/myheader.h

You can define these constants from C:

# EXAMPLE: examples/bundle-const/ffi/const.c

Your Perl code doesn't have to do anything when calling bundle:

# EXAMPLE: examples/bundle-const/lib/Const.pm

=cut

{
  my $ffi = FFI::Platypus->new( api => 1, experimental => 1 );
  $ffi->bundle;

  $ffi->type( 'opaque'                => 'ffi_platypus_constant_t' );
  $ffi->type( '(string,string)->void' => 'set_str_t'       );
  $ffi->type( '(string,sint64)->void' => 'set_sint_t'      );
  $ffi->type( '(string,uint64)->void' => 'set_uint_t'      );
  $ffi->type( '(string,double)->void' => 'set_double_t'    );

  $ffi->mangler(sub {
    my($name) = @_;
    $name =~ s/^/ffi_platypus_constant__/;
    $name;
  });

  $ffi->attach( new => [ 'set_str_t', 'set_sint_t', 'set_uint_t', 'set_double_t' ] => 'ffi_platypus_constant_t' => sub {
    my($xsub, $class, $default_package) = @_;
    my $f = $ffi->closure(sub {
      my($name, $value) = @_;
      if($name !~ /::/)
      {
        $name = join('::', $default_package, $name);
      }
      constant->import($name, $value);
    });

    bless {
      ptr => $xsub->($f, $f, $f, $f),
      f   => $f,
    }, $class;
  });

  $ffi->attach( DESTROY => ['ffi_platypus_constant_t'] => 'void' => sub {
    my($xsub, $self) = @_;
    $xsub->($self->ptr);
  });

  sub ptr { shift->{ptr} }

}

1;
