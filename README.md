# FFI::Platypus

Glue a duckbill to an adorable aquatic mammal

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

    Signed 8 bit byte (_signed char_).

- uint8

    Unsigned 8 bit byte (_unsigned char_).

- sint16

    Signed 16 bit integer (_short_)

- uint16

    Unsigned 16 bit integer (_unsigned short_)

- sint32

    Signed 32 bit integer (_int_)

- uint32

    Unsigned 32 bit integer (_unsigned int_)

- sint64

    Signed 64 bit integer (_long_ or _long long_)

- uint64

    Unsigned 64 bit integer (_unsigned long_ or _unsigned long long_)

- float

    Single precision floating point (_float_)

- double

    Double precision floating point (_double_)

- pointer

    Opaque pointer (_void \*_)

- string

    Null terminated ASCII string (_char \*_)

The following FFI types _may_ be available depending on your platform:

- longdouble

    Double or Quad precision floating point (_long double_)

## types

    my @types = $ffi->types;
    my @types = FFI::Platypus->types;

Returns the list of types that FFI knows about.  This may be either built in FFI types (example: _sint32_) or
detected C types (example: _signed int_), or types that you have defined using the [FFI::Platypus#type](https://metacpan.org/pod/type) method.

It can also be called as a class method, in which case, not user defined types will be included.

## function

    my $function = $ffi->function('my_function_name', ['int', 'string'] => 'string');
    my $return_value = $function->(1, "hi there");

Returns an object that is similar to a code reference in that it can be called like one.

Caveat: many situations require a real code reference, at the price of a performance
penalty you can get one like this:

    my $coderef = sub { $function->(@_) };

It may be better, and faster to create a real Perl function using the [FFI::Platypus#attach](https://metacpan.org/pod/attach) method.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
