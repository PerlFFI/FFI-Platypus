package FFI::Platypus;

use strict;
use warnings;
use 5.008001;
use Carp qw( croak );
use FFI::Platypus::Function;
use FFI::Platypus::Type;

# ABSTRACT: Write Perl bindings to non-Perl libraries with FFI. No XS required.
# VERSION

# Platypus Man,
# Platypus Man,
# Does Everything The Platypus Can
# ...
# Watch Out!
# Here Comes The Platypus Man

# From the original FFI::Platypus prototype:
#  Kinda like gluing a duckbill to an adorable mammal

=begin stopwords

ØMQ

=end stopwords

=head1 SYNOPSIS

 use FFI::Platypus;
 
 # for all new code you should use api => 1
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->lib(undef); # search libc
 
 # call dynamically
 $ffi->function( puts => ['string'] => 'int' )->call("hello world");
 
 # attach as a xsub and call (much faster)
 $ffi->attach( puts => ['string'] => 'int' );
 puts("hello world");

=head1 DESCRIPTION

Platypus is a library for creating interfaces to machine code libraries
written in languages like C, L<C++|FFI::Platypus::Lang::CPP>,
L<Fortran|FFI::Platypus::Lang::Fortran>,
L<Rust|FFI::Platypus::Lang::Rust>,
L<Pascal|FFI::Platypus::Lang::Pascal>. Essentially anything that gets
compiled into machine code.  This implementation uses C<libffi> to
accomplish this task.  C<libffi> is battle tested by a number of other
scripting and virtual machine languages, such as Python and Ruby to
serve a similar role.  There are a number of reasons why you might want
to write an extension with Platypus instead of XS:

=over 4

=item FFI / Platypus does not require messing with the guts of Perl

XS is less of an API and more of the guts of perl splayed out to do
whatever you want.  That may at times be very powerful, but it can also
be a frustrating exercise in hair pulling.

=item FFI / Platypus is portable

Lots of languages have FFI interfaces, and it is subjectively easier to
port an extension written in FFI in Perl or another language to FFI in
another language or Perl.  One goal of the Platypus Project is to reduce
common interface specifications to a common format like JSON that could
be shared between different languages.

=item FFI / Platypus could be a bridge to Perl 6

One of those "other" languages could be Perl 6 and Perl 6 already has an
FFI interface I am told.

=item FFI / Platypus can be reimplemented

In a bright future with multiple implementations of Perl 5, each
interpreter will have its own implementation of Platypus, allowing
extensions to be written once and used on multiple platforms, in much
the same way that Ruby-FFI extensions can be use in Ruby, JRuby and
Rubinius.

=item FFI / Platypus is pure perl (sorta)

One Platypus script or module works on any platform where the libraries
it uses are available.  That means you can deploy your Platypus script
in a shared filesystem where they may be run on different platforms.  It
also means that Platypus modules do not need to be installed in the
platform specific Perl library path.

=item FFI / Platypus is not C or C++ centric

XS is implemented primarily as a bunch of C macros, which requires at
least some understanding of C, the C pre-processor, and some C++ caveats
(since on some platforms Perl is compiled and linked with a C++
compiler). Platypus on the other hand could be used to call other
compiled languages, like L<Fortran|FFI::Platypus::Lang::Fortran>,
L<Rust|FFI::Platypus::Lang::Rust>,
L<Pascal|FFI::Platypus::Lang::Pascal>, L<C++|FFI::Platypus::Lang::CPP>,
or even L<assembly|FFI::Platypus::Lang::ASM>, allowing you to focus
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

Platypus has extensive documentation of types at L<FFI::Platypus::Type>
and its custom types API at L<FFI::Platypus::API>.

You are B<strongly> encouraged to use API level 1 for all new code.
There are a number of improvements and design fixes that you get
for free.  You should even consider updating existing modules to
use API level 1 where feasible.  How do I do that you might ask?
Simply pass in the API level to the platypus constructor.

 my $ffi = FFI::Platypus->new( api => 1 );

The Platypus documentation has already been updated to assume API
level 1.

=cut

our @CARP_NOT = qw( FFI::Platypus::Declare FFI::Platypus::Record );

require XSLoader;
XSLoader::load(
  'FFI::Platypus', $FFI::Platypus::VERSION || 0
);

=head1 CONSTRUCTORS

=head2 new

 my $ffi = FFI::Platypus->new( api => 1, %options);

Create a new instance of L<FFI::Platypus>.

Any types defined with this instance will be valid for this instance
only, so you do not need to worry about stepping on the toes of other
CPAN FFI / Platypus Authors.

Any functions found will be out of the list of libraries specified with
the L<lib|/lib> attribute.

=head3 options

=over 4

=item api

Sets the API level.  Legal values are

=over

=item C<0>

Original API level.  See L<FFI::Platypus::TypeParser::Version0> for details
on the differences.

=item C<1>

Enable the next generation type parser which allows pass-by-value records
and type decoration on basic types.  Using API level 1 prior to Platypus
version 1.00 will trigger a (noisy) warning.

