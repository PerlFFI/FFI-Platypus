package FFI::Platypus;

use strict;
use warnings;
use 5.008001;
use Carp qw( croak );

# ABSTRACT: Write Perl bindings to foreign language libraries without XS
# VERSION

# Platypus Man,
# Platypus Man,
# Does Everything The Platypus Can
# ...
# Watch Out!
# Here Comes The Platypus Man

=head1 SYNOPSIS

 use FFI::Platypus;
 
 my $ffi = FFI::Platypus->new;
 $ffi->lib(undef); # search libc
 
 # call dynamically
 $ffi->function( puts => ['string'] => 'int' )->call("hello world");
 
 # attach as a xsub and call (much faster)
 $ffi->attach( puts => ['string'] => 'int' );
 puts("hello world");

=head1 DESCRIPTION

Platypus provides an interface for creating FFI based modules in
Perl that call machine code via C<libffi>.  This is an alternative
to XS that does not require a compiler.

The declarative interface L<FFI::Platypus::Declare> may be more
suitable, if you do not need the extra power of the OO interface
and you do not mind the namespace pollution.

=cut

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

 my $ffi = FFI::Platypus->new(%options);

Create a new instance of L<FFI::Platypus>.

Any types defined with this instance will be valid for this
instance only, so you do not need to worry about stepping on
the toes of other CPAN FFI Authors.

Any functions found will be out of the list of libraries
specified with the L<lib|FFI::Platypus#lib> attribute.

=head3 options

=over 4

=item lib

Either a pathname (string) or a list of pathnames (array ref of strings)
to pre-populate the L<lib|FFI::Platypus#lib> attribute.

=back

=cut

sub new
{
  my($class, %args) = @_;
  my @lib;
  if(defined $args{lib})
  {
    if(!ref($args{lib}))
    {
      push @lib, $args{lib};
    }
    elsif(ref($args{lib}) eq 'ARRAY')
    {
      push @lib, @{$args{lib}};
    }
    else
    {
      croak "lib argument must be a scalar or array reference";
    }
  }
  bless { lib => \@lib, handles => {}, types => {} }, $class;
}

=head1 ATTRIBUTES

=head2 lib

 $ffi->lib($path1, $path2, ...);
 my @paths = $ffi->lib;

The list of libraries to search for symbols in.

The most portable and reliable way to find dynamic libraries is by using
L<FFI::CheckLib>, like this:

 use FFI::CheckLib 0.06;
 $ffi->lib(find_lib_or_die lib => 'archive'); 
   # finds libarchive.so on Linux
   #       libarchive.bundle on OS X
   #       libarchive.dll (or archive.dll) on Windows
   #       cygarchive-13.dll on Cygwin
   #       ...
   # and will die if it isn't found

L<FFI::CheckLib> has a number of options, such as checking for specific
symbols, etc.  You should consult the documentation for that module.

As a special case, if you add C<undef> as a "library" to be searched,
L<FFI::Platypus> will also search the current process for symbols.
This is mostly useful for finding functions in the standard C library,
without having to know the name of libc for your platform (as it turns
out it is different just about everywhere!).

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

=head2 type

 $ffi->type($typename);
 $ffi->type($typename => $alias);

Define a type.  The first argument is the native or C name of the type.  The second argument (optional) is an alias name
that you can use to refer to this new type.  See L<FFI:Platypus::Type> for legal type definitions.

Examples:

 $ffi->type('sint32'); # oly checks to see that sint32 is a valid type
 $ffi->type('sint32' => 'myint'); # creates an alias myint for sint32
 $ffi->type('bogus'); # dies with appropriate diagnostic

=cut

