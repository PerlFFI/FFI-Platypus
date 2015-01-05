package FFI::Platypus;

use strict;
use warnings;
use 5.008001;
use Carp qw( croak );

# ABSTRACT: Glue a duckbill to an adorable aquatic mammal
# VERSION

require XSLoader;
XSLoader::load(
  'FFI::Platypus', eval q{ $VERSION } || do {
    # this is for testing without dzil
    # it expects MYMETA.json for FFI::Platypus
    # to be in the current working directory.
    require JSON::PP;
    my $fh;
    open($fh, '<', 'MYMETA.json') || die "unable to read MYMETA.json";
    my $config = JSON::PP::decode_json(do { local $/; <$fh> });
    close $fh;
    $config->{version};
  }
);

=head1 CONSTRUCTORS

=head2 new

 my $ffi = FFI::Platypus->new;

Create a new instance of L<FFI::Platypus>.

=cut

sub new
{
  my($class) = @_;
  bless { lib => [], handles => {}, types => {} }, $class;
}

=head1 ATTRIBUTES

=head2 lib

 $ffi->lib($path1, $path2, ...);
 my @paths = $ffi->lib;

The list of libraries to search for symbols in.

=cut

sub lib
{
  my($self, @new) = @_;
  if(@new)
  {
    push @{ $self->{lib} }, @new;
  }
  
  @{ $self->{lib} };
}

=head1 METHODS

=head2 find_symbol

 my $address = $ffi->find_symbol($name);

Return the address of the given symbol (usually function).

=cut

sub find_symbol
{
  my($self, $name) = @_;

  foreach my $path (@{ $self->{lib} })
  {
    my $handle = do { no warnings; $self->{handles}->{$path||0} } || FFI::Platypus::dl::dlopen($path);
    next unless $handle;
    my $address = FFI::Platypus::dl::dlsym($handle, $name);
    if($address)
    {
      $self->{handles}->{$path||0} = $handle;
      return $address;
    }
    else
    {
      FFI::Platypus::dl::dlclose($handle);
    }
  }
  return;
}

=head2 type

 $ffi->type('sint32');
 $ffi->type('sint32' => 'myint');

Define a type.  The first argument is the FFI or C name of the type.  The second argument (optional) is an alias name
that you can use to refer to this new type.

The following FFI types are always available (parentheticals indicates the usual corresponding C type):

=over 4

=item sint8

Signed 8 bit byte (I<signed char>).

=item uint8

Unsigned 8 bit byte (I<unsigned char>).

=item sint16

Signed 16 bit integer (I<short>)

=item uint16

Unsigned 16 bit integer (I<unsigned short>)

=item sint32

Signed 32 bit integer (I<int>)

=item uint32

Unsigned 32 bit integer (I<unsigned int>)

=item sint64

Signed 64 bit integer (I<long> or I<long long>)

=item uint64

Unsigned 64 bit integer (I<unsigned long> or I<unsigned long long>)

=item float

Single precision floating point (I<float>)

=item double

Double precision floating point (I<double>)

=item pointer

Opaque pointer (I<void *>)

=item string

Null terminated ASCII string (I<char *>)

=back

The following FFI types I<may> be available depending on your platform:

=over 4

=item longdouble

Double or Quad precision floating point (I<long double>)

=back

=cut

sub type
{
  my($self, $name, $alias) = @_;
  croak "usage: \$ffi->type(name => alias) (alias is optional)" unless defined $self && defined $name;
  require FFI::Platypus::ConfigData;
  my $type_map = FFI::Platypus::ConfigData->config("type_map");
  croak "unknown type: $name" unless defined $type_map->{$name};
  croak "alias conflicts with existing type" if defined $alias && defined $type_map->{$alias};
  $self->{types}->{$name} = FFI::Platypus::Type->new($name);
  if(defined $alias)
  {
    $self->{types}->{$alias} = $self->{types}->{$name};
  }
  $self;
}

sub _type_lookup
{
  my($self, $name) = @_;
  
  unless(defined $self->{types}->{$name})
  {
    require FFI::Platypus::ConfigData;
    my $type_map = FFI::Platypus::ConfigData->config("type_map");
    if(defined $type_map->{$name})
    {
      $self->{types}->{$name} = FFI::Platypus::Type->new($name);
    }
  }
  
  $self->{types}->{$name};
}

=head2 types

 my @types = $ffi->types;
 my @types = FFI::Platypus->types;

Returns the list of types that FFI knows about.  This may be either built in FFI types (example: I<sint32>) or
detected C types (example: I<signed int>), or types that you have defined using the L</#type|type> method.

It can also be called as a class method, in which case, not user defined types will be included.

=cut

sub types
{
  my($self) = @_;
  $self = $self->new unless ref $self && eval { $self->isa('FFI::Platypus') };
  require FFI::Platypus::ConfigData;
  my %types = map { $_ => 1 } keys %{ FFI::Platypus::ConfigData->config("type_map") };
  $types{$_} ||= 1 foreach keys %{ $self->{types} };
  sort keys %types;
}

=head2 function

 my $function = $ffi->function('my_function_name', ['int', 'string'] => 'string');
 my $return_value = $function->(1, "hi there");

Returns an object that is simular to a code reference in that it can be called like one.

Caveat: many situations require a real code reference, at the price of a performance
penalty you can get one like this:

 my $coderef = sub { $function->(@_) };

It may be better, and faster to create a real Perl function using the L</#attach|attach> method.

=cut

sub function
{
  my($self, $name, $args, $ret) = @_;
  croak "usage \$ffi->function( name, [ arguments ], return_type)" unless @_ == 4;
  my @args = map { $self->_type_lookup($_) || croak "unknown type: $_" } @$args;
  $ret = $self->_type_lookup($ret) || croak "unknown type: $ret";
  my $address = $self->find_symbol($name);
  croak "unable to find $name" unless $address;
  FFI::Platypus::Function->new($self, $address, $ret, @args);
}

sub DESTROY
{
  my($self) = @_;
  # TODO: Need to remember not to free these if they
  # have been perminently attached as an xsub
  # TODO: also need to be ABLE to attach as an xsub :P
  foreach my $handle (values %{ $self->{handles} })
  {
    next unless $handle;
    FFI::Platypus::dl::dlclose($handle);
  }
}

1;