All new code should be written with this set to 1!  The Platypus documentation
assumes this api level is set.

=back

=item lib

Either a pathname (string) or a list of pathnames (array ref of strings)
to pre-populate the L<lib|/lib> attribute.  Use C<[undef]> to search the
current process for symbols.

0.48

C<undef> (without the array reference) can be used to search the current
process for symbols.

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
  if(exists $args{lib})
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

  my $api          = $args{api} || 0;
  my $experimental = $args{experimental} || 0;

  if($experimental == 1)
  {
    Carp::croak("Please do not use the experimental version of api = 1, instead require FFI::Platypus 1.00 or better");
  }

  if(defined $api && $api > 1 && $experimental != $api)
  {
    Carp::cluck("Enabling development API version $api prior to FFI::Platypus $api.00");
  }

  my $tp;

  if($api == 0)
  {
    $tp = 'Version0';
  }
  elsif($api == 1)
  {
    $tp = 'Version1';
  }
  elsif($api == 2)
  {
    $tp = 'Version1';
  }
  else
  {
    Carp::croak("API version $api not (yet) implemented");
  }

  require "FFI/Platypus/TypeParser/$tp.pm";
  $tp = "FFI::Platypus::TypeParser::$tp";

  my $self = bless {
    lib              => \@lib,
    lang             => '',
    handles          => {},
    abi              => -1,
    api              => $api,
    tp               => $tp->new,
    fini             => [],
    ignore_not_found => defined $args{ignore_not_found} ? $args{ignore_not_found} : 0,
  }, $class;

  $self->lang($args{lang} || 'C');

  $self;
}

sub _lang_class ($)
{
  my($lang) = @_;
  my $class = $lang =~ m/^=(.*)$/ ? $1 : "FFI::Platypus::Lang::$lang";
  unless($class->can('native_type_map'))
  {
    my $pm = "$class.pm";
    $pm =~ s/::/\//g;
    require $pm;
  }
  croak "$class does not provide native_type_map method"
    unless $class->can("native_type_map");
  $class;
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
    push @{ $self->{lib} }, map { ref $_ eq 'CODE' ? $_->() : $_ } @new;
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

  if(defined $value && $value ne $self->{lang})
  {
    $self->{lang} = $value;
    my $class = _lang_class($self->{lang});
    $self->abi($class->abi) if $class->can('abi');

    {
      my %type_map;
      my $map = $class->native_type_map(
        $self->{api} > 0
          ? (api => $self->{api})
          : ()
      );
      foreach my $key (keys %$map)
      {
        my $value = $map->{$key};
        next unless $self->{tp}->have_type($value);
        $type_map{$key} = $value;
      }
      $type_map{$_} = $_ for grep { $self->{tp}->have_type($_) }
        qw( void sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double string opaque
            longdouble complex_float complex_double );
      $type_map{pointer} = 'opaque' if $self->{tp}->isa('FFI::Platypus::TypeParser::Version0');
      $self->{tp}->type_map(\%type_map);
    }
  }

  $self->{lang};
}

=head2 api

[version 1.11]

 my $level = $ffi->api;

Returns the API level of the Platypus instance.

=cut

sub api { shift->{api} }

=head1 METHODS

=head2 type

 $ffi->type($typename);
 $ffi->type($typename => $alias);

Define a type.  The first argument is the native or C name of the type.
The second argument (optional) is an alias name that you can use to
refer to this new type.  See L<FFI::Platypus::Type> for legal type
definitions.

Examples:

 $ffi->type('sint32');            # oly checks to see that sint32 is a valid type
 $ffi->type('sint32' => 'myint'); # creates an alias myint for sint32
 $ffi->type('bogus');             # dies with appropriate diagnostic

=cut

sub type
{
  my($self, $name, $alias) = @_;
  croak "usage: \$ffi->type(name => alias) (alias is optional)" unless defined $self && defined $name;

  $self->{tp}->check_alias($alias) if defined $alias;
  my $type = $self->{tp}->parse($name);
  $self->{tp}->set_alias($alias, $type) if defined $alias;

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
  my($self, $alias, $cb) = @_;

  my $argument_count = $cb->{argument_count} || 1;

  croak "argument_count must be >= 1"
    unless $argument_count >= 1;

  croak "Usage: \$ffi->custom_type(\$alias, { ... })"
    unless defined $alias && ref($cb) eq 'HASH';

  croak "must define at least one of native_to_perl, perl_to_native, or perl_to_native_post"
    unless defined $cb->{native_to_perl} || defined $cb->{perl_to_native} || defined $cb->{perl_to_native_post};

  $self->{tp}->check_alias($alias);

  my $type = $self->{tp}->create_type_custom(
    $cb->{native_type},
    $cb->{perl_to_native},
    $cb->{native_to_perl},
    $cb->{perl_to_native_post},
    $argument_count,
  );

  $self->{tp}->set_alias($alias, $type);

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
    my $pm = "$name.pm";
    $pm =~ s/::/\//g;
    eval { require $pm };
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

=head2 types

 my @types = $ffi->types;
 my @types = FFI::Platypus->types;

Returns the list of types that FFI knows about.  This will include the
native C<libffi> types (example: C<sint32>, C<opaque> and C<double>) and
the normal C types (example: C<unsigned int>, C<uint32_t>), any types
that you have defined using the L<type|/type> method, and custom types.

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
  sort $self->{tp}->list_types;
}

