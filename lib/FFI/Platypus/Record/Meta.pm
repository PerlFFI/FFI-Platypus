package FFI::Platypus::Record::Meta;

use strict;
use warnings;
use 5.008004;

# ABSTRACT: FFI support for structured records data
# VERSION

=head1 DESCRIPTION

This class is private to FFI::Platypus.  See L<FFI::Platypus::Record> for
the public interface to Platypus records.

=cut

{
  require FFI::Platypus;
  my $ffi = FFI::Platypus->new(
    api          => 1,
  );
  $ffi->bundle;
  $ffi->mangler(sub {
    my($name) = @_;
    $name =~ s/^/ffi_platypus_record_meta__/;
    $name;
  });

  $ffi->type('opaque' => 'ffi_type');

  $ffi->custom_type('meta_t' => {
    native_type    => 'opaque',
    perl_to_native => sub {
      ${ $_[0] };
    },
  });

  $ffi->attach( _find_symbol => ['string'] => 'ffi_type');

  $ffi->attach( new => ['ffi_type[]','int'] => 'meta_t', sub {
    my($xsub, $class, $elements, $closure_safe) = @_;

    if(ref($elements) ne 'ARRAY')
    {
      require Carp;
      Carp::croak("passed something other than a array ref to @{[ __PACKAGE__ ]}");
    }

    my @element_type_pointers;
    foreach my $element_type (@$elements)
    {
      my $ptr = _find_symbol($element_type);
      if($ptr)
      {
        push @element_type_pointers, $ptr;
      }
      else
      {
        require Carp;
        Carp::croak("unknown type: $element_type");
      }
    }

    push @element_type_pointers, undef;

    my $ptr = $xsub->(\@element_type_pointers, $closure_safe);
    bless \$ptr, $class;
  });

  $ffi->attach( ffi_type         => ['meta_t'] => 'ffi_type'   );
  $ffi->attach( size             => ['meta_t'] => 'size_t'     );
  $ffi->attach( alignment        => ['meta_t'] => 'ushort'     );
  $ffi->attach( element_pointers => ['meta_t'] => 'ffi_type[]' );

  $ffi->attach( DESTROY          => ['meta_t'] => 'void'       );
}

sub ptr { ${ shift() } }

1;
