package FFI::Platypus::Bundle::Constant;

use strict;
use warnings;
use constant 1.32 ();
use FFI::Platypus;

# ABSTRACT: Platypus Bundle code
# VERSION

=head1 DESCRIPTION

This class is private to L<FFI::Platypus>.

=cut

{
  my $ffi = FFI::Platypus->new( api => 1, experimental => 1 );
  $ffi->bundle;

  $ffi->type( 'opaque'                       => 'ffi_pl_bundle_t' );
  $ffi->type( '(string,string)->void' => 'set_str_t'       );
  $ffi->type( '(string,sint64)->void' => 'set_sint_t'      );
  $ffi->type( '(string,uint64)->void' => 'set_uint_t'      );
  $ffi->type( '(string,double)->void' => 'set_double_t'    );

  $ffi->mangler(sub {
    my($name) = @_;
    $name =~ s/^/ffi_platypus_bundle_api__/;
    $name;
  });

  $ffi->attach( new => [ 'set_str_t', 'set_sint_t', 'set_uint_t', 'set_double_t' ] => 'opaque' => sub {
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

  $ffi->attach( DESTROY => ['opaque'] => 'void' => sub {
    my($xsub, $self) = @_;
    $xsub->($self->ptr);
  });

  sub ptr { shift->{ptr} }

}

1;
