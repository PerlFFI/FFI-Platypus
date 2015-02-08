package FFI::Platypus;

use strict;
use warnings;
use 5.008001;
use Carp qw( croak );

# ABSTRACT: Write Perl bindings to non-Perl libraries with FFI. No XS required.
# VERSION

# Platypus Man,
# Platypus Man,
# Does Everything The Platypus Can
# ...
# Watch Out!
# Here Comes The Platypus Man

=begin stopwords

ØMQ

=end stopwords

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

Platypus provides a method for creating interfaces to machine code 
libraries.  This implementation uses C<libffi>, a library that provides 
Foreign Function Interfaces for a number of other languages, including 
Ruby and Python.  Platypus can be used in stand alone scripts, or to 
create Perl extensions for CPAN.  There are a number of reasons why you 
might want to write extensions with FFI instead of XS:

=over 4

=item FFI / Platypus does not require messing with the guts of Perl

XS is less of an API and more of the guts of perl splayed out to do 
whatever you want.  That may at times be very powerful, but it may also 
sometimes be very dangerous to your mental health.

=item FFI / Platypus is portable

Lots of languages have FFI interfaces, and it is subjectively easier to 
port an extension written in FFI in Perl or another language to FFI in 
another language or Perl.  One goal of the Platypus Project is to reduce 
common interface specifications to a common format like JSON that could 
be shared between different languages.

=item FFI / Platypus could be a bridge to Perl 6

One of those "other" languages could be Perl 6 and Perl 6 already has an 
FFI interface I am told.

=item FFI / Platypus is pure perl (sorta)

One Platypus script or module works on any platform where the libraries 
it uses are available.  That means you can deploy your Platypus script 
in a shared filesystem where they may be run on different platforms.  It 
also means that Platypus modules do not need to be installed in the 
platform specific Perl library path.

=item FFI / Platypus is not C or C++ centric

XS is implemented primarily as a bunch of C macros, which requires at 
least some understanding of C, the C pre-processor, and some C++ 
caveats (since on some platforms Perl is compiled and linked with a C++ 
compiler). Platypus on the other hand could be used to call other 
compiled languages, like Fortran, L<Rust|FFI::Platypus::Lang::Rust>,
L<Pascal|FFI::Platypus::Lang::Pascal>, L<C++|FFI::Platypus::Lang::CPP>,
Go or even L<assembly|FFI::Platypus::Lang::ASM>, allowing you to focus
on your strengths.

=item FFI / Platypus does not require a parser

L<Inline> isolates the extension developer from XS to some extent, but 
it also requires a parser.  The various L<Inline> language bindings are 
a great technical achievement, but I think writing a parser for every 
language that you want to interface with is a bit of an anti-pattern.

=back

This document consists of an API reference, a set of examples, some 
support and development (for contributors) information.  If you are new 
to Platypus or FFI, you may want to skip down to the 
L<EXAMPLES|/EXAMPLES> to get a taste of what you can do with Platypus.

Platypus also provides an declarative interface you may want to use 
instead of the object oriented interface called 
L<FFI::Platypus::Declare>.

Platypus has extensive documentation of types at L<FFI::Platypus::Type> 
and its custom types API at L<FFI::Platypus::API>.

=cut

our @CARP_NOT = qw( FFI::Platypus::Declare );

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

Any types defined with this instance will be valid for this instance 
only, so you do not need to worry about stepping on the toes of other 
CPAN FFI / Platypus Authors.

Any functions found will be out of the list of libraries specified with 
the L<lib|/lib> attribute.

=head3 options

=over 4

=item lib

Either a pathname (string) or a list of pathnames (array ref of strings) 
to pre-populate the L<lib|/lib> attribute.

=item ignore_not_found

[version 0.15]

Set the L<ignore_not_found|/ignore_not_found> attribute.

=item lang

[version 0.18]

Set the L<lang|/lang> attribute.

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
  bless {
    lib              => \@lib,
    handles          => {},
    types            => {},
    lang             => $args{lang} || 'C',
    ignore_not_found => defined $args{ignore_not_found} ? $args{ignore_not_found} : 0,
  }, $class;
}

