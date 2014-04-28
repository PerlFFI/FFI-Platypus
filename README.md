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

- `FFI_PLATYPUS_BUILD_CFLAGS`

    Extra c flags to include during the build of [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).  Useful for
    including debug flags like `-g3`.

- `FFI_PLATYPUS_BUILD_LDFLAGS`

    Extra linker flags to include during the build of [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).

- `FFI_PLATYPUS_BUILD_SYSTEM_FFI`

    If your system does not provide `libffi`, then [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) will attempt
    to build it from bundled source.  Setting this environment variable to `0`
    will skip the check for a system `libffi` and build it from source regardless.

- `FFI_PLATYPUS_BUILD_VERBOSE`

    Be more verbose to stdout during the configuration / build step.  All
    of this verbosity may be viewed in the `build.log`, but you may want
    to see it spew as it happens.

- `FFI_PLATYPUS_TEST_LIBARCHIVE`

    Full path to `libarchive.so` or `archive.dll` used optionally during test.

# BUNDLED SOFTWARE

This distribution comes with this bundled software:

- [libffi](https://metacpan.org/pod/libffi)

    If your system provides a version of `libffi` that can be guessed or
    discovered using `pkg-config` or [PkgConfig](https://metacpan.org/pod/PkgConfig), then it will be used.

    If not, then a bundled version of libffi will be used.

        libffi - Copyright (c) 1996-2014  Anthony Green, Red Hat, Inc and others.
        See source files for details.
        
        Permission is hereby granted, free of charge, to any person obtaining
        a copy of this software and associated documentation files (the
        ``Software''), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, sublicense, and/or sell copies of the Software, and to
        permit persons to whom the Software is furnished to do so, subject to
        the following conditions:
        
        The above copyright notice and this permission notice shall be
        included in all copies or substantial portions of the Software.
        
        THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
        EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
