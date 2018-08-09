# FFI::Build [![Build Status](https://secure.travis-ci.org/Perl5-FFI/FFI-Build.png)](http://travis-ci.org/Perl5-FFI/FFI-Build)

Build shared libraries for use with FFI::Platypus

# SYNOPSIS

    use FFI::Platypus;
    use FFI::Build;
    
    my $build = FFI::Build->new(
      'frooble',
      source => 'ffi/*.c',
    );
    
    # $lib is an instance of FFI::Build::File::Library
    my $lib = $build->build;
    
    my $ffi = FFI::Platypus->new;
    $ffi->lib($lib->path);
    
    ... # use $ffi to attach functions in ffi/*.c

# DESCRIPTION

**WARNING**: Alpha quality software, expect a somewhat unstable API until it stabilizes.  Documentation
may be missing or inaccurate.

Using libffi based [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) is a great alternative to XS for writing library bindings for Perl.
Sometimes, however, you need to bundle a little C code with your FFI module, but this has never been
that easy to use.  [Module::Build::FFI](https://metacpan.org/pod/Module::Build::FFI) was an early attempt to address this use case, but it uses
the now out of fashion [Module::Build](https://metacpan.org/pod/Module::Build).

This module itself doesn't directly integrate with CPAN installers like [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker) or
[Module::Build](https://metacpan.org/pod/Module::Build), but there is a light weight layer [FFI::Build::MM](https://metacpan.org/pod/FFI::Build::MM) that will allow you to easily
use this module with [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker).  If you are using [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) as your dist builder,
then there is also [Dist::Zilla::Plugin::FFI::Build](https://metacpan.org/pod/Dist::Zilla::Plugin::FFI::Build), which will help with the connections.

There is some functional overlap with [ExtUtils::CBuilder](https://metacpan.org/pod/ExtUtils::CBuilder), which was in fact used by [Module::Build::FFI](https://metacpan.org/pod/Module::Build::FFI).
For this iteration I have decided not to use that module because although it will generate dynamic libraries
that can sometimes be used by [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus), it is really designed for building XS modules, and trying
to coerce it into a more general solution has proved difficult in the past.

Supported languages out of the box are C, C++ and Fortran.  In the future I plan on also supporting
other languages like Rust, and maybe Go, but the machinery for that will eventually live in
[FFI::Build::Foreign](https://metacpan.org/pod/FFI::Build::Foreign).

The hope is that this module will be merged into [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus), if and when this module becomes appropriately
stable.

# CONSTRUCTOR

## new

    my $build = FFI::Build->new($name, %options);

Create an instance of this class.  The `$name` argument is used when computing the file name for
the library.  The actual name will be something like `lib$name.so` or `$name.dll`.  The following
options are supported:

- alien

    List of Aliens to compile/link against.  [FFI::Build](https://metacpan.org/pod/FFI::Build) will work with any [Alien::Base](https://metacpan.org/pod/Alien::Base) based
    alien, or modules that provide a compatible API.

- buildname

    Directory name that will be used for building intermediate files, such as object files.  This is
    `_build` by default.

- cflags

    Extra compiler flags to use.  Things like `-I/foo/include` or `-DFOO=1`.

- dir

    The directory where the library will be written.  This is `.` by default.

- file

    An instance of [FFI::Build::File::Library](https://metacpan.org/pod/FFI::Build::File::Library) to which the library will be written.  Normally not needed.

- libs

    Extra library flags to use.  Things like `-L/foo/lib -lfoo`.

- platform

    An instance of [FFI::Build::Platform](https://metacpan.org/pod/FFI::Build::Platform).  Usually you want to omit this and use the default instance.

- source

    List of source files.  You can use wildcards supported by `bsd_glob` from [File::Glob](https://metacpan.org/pod/File::Glob).

- verbose

    By default this class does not print out the actual compiler and linker commands used in building
    the library unless there is a failure.  If this option is set to true, then these commands will
    always be printed.

# METHODS

## dir

    my $dir = $build->dir;

Returns the directory where the library will be written.

## buildname

    my $builddir = $build->builddir;

Returns the build name.  This is used in computing a directory to save intermediate files like objects.  For example,
if you specify a file like `ffi/foo.c`, then the object file will be stored in `ffi/_build/foo.o` by default.
`_build` in this example (the default) is the build name.

## file

    my $file = $build->file;

Returns an instance of [FFI::Build::File::Library](https://metacpan.org/pod/FFI::Build::File::Library) corresponding to the library being built.  This is
also returned by the `build` method below.

## platform

    my $platform = $build->platform;

An instance of [FFI::Build::Platform](https://metacpan.org/pod/FFI::Build::Platform), which contains information about the platform on which you are building.
The default is usually reasonable.

## verbose

    my $verbose = $build->verbose;

Returns the verbose flag.

## cflags

    my $cflags = $build->cflags;

Returns the compiler flags.

## libs

    my $libs = $build->libs;

Returns the library flags.

## alien

    my @aliens = @{ $build->alien };

Returns a the list of aliens being used.

## source

    $build->source(@files);

Add the `@files` to the list of source files that will be used in building the library.
The format is the same as with the `source` attribute above.

## build

    my $lib = $build->build;

This compiles the source files and links the library.  Files that have already been compiled or linked
may be reused without recompiling/linking if the timestamps are newer than the source files.  An instance
of [FFI::Build::File::Library](https://metacpan.org/pod/FFI::Build::File::Library) is returned which can be used to get the path to the library, which can
be feed into [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) or similar.

## clean

    $build->clean;

Removes the library and intermediate files.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
