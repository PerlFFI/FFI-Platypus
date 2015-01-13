# FFI::Platypus

Glue a duckbill to an adorable aquatic mammal

# SYNOPSIS

    use FFI::Platypus;
    
    my $ffi = FFI::Platypus->new;
    $ffi->lib(undef); # search libc
    
    # call dynamically
    $ffi->function( puts => ['string'] => 'int' )->call("hello world");
    
    # attach as a xsub and call (much faster)
    $ffi->attach( puts => ['string'] => 'int' );
    puts("hello world");

# DESCRIPTION

Platypus provides an interface for creating FFI based modules in
Perl that call machine code via `libffi`.  This is an alternative
to XS that does not require a compiler.

The declarative interface [FFI::Platypus::Declare](https://metacpan.org/pod/FFI::Platypus::Declare) may be more
suitable, if you do not need the extra power of the OO interface
and you do not mind the namespace pollution.

# CONSTRUCTORS

## new

    my $ffi = FFI::Platypus->new;

Create a new instance of [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).

# ATTRIBUTES

## lib

    $ffi->lib($path1, $path2, ...);
    my @paths = $ffi->lib;

The list of libraries to search for symbols in.

# METHODS

## find\_symbol

    my $address = $ffi->find_symbol($name);

Return the address of the given symbol (usually function).

## type

    $ffi->type('sint32');
    $ffi->type('sint32' => 'myint');

Define a type.  The first argument is the FFI or C name of the type.  The second argument (optional) is an alias name
that you can use to refer to this new type.

The following FFI types are always available (parentheticals indicates the usual corresponding C type):

- sint8

    Signed 8 bit byte (`signed char`, `int8_t`).

- uint8

    Unsigned 8 bit byte (`unsigned char`, `uint8_t`).

- sint16

    Signed 16 bit integer (`short`, `int16_t`)

- uint16

    Unsigned 16 bit integer (`unsigned short`, `uint16_t`)

- sint32

    Signed 32 bit integer (`int`, `int32_t`)

- uint32

    Unsigned 32 bit integer (`unsigned int`, `uint32_t`)

- sint64

    Signed 64 bit integer (`long` or `long long`, `int64_t`)

- uint64

    Unsigned 64 bit integer (`unsigned long` or `unsigned long long`, `uint64_t`)

- float

    Single precision floating point (_float_)

- double

    Double precision floating point (_double_)

- opaque (or pointer)

    Opaque pointer (_void \*_)

    The [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) documentation refers to this as the opaque type differentiate
    it from pointers to defined types (such as integers or floating points).  It provides
    the alias "pointer" as this is what libffi calls them internally.

- string

    Null terminated ASCII string (_char \*_)

The following FFI types _may_ be available depending on your platform:

- longdouble

    Double or Quad precision floating point (_long double_)

The following types are supported, but actual size or sign depends on your platform:

- char

    May be either signed or unsigned.

- size\_t

    May be either 32 or 64 bit.  Usually unsigned.

## types

    my @types = $ffi->types;
    my @types = FFI::Platypus->types;

Returns the list of types that FFI knows about.  This may be either built in FFI types (example: _sint32_) or
detected C types (example: _signed int_), or types that you have defined using the [FFI::Platypus#type](https://metacpan.org/pod/type) method.

It can also be called as a class method, in which case, no user defined types will be included.

## type\_meta

    my $meta = $ffi->type_meta($type_name);

Returns a hash reference with the meta information for the given type.

## function

    my $function = $ffi->function('my_function_name', ['int', 'string'] => 'string');
    my $return_value = $function->(1, "hi there");

Returns an object that is similar to a code reference in that it can be called like one.

Caveat: many situations require a real code reference, at the price of a performance
penalty you can get one like this:

    my $coderef = sub { $function->(@_) };

It may be better, and faster to create a real Perl function using the [FFI::Platypus#attach](https://metacpan.org/pod/attach) method.

## attach

    $ffi->attach('my_functon_name', ['int', 'string'] => 'string');
    $ffi->attach(['my_c_functon_name' => 'my_perl_function_name'], ['int', 'string'] => 'string');

Find and attach the given C function as the given perl function name as a real live xsub.
The advantage of attaching a function over using the [FFI::Platypus#function](https://metacpan.org/pod/function) method
is that it is much much faster since no object resolution needs to be done.  The disadvantage
is that it locks the function and the [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instance into memory permanently, since
there is no way to deallocate an xsub.

## closure

    my $closure = $ffi->closure(sub { ... });

Prepares a code reference so that it can be used as a FFI closure (a Perl subroutine that can be called
from C code).

# SUPPORT

If something does not work the way you think it should, or if you have a feature
request, please open an issue on this project's GitHub Issue tracker:

[https://github.com/plicease/FFI-Platypus/issues](https://github.com/plicease/FFI-Platypus/issues)

# CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a pull request on
this project's GitHub repository:

[https://github.com/plicease/FFI-Platypus/pulls](https://github.com/plicease/FFI-Platypus/pulls)

This project is developed using [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).  The project's git repository also
comes with `Build.PL` and `cpanfile` files necessary for building, testing 
(and even installing if necessary) without [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).  Please keep in mind
though that these files are generated so if changes need to be made to those files
they should be done through the project's `dist.ini` file.  If you do use [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)
and already have the necessary plugins installed, then I encourage you to run
`dzil test` before making any pull requests.  This is not a requirement, however,
I am happy to integrate especially smaller patches that need tweaking to fit the project
standards.  I may push back and ask you to write a test case or alter the formatting of 
a patch depending on the amount of time I have and the amount of code that your patch 
touches.

# SEE ALSO

- [FFI::Platypus::Declare](https://metacpan.org/pod/FFI::Platypus::Declare)

    Declarative interface to [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).

- [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib)

    Find dynamic libraries in a portable way.

- [FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC)

    JIT compiler for FFI.

- [FFI::Raw](https://metacpan.org/pod/FFI::Raw)

    Alternate interface to libffi with fewer features.  It notably lacks the ability to
    create real xsubs, which may make [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) much faster.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