sub _type_map
{
  my($self) = @_;
  
  unless(defined $self->{type_map})
  {
    my $class = "FFI::Platypus::Lang::".$self->{lang};
    unless($class->can("native_type_map"))
    {
      eval qq{ use $class };
      croak "erro loding $class: $@" if $@;
    }
    unless($class->can("native_type_map"))
    {
      croak "$class does not provide a native_type_map method";
    }
    my %type_map = %{ $class->native_type_map };
    # include the standard libffi types
    $type_map{$_} = $_ for qw( void sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double string opaque );
    $type_map{pointer} = 'opaque';
    $self->{type_map} = \%type_map;
  }
  
  $self->{type_map};
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
Platypus will also search the current process for symbols. This is 
mostly useful for finding functions in the standard C library, without 
having to know the name of the standard c library for your platform (as 
it turns out it is different just about everywhere!).

You may also use the L</find_lib> method as a shortcut:

 $ffi->find_lib( lib => 'archive' );

=cut

sub lib
{
  my($self, @new) = @_;

  if(@new)
  {
    push @{ $self->{lib} }, @new;
    delete $self->{mangler};
  }
  
  @{ $self->{lib} };
}

=head2 ignore_not_found

[version 0.15]

 $ffi->ignore_not_found(1);
 my $ignore_not_found = $ffi->ignore_not_found;

Normally the L<attach|/attach> and L<function|/function> methods will 
throw an exception if it cannot find the name of the function you 
provide it.  This will change the behavior such that 
L<function|/function> will return C<undef> when the function is not 
found and L<attach|/attach> will ignore functions that are not found. 
This is useful when you are writing bindings to a library and have many 
optional functions and you do not wish to wrap every call to 
L<function|/function> or L<attach|/attach> in an C<eval>.

=cut

sub ignore_not_found
{
  my($self, $value) = @_;
  
  if(defined $value)
  {
    $self->{ignore_not_found} = $value;
  }
  
  $self->{ignore_not_found};
}

=head2 lang

[version 0.18]

 $ffi->lang($language);

Specifies the foreign language that you will be interfacing with. The 
default is C.  The foreign language specified with this attribute 
changes the default native types (for example, if you specify 
L<Rust|FFI::Platypus::Lang::Rust>, you will get C<i32> as an alias for 
C<sint32> instead of C<int> as you do with L<C|FFI::Platypus::Lang::C>).

If the foreign language plugin supports it, this will also enable 
Platypus to find symbols using the demangled names (for example, if you 
specify L<CPP|FFI::Platypus::Lang::CPP> for C++ you can use method names 
like C<Foo::get_bar()> with L</attach> or L</function>.

=cut

sub lang
{
  my($self, $value) = @_;
  
  if(defined $value)
  {
    $self->{lang} = $value;
    delete $self->{type_map};
  }
  
  $self->{lang};
}

=head1 METHODS

=head2 type

 $ffi->type($typename);
 $ffi->type($typename => $alias);

Define a type.  The first argument is the native or C name of the type.  
The second argument (optional) is an alias name that you can use to 
refer to this new type.  See L<FFI::Platypus::Type> for legal type 
definitions.

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

  my $type_map = $self->_type_map;

  croak "alias conflicts with existing type" if defined $alias && (defined $type_map->{$alias} || defined $self->{types}->{$alias});

  if($name =~ /-\>/ || $name =~ /^record\s*\([0-9A-Z:a-z_]+\)$/
  || $name =~ /^string(_rw|_ro|\s+rw|\s+ro|\s*\([0-9]+\))$/)
  {
    # for closure and record types we do not try to convet into the
    # basic type so you can have many many many copies of a given
    # closure type if you do not spell it exactly the same each time.
    # Recommended that you use an alias for a closure type anyway.
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

 $ffi->custom_type($alias => {
   native_type         => $native_type,
   native_to_perl      => $coderef,
   perl_to_native      => $coderef,
   perl_to_native_post => $coderef,
 });

Define a custom type.  See L<FFI::Platypus::Type#Custom-Types> for details.

=cut

sub custom_type
{
  my($self, $name, $cb) = @_;
  
  my $type = $cb->{native_type};
  $type ||= 'opaque';
  
  my $argument_count = $cb->{argument_count} || 1;
  
  croak "argument_count must be >= 1"
    unless $argument_count >= 1;
  
  croak "Usage: \$ffi->custom_type(\$name, { ... })"
    unless defined $name && ref($cb) eq 'HASH';
  
  croak "must define at least one of native_to_perl, perl_to_native, or perl_to_native_post"
    unless defined $cb->{native_to_perl} || defined $cb->{perl_to_native} || defined $cb->{perl_to_native_post};
  
  my $type_map = $self->_type_map;
  croak "$type is not a native type" unless defined $type_map->{$type} || $type eq 'string';
  croak "name conflicts with existing type" if defined $type_map->{$name} || defined $self->{types}->{$name};
  
  $self->{types}->{$name} = FFI::Platypus::Type->_new_custom_perl(
    $type_map->{$type},
    $cb->{perl_to_native},
    $cb->{native_to_perl},
    $cb->{perl_to_native_post},
    $argument_count,
  );
  
  $self;
}

=head2 load_custom_type

 $ffi->load_custom_type($name => $alias, @type_args);

Load the custom type defined in the module I<$name>, and make an alias 
I<$alias>. If the custom type requires any arguments, they may be passed 
in as I<@type_args>. See L<FFI::Platypus::Type#Custom-Types> for 
details.

If I<$name> contains C<::> then it will be assumed to be a fully 
qualified package name. If not, then C<FFI::Platypus::Type::> will be 
prepended to it.

=cut

sub load_custom_type
{
  my($self, $name, $alias, @type_args) = @_;

  croak "usage: \$ffi->load_custom_type(\$name, \$alias, ...)"
    unless defined $name && defined $alias;

  $name = "FFI::Platypus::Type$name" if $name =~ /^::/;
  $name = "FFI::Platypus::Type::$name" unless $name =~ /::/;
  
  unless($name->can("ffi_custom_type_api_1"))
  {
    eval qq{ use $name () };
    warn $@ if $@;
  }
  
  unless($name->can("ffi_custom_type_api_1"))
  {
    croak "$name does not appear to conform to the custom type API";
  }
  
  my $cb = $name->ffi_custom_type_api_1($self, @type_args);
  $self->custom_type($alias => $cb);
  
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

Returns the list of types that FFI knows about.  This will include the 
native C<libffi> types (example: C<sint32>, C<opaque> and C<double>) and 
the normal C types (example: C<unsigned int>, C<uint32_t>), any types 
that you have defined using the L<type|/type> method, and
custom types.

The list of types that Platypus knows about varies somewhat from 
platform to platform, L<FFI::Platypus::Type> includes a list of the core 
types that you can always count on having access to.

It can also be called as a class method, in which case, no user defined 
or custom types will be included in the list.

=cut

sub types
{
  my($self) = @_;
  $self = $self->new unless ref $self && eval { $self->isa('FFI::Platypus') };
  my %types = map { $_ => 1 } keys %{ $self->_type_map };
  $types{$_} ||= 1 foreach keys %{ $self->{types} };
  sort keys %types;
}

=head2 type_meta

 my $meta = $ffi->type_meta($type_name);
 my $meta = FFI::Platypus->type_meta($type_name);

Returns a hash reference with the meta information for the given type.

It can also be called as a class method, in which case, you won't be 
able to get meta data on user defined types.

The format of the meta data is implementation dependent and subject
to change.  It may be useful for display or debugging.

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
  my $type = $self->{types}->{$name} || $self->_type_lookup($name);
  $type->meta;
}

=head2 function

 my $function = $ffi->function($name => \@argument_types => $return_type);
 my $function = $ffi->function($address => \@argument_types => $return_type);
 
Returns an object that is similar to a code reference in that it can be 
called like one.

Caveat: many situations require a real code reference, so at the price 
of a performance penalty you can get one like this:

 my $function = $ffi->function(...);
 my $coderef = sub { $function->(@_) };

It may be better, and faster to create a real Perl function using the 
L<attach|/attach> method.

In addition to looking up a function by name you can provide the address 
of the symbol yourself:

 my $address = $ffi->find_symbol('my_functon');
 my $function = $ffi->function($address => ...);

Under the covers, L<function|/function> uses 
L<find_symbol|/find_symbol> when you provide it with a 
name, but it is useful to keep this in mind as there are alternative 
ways of obtaining a functions address.  Example: a C function could 
return the address of another C function that you might want to call, or 
modules such as L<FFI::TinyCC> produce machine code at runtime that you 
can call from Platypus.

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
  croak "unable to find $name" unless defined $address || $self->ignore_not_found;
  return unless defined $address;
  FFI::Platypus::Function->new($self, $address, $ret, @args);
}

=head2 attach

 $ffi->attach($name => \@argument_types => $return_type);
 $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type);
 $ffi->attach([$address => $perl_name] => \@argument_types => $return_type);
 $ffi->attach($name => \@argument_types => $return_type, sub { ... });
 $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type, sub { ... });
 $ffi->attach([$address => $perl_name] => \@argument_types => $return_type, sub { ... });