=head2 type_meta

 my $meta = $ffi->type_meta($type_name);
 my $meta = FFI::Platypus->type_meta($type_name);

Returns a hash reference with the meta information for the given type.

It can also be called as a class method, in which case, you won't be
able to get meta data on user defined types.

The format of the meta data is implementation dependent and subject to
change.  It may be useful for display or debugging.

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
  $self->{tp}->parse($name)->meta;
}

=head2 mangler

 $ffi->mangler(\&mangler);

Specify a customer mangler to be used for symbol lookup.  This is usually useful
when you are writing bindings for a library where all of the functions have the
same prefix.  Example:

 $ffi->mangler(sub {
   my($symbol) = @_;
   return "foo_$symbol";
 });
 
 $ffi->function( get_bar => [] => 'int' );  # attaches foo_get_bar
 
 my $f = $ffi->function( set_baz => ['int'] => 'void' );
 $f->call(22); # calls foo_set_baz

=cut

sub mangler
{
  my($self, $sub) = @_;
  $self->{mangler} = $self->{mymangler} = $sub;
}

=head2 function

 my $function = $ffi->function($name => \@argument_types => $return_type);
 my $function = $ffi->function($address => \@argument_types => $return_type);
 my $function = $ffi->function($name => \@argument_types => $return_type, \&wrapper);
 my $function = $ffi->function($address => \@argument_types => $return_type, \&wrapper);

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

Under the covers, L<function|/function> uses L<find_symbol|/find_symbol>
when you provide it with a name, but it is useful to keep this in mind
as there are alternative ways of obtaining a functions address.
Example: a C function could return the address of another C function
that you might want to call, or modules such as L<FFI::TinyCC> produce
machine code at runtime that you can call from Platypus.

[version 0.76]

If the last argument is a code reference, then it will be used as a
wrapper around the function when called.  The first argument to the wrapper
will be the inner function, or if it is later attached an xsub.  This can be
used if you need to verify/modify input/output data.

Examples:

 my $function = $ffi->function('my_function_name', ['int', 'string'] => 'string');
 my $return_string = $function->(1, "hi there");

[version 0.91]

 my $function = $ffi->function( $name => \@fixed_argument_types => \@var_argument_types => $return_type);
 my $function = $ffi->function( $name => \@fixed_argument_types => \@var_argument_types => $return_type, \&wrapper);

Version 0.91 and later allows you to creat functions for c variadic functions
(such as printf, scanf, etc) which can take a variable number of arguments.
The first set of arguments are the fixed set, the second set are the variable
arguments to bind with.  The variable argument types must be specified in order
to create a function object, so if you need to call variadic function with
different set of arguments then you will need to create a new function object
each time:

 # int printf(const char *fmt, ...);
 $ffi->function( printf => ['string'] => ['int'] => 'int' )
     ->call("print integer %d\n", 42);
 $ffi->function( printf => ['string'] => ['string'] => 'int' )
     ->call("print string %s\n", 'platypus');

Some older versions of libffi and possibly some platforms may not support
variadic functions.  If you try to create a one, then an exception will be
thrown.

=cut

sub function
{
  my $wrapper;
  $wrapper = pop if ref $_[-1] eq 'CODE';

  croak "usage \$ffi->function( name, [ arguments ], return_type)" unless @_ >= 4 && @_ <= 6;

  my $self = shift;
  my $name = shift;
  my $fixed_args = shift;
  my $var_args;
  $var_args = shift if defined $_[0] && ref($_[0]) eq 'ARRAY';
  my $ret = shift;

  # special case: treat a single void argument type as an empty list of
  # arguments, a la olde timey C compilers.
  if( (!defined $var_args) && @$fixed_args == 1 && $fixed_args->[0] eq 'void' )
  {
    $fixed_args = [];
  }

  my $args = [@$fixed_args, @{ $var_args || [] } ];
  my $fixed_arg_count = defined $var_args ? scalar(@$fixed_args) : -1;

  my @args = map { $self->{tp}->parse($_) || croak "unknown type: $_" } @$args;
  $ret = $self->{tp}->parse($ret) || croak "unknown type: $ret";
  my $address = $name =~ /^-?[0-9]+$/ ? $name : $self->find_symbol($name);
  croak "unable to find $name" unless defined $address || $self->ignore_not_found;
  return unless defined $address;
  $address = @args > 0 ? _cast1() : _cast0() if $address == 0;
  my $function = FFI::Platypus::Function::Function->new($self, $address, $self->{abi}, $fixed_arg_count, $ret, @args);
  $wrapper
    ? FFI::Platypus::Function::Wrapper->new($function, $wrapper)
    : $function;
}