sub type
{
  my($self, $name, $alias) = @_;
  croak "usage: \$ffi->type(name => alias) (alias is optional)" unless defined $self && defined $name;
  croak "spaces not allowed in alias" if defined $alias && $alias =~ /\s/;
  croak "allowed characters for alias: [A-Za-z0-9_]+" if defined $alias && $alias =~ /[^A-Za-z0-9_]/;

  require FFI::Platypus::ConfigData;
  my $type_map = FFI::Platypus::ConfigData->config("type_map");

  croak "alias conflicts with existing type" if defined $alias && (defined $type_map->{$alias} || defined $self->{types}->{$alias});

  if($name =~ /-\>/)
  {
    # for closure types we do not try to convet into the basic type
    # so you can have many many many copies of a given closure type
    # if you do not spell it exactly the same each time.  Recommended
    # thsat you use an alias for a closure type anyway.
    $self->{types}->{$name} ||= FFI::Platypus::Type->new($name, $self);
  }
  else
  {
    my $basic = $name;
    my $extra = '';
    if($basic =~ s/\s*((\*|\[|\<).*)$//)
    {
      $extra = " $1";
    }
  
    croak "unknown type: $basic" unless defined $type_map->{$basic};
    $self->{types}->{$name} = $self->{types}->{$type_map->{$basic}.$extra} ||= FFI::Platypus::Type->new($type_map->{$basic}.$extra, $self);
  }
  
  if(defined $alias)
  {
    $self->{types}->{$alias} = $self->{types}->{$name};
  }
  $self;
}

=head2 custom_type

 $ffi->custom_type($type, $name, {
   ffi_to_perl => $coderef,
   ffi_to_perl => $coderef,
   perl_to_ffi_post => $coderef,
 });

Define a custom type.  See L<FFI::Platypus::Type#Custom Types> for details.

=cut

sub custom_type
{
  my($self, $type, $name, $cb) = @_;
  
  croak "Usage: \$ffi->custom_type(\$type, \$name, { ... })"
    unless defined $type && defined $name && ref($cb) eq 'HASH';
  
  croak "must define at least one of ffi_to_perl, perl_to_ffi, or perl_to_ffi_post"
    unless defined $cb->{ffi_to_perl} || defined $cb->{perl_to_ffi} || defined $cb->{perl_to_ffi_post};
  
  require FFI::Platypus::ConfigData;
  my $type_map = FFI::Platypus::ConfigData->config("type_map");  
  croak "$type is not a basic type" unless defined $type_map->{$type} || $type eq 'string';
  croak "name conflicts with existing type" if defined $type_map->{$name} || defined $self->{types}->{$name};
  
  $self->{types}->{$name} = FFI::Platypus::Type->_new_custom_perl($type_map->{$type}, $cb->{perl_to_ffi}, $cb->{ffi_to_perl}, $cb->{perl_to_ffi_post});
  
  $self;
}

sub _type_lookup
{
  my($self, $name) = @_;
  $self->type($name) unless defined $self->{types}->{$name};
  $self->{types}->{$name};
}

=head2 types

 my @types = $ffi->types;
 my @types = FFI::Platypus->types;

Returns the list of types that FFI knows about.  This may be either built in FFI types (example: I<sint32>) or
detected C types (example: I<signed int>), or types that you have defined using the L<type|FFI::Platypus#type> method.

It can also be called as a class method, in which case, no user defined types will be included.

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

=head2 type_meta

 my $meta = $ffi->type_meta($type_name);
 my $meta = FFI::Platypus->type_meta($type_name);

Returns a hash reference with the meta information for the given type.

It can also be called as a class method, in which case, you won't be able to get meta data on user defined types.

Examples:

 my $meta = $ffi->type_meta('int');        # standard int type
 my $meta = $ffi->type_meta('int[64]');    # array of 64 ints
 $ffi->type('int[128]' => 'myintarray');
 my $meta = $ffi->type_meta('myintarray'); # array of 128 ints

=cut

sub type_meta
{
  my($self, $name) = @_;
  $self = $self->new unless ref $self && eval { $self->isa('FFI::Platypus') };
  my $type = $self->_type_lookup($name);
  $type->meta;
}

=head2 function

 my $function = $ffi->function($name => \@argument_types => $return_type);
 my $function = $ffi->function($address => \@argument_types => $return_type);
 
Returns an object that is similar to a code reference in that it can be called like one.

Caveat: many situations require a real code reference, at the price of a performance
penalty you can get one like this:

 my $function = $ffi->function(...);
 my $coderef = sub { $function->(@_) };

It may be better, and faster to create a real Perl function using the L<attach|FFI::Platypus#attach> method.

In addition to looking up a function by name you can provide the address of the symbol
yourself:

 my $address = $ffi->find_symbol('my_functon');
 my $function = $ffi->function($address => ...);

Under the covers this function uses L<find_symbol|FFI::Platypus#find_symbol> when you provide it
with a name rather than an address, but you may have alternative ways of obtaining a function's
address, such as it could be returned as an C<opaque> pointer.

Examples:

 my $function = $ffi->function('my_function_name', ['int', 'string'] => 'string');
 my $return_string = $function->(1, "hi there");

=cut

sub function
{
  my($self, $name, $args, $ret) = @_;
  croak "usage \$ffi->function( name, [ arguments ], return_type)" unless @_ == 4;
  my @args = map { $self->_type_lookup($_) || croak "unknown type: $_" } @$args;
  $ret = $self->_type_lookup($ret) || croak "unknown type: $ret";
  my $address = $name =~ /^-?[0-9]+$/ ? $name : $self->find_symbol($name);
  croak "unable to find $name" unless defined $address;
  FFI::Platypus::Function->new($self, $address, $ret, @args);
}

=head2 attach

 $ffi->attach($name => \@argument_types => $return_type);
 $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type);
 $ffi->attach([$address => $perl_name] => \@argument_types => $return_type);

Find and attach a C function as a Perl function as a real live xsub.  The advantage of
attaching a function over using the L<function|FFI::Platypus#function> method is that
it is much much much faster since no object resolution needs to be done.  The disadvantage
is that it locks the function and the L<FFI::Platypus> instance into memory permanently,
since there is no way to deallocate an xsub.

If just one I<$name> is given, then the function will be attached in Perl with the same
name as it has in C.  The second form allows you to give the Perl function a different
name.  You can also provide an address (the third form), just like with the 
L<function|FFI::Platypus#function> method.

Examples:

 $ffi->attach('my_functon_name', ['int', 'string'] => 'string');
 $ffi->attach(['my_c_functon_name' => 'my_perl_function_name'], ['int', 'string'] => 'string');
 my $string1 = my_function_name($int);
 my $string2 = my_perl_function_name($int);

=cut

sub attach
{
  my($self, $name, $args, $ret, $proto) = @_;
  my($c_name, $perl_name) = ref($name) ? @$name : ($name, $name);

  croak "you tried to provide a perl name that looks like an address"
    if $perl_name =~ /^-?[0-9]+$/;
  
  my $function = $self->function($c_name, $args, $ret);
  
  my($caller, $filename, $line) = caller;
  $perl_name = join '::', $caller, $perl_name
    unless $perl_name =~ /::/;
    
  $function->attach($perl_name, "$filename:$line", $proto);
}

=head2 closure

 my $closure = $ffi->closure($coderef);

Prepares a code reference so that it can be used as a FFI closure (a Perl subroutine that can be called
from C code).  For details on closures, see L<FFI::Platypus::Type#Closures>.

=cut

sub closure
{
  my($self, $coderef) = @_;
  FFI::Platypus::Closure->new($coderef);
}

=head2 find_symbol

 my $address = $ffi->find_symbol($name);

Return the address of the given symbol (usually function).  Usually you
can use the L<function|FFI::Platypus#function> method or the 
L<attach|FFI::Platypus#attach> function directly and will not need
to use this.

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
      FFI::Platypus::dl::dlclose($handle) unless $self->{handles}->{$path||0};
    }
  }
  return;
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
  delete $self->{handles};
}