Find and attach a C function as a real live Perl xsub.  The advantage of 
attaching a function over using the L<function|/function> 
method is that it is much much much faster since no object resolution 
needs to be done.  The disadvantage is that it locks the function and 
the L<FFI::Platypus> instance into memory permanently, since there is no 
way to deallocate an xsub.

If just one I<$name> is given, then the function will be attached in 
Perl with the same name as it has in C.  The second form allows you to 
give the Perl function a different name.  You can also provide an 
address (the third form), just like with the 
L<function|/function> method.

Examples:

 $ffi->attach('my_functon_name', ['int', 'string'] => 'string');
 $ffi->attach(['my_c_functon_name' => 'my_perl_function_name'], ['int', 'string'] => 'string');
 my $string1 = my_function_name($int);
 my $string2 = my_perl_function_name($int);

[version 0.20]

If the last argument is a code reference, then it will be used as a wrapper
around the attached xsub.  The first argument to the wrapper will be the
inner xsub.  This can be used if you need to verify/modify input/output
data.

Examples:

 $ffi->attach('my_function', ['int', 'string'] => 'string', sub {
   my($my_function_xsub, $integer, $string) = @_;
   $integer++;
   $string .= " and another thing";
   my $return_string = $my_function->($integer, $string);
   $return_string =~ /Belgium//; # HHGG remove profanity
   $return_string;
 });