sub _function_meta
{
  # NOTE: may be upgraded to a documented function one day,
  # but shouldn't be used externally as we will rename it
  # if that happens.
  my($self, $name, $meta, $args, $ret) = @_;
  $args = ['opaque','int',@$args];
  $self->function(
    $name, $args, $ret, sub {
      my $xsub = shift;
      $xsub->($meta, scalar(@_), @_);
    },
  );
}

=head2 attach

 $ffi->attach($name => \@argument_types => $return_type);
 $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type);
 $ffi->attach([$address => $perl_name] => \@argument_types => $return_type);
 $ffi->attach($name => \@argument_types => $return_type, \&wrapper);
 $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type, \&wrapper);
 $ffi->attach([$address => $perl_name] => \@argument_types => $return_type, \&wrapper);

Find and attach a C function as a real live Perl xsub.  The advantage of
attaching a function over using the L<function|/function> method is that
it is much much much faster since no object resolution needs to be done.
The disadvantage is that it locks the function and the L<FFI::Platypus>
instance into memory permanently, since there is no way to deallocate an
xsub.

If just one I<$name> is given, then the function will be attached in
Perl with the same name as it has in C.  The second form allows you to
give the Perl function a different name.  You can also provide an
address (the third form), just like with the L<function|/function>
method.

Examples:

 $ffi->attach('my_functon_name', ['int', 'string'] => 'string');
 $ffi->attach(['my_c_functon_name' => 'my_perl_function_name'], ['int', 'string'] => 'string');
 my $string1 = my_function_name($int);
 my $string2 = my_perl_function_name($int);

[version 0.20]

If the last argument is a code reference, then it will be used as a
wrapper around the attached xsub.  The first argument to the wrapper
will be the inner xsub.  This can be used if you need to verify/modify
input/output data.

Examples:

 $ffi->attach('my_function', ['int', 'string'] => 'string', sub {
   my($my_function_xsub, $integer, $string) = @_;
   $integer++;
   $string .= " and another thing";
   my $return_string = $my_function_xsub->($integer, $string);
   $return_string =~ s/Belgium//; # HHGG remove profanity
   $return_string;
 });

[version 0.91]

 $ffi->attach($name => \@fixed_argument_types => \@var_argument_types, $return_type);
 $ffi->attach($name => \@fixed_argument_types => \@var_argument_types, $return_type, \&wrapper);

As of version 0.91 you can attach a variadic functions, if it is supported
by the platform / libffi that you are using.  For details see the C<function>
documentation.  If not supported by the implementation then an exception
will be thrown.

=cut

sub attach
{
  my $wrapper;
  $wrapper = pop if ref $_[-1] eq 'CODE';

  my $self = shift;
  my $name = shift;
  my $args = shift;
  my $varargs;
  $varargs = shift if defined $_[0] && ref($_[0]) eq 'ARRAY';
  my $ret = shift;
  my $proto = shift;

  $ret = 'void' unless defined $ret;

  my($c_name, $perl_name) = ref($name) ? @$name : ($name, $name);

  croak "you tried to provide a perl name that looks like an address"
    if $perl_name =~ /^-?[0-9]+$/;

  my $function = $varargs
    ? $self->function($c_name, $args, $varargs, $ret, $wrapper)
    : $self->function($c_name, $args, $ret, $wrapper);

  if(defined $function)
  {
    $function->attach($perl_name, $proto);
  }

  $self;
}

=head2 closure

 my $closure = $ffi->closure($coderef);
 my $closure = FFI::Platypus->closure($coderef);

Prepares a code reference so that it can be used as a FFI closure (a
Perl subroutine that can be called from C code).  For details on
closures, see L<FFI::Platypus::Type#Closures> and L<FFI::Platypus::Closure>.

=cut

sub closure
{
  my($self, $coderef) = @_;
  croak "not a coderef" unless ref $coderef eq 'CODE';
  require FFI::Platypus::Closure;
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
 my $size = FFI::Platypus->sizeof($type);

Returns the total size of the given type in bytes.  For example to get
the size of an integer:

 my $intsize = $ffi->sizeof('int');   # usually 4
 my $longsize = $ffi->sizeof('long'); # usually 4 or 8 depending on platform

You can also get the size of arrays

 my $intarraysize = $ffi->sizeof('int[64]');  # usually 4*64
 my $intarraysize = $ffi->sizeof('long[64]'); # usually 4*64 or 8*64
                                              # depending on platform

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
  ref $self
    ? $self->{tp}->parse($name)->sizeof
    : $self->new->sizeof($name);
}

=head2 alignof

[version 0.21]

 my $align = $ffi->alignof($type);

Returns the alignment of the given type in bytes.

=cut

sub alignof
{
  my($self, $name) = @_;
  ref $self
    ? $self->{tp}->parse($name)->alignof
    : $self->new->alignof($name);
}

# will make public versions of these when they are ready
sub _kindof
{
  my($self, $name) = @_;
  ref $self
    ? $self->{tp}->parse($name)->kindof
    : $self->new->_kindof($name);
}

