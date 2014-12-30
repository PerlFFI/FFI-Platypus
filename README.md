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

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
