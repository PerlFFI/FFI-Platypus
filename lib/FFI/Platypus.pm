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
  croak "spaces not allowed in alias" if defined $alias && $alias =~ /\s/;
  croak "allowed characters for alias: [A-Za-z0-9_]+" if defined $alias && $alias =~ /[^A-Za-z0-9_]/;
  require FFI::Platypus::ConfigData;
  my $type_map = FFI::Platypus::ConfigData->config("type_map");
  
  my $basic = $name;
  my $extra = '';
  if($basic =~ s/\s+((\*|\[|\<).*)$//)
  {
    $extra = " $1";
  }
  
  croak "unknown type: $basic" unless defined $type_map->{$basic};
  croak "alias conflicts with existing type" if defined $alias && defined $type_map->{$alias};
  
  $self->{types}->{$name} = $self->{types}->{$type_map->{$basic}.$extra} ||= FFI::Platypus::Type->new($type_map->{$basic}.$extra);
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
detected C types (example: I<signed int>), or types that you have defined using the L<FFI::Platypus#type|type> method.

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

Returns an object that is similar to a code reference in that it can be called like one.

Caveat: many situations require a real code reference, at the price of a performance
penalty you can get one like this:

 my $coderef = sub { $function->(@_) };

It may be better, and faster to create a real Perl function using the L<FFI::Platypus#attach|attach> method.

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

=head2 attach

 $ffi->attach('my_functon_name', ['int', 'string'] => 'string');
 $ffi->attach(['my_c_functon_name' => 'my_perl_function_name'], ['int', 'string'] => 'string');

Find and attach the given C function as the given perl function name as a real live xsub.
The advantage of attaching a function over using the L<FFI::Platypus#function|function> method
is that it is much much faster since no object resolution needs to be done.  The disadvantage
is that it locks the function and the L<FFI::Platypus> instance into memory permanently, since
there is no way to deallocate an xsub.

=cut

sub attach
{
  my($self, $name, $args, $ret) = @_;
  my($c_name, $perl_name) = ref($name) ? @$name : ($name, $name);
  
  my $function = $self->function($c_name, $args, $ret);
  
  my($caller, $filename, $line) = caller;
  $perl_name = join '::', $caller, $perl_name
    unless $perl_name =~ /::/;
    
  $function->attach($perl_name, "$filename:$line");
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

package
  FFI::Platypus::Function;

use overload '&{}' => sub {
  my $ffi = shift;
  sub { $ffi->call(@_) };
};

package
  FFI::Platypus::Type;

sub new
{
  my($class, $type) = @_;
  
  my $ffi_type;
  my $platypus_type;
  
  if($type eq 'string')
  {
    $ffi_type = 'pointer';
    $platypus_type = 'string';
  }
  elsif($type =~ s/\s+\*$//)
  {
    $ffi_type = $type;
    $platypus_type = 'pointer';
  }
  elsif($type =~ s/\s+\[[0-9]+\]$//)
  {
    $ffi_type = $type;
    $platypus_type = 'array';
    # TODO: size
  }
  elsif($type =~ s/\s+\<buffer\>//)
  {
    $ffi_type = $type;
    $platypus_type = 'buffer';
    # TODO: order
  }
  elsif($type =~ s/\s+\<custom\>//)
  {
    $ffi_type = $type;
    $platypus_type = 'custom';
  }
  else
  {
    $ffi_type = $type;
    $platypus_type = 'ffi';
  }
  
  $class->_new($ffi_type, $platypus_type);
}

1;
