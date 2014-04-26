# FFI::Platypus

Kinda like gluing a duckbill to an adorable mammal

# ENVIRONMENT VARIABLES

The following is a (probably incomplete) list of environment variables
recognized by [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus):

- `FFI_PLATYPUS_BUILD_ALLOCA`

    [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) may use the non standard and sometimes controversial `alloca`
    function to allocate very small amounts of memory during ffi calls.  I
    test whether or not it works on your platform during build, and use it in
    moderation, so I believe it to be safe.  You may turn it off by setting
    this environment variable to `0` when you run `Build.PL`.

- `FFI_PLATYPUS_BUILD_VERBOSE`

    Be more verbose to stdout during the configuration / build step.  All
    of this verbosity may be viewed in the `build.log`, but you may want
    to see it spew as it happens.

- `FFI_PLATYPUS_TEST_LIBARCHIVE`

    Full path to `libarchive.so` or `archive.dll` used optionally during test.

# BUNDLED SOFTWARE

This distribution comes with this bundled software:

- [PkgConfig](https://metacpan.org/pod/PkgConfig)

    Currently maintained by Graham Ollis <plicease@cpan.org>.
    This is only used during the build process and only if the `Build.PL`
    cannot find libffi either by guessing or by using the system pkg-config.

    Copyright 2012 M. Nunberg

    This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