sub _countof
{
  my($self, $name) = @_;
  ref $self
    ? $self->{tp}->parse($name)->countof
    : $self->new->_countof($name);
}

sub _def
{
  my $self = shift;
  my $package = shift || caller;
  my $type = shift;
  $self->type($type);
  if(@_)
  {
    $self->{def}->{$package}->{$type} = shift;
  }
  $self->{def}->{$package}->{$type};
}

sub _unitof
{
  my($self, $name) = @_;
  ref $self
    ? $self->{tp}->parse($name)->unitof
    : $self->new->_unitof($name);
}

=head2 find_lib

[version 0.20]

 $ffi->find_lib( lib => $libname );

This is just a shortcut for calling L<FFI::CheckLib#find_lib> and
updating the L</lib> attribute appropriately.  Care should be taken
though, as this method simply passes its arguments to
L<FFI::CheckLib#find_lib>, so if your module or script is depending on a
specific feature in L<FFI::CheckLib> then make sure that you update your
prerequisites appropriately.

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

  $self->{mangler} ||= $self->{mymangler};

  unless(defined $self->{mangler})
  {
    my $class = _lang_class($self->{lang});
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
    my $handle = do { no warnings; $self->{handles}->{$path||0} } || FFI::Platypus::DL::dlopen($path, FFI::Platypus::DL::RTLD_PLATYPUS_DEFAULT());
    unless($handle)
    {
      warn "warning: error loading $path: ", FFI::Platypus::DL::dlerror()
        if $self->{api} > 0 || $ENV{FFI_PLATYPUS_DLERROR};
      next;
    }
    my $address = FFI::Platypus::DL::dlsym($handle, $self->{mangler}->($name));
    if($address)
    {
      $self->{handles}->{$path||0} = $handle;
      return $address;
    }
    else
    {
      FFI::Platypus::DL::dlclose($handle) unless $self->{handles}->{$path||0};
    }
  }
  return;
}

=head2 bundle

[version 0.96 api = 1+]

 $ffi->bundle($package, \@args);
 $ffi->bundle(\@args);
 $ffi->bundle($package);
 $ffi->bundle;

This is an interface for bundling compiled code with your
distribution intended to eventually replace the C<package> method documented
above.  See L<FFI::Platypus::Bundle> for details on how this works.

=cut

sub bundle
{
  croak "bundle method only available with api => 1 or better" if $_[0]->{api} < 1;
  require FFI::Platypus::Bundle;
  goto &_bundle;
}

=head2 package

[version 0.15 api = 0]

 $ffi->package($package, $file); # usually __PACKAGE__ and __FILE__ can be used
 $ffi->package;                  # autodetect

B<Note>: This method is officially discouraged in favor of C<bundle>
described above.