=cut

my $inner_counter=0;

sub attach
{
  my $wrapper;
  $wrapper = pop if ref $_[-1] eq 'CODE';

  my($self, $name, $args, $ret, $proto) = @_;
  my($c_name, $perl_name) = ref($name) ? @$name : ($name, $name);

  croak "you tried to provide a perl name that looks like an address"
    if $perl_name =~ /^-?[0-9]+$/;
  
  my $function = $self->function($c_name, $args, $ret);
  
  if(defined $function)
  {
    my($caller, $filename, $line) = caller;
    $perl_name = join '::', $caller, $perl_name
      unless $perl_name =~ /::/;
    
    my $attach_name = $perl_name;
    if($wrapper)
    {
      $attach_name = "FFI::Platypus::Inner::xsub$inner_counter";
      $inner_counter++;
    }
    
    $function->attach($attach_name, "$filename:$line", $proto);
    
    if($wrapper)
    {
      my $inner_coderef = \&{$attach_name};
      no strict 'refs';
      # TODO: Sub::Name ?
      *{$perl_name} = sub { $wrapper->($inner_coderef, @_) };
    }
  }
  
  $self;
}

=head2 closure

 my $closure = $ffi->closure($coderef);

Prepares a code reference so that it can be used as a FFI closure (a 
Perl subroutine that can be called from C code).  For details on 
closures, see L<FFI::Platypus::Type#Closures>.

=cut

sub closure
{
  my($self, $coderef) = @_;
  FFI::Platypus::Closure->new($coderef);
}

=head2 cast

 my $converted_value = $ffi->cast($original_type, $converted_type, $original_value);

The C<cast> function converts an existing I<$original_value> of type 
I<$original_type> into one of type I<$converted_type>.  Not all types 
are supported, so care must be taken.  For example, to get the address 
of a string, you can do this:

 my $address = $ffi->cast('string' => 'opaque', $string_value);

Something that won't work is trying to cast an array to anything:

 my $address = $ffi->cast('int[10]' => 'opaque', \@list);  # WRONG

=cut

sub cast
{
  $_[0]->function(0 => [$_[1]] => $_[2])->call($_[3]);
}

=head2 attach_cast

 $ffi->attach_cast("cast_name", $original_type, $converted_type);
 my $converted_value = cast_name($original_value);

This function attaches a cast as a permanent xsub.  This will make it 
faster and may be useful if you are calling a particular cast a lot.

=cut

sub attach_cast
{
  my($self, $name, $type1, $type2) = @_;
  my $caller = caller;
  $name = join '::', $caller, $name unless $name =~ /::/;
  $self->attach([0 => $name] => [$type1] => $type2 => '$');
  $self;
}

=head2 sizeof

 my $size = $ffi->sizeof($type);

Returns the total size of the given type in bytes.  For example to get 
the size of an integer:

 my $intsize = $ffi->sizeof('int'); # usually 4 or 8 depending on platform

You can also get the size of arrays

 my $intarraysize = $ffi->sizeof('int[64]'); # usually 4*64 or 8*64

Keep in mind that "pointer" types will always be the pointer / word size 
for the platform that you are using.  This includes strings, opaque and 
pointers to other types.

This function is not very fast, so you might want to save this value as 
a constant, particularly if you need the size in a loop with many 
iterations.

=cut

sub sizeof
{
  my($self,$name) = @_;
  my $type = $self->{types}->{$name} || $self->_type_lookup($name);
  FFI::Platypus::Type::sizeof($type);
}

=head2 alignof

[version 0.21]

 my $align = $ffi->alignof($type);

Returns the alignment of the given type in bytes.

=cut

sub alignof
{
  my($self, $name) = @_;
  my $meta = $self->type_meta($name);
  
  croak "cannot determine alignment of record"
    if $meta->{type} eq 'record';
  
  require FFI::Platypus::ConfigData;

  my $ffi_type;
  if($meta->{type} eq 'pointer')
  {
    $ffi_type = 'pointer';
  }
  else
  {
    $ffi_type = $meta->{ffi_type};
  }
  
  FFI::Platypus::ConfigData->config('align')->{$ffi_type};
}

=head2 find_lib

[version 0.20]

 $ffi->find_lib( lib => $libname );

This is just a shortcut for calling L<FFI::CheckLib#find_lib> and
updating the L</lib> attribute appropriately.  Care should be taken
though, as this method simply passes its arguments to
L<FFI::CheckLib#find_lib>, so if your module or script is depending
on a specific feature in L<FFI::CheckLib> then make sure that you
update your prerequisites appropriately.