package FFI::Platypus::Function;

# VERSION

use overload '&{}' => sub {
  my $ffi = shift;
  sub { $ffi->call(@_) };
};

package FFI::Platypus::Closure;

use Scalar::Util qw( refaddr);
use Carp qw( croak );

# VERSION

our %cbdata;

sub new
{
  my($class, $coderef) = @_;
  croak "not a coderef" unless ref($coderef) eq 'CODE';
  my $self = bless $coderef, $class;
  $cbdata{refaddr $self} = {};
  $self;
}

sub add_data
{
  my($self, $key, $payload) = @_;
  $cbdata{refaddr $self}->{$key} = $payload;
}

sub get_data
{
  my($self, $key) = @_;
  $cbdata{refaddr $self}->{$key};
}

sub DESTROY
{
  my($self) = @_;
  delete $cbdata{refaddr $self};
}

package FFI::Platypus::Type;

use Carp qw( croak );

# VERSION

sub new
{
  my($class, $type, $platypus) = @_;

  # the platypus object is only needed for closures, so
  # that it can lookup existing types.

  if($type =~ m/^\((.*)\)-\>\s*(.*)\s*$/)
  {
    croak "passing closure into a closure not supported" if $1 =~ /(\(|\)|-\>)/;
    my @argument_types = map { $platypus->_type_lookup($_) } map { s/^\s+//; s/\s+$//; $_ } split /,/, $1;
    my $return_type = $platypus->_type_lookup($2);
    return $class->_new_closure($return_type, @argument_types);
  }
  
  my $ffi_type;
  my $platypus_type;
  my $array_size = 0;
  
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
  elsif($type =~ s/\s+\[([0-9]+)\]$//)
  {
    $ffi_type = $type;
    $platypus_type = 'array';
    $array_size = $1;
  }
  else
  {
    $ffi_type = $type;
    $platypus_type = 'ffi';
  }
  
  $class->_new($ffi_type, $platypus_type, $array_size);
}

1;

=head1 SUPPORT

If something does not work the way you think it should, or if you have a feature
request, please open an issue on this project's GitHub Issue tracker:

L<https://github.com/plicease/FFI-Platypus/issues>

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a pull request on
this project's GitHub repository:

L<https://github.com/plicease/FFI-Platypus/pulls>

This project is developed using L<Dist::Zilla>.  The project's git repository also
comes with C<Build.PL> and C<cpanfile> files necessary for building, testing 
(and even installing if necessary) without L<Dist::Zilla>.  Please keep in mind
though that these files are generated so if changes need to be made to those files
they should be done through the project's C<dist.ini> file.  If you do use L<Dist::Zilla>
and already have the necessary plugins installed, then I encourage you to run
C<dzil test> before making any pull requests.  This is not a requirement, however,
I am happy to integrate especially smaller patches that need tweaking to fit the project
standards.  I may push back and ask you to write a test case or alter the formatting of 
a patch depending on the amount of time I have and the amount of code that your patch 
touches.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus::Declare>

Declarative interface to L<FFI::Platypus>.

=item L<FFI::Platypus::Type>

Type definitions for L<FFI::Platypus>.

=item L<FFI::Platypus::Memory>

memory functions for FFI.

=item L<FFI::CheckLib>

Find dynamic libraries in a portable way.

=item L<FFI::TinyCC>

JIT compiler for FFI.

=item L<Convert::Binary::C>

An interface for interacting with C C<struct> types.  Unfortunately it appears to
be unmaintained, and has a failing pod test, so I cannot recommend it for use 
by CPAN modules.

=item L<pack|perlfunc#pack> and L<unpack|perlfunc#unpack>

Native to Perl functions that can be used to decode C C<struct> types.

=item L<FFI::Raw>

Alternate interface to libffi with fewer features.  It notably lacks the ability to
create real xsubs, which may make L<FFI::Platypus> much faster.  Also lacking are
pointers to native types, arrays and custom types.  In its favor, it has been around
for longer that Platypus, and has been battle tested to some success.

=item L<Win32::API>

Microsoft Windows specific FFI style interface.

=item L<Ctypes|https://gitorious.org/perl-ctypes>

Ctypes was intended as a FFI style interface for Perl, but was never part of CPAN,
and at least the last time I tried it did not work with recent versions of Perl.

=item L<FFI>

Foreign function interface based on (nomenclature is everything) FSF's C<ffcall>.
It hasn't worked for quite some time, and C<ffcall> is no longer supported or
distributed.

=item L<C::DynaLib>

Another FFI for Perl that doesn't appear to have worked for a long time.

=back

=cut