If you use L<FFI::Build> (or the older deprecated L<Module::Build::FFI>
to bundle C code with your distribution, you can use this method to tell
the L<FFI::Platypus> instance to look for symbols that came with the
dynamic library that was built when your distribution was installed.

=cut

sub package
{
  croak "package method only available with api => 0" if $_[0]->{api} > 0;
  require FFI::Platypus::Legacy;
  goto &_package;
}

=head2 abis

 my $href = $ffi->abis;
 my $href = FFI::Platypus->abis;

Get the legal ABIs supported by your platform and underlying
implementation.  What is supported can vary a lot by CPU and by
platform, or even between 32 and 64 bit on the same CPU and platform.
They keys are the "ABI" names, also known as "calling conventions".  The
values are integers used internally by the implementation to represent
those ABIs.

=cut

sub abis
{
  require FFI::Platypus::ShareConfig;
  FFI::Platypus::ShareConfig->get("abi");
}

=head2 abi

 $ffi->abi($name);

Set the ABI or calling convention for use in subsequent calls to
L</function> or L</attach>.  May be either a string name or integer
value from the L</abis> method above.

=cut

sub abi
{
  my($self, $newabi) = @_;
  unless($newabi =~ /^[0-9]+$/)
  {
    unless(defined $self->abis->{$newabi})
    {
      croak "no such ABI: $newabi";
    }
    $newabi = $self->abis->{$newabi};
  }

  unless(FFI::Platypus::ABI::verify($newabi))
  {
    croak "no such ABI: $newabi";
  }

  $self->{abi} = $newabi;

  $self;
}

sub DESTROY
{
  my($self) = @_;
  foreach my $fini (@{ $self->{fini} })
  {
    $fini->($self);
  }
  foreach my $handle (values %{ $self->{handles} })
  {
    next unless $handle;
    FFI::Platypus::DL::dlclose($handle);
  }
  delete $self->{handles};
}

1;

__END__

=head1 EXAMPLES

Here are some examples.  These examples
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

 $ffi->attach( [notify_notification_new => 'notify_new']
   => ['string','string','string']
   => 'opaque'
 );

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

=head2 structured data records

# EXAMPLE: examples/time_record.pl

B<Discussion>: C and other machine code languages frequently provide
interfaces that include structured data records (known as "structs" in
C).  They sometimes provide an API in which you are expected to
manipulate these records before and/or after passing them along to C
functions.  There are a few ways of dealing with such interfaces, but
the easiest way is demonstrated here defines a record class using a
specific layout.  For more details see L<FFI::Platypus::Record>.
(L<FFI::Platypus::Type> includes some other ways of manipulating
structured data records).

The C C<localtime> function takes a pointer to a record, hence we suffix
the type with a star: C<record(My::UnixTime)*>.  If the function takes
a record in pass-by-value mode then we'd just say C<record(My::UnixTime)>
with no star suffix.

=head2 libuuid

# EXAMPLE: examples/uuid.pl

B<Discussion>: libuuid is a library used to generate unique identifiers
(UUID) for objects that may be accessible beyond the local system.  The
library is or was part of the Linux e2fsprogs package.

Knowing the size of objects is sometimes important.  In this example, we
use the L<sizeof|/sizeof> function to get the size of 16 characters (in
this case it is simply 16 bytes).  We also know that the strings
"deparsed" by C<uuid_unparse> are exactly 37 bytes.

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
L<function|/function> or L<attach|/attach> methods.  In this example we
use L<FFI::TinyCC> to compile a short piece of C code and to give us the
address of one of its functions, which we then use to create a perl xsub
to call it.

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

# EXAMPLE: examples/archive_object.pl

B<Discussion>: libarchive is the implementation of C<tar> for FreeBSD
provided as a library and available on a number of platforms.

One interesting thing about libarchive is that it provides a kind of
object oriented interface via opaque pointers.  This example creates an
abstract class C<Archive>, and concrete classes C<ArchiveWrite>,
C<ArchiveRead> and C<ArchiveEntry>.  The concrete classes can even be
inherited from and extended just like any Perl classes because of the
way the custom types are implemented.  We use Platypus's C<object>
type for this implementation, which is a wrapper around an C<opaque>
(can also be an integer) type that is blessed into a particular class.

Another advanced feature of this example is that we define a mangler
to modify the symbol resolution for each class.  This means we can do
this when we define a method for Archive:

 $ffi->attach( support_filter_all => ['archive_t'] => 'int' );

Rather than this:

 $ffi->attach(
   [ archive_read_support_filter_all => 'support_read_filter_all' ] =>
   ['archive_t'] => 'int' );
 );

=head2 unix open

# EXAMPLE: examples/file_handle.pl

B<Discussion>: The Unix file system calls use an integer handle for
each open file.  We can use the same C<object> type that we used
for libarchive above, except we let platypus know that the underlying
type is C<int> instead of C<opaque> (the latter being the default for
the C<object> type).  Mainly just for demonstration since Perl has much
better IO libraries, but now we have an OO interface to the Unix IO
functions.

=head2 bzip2

# EXAMPLE: examples/bzip2.pl

B<Discussion>: bzip2 is a compression library.  For simple one shot
attempts at compression/decompression when you expect the original and
the result to fit within memory it provides two convenience functions
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

=head2 bundle your own code

C<ffi/foo.c>:

# EXAMPLE: examples/bundle-foo/ffi/foo.c

C<lib/Foo.pm>:

# EXAMPLE: examples/bundle-foo/lib/Foo.pm

You can bundle your own C (or other compiled language) code with your
Perl extension.  Sometimes this is helpful for smoothing over the
interface of a C library which is not very FFI friendly.  Sometimes
you may want to write some code in C for a tight loop.  Either way,
you can do this with the Platypus bundle interface.  See
L<FFI::Platypus::Bundle> for more details.

Also related is the bundle constant interface, which allows you to
define Perl constants in C space.  See L<FFI::Platypus::Constant>
for details.

=head1 FAQ

=head2 How do I get constants defined as macros in C header files

This turns out to be a challenge for any language calling into C, which
frequently uses C<#define> macros to define constants like so:

 #define FOO_STATIC  1
 #define FOO_DYNAMIC 2
 #define FOO_OTHER   3

As macros are expanded and their definitions are thrown away by the C pre-processor
there isn't any way to get the name/value mappings from the compiled dynamic
library.

You can manually create equivalent constants in your Perl source:

 use constant FOO_STATIC  => 1;
 use constant FOO_DYNAMIC => 2;
 use constant FOO_OTHER   => 3;

If there are a lot of these types of constants you might want to consider using
a tool (L<Convert::Binary::C> can do this) that can extract the constants for you.

See also the "Integer constants" example in L<FFI::Platypus::Type>.

You can also use the new Platypus bundle interface to define Perl constants
from C space.  This is more reliable, but does require a compiler at install
time.  It is recommended mainly for writing bindings against libraries that
have constants that can vary widely from platform to platform.  See
L<FFI::Platypus::Constant> for details.

=head2 What about enums?