=cut

sub find_lib
{
  my $self = shift;
  require FFI::CheckLib;
  $self->lib(FFI::CheckLib::find_lib(@_));
  $self;
}

=head2 find_symbol

 my $address = $ffi->find_symbol($name);

Return the address of the given symbol (usually function).

=cut

sub find_symbol
{
  my($self, $name) = @_;

  unless(defined $self->{mangler})
  {
    my $class = "FFI::Platypus::Lang::".$self->{lang};
    unless($class->can('native_type_map'))
    {
      eval qq{ use $class };
      croak "unable to load $class: $@" if $@;
    }
    if($class->can('mangler'))
    {
      $self->{mangler} = $class->mangler($self->lib);
    }
    else
    {
      $self->{mangler} = sub { $_[0] };
    }
  }

  foreach my $path (@{ $self->{lib} })
  {
    my $handle = do { no warnings; $self->{handles}->{$path||0} } || FFI::Platypus::dl::dlopen($path);
    unless($handle)
    {
      warn "error loading $path: ", FFI::Platypus::dl::dlerror()
        if $ENV{FFI_PLATYPUS_DLERROR};
      next;
    }
    my $address = FFI::Platypus::dl::dlsym($handle, $self->{mangler}->($name));
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

=head2 package

[version 0.15]

 $ffi->package($package, $file); # usually __PACKAGE__ and __FILE__ can be used
 $ffi->package;                  # autodetect

If you have used L<Module::Build::FFI> to bundle C code with your
distribution, you can use this method to tell the L<FFI::Platypus> instance
to look for symbols that came with the dynamic library that was built
when your distribution was installed.

=cut

sub package
{
  my($self, $module, $modlibname) = @_;
  
  require FFI::Platypus::ConfigData;
  my @dlext = @{ FFI::Platypus::ConfigData->config("config_dlext") };

  ($module, $modlibname) = caller() unless defined $modlibname;  
  my @modparts = split /::/, $module;
  my $modfname = $modparts[-1];
  my $modpname = join('/',@modparts);
  my $c = @modparts;
  $modlibname =~ s,[\\/][^\\/]+$,, while $c--;    # Q&D basename
  
  foreach my $dlext (@dlext)
  {
    my $file = "$modlibname/auto/$modpname/$modfname.$dlext";
    unless(-e $file)
    {
      $modlibname =~ s,[\\/][^\\/]+$,,;
      $file = "$modlibname/arch/auto/$modpname/$modfname.$dlext";
    }
  
    if(-e $file)
    {
      $self->lib($file);
      return $self;
    }
  }
  
  $self;
}

=head1 EXAMPLES

Here are some examples.  Some of them use the L<FFI::Platypus::Declare> 
interface, but the principles apply to the OO interface.  These examples 
are provided in full with the Platypus distribution in the "examples" 
directory.  There are also some more examples in L<FFI::Platypus::Type> 
that are related to types.

=head2 Integer conversions

# EXAMPLE: examples/integer.pl

B<Discussion>: C<puts> and C<atoi> should be part of the standard C 
library on all platforms.  C<puts> prints a string to standard output, 
and C<atoi> converts a string to integer.  Specifying C<undef> as a 
library tells Platypus to search the current process for symbols, which 
includes the standard c library.

=head2 libnotify

# EXAMPLE: examples/notify.pl

B<Discussion>: libnotify is a desktop GUI notification library for the 
GNOME Desktop environment. This script sends a notification event that 
should show up as a balloon, for me it did so in the upper right hand 
corner of my screen.

The most portable way to find the correct name and location of a dynamic 
library is via the L<FFI::CheckLib#find_lib> family of functions.  If 
you are putting together a CPAN distribution, you should also consider 
using L<FFI::CheckLib#check_lib_or_exit> function in your C<Build.PL> or 
C<Makefile.PL> file (If you are using L<Dist::Zilla>, check out the 
L<Dist::Zilla::Plugin::FFI::CheckLib> plugin). This will provide a user 
friendly diagnostic letting the user know that the required library is 
missing, and reduce the number of bogus CPAN testers results that you 
will get.

Also in this example, we rename some of the functions when they are
placed into Perl space to save typing:

 attach [notify_notification_new => 'notify_new']
   => [string,string,string]
   => opaque;

When you specify a list reference as the "name" of the function the
first element is the symbol name as understood by the dynamic library.
The second element is the name as it will be placed in Perl space.

Later, when we call C<notify_new>:

 my $n = notify_new('','','');

We are really calling the C function C<notify_notification_new>.

=head2 Allocating and freeing memory

# EXAMPLE: examples/malloc.pl

B<Discussion>: C<malloc> and C<free> are standard memory allocation 
functions available from the standard c library and.  Interfaces to 
these and other memory related functions are provided by the 
L<FFI::Platypus::Memory> module.

=head2 libuuid

# EXAMPLE: examples/uuid.pl

B<Discussion>: libuuid is a library used to generate unique identifiers 
(UUID) for objects that may be accessible beyond the local system.  The 
library is or was part of the Linux e2fsprogs package.

Knowing the size of objects is sometimes important.  In this example, we 
use the L<sizeof|/sizeof> function to get the size of 16 
characters (in this case it is simply 16 bytes).  We also know that the 
strings "deparsed" by C<uuid_unparse> are exactly 37 bytes.

=head2 puts and getpid

# EXAMPLE: examples/getpid.pl

B<Discussion>: C<puts> is part of standard C library on all platforms.  
C<getpid> is available on Unix type platforms.

=head2 Math library

# EXAMPLE: examples/math.pl

B<Discussion>: On UNIX the standard c library math functions are 
frequently provided in a separate library C<libm>, so you could search 
for those symbols in "libm.so", but that won't work on non-UNIX 
platforms like Microsoft Windows.  Fortunately Perl uses the math 
library so these symbols are already in the current process so you can 
use C<undef> as the library to find them.

=head2 Strings

# EXAMPLE: examples/string.pl

B<Discussion>: Strings are not a native type to C<libffi> but the are 
handled seamlessly by Platypus.

=head2 Attach function from pointer

# EXAMPLE: examples/attach_from_pointer.pl

B<Discussion>: Sometimes you will have a pointer to a function from a 
source other than Platypus that you want to call.  You can use that 
address instead of a function name for either of the 
L<function|/function> or L<attach|/attach> 
methods.  In this example we use L<FFI::TinyCC> to compile a short piece 
of C code and to give us the address of one of its functions, which we 
then use to create a perl xsub to call it.

L<FFI::TinyCC> embeds the Tiny C Compiler (tcc) to provide a 
just-in-time (JIT) compilation service for FFI.

=head2 libzmq

# EXAMPLE: examples/zmq3.pl

B<Discussion>: ØMQ is a high-performance asynchronous messaging library.  
There are a few things to note here.

Firstly, sometimes there may be multiple versions of a library in the 
wild and you may need to verify that the library on a system meets your 
needs (alternatively you could support multiple versions and configure 
your bindings dynamically).  Here we use C<zmq_version> to ask libzmq 
which version it is.

C<zmq_version> returns the version number via three integer pointer 
arguments, so we use the pointer to integer type: C<int *>.  In order to 
pass pointer types, we pass a reference. In this case it is a reference 
to an undefined value, because zmq_version will write into the pointers 
the output values, but you can also pass in references to integers, 
floating point values and opaque pointer types.  When the function 
returns the C<$major> variable (and the others) has been updated and we 
can use it to verify that it supports the API that we require.

Notice that we define three aliases for the C<opaque> type: 
C<zmq_context>, C<zmq_socket> and C<zmq_msg_t>.  While this isn't 
strictly necessary, since Platypus and C treat all three of these types 
the same, it is useful form of documentation that helps describe the 
functionality of the interface.

Finally we attach the necessary functions, send and receive a message. 
If you are interested, there is a fully fleshed out ØMQ Perl interface 
implemented using FFI called L<ZMQ::FFI>.

=head2 libarchive

# EXAMPLE: examples/archive.pl

B<Discussion>: libarchive is the implementation of C<tar> for FreeBSD 
provided as a library and available on a number of platforms.

One interesting thing about libarchive is that it provides a kind of 
object oriented interface via opaque pointers.  This example creates an 
abstract class C<Archive>, and concrete classes C<ArchiveWrite>, 
C<ArchiveRead> and C<ArchiveEntry>.  The concrete classes can even be 
inherited from and extended just like any Perl classes because of the 
way the custom types are implemented.  For more details on custom types 
see L<FFI::Platypus::Type> and L<FFI::Platypus::API>.

Another advanced feature of this example is that we extend the 
L<FFI::Platypus> class to define our own find_symbol method that prefixes
the symbol names depending on the class in which they are defined.
This means we can do this when we define a method for Archive:

 $ffi->attach( support_filter_all => ['archive'] => 'int' );

Rather than this:

 $ffi->attach(
   [ archive_read_support_filter_all => 'support_read_filter_all' ] => 
   ['archive'] => 'int' );
 );

If you didn't want to create an entire new class just for this little
trick you could also use something like L<Object::Method> to extend
C<find_symbol>.

=head2 bzip2

# EXAMPLE: examples/bzip2.pl

B<Discussion>: bzip2 is a compression library.  For simple one shot
attempts at compression/decompression when you expect the original
and the result to fit within memory it provides two convenience functions
C<BZ2_bzBuffToBuffCompress> and C<BZ2_bzBuffToBuffDecompress>.

The first four arguments of both of these C functions are identical, and 
represent two buffers.  One buffer is the source, the second is the 
destination.  For the destination, the length is passed in as a pointer 
to an integer.  On input this integer is the size of the destination 
buffer, and thus the maximum size of the compressed or decompressed 
data.  When the function returns the actual size of compressed or 
compressed data is stored in this integer.

This is normal stuff for C, but in Perl our buffers are scalars and they 
already know how large they are.  In this sort of situation, wrapping 
the C function in some Perl code can make your interface a little more 
Perl like.  In order to do this, just provide a code reference as the 
last argument to the L</attach> method.  The first argument to this 
wrapper will be a code reference to the C function.  The Perl arguments 
will come in after that.  This allows you to modify / convert the 
arguments to conform to the C API.  What ever value you return from the 
wrapper function will be returned back to the original caller.

=cut

sub DESTROY
{
  my($self) = @_;
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
  $cbdata{refaddr $self} = [];
  $self;
}

sub add_data
{
  my($self, $payload) = @_;
  push @{ $cbdata{refaddr $self} }, bless \$payload, 'FFI::Platypus::ClosureData';
}

sub DESTROY
{
  my($self) = @_;
  delete $cbdata{refaddr $self};
}

package FFI::Platypus::ClosureData;

# VERSION

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
  my $size = 0;
  my $classname;
  my $rw = 0;

  if($type =~ /^string(_rw|_ro|\s+ro|\s+rw|\s*\([0-9]+\)|)$/)
  {
    my $extra = $1;
    $ffi_type = 'pointer';
    $platypus_type = 'string';
    $rw = 1 if $extra =~ /rw$/;
    $size = $1 if $extra =~ /\(([0-9]+)\)$/;
  }
  elsif($type =~ /^record\s*\(([0-9:A-Za-z_]+)\)$/)
  {
    $ffi_type = 'pointer';
    $platypus_type = 'record';
    if($1 =~ /^([0-9]+)$/)
    {
      $size = $1;
    }
    else
    {
      $classname = $1;
      unless($classname->can('ffi_record_size') || $classname->can('_ffi_record_size'))
      {
        eval qq{ use $classname };
        warn "error requiring $classname: $@";
      }
      if($classname->can('ffi_record_size'))
      {
        $size = $classname->ffi_record_size;
      }
      elsif($classname->can('_ffi_record_size'))
      {
        $size = $classname->_ffi_record_size;
      }
      else
      {
        croak "$classname has not ffi_record_size or _ffi_record_size method";
      }
    }
  }
  elsif($type =~ s/\s+\*$//) {
    $ffi_type = $type;
    $platypus_type = 'pointer';
  }
  elsif($type =~ s/\s+\[([0-9]+)\]$//)
  {
    $ffi_type = $type;
    $platypus_type = 'array';
    $size = $1;
  }
  else
  {
    $ffi_type = $type;
    $platypus_type = 'ffi';
  }
  
  $class->_new($ffi_type, $platypus_type, $size, $classname, $rw);
}

1;

=head1 SUPPORT

If something does not work the way you think it should, or if you have a 
feature request, please open an issue on this project's GitHub Issue 
tracker:

L<https://github.com/plicease/FFI-Platypus/issues>

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a 
pull request on this project's GitHub repository:

L<https://github.com/plicease/FFI-Platypus/pulls>

This project is developed using L<Dist::Zilla>.  The project's git 
repository also comes with C<Build.PL> and C<cpanfile> files necessary 
for building, testing (and even installing if necessary) without 
L<Dist::Zilla>.  Please keep in mind though that these files are 
generated so if changes need to be made to those files they should be 
done through the project's C<dist.ini> file.  If you do use 
L<Dist::Zilla> and already have the necessary plugins installed, then I 
encourage you to run C<dzil test> before making any pull requests.  This 
is not a requirement, however, I am happy to integrate especially 
smaller patches that need tweaking to fit the project standards.  I may 
push back and ask you to write a test case or alter the formatting of a 
patch depending on the amount of time I have and the amount of code that 
your patch touches.

This project's GitHub issue tracker listed above is not Write-Only.  If 
you want to contribute then feel free to browse through the existing 
issues and see if there is something you feel you might be good at and 
take a whack at the problem.  I frequently open issues myself that I 
hope will be accomplished by someone in the future but do not have time 
to immediately implement myself.

Another good area to help out in is documentation.  I try to make sure 
that there is good document coverage, that is there should be 
documentation describing all the public features and warnings about 
common pitfalls, but an outsider's or alternate view point on such 
things would be welcome; if you see something confusing or lacks 
sufficient detail I encourage documentation only pull requests to 
improve things.

The Platypus distribution comes with a test library named C<libtest> 
that is normally automatically built by C<./Build test>.  If you prefer 
to use C<prove> or run tests directly, you can use the C<./Build 
libtest> command to build it.  Example:

 % perl Build.PL
 % ./Build
 % ./Build libtest
 % prove -bv t
 # or an individual test
 % perl -Mblib t/ffi_platypus_memory.t

The build process also respects these environment variables:

=over 4

=item FFI_PLATYPUS_DEBUG

Build the XS code portion of Platypus with -g3 instead of what ever 
optimizing flags that your Perl normally uses.  This is useful if you 
need to debug the C or XS code that comes with Platypus, but do not have 
a debugging Perl.

 % env FFI_PLATYPUS_DEBUG=1 perl Build.PL
 
 
 DEBUG:
   - $Config{lddlflags} = -shared -O2 -L/usr/local/lib -fstack-protector
   + $Config{lddlflags} = -shared -g3 -L/usr/local/lib -fstack-protector
   - $Config{optimize} = -O2
   + $Config{optimize} = -g3
 
 
 Created MYMETA.yml and MYMETA.json
 Creating new 'Build' script for 'FFI-Platypus' version '0.10'

=item FFI_PLATYPUS_DEBUG_FAKE32

When building Platypus on 32 bit Perls, it will use the L<Math::Int64> C 
API and make L<Math::Int64> a prerequisite.  Setting this environment 
variable will force Platypus to build with both of those options on a 64 
bit Perl as well.

 % env FFI_PLATYPUS_DEBUG_FAKE32=1 perl Build.PL
 
 
 DEBUG_FAKE32:
   + making Math::Int64 a prerequsite (not normally done on 64 bit Perls)
   + using Math::Int64's C API to manipulate 64 bit values (not normally done on 64 bit Perls)
 
 Created MYMETA.yml and MYMETA.json
 Creating new 'Build' script for 'FFI-Platypus' version '0.10'

=item FFI_PLATYPUS_NO_ALLOCA

Platypus uses the non-standard and somewhat controversial C function 
C<alloca> by default on platforms that support it.  I believe that 
Platypus uses it responsibly to allocate small amounts of memory for 
argument type parameters, and does not use it to allocate large 
structures like arrays or buffers.  If you prefer not to use C<alloca> 
despite these precautions, then you can turn its use off by setting this 
environment variable when you run C<Build.PL>:

 % env FFI_PLATYPUS_NO_ALLOCA=1 perl Build.PL 
 
 
 NO_ALLOCA:
   + alloca() will not be used, even if your platform supports it.
 
 
  Created MYMETA.yml and MYMETA.json
  Creating new 'Build' script for 'FFI-Platypus' version '0.10'

=back

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus::Declare>

Declarative interface to Platypus.

=item L<FFI::Platypus::Type>

Type definitions for Platypus.

=item L<FFI::Platypus::API>

The custom types API for Platypus.

=item L<FFI::Platypus::Memory>

Memory functions for FFI.

=item L<FFI::CheckLib>

Find dynamic libraries in a portable way.

=item L<Module::Build::FFI>

Bundle C code with your FFI extension.

=item L<FFI::TinyCC>

JIT compiler for FFI.

=item L<FFI::Platypus::Lang::C>

Documentation and tools for using Platypus with the C programming 
language

=item L<FFI::Platypus::Lang::CPP>

Documentation and tools for using Platypus with the C++ programming 
language

=item L<FFI::Platypus::Lang::Rust>

Documentation and tools for using Platypus with the Rust programming 
language

=item L<FFI::Platypus::Lang::ASM>

Documentation and tools for using Platypus with the Assembly

=item L<Convert::Binary::C>

An interface for interacting with C C<struct> types.  Unfortunately it 
appears to be unmaintained, and has a failing pod test, so I cannot 
recommend it for use by CPAN modules.

=item L<pack and unpack|perlpacktut>

Native to Perl functions that can be used to decode C C<struct> types.

=item L<FFI::Raw>

Alternate interface to libffi with fewer features.  It notably lacks the 
ability to create real xsubs, which may make L<FFI::Platypus> much 
faster.  Also lacking are pointers to native types, arrays and custom 
types.  In its favor, it has been around for longer that Platypus, and 
has been battle tested to some success.

=item L<Win32::API>

Microsoft Windows specific FFI style interface.

=item L<Ctypes|https://gitorious.org/perl-ctypes>

Ctypes was intended as a FFI style interface for Perl, but was never 
part of CPAN, and at least the last time I tried it did not work with 
recent versions of Perl.

=item L<FFI>

Foreign function interface based on (nomenclature is everything) FSF's 
C<ffcall>. It hasn't worked for quite some time, and C<ffcall> is no 
longer supported or distributed.

=item L<C::DynaLib>

Another FFI for Perl that doesn't appear to have worked for a long time.

=back

=cut