The C enum types are integers.  The underlying type is up to the platform, so
Platypus provides C<enum> and C<senum> types for unsigned and singed enums
respectively.  At least some compilers treat signed and unsigned enums as
different types.  The enum I<values> are essentially the same as macro constants
described above from an FFI perspective.  Thus the process of defining enum values
is identical to the process of defining macro constants in Perl.

For more details on enumerated types see L<FFI::Platypus::Type/"Enum types">.

=head2 Memory leaks

There are a couple places where memory is allocated, but never deallocated that may
look like memory leaks by tools designed to find memory leaks like valgrind.  This
memory is intended to be used for the lifetime of the perl process so there normally
this isn't a problem unless you are embedding a Perl interpreter which doesn't closely
match the lifetime of your overall application.

Specifically:

=over 4

=item type cache

some types are cached and not freed.  These are needed as long as there are FFI
functions that could be called.

=item attached functions

Attaching a function as an xsub will definitely allocate memory that won't be freed
because the xsub could be called at any time, including in C<END> blocks.

=back

The Platypus team plans on adding a hook to free some of this "leaked" memory
for use cases where Perl and Platypus are embedded in a larger application
where the lifetime of the Perl process is significantly smaller than the
overall lifetime of the whole process.

=head2 I get seg faults on some platforms but not others with a library using pthreads.

On some platforms, Perl isn't linked with C<libpthreads> if Perl threads are not
enabled.  On some platforms this doesn't seem to matter, C<libpthreads> can be
loaded at runtime without much ill-effect.  (Linux from my experience doesn't seem
to mind one way or the other).  Some platforms are not happy about this, and about
the only thing that you can do about it is to build Perl such that it links with
C<libpthreads> even if it isn't a threaded Perl.

This is not really an FFI issue, but a Perl issue, as you will have the same
problem writing XS code for the such libraries.

=head2 Doesn't work on Perl 5.10.0.

I try as best as possible to support the same range of Perls as the Perl toolchain.
That means all the way back to 5.8.1.  Unfortunately, 5.10.0 seems to have a problem
that is difficult to diagnose.  Patches to fix are welcome, if you want to help
out on this, please see:

L<https://github.com/Perl5-FFI/FFI-Platypus/issues/68>

Since this is an older buggy version of Perl it is recommended that you instead
upgrade to 5.10.1 or later.

=head1 CAVEATS

Platypus and Native Interfaces like libffi rely on the availability of
dynamic libraries.  Things not supported include:

=over 4

=item Systems that lack dynamic library support

Like MS-DOS

=item Systems that are not supported by libffi

Like OpenVMS

=item Languages that do not support using dynamic libraries from other languages

Like older versions of Google's Go. This is a problem for C / XS code as well.

=item Languages that do not compile to machine code

Like .NET based languages and Java.

=back

The documentation has a bias toward using FFI / Platypus with C.  This
is my fault, as my background in mainly in C/C++ programmer (when I am
not writing Perl).  In many places I use "C" as a short form for "any
language that can generate machine code and is callable from C".  I
welcome pull requests to the Platypus core to address this issue.  In an
attempt to ease usage of Platypus by non C programmers, I have written a
number of foreign language plugins for various popular languages (see
the SEE ALSO below).  These plugins come with examples specific to those
languages, and documentation on common issues related to using those
languages with FFI.  In most cases these are available for easy adoption
for those with the know-how or the willingness to learn.  If your
language doesn't have a plugin YET, that is just because you haven't
written it yet.

=head1 SUPPORT

IRC: #native on irc.perl.org

L<(click for instant chat room login)|http://chat.mibbit.com/#native@irc.perl.org>

If something does not work the way you think it should, or if you have a
feature request, please open an issue on this project's GitHub Issue
tracker:

L<https://github.com/perl5-FFI/FFI-Platypus/issues>

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a
pull request on this project's GitHub repository:

L<https://github.com/Perl5-FFI/FFI-Platypus/pulls>

This project is developed using L<Dist::Zilla>.  The project's git
repository also comes with the C<Makefile.PL> file necessary
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

 % perl Makefile.PL
 % make
 % make ffi-test
 % prove -bv t
 # or an individual test
 % perl -Mblib t/ffi_platypus_memory.t

The build process also respects these environment variables:

=over 4

=item FFI_PLATYPUS_DEBUG_FAKE32

When building Platypus on 32 bit Perls, it will use the L<Math::Int64> C
API and make L<Math::Int64> a prerequisite.  Setting this environment
variable will force Platypus to build with both of those options on a 64
bit Perl as well.

 % env FFI_PLATYPUS_DEBUG_FAKE32=1 perl Makefile.PL
 DEBUG_FAKE32:
   + making Math::Int64 a prereq
   + Using Math::Int64's C API to manipulate 64 bit values
 Generating a Unix-style Makefile
 Writing Makefile for FFI::Platypus
 Writing MYMETA.yml and MYMETA.json
 %

=item FFI_PLATYPUS_NO_ALLOCA

Platypus uses the non-standard and somewhat controversial C function
C<alloca> by default on platforms that support it.  I believe that
Platypus uses it responsibly to allocate small amounts of memory for
argument type parameters, and does not use it to allocate large
structures like arrays or buffers.  If you prefer not to use C<alloca>
despite these precautions, then you can turn its use off by setting this
environment variable when you run C<Makefile.PL>:

 helix% env FFI_PLATYPUS_NO_ALLOCA=1 perl Makefile.PL
 NO_ALLOCA:
   + alloca() will not be used, even if your platform supports it.
 Generating a Unix-style Makefile
 Writing Makefile for FFI::Platypus
 Writing MYMETA.yml and MYMETA.json

=item V

When building platypus may hide some of the excessive output when
probing and building, unless you set C<V> to a true value.

 % env V=1 perl Makefile.PL
 % make V=1
 ...

=back

=head2 Coding Guidelines

=over 4

=item

Do not hesitate to make code contribution.  Making useful contributions
is more important than following byzantine bureaucratic coding
regulations.  We can always tweak things later.

=item

Please make an effort to follow existing coding style when making pull
requests.

=item

Platypus supports all production Perl releases since 5.8.1.  For that
reason, please do not introduce any code that requires a newer version
of Perl.

=back

=head2 Performance Testing

As Mark Twain was fond of saying there are four types of lies: lies,
damn lies, statistics and benchmarks.  That being said, it can sometimes
be helpful to compare the runtime performance of Platypus if you are
making significant changes to the Platypus Core.  For that I use
`FFI-Performance`, which can be found in my GitHub repository here:

=over 4

=item L<https://github.com/Perl5-FFI/FFI-Performance>

=back

=head2 System integrators

This distribution uses L<Alien::FFI> in fallback mode, meaning if
the system doesn't provide C<pkg-config> and C<libffi> it will attempt
to download C<libffi> and build it from source.  If you are including
Platypus in a larger system (for example a Linux distribution) you
only need to make sure to declare C<pkg-config> or C<pkgconf> and
the development package for C<libffi> as prereqs for this module.

=head1 SEE ALSO

=over 4

=item L<NativeCall>

Promising interface to Platypus inspired by Perl 6.

=item L<FFI::Platypus::Type>

Type definitions for Platypus.

=item L<FFI::Platypus::Record>

Define structured data records (C "structs") for use with
Platypus.

=item L<FFI::Platypus::API>

The custom types API for Platypus.

=item L<FFI::Platypus::Memory>

Memory functions for FFI.

=item L<FFI::CheckLib>

Find dynamic libraries in a portable way.

=item L<FFI::TinyCC>

JIT compiler for FFI.

=item L<FFI::Platypus::Lang::C>

Documentation and tools for using Platypus with the C programming
language

=item L<FFI::Platypus::Lang::CPP>

Documentation and tools for using Platypus with the C++ programming
language

=item L<FFI::Platypus::Lang::Fortran>

Documentation and tools for using Platypus with Fortran

=item L<FFI::Platypus::Lang::Pascal>

Documentation and tools for using Platypus with Free Pascal

=item L<FFI::Platypus::Lang::Rust>

Documentation and tools for using Platypus with the Rust programming
language

=item L<FFI::Platypus::Lang::ASM>

Documentation and tools for using Platypus with the Assembly

=item L<Convert::Binary::C>

A great interface for decoding C data structures, including C<struct>s,
C<enum>s, C<#define>s and more.

=item L<pack and unpack|perlpacktut>

Native to Perl functions that can be used to decode C C<struct> types.

=item L<C::Scan>

This module can extract constants and other useful objects from C header
files that may be relevant to an FFI application.  One downside is that
its use may require development packages to be installed.

=item L<Win32::API>

Microsoft Windows specific FFI style interface.

=item L<Ctypes|https://gitorious.org/perl-ctypes>

Ctypes was intended as a FFI style interface for Perl, but was never
part of CPAN, and at least the last time I tried it did not work with
recent versions of Perl.

=item L<FFI>

Older, simpler, less featureful FFI.  It used to be implemented
using FSF's C<ffcall>.  Because C<ffcall> has been unsupported for
some time, I reimplemented this module using L<FFI::Platypus>.

=item L<C::DynaLib>

Another FFI for Perl that doesn't appear to have worked for a long time.

=item L<C::Blocks>

Embed a tiny C compiler into your Perl scripts.

=item L<Alien::FFI>

Provides libffi for Platypus during its configuration and build stages.

=item L<P5NCI>

Yet another FFI like interface that does not appear to be supported or
under development anymore.

=back

=head1 ACKNOWLEDGMENTS

In addition to the contributors mentioned below, I would like to
acknowledge Brock Wilcox (AWWAIID) and Meredith Howard (MHOWARD) whose
work on C<FFI::Sweet> not only helped me get started with FFI but
significantly influenced the design of Platypus.

Dan Book, who goes by Grinnz on IRC for answering user questions about
FFI and Platypus.

In addition I'd like to thank Alessandro Ghedini (ALEXBIO) whose work
on another Perl FFI library helped drive some of the development ideas
for L<FFI::Platypus>.

=cut

