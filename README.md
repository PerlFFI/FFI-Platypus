# FFI::Platypus [![Build Status](https://api.cirrus-ci.com/github/PerlFFI/FFI-Platypus.svg)](https://cirrus-ci.com/github/PerlFFI/FFI-Platypus) ![static](https://github.com/PerlFFI/FFI-Platypus/workflows/static/badge.svg) ![linux](https://github.com/PerlFFI/FFI-Platypus/workflows/linux/badge.svg) ![windows](https://github.com/PerlFFI/FFI-Platypus/workflows/windows/badge.svg) ![macos](https://github.com/PerlFFI/FFI-Platypus/workflows/macos/badge.svg) ![msys2-mingw](https://github.com/PerlFFI/FFI-Platypus/workflows/msys2-mingw/badge.svg)

Write Perl bindings to non-Perl libraries with FFI. No XS required.

# SYNOPSIS

```perl
use FFI::Platypus 2.00;

# for all new code you should use api => 2
my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(undef); # search libc

# call dynamically
$ffi->function( puts => ['string'] => 'int' )->call("hello world");

# attach as a xsub and call (much faster)
$ffi->attach( puts => ['string'] => 'int' );
puts("hello world");
```

# DESCRIPTION

Platypus is a library for creating interfaces to machine code libraries
written in languages like C, [C++](https://metacpan.org/pod/FFI::Platypus::Lang::CPP),
[Go](https://metacpan.org/pod/FFI::Platypus::Lang::Go),
[Fortran](https://metacpan.org/pod/FFI::Platypus::Lang::Fortran),
[Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust),
[Pascal](https://metacpan.org/pod/FFI::Platypus::Lang::Pascal). Essentially anything that gets
compiled into machine code.  This implementation uses [libffi](https://sourceware.org/libffi/) to
accomplish this task.  [libffi](https://sourceware.org/libffi/) is battle tested by a number of other
scripting and virtual machine languages, such as Python and Ruby to
serve a similar role.  There are a number of reasons why you might want
to write an extension with Platypus instead of XS:

- FFI / Platypus does not require messing with the guts of Perl

    XS is less of an API and more of the guts of perl splayed out to do
    whatever you want.  That may at times be very powerful, but it can also
    be a frustrating exercise in hair pulling.

- FFI / Platypus is portable

    Lots of languages have FFI interfaces, and it is subjectively easier to
    port an extension written in FFI in Perl or another language to FFI in
    another language or Perl.  One goal of the Platypus Project is to reduce
    common interface specifications to a common format like JSON that could
    be shared between different languages.

- FFI / Platypus could be a bridge to Raku

    One of those "other" languages could be Raku and Raku already has an
    FFI interface I am told.

- FFI / Platypus can be reimplemented

    In a bright future with multiple implementations of Perl 5, each
    interpreter will have its own implementation of Platypus, allowing
    extensions to be written once and used on multiple platforms, in much
    the same way that Ruby-FFI extensions can be use in Ruby, JRuby and
    Rubinius.

- FFI / Platypus is pure perl (sorta)

    One Platypus script or module works on any platform where the libraries
    it uses are available.  That means you can deploy your Platypus script
    in a shared filesystem where they may be run on different platforms.  It
    also means that Platypus modules do not need to be installed in the
    platform specific Perl library path.

- FFI / Platypus is not C or C++ centric

    XS is implemented primarily as a bunch of C macros, which requires at
    least some understanding of C, the C pre-processor, and some C++ caveats
    (since on some platforms Perl is compiled and linked with a C++
    compiler). Platypus on the other hand could be used to call other
    compiled languages, like [Fortran](https://metacpan.org/pod/FFI::Platypus::Lang::Fortran),
    [Go](https://metacpan.org/pod/FFI::Platypus::Lang::Go),
    [Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust),
    [Pascal](https://metacpan.org/pod/FFI::Platypus::Lang::Pascal), [C++](https://metacpan.org/pod/FFI::Platypus::Lang::CPP),
    or even [assembly](https://metacpan.org/pod/FFI::Platypus::Lang::ASM), allowing you to focus
    on your strengths.

- FFI / Platypus does not require a parser

    [Inline](https://metacpan.org/pod/Inline) isolates the extension developer from XS to some extent, but
    it also requires a parser.  The various [Inline](https://metacpan.org/pod/Inline) language bindings are
    a great technical achievement, but I think writing a parser for every
    language that you want to interface with is a bit of an anti-pattern.

This document consists of an API reference, a set of examples, some
support and development (for contributors) information.  If you are new
to Platypus or FFI, you may want to skip down to the
[EXAMPLES](#examples) to get a taste of what you can do with Platypus.

Platypus has extensive documentation of types at [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type)
and its custom types API at [FFI::Platypus::API](https://metacpan.org/pod/FFI::Platypus::API).

You are **strongly** encouraged to use API level 1 for all new code.
There are a number of improvements and design fixes that you get
for free.  You should even consider updating existing modules to
use API level 1 where feasible.  How do I do that you might ask?
Simply pass in the API level to the platypus constructor.

```perl
my $ffi = FFI::Platypus->new( api => 2 );
```

The Platypus documentation has already been updated to assume API
level 1.

# CONSTRUCTORS

## new

```perl
my $ffi = FFI::Platypus->new( api => 2, %options);
```

Create a new instance of [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).

Any types defined with this instance will be valid for this instance
only, so you do not need to worry about stepping on the toes of other
CPAN FFI / Platypus Authors.

Any functions found will be out of the list of libraries specified with
the [lib](#lib) attribute.

### options

- api

    \[version 0.91\]

    Sets the API level.  Legal values are

    - `0`

        Original API level.  See [FFI::Platypus::TypeParser::Version0](https://metacpan.org/pod/FFI::Platypus::TypeParser::Version0) for details
        on the differences.

    - `1`

        Enable version 1 API type parser which allows pass-by-value records
        and type decoration on basic types.

    - `2`

        Enable version 2 API. All new code should be written with this set to 1!
        The Platypus documentation assumes this api level is set.

        API version 2 is identical to version 1, except:

        - Pointer functions that return `NULL` will return `undef` instead of empty list

            This fixes a long standing design bug in Platypus.

        - Array references may be passed to pointer argument types

            This replicates the behavior of array argument types with no size.  So the types `sint8*` and `sint8[]`
            behave identically when an array reference is passed in.  They differ in that, as before, you can
            pass a scalar reference into type `sint8*`.

        - The fixed string type can be specified without pointer modifier

            That is you can use `string(10)` instead of `string(10)*` as you were previously able to
            in API 0.

- lib

    Either a pathname (string) or a list of pathnames (array ref of strings)
    to pre-populate the [lib](#lib) attribute.  Use `[undef]` to search the
    current process for symbols.

    0.48

    `undef` (without the array reference) can be used to search the current
    process for symbols.

- ignore\_not\_found

    \[version 0.15\]

    Set the [ignore\_not\_found](#ignore_not_found) attribute.

- lang

    \[version 0.18\]

    Set the [lang](#lang) attribute.

# ATTRIBUTES

## lib

```perl
$ffi->lib($path1, $path2, ...);
my @paths = $ffi->lib;
```

The list of libraries to search for symbols in.

The most portable and reliable way to find dynamic libraries is by using
[FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib), like this:

```perl
use FFI::CheckLib 0.06;
$ffi->lib(find_lib_or_die lib => 'archive');
  # finds libarchive.so on Linux
  #       libarchive.bundle on OS X
  #       libarchive.dll (or archive.dll) on Windows
  #       cygarchive-13.dll on Cygwin
  #       ...
  # and will die if it isn't found
```

[FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) has a number of options, such as checking for specific
symbols, etc.  You should consult the documentation for that module.

As a special case, if you add `undef` as a "library" to be searched,
Platypus will also search the current process for symbols. This is
mostly useful for finding functions in the standard C library, without
having to know the name of the standard c library for your platform (as
it turns out it is different just about everywhere!).

You may also use the ["find\_lib"](#find_lib) method as a shortcut:

```perl
$ffi->find_lib( lib => 'archive' );
```

## ignore\_not\_found

\[version 0.15\]

```perl
$ffi->ignore_not_found(1);
my $ignore_not_found = $ffi->ignore_not_found;
```

Normally the [attach](#attach) and [function](#function) methods will
throw an exception if it cannot find the name of the function you
provide it.  This will change the behavior such that
[function](#function) will return `undef` when the function is not
found and [attach](#attach) will ignore functions that are not found.
This is useful when you are writing bindings to a library and have many
optional functions and you do not wish to wrap every call to
[function](#function) or [attach](#attach) in an `eval`.

## lang

\[version 0.18\]

```
$ffi->lang($language);
```

Specifies the foreign language that you will be interfacing with. The
default is C.  The foreign language specified with this attribute
changes the default native types (for example, if you specify
[Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust), you will get `i32` as an alias for
`sint32` instead of `int` as you do with [C](https://metacpan.org/pod/FFI::Platypus::Lang::C)).

If the foreign language plugin supports it, this will also enable
Platypus to find symbols using the demangled names (for example, if you
specify [CPP](https://metacpan.org/pod/FFI::Platypus::Lang::CPP) for C++ you can use method names
like `Foo::get_bar()` with ["attach"](#attach) or ["function"](#function).

## api

\[version 1.11\]

```perl
my $level = $ffi->api;
```

Returns the API level of the Platypus instance.

# METHODS

## type

```perl
$ffi->type($typename);
$ffi->type($typename => $alias);
```

Define a type.  The first argument is the native or C name of the type.
The second argument (optional) is an alias name that you can use to
refer to this new type.  See [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type) for legal type
definitions.

Examples:

```perl
$ffi->type('sint32');            # only checks to see that sint32 is a valid type
$ffi->type('sint32' => 'myint'); # creates an alias myint for sint32
$ffi->type('bogus');             # dies with appropriate diagnostic
```

## custom\_type

```perl
$ffi->custom_type($alias => {
  native_type         => $native_type,
  native_to_perl      => $coderef,
  perl_to_native      => $coderef,
  perl_to_native_post => $coderef,
});
```

Define a custom type.  See [FFI::Platypus::Type#Custom-Types](https://metacpan.org/pod/FFI::Platypus::Type#Custom-Types) for details.

## load\_custom\_type

```perl
$ffi->load_custom_type($name => $alias, @type_args);
```

Load the custom type defined in the module _$name_, and make an alias
_$alias_. If the custom type requires any arguments, they may be passed
in as _@type\_args_. See [FFI::Platypus::Type#Custom-Types](https://metacpan.org/pod/FFI::Platypus::Type#Custom-Types) for
details.

If _$name_ contains `::` then it will be assumed to be a fully
qualified package name. If not, then `FFI::Platypus::Type::` will be
prepended to it.

## types

```perl
my @types = $ffi->types;
my @types = FFI::Platypus->types;
```

Returns the list of types that FFI knows about.  This will include the
native `libffi` types (example: `sint32`, `opaque` and `double`) and
the normal C types (example: `unsigned int`, `uint32_t`), any types
that you have defined using the [type](#type) method, and custom types.

The list of types that Platypus knows about varies somewhat from
platform to platform, [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type) includes a list of the core
types that you can always count on having access to.

It can also be called as a class method, in which case, no user defined
or custom types will be included in the list.

## type\_meta

```perl
my $meta = $ffi->type_meta($type_name);
my $meta = FFI::Platypus->type_meta($type_name);
```

Returns a hash reference with the meta information for the given type.

It can also be called as a class method, in which case, you won't be
able to get meta data on user defined types.

The format of the meta data is implementation dependent and subject to
change.  It may be useful for display or debugging.

Examples:

```perl
my $meta = $ffi->type_meta('int');        # standard int type
my $meta = $ffi->type_meta('int[64]');    # array of 64 ints
$ffi->type('int[128]' => 'myintarray');
my $meta = $ffi->type_meta('myintarray'); # array of 128 ints
```

## mangler

```
$ffi->mangler(\&mangler);
```

Specify a customer mangler to be used for symbol lookup.  This is usually useful
when you are writing bindings for a library where all of the functions have the
same prefix.  Example:

```perl
$ffi->mangler(sub {
  my($symbol) = @_;
  return "foo_$symbol";
});

$ffi->function( get_bar => [] => 'int' );  # attaches foo_get_bar

my $f = $ffi->function( set_baz => ['int'] => 'void' );
$f->call(22); # calls foo_set_baz
```

## function

```perl
my $function = $ffi->function($name => \@argument_types => $return_type);
my $function = $ffi->function($address => \@argument_types => $return_type);
my $function = $ffi->function($name => \@argument_types => $return_type, \&wrapper);
my $function = $ffi->function($address => \@argument_types => $return_type, \&wrapper);
```

Returns an object that is similar to a code reference in that it can be
called like one.

Caveat: many situations require a real code reference, so at the price
of a performance penalty you can get one like this:

```perl
my $function = $ffi->function(...);
my $coderef = sub { $function->(@_) };
```

It may be better, and faster to create a real Perl function using the
[attach](#attach) method.

In addition to looking up a function by name you can provide the address
of the symbol yourself:

```perl
my $address = $ffi->find_symbol('my_function');
my $function = $ffi->function($address => ...);
```

Under the covers, [function](#function) uses [find\_symbol](#find_symbol)
when you provide it with a name, but it is useful to keep this in mind
as there are alternative ways of obtaining a functions address.
Example: a C function could return the address of another C function
that you might want to call, or modules such as [FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC) produce
machine code at runtime that you can call from Platypus.

\[version 0.76\]

If the last argument is a code reference, then it will be used as a
wrapper around the function when called.  The first argument to the wrapper
will be the inner function, or if it is later attached an xsub.  This can be
used if you need to verify/modify input/output data.

Examples:

```perl
my $function = $ffi->function('my_function_name', ['int', 'string'] => 'string');
my $return_string = $function->(1, "hi there");
```

\[version 0.91\]

```perl
my $function = $ffi->function( $name => \@fixed_argument_types => \@var_argument_types => $return_type);
my $function = $ffi->function( $name => \@fixed_argument_types => \@var_argument_types => $return_type, \&wrapper);
my $function = $ffi->function( $name => \@fixed_argument_types => \@var_argument_types);
my $function = $ffi->function( $name => \@fixed_argument_types => \@var_argument_types => \&wrapper);
```

Version 0.91 and later allows you to creat functions for c variadic functions
(such as printf, scanf, etc) which can take a variable number of arguments.
The first set of arguments are the fixed set, the second set are the variable
arguments to bind with.  The variable argument types must be specified in order
to create a function object, so if you need to call variadic function with
different set of arguments then you will need to create a new function object
each time:

```perl
# int printf(const char *fmt, ...);
$ffi->function( printf => ['string'] => ['int'] => 'int' )
    ->call("print integer %d\n", 42);
$ffi->function( printf => ['string'] => ['string'] => 'int' )
    ->call("print string %s\n", 'platypus');
```

Some older versions of libffi and possibly some platforms may not support
variadic functions.  If you try to create a one, then an exception will be
thrown.

\[version 1.26\]

If the return type is omitted then `void` will be the assumed return type.

## attach

```perl
$ffi->attach($name => \@argument_types => $return_type);
$ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type);
$ffi->attach([$address => $perl_name] => \@argument_types => $return_type);
$ffi->attach($name => \@argument_types => $return_type, \&wrapper);
$ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type, \&wrapper);
$ffi->attach([$address => $perl_name] => \@argument_types => $return_type, \&wrapper);
```

Find and attach a C function as a real live Perl xsub.  The advantage of
attaching a function over using the [function](#function) method is that
it is much much much faster since no object resolution needs to be done.
The disadvantage is that it locks the function and the [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus)
instance into memory permanently, since there is no way to deallocate an
xsub.

If just one _$name_ is given, then the function will be attached in
Perl with the same name as it has in C.  The second form allows you to
give the Perl function a different name.  You can also provide an
address (the third form), just like with the [function](#function)
method.

Examples:

```perl
$ffi->attach('my_function_name', ['int', 'string'] => 'string');
$ffi->attach(['my_c_function_name' => 'my_perl_function_name'], ['int', 'string'] => 'string');
my $string1 = my_function_name($int);
my $string2 = my_perl_function_name($int);
```

\[version 0.20\]

If the last argument is a code reference, then it will be used as a
wrapper around the attached xsub.  The first argument to the wrapper
will be the inner xsub.  This can be used if you need to verify/modify
input/output data.

Examples:

```perl
$ffi->attach('my_function', ['int', 'string'] => 'string', sub {
  my($my_function_xsub, $integer, $string) = @_;
  $integer++;
  $string .= " and another thing";
  my $return_string = $my_function_xsub->($integer, $string);
  $return_string =~ s/Belgium//; # HHGG remove profanity
  $return_string;
});
```

\[version 0.91\]

```perl
$ffi->attach($name => \@fixed_argument_types => \@var_argument_types, $return_type);
$ffi->attach($name => \@fixed_argument_types => \@var_argument_types, $return_type, \&wrapper);
```

As of version 0.91 you can attach a variadic functions, if it is supported
by the platform / libffi that you are using.  For details see the `function`
documentation.  If not supported by the implementation then an exception
will be thrown.

## closure

```perl
my $closure = $ffi->closure($coderef);
my $closure = FFI::Platypus->closure($coderef);
```

Prepares a code reference so that it can be used as a FFI closure (a
Perl subroutine that can be called from C code).  For details on
closures, see [FFI::Platypus::Type#Closures](https://metacpan.org/pod/FFI::Platypus::Type#Closures) and [FFI::Platypus::Closure](https://metacpan.org/pod/FFI::Platypus::Closure).

## cast

```perl
my $converted_value = $ffi->cast($original_type, $converted_type, $original_value);
```

The `cast` function converts an existing _$original\_value_ of type
_$original\_type_ into one of type _$converted\_type_.  Not all types
are supported, so care must be taken.  For example, to get the address
of a string, you can do this:

```perl
my $address = $ffi->cast('string' => 'opaque', $string_value);
```

Something that won't work is trying to cast an array to anything:

```perl
my $address = $ffi->cast('int[10]' => 'opaque', \@list);  # WRONG
```

## attach\_cast

```perl
$ffi->attach_cast("cast_name", $original_type, $converted_type);
$ffi->attach_cast("cast_name", $original_type, $converted_type, \&wrapper);
my $converted_value = cast_name($original_value);
```

This function attaches a cast as a permanent xsub.  This will make it
faster and may be useful if you are calling a particular cast a lot.

\[version 1.26\]

A wrapper may be added as the last argument to `attach_cast` and works
just like the wrapper for `attach` and `function` methods.

## sizeof

```perl
my $size = $ffi->sizeof($type);
my $size = FFI::Platypus->sizeof($type);
```

Returns the total size of the given type in bytes.  For example to get
the size of an integer:

```perl
my $intsize = $ffi->sizeof('int');   # usually 4
my $longsize = $ffi->sizeof('long'); # usually 4 or 8 depending on platform
```

You can also get the size of arrays

```perl
my $intarraysize = $ffi->sizeof('int[64]');  # usually 4*64
my $intarraysize = $ffi->sizeof('long[64]'); # usually 4*64 or 8*64
                                             # depending on platform
```

Keep in mind that "pointer" types will always be the pointer / word size
for the platform that you are using.  This includes strings, opaque and
pointers to other types.

This function is not very fast, so you might want to save this value as
a constant, particularly if you need the size in a loop with many
iterations.

## alignof

\[version 0.21\]

```perl
my $align = $ffi->alignof($type);
```

Returns the alignment of the given type in bytes.

## kindof

\[version 1.24\]

```perl
my $kind = $ffi->kindof($type);
```

Returns the kind of a type.  This is a string with a value of one of

- `void`
- `scalar`
- `string`
- `closure`
- `record`
- `record-value`
- `pointer`
- `array`
- `object`

## countof

\[version 1.24\]

```perl
my $count = $ffi->countof($type);
```

For array types returns the number of elements in the array (returns 0 for variable length array).
For the `void` type returns 0.  Returns 1 for all other types.

## def

\[version 1.24\]

```perl
$ffi->def($package, $type, $value);
my $value = $ff->def($package, $type);
```

This method allows you to store data for types.  If the `$package` is not provided, then the
caller's package will be used.  `$type` must be a legal Platypus type for the [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus)
instance.

## unitof

\[version 1.24\]

```perl
my $unittype = $ffi->unitof($type);
```

For array and pointer types, returns the basic type without the array or pointer part.
In other words, for `sin16[]` or `sint16*` it will return `sint16`.

## find\_lib

\[version 0.20\]

```perl
$ffi->find_lib( lib => $libname );
```

This is just a shortcut for calling [FFI::CheckLib#find\_lib](https://metacpan.org/pod/FFI::CheckLib#find_lib) and
updating the ["lib"](#lib) attribute appropriately.  Care should be taken
though, as this method simply passes its arguments to
[FFI::CheckLib#find\_lib](https://metacpan.org/pod/FFI::CheckLib#find_lib), so if your module or script is depending on a
specific feature in [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) then make sure that you update your
prerequisites appropriately.

## find\_symbol

```perl
my $address = $ffi->find_symbol($name);
```

Return the address of the given symbol (usually function).

## bundle

\[version 0.96 api = 1+\]

```
$ffi->bundle($package, \@args);
$ffi->bundle(\@args);
$ffi->bundle($package);
$ffi->bundle;
```

This is an interface for bundling compiled code with your
distribution intended to eventually replace the `package` method documented
above.  See [FFI::Platypus::Bundle](https://metacpan.org/pod/FFI::Platypus::Bundle) for details on how this works.

## package

\[version 0.15 api = 0\]

```perl
$ffi->package($package, $file); # usually __PACKAGE__ and __FILE__ can be used
$ffi->package;                  # autodetect
```

**Note**: This method is officially discouraged in favor of `bundle`
described above.

If you use [FFI::Build](https://metacpan.org/pod/FFI::Build) (or the older deprecated [Module::Build::FFI](https://metacpan.org/pod/Module::Build::FFI)
to bundle C code with your distribution, you can use this method to tell
the [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instance to look for symbols that came with the
dynamic library that was built when your distribution was installed.

## abis

```perl
my $href = $ffi->abis;
my $href = FFI::Platypus->abis;
```

Get the legal ABIs supported by your platform and underlying
implementation.  What is supported can vary a lot by CPU and by
platform, or even between 32 and 64 bit on the same CPU and platform.
They keys are the "ABI" names, also known as "calling conventions".  The
values are integers used internally by the implementation to represent
those ABIs.

## abi

```
$ffi->abi($name);
```

Set the ABI or calling convention for use in subsequent calls to
["function"](#function) or ["attach"](#attach).  May be either a string name or integer
value from the ["abis"](#abis) method above.

# EXAMPLES

Here are some examples.  These examples are provided in full with the
Platypus distribution in the "examples" directory.  There are also some
more examples in [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type) that are related to types.

## Passing and Returning Integers

### C Source

```
int add(int a, int b) {
  return a+b;
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lib => './add.so' );
$ffi->attach( add => ['int', 'int'] => 'int' );

print add(1,2), "\n";  # prints 3
```

### Execute

```
$ cc -shared -o add.so add.c
$ perl add.pl
3
```

### Discussion

Basic types like integers and floating points are the easiest to pass
across the FFI boundary.  Because they are values that are passed on
the stack (or through registers) you don't need to worry about memory
allocations or ownership.

Here we are building our own C dynamic library using the native C
compiler on a Unix like platform.  The exact incantation that you
will use to do this would unfortunately depend on your platform and
C compiler.

By default, Platypus uses the
[Platypus C language plugin](https://metacpan.org/pod/FFI::Platypus::Lang::C), which gives you
easy access to many of the basic types used by C APIs.  (for example
`int`, `unsigned long`, `double`, `size_t` and others).

If you are working with another language like
[Fortran](https://metacpan.org/pod/FFI::Platypus::Lang::Fortran#Passing-and-Returning-Integers),
[Go](https://metacpan.org/pod/FFI::Platypus::Lang::Go#Passing-and-Returning-Integers),
[Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust#Passing-and-Returning-Integers) or
[Zig](https://metacpan.org/pod/FFI::Platypus::Lang::Zig#Passing-and-Returning-Integers),
you will find similar examples where you can use the Platypus language
plugin for that language and use the native types.

## String Arguments (with puts)

### C API

[cppreference - puts](https://en.cppreference.com/w/c/io/puts)

### Perl Source

```perl
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2, lib => undef );
$ffi->attach( puts => ['string'] => 'int' );

puts("hello world");
```

### Execute

```
$ perl puts.pl
hello world
```

### Discussion

Passing strings into a C function as an argument is also pretty easy
using Platypus.  Just use the `string` type, which is equivalent to
the C &lt;char \*> or `const char *` types.

In this example we are using the C Standard Library's `puts` function,
so we don't need to build our own C code.  We do still need to tell
Platypus where to look for the `puts` symbol though, which is why
we set `lib` to `undef`.  This is a special value which tells
Platypus to search the Perl runtime executable itself (including any
dynamic libraries) for symbols.  That helpfully includes the C Standard
Library.

## Returning Strings

### C Source

```
#include <string.h>
#include <stdlib.h>

const char *
string_reverse(const char *input)
{
  static char *output = NULL;
  int i, len;

  if(output != NULL)
    free(output);

  if(input == NULL)
    return NULL;

  len = strlen(input);
  output = malloc(len+1);

  for(i=0; input[i]; i++)
    output[len-i-1] = input[i];
  output[len] = '\0';

  return output;
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './string_reverse.so',
);

$ffi->attach( string_reverse => ['string'] => 'string' );

print string_reverse("\nHello world");

string_reverse(undef);
```

### Execute

```
$ gcc -shared -o string_reverse.so string_reverse.c
$ perl string_reverse.pl
dlrow olleH
```

### Discussion

The C code here takes an input ASCII string and reverses it, returning
the result.  Note that it retains ownership of the string, the caller
is expected to use it before the next call to `reverse_string`, or
copy it.

The Perl code simply declares the return value as `string` and is very
simple.  This does bring up an inconsistency though, strings passed in
to a function as arguments are passed by reference, whereas the return
value is copied!  This is usually what you want because C APIs usually
follow this pattern where you are expected to make your own copy of
the string.

At the end of the program we call `reverse_string` with `undef`, which
gets translated to C as `NULL`.  This allows it to free the output buffer
so that the memory will not leak.

## Returning and Freeing Strings with Embedded NULLs

### C Source

```
#include <string.h>
#include <stdlib.h>

char *
string_crypt(const char *input, int len, const char *key)
{
  char *output;
  int i, n;

  if(input == NULL)
    return NULL;

  output = malloc(len+1);
  output[len] = '\0';

  for(i=0, n=0; i<len; i++, n++) {
    if(key[n] == '\0')
      n = 0;
    output[i] = input[i] ^ key[n];
  }

  return output;
}

void
string_crypt_free(char *output)
{
  if(output != NULL)
    free(output);
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;
use FFI::Platypus::Buffer qw( buffer_to_scalar );
use YAML ();

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './xor_cipher.so',
);

$ffi->attach( string_crypt_free => ['opaque'] );

$ffi->attach( string_crypt => ['string','int','string'] => 'opaque' => sub{
  my($xsub, $input, $key) = @_;
  my $ptr = $xsub->($input, length($input), $key);
  my $output = buffer_to_scalar $ptr, length($input);
  string_crypt_free($ptr);
  return $output;
});

my $orig = "hello world";
my $key  = "foobar";

print YAML::Dump($orig);
my $encrypted = string_crypt($orig, $key);
print YAML::Dump($encrypted);
my $decrypted = string_crypt($encrypted, $key);
print YAML::Dump($decrypted);
```

### Execute

```
$ gcc -shared -o xor_cipher.so xor_cipher.c
$ perl xor_cipher.pl
--- hello world
--- "\x0e\n\x03\x0e\x0eR\x11\0\x1d\x0e\x05"
--- hello world
```

### Discussion

The C code here also returns a string, but it has some different expectations,
so we can't just use the `string` type like we did in the previous example
and copy the string.

This C code implements a simple XOR cipher.  Given an input string and a key
it returns an encrypted or decrypted output string where the characters are
XORd with the key.  There are some challenges here though.  First the input
and output strings can have embedded `NULL`s in them.  For the string passed
in, we can provide the length of the input string.  For the output, the
`string` type expects a `NULL` terminated string, so we can't use that.  So
instead we get a pointer to the output using the `opaque` type.  Because we
know that the output string is the same length as the input string we can
convert the pointer to a regular Perl string using the `buffer_to_scalar`
function.  (For more details about working with buffers and strings see
[FFI::Platypus::Buffer](https://metacpan.org/pod/FFI::Platypus::Buffer)).

Next, the C code here does not keep the pointer to the output string, as in
the previous example.  We are expected to call `string_encrypt_free` when
we are done.  Since we are getting the pointer back from the C code instead
of copying the string that is easy to do.

Finally, we are using a wrapper to hide a lot of this complexity from our
caller.  The last argument to the `attach` call is a code reference which will
wrap around the C function, which is passed in as the first argument of
the wrapper.  This is a good practice when writing modules, to hide the
complexity of C.

## Pointers

### C Source

```
void
swap(int *a, int *b)
{
  int tmp = *b;
  *b = *a;
  *a = tmp;
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => './swap.so',
);

$ffi->attach( swap => ['int*','int*'] );

my $a = 1;
my $b = 2;

print "[a,b] = [$a,$b]\n";

swap( \$a, \$b );

print "[a,b] = [$a,$b]\n";
```

### Execute

```
$ gcc -shared -o swap.so swap.c
$ perl swap.pl
[a,b] = [1,2]
[a,b] = [2,1]
```

### Discussion

Pointers are often use in C APIs to return simple values like this.  Platypus
provides access to pointers to primitive types by appending `*` to the
primitive type.  Here for example we are using `int*` to create a function
that takes two pointers to integers and swaps their values.

When calling the function from Perl we pass in a reference to a scalar.
Strictly speaking Perl allows modifying the argument values to subroutines, so
we could have allowed just passing in a scalar, but in the design of Platypus
we decided that forcing the use of a reference here emphasizes that you are
passing a reference to the variable, not just the value.

Not pictured in this example, but you can also pass in `undef` for a pointer
value and that will be translated into `NULL` on the C side.  You can also
return a pointer to a primitive type from a function, again this will be
returned to Perl as a reference to a scalar.  Platypus also supports string
pointers (`string*`).  (Though the C equivalent to a `string*` is a double
pointer to char `char**`).

## Opaque Pointers (objects)

### C Source

```
#include <string.h>
#include <stdlib.h>

typedef struct person_t {
  char *name;
  unsigned int age;
} person_t;

person_t *
person_new(const char *name, unsigned int age) {
  person_t *self = malloc(sizeof(person_t));
  self->name = strdup(name);
  self->age  = age;
}

const char *
person_name(person_t *self) {
  return self->name;
}

unsigned int
person_age(person_t *self) {
  return self->age;
}

void
person_free(person_t *self) {
  free(self->name);
  free(self);
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './person.so',
);

$ffi->type( 'opaque' => 'person_t' );

$ffi->attach( person_new =>  ['string','unsigned int'] => 'person_t'       );
$ffi->attach( person_name => ['person_t']              => 'string'       );
$ffi->attach( person_age =>  ['person_t']              => 'unsigned int' );
$ffi->attach( person_free => ['person_t']                                  );

my $person = person_new( 'Roger Frooble Bits', 35 );

print "name = ", person_name($person), "\n";
print "age  = ", person_age($person),  "\n";

person_free($person);
```

### Execute

```
$ gcc -shared -o person.so person.c
$ perl person.pl
name = Roger Frooble Bits
age  = 35
```

### Discussion

An opaque pointer is a pointer (memory address) that is pointing to _something_
but you do not know the structure of that something.  In C this is usually a
`void*`, but it could also be a pointer to a `struct` without a defined body.

This is often used to as an abstraction around objects in C.  Here in the C
code we have a `person_t` struct with functions to create (a constructor), free
(a destructor) and query it (methods).

The Perl code can then use the constructor, methods and destructors without having
to understand the internals.  The `person_t` internals can also be changed
without having to modify the calling code.

We use the Platypus [type method](#type) to create an alias of `opaque` called
`person_t`.  While this is not necessary, it does make the Perl code easier
to understand.

In later examples we will see how to hide the use of `opaque` types further
using the `object` type, but for some code direct use of `opaque` is
appropriate.

## Opaque Pointers (buffers and strings)

### C API

- [cppreference - free](https://en.cppreference.com/w/c/memory/free)
- [cppreference - malloc](https://en.cppreference.com/w/c/memory/malloc)
- [cppreference - memcpy](https://en.cppreference.com/w/c/string/byte/memcpy)
- [cppreference - strdup](https://en.cppreference.com/w/c/string/byte/strdup)

### Perl Source

```perl
use FFI::Platypus 2.00;
use FFI::Platypus::Memory qw( malloc free memcpy strdup );

my $ffi = FFI::Platypus->new( api => 2 );
my $buffer = malloc 14;
my $ptr_string = strdup("hello there!!\n");

memcpy $buffer, $ptr_string, 15;

print $ffi->cast('opaque' => 'string', $buffer);

free $ptr_string;
free $buffer;
```

### Execute

```
$ perl malloc.pl
hello there!!
```

### Discussion

Another useful application of the `opaque` type is for dealing with buffers,
and C strings that you do not immediately need to convert into Perl strings.
This example is completely contrived, but we are using `malloc` to create a
buffer of 14 bytes.  We create a C string using `strdup`, and then copy it
into the buffer using `memcpy`.  When we are done with the `opaque` pointers
we can free them using `free` since they. (This is generally only okay when
freeing memory that was allocated by `malloc`, which is the case for `strdup`).

These memory tools, along with others are provided by the [FFI::Platypus::Memory](https://metacpan.org/pod/FFI::Platypus::Memory)
module, which is worth reviewing when you need to manipulate memory from
Perl when writing your FFI code.

Just to verify that the `memcpy` did the right thing we convert the
buffer into a Perl string and print it out using the Platypus [cast method](#cast).

## Arrays

### C Source

```
void
array_reverse(int a[], int len) {
  int tmp, i;

  for(i=0; i < len/2; i++) {
    tmp = a[i];
    a[i] = a[len-i-1];
    a[len-i-1] = tmp;
  }
}

void
array_reverse10(int a[10]) {
  array_reverse(a, 10);
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => './array_reverse.so',
);

$ffi->attach( array_reverse   => ['int[]','int'] );
$ffi->attach( array_reverse10 => ['int[10]'] );

my @a = (1..10);
array_reverse10( \@a );
print "$_ " for @a;
print "\n";

@a = (1..20);
array_reverse( \@a, 20 );
print "$_ " for @a;
print "\n";
```

### Execute

```
$ gcc -shared -o array_reverse.so array_reverse.c
$ perl array_reverse.pl
10 9 8 7 6 5 4 3 2 1
20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1
```

### Discussion

Arrays in C are passed as pointers, so the C code here reverses the array
in place, rather than returning it.  Arrays can also be fixed or variable
length.  If the array is variable length the length of the array must be
provided in some way.  In this case we explicitly pass in a length.  Another
way might be to end the array with `0`, if you don't otherwise expect any
`0` to appear in your data.  For this reason, Platypus adds a zero (or
`NULL` in the case of pointers) element at the end of the array when passing
it into a variable length array type, although we do not use it here.

With Platypus you can declare an array type as being either fixed or variable
length.  Because Perl stores arrays in completely differently than C, a
temporary array is created by Platypus, passed into the C function as a pointer.
When the function returns the array is re-read by Platypus and the Perl array
is updated with the new values.  The temporary array is then freed.

You can use any primitive type for arrays, even `string`.  You can also
return an array from a function.  As in our discussion about strings, when
you return an array the value is copied, which is usually what you want.

## Pointers as Arrays

### C Source

```
#include <stdlib.h>

int
array_sum(const int *a) {
  int i, sum;
  if(a == NULL)
    return -1;
  for(i=0, sum=0; a[i] != 0; i++)
    sum += a[i];
  return sum;
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './array_sum.so',
);

$ffi->attach( array_sum => ['int*'] => 'int' );

print array_sum(undef), "\n";     # -1
print array_sum([0]), "\n";       # 0
print array_sum([1,2,3,0]), "\n"; # 6
```

### Execute

```
$ gcc -shared -o array_sum.so array_sum.c
$ perl array_sum.pl
-1
0
6
```

### Discussion

Starting with the Platypus version 2 API, you can also pass an array reference
in to a pointer argument.

In C pointer and array arguments are often used somewhat interchangeably.  In
this example we have an `array_sum` function that takes a zero terminated
array of integers and computes the sum.  If the pointer to the array is zero
(`0`) then we return `-1` to indicate an error.

This is the main advantage from Perl for using pointer argument rather than
an array one: the array argument will not let you pass in `undef` / `NULL`.

## Sending Strings to GUI on Unix with libnotify

### C API

[Libnotify Reference Manual](https://developer-old.gnome.org/libnotify/unstable)

### Perl Source

```perl
use FFI::CheckLib;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(find_lib_or_die lib => 'notify');

$ffi->attach( notify_init              => ['string']                                  );
$ffi->attach( notify_uninit            => []                                          );
$ffi->attach( notify_notification_new  => ['string', 'string', 'string']  => 'opaque' );
$ffi->attach( notify_notification_show => ['opaque', 'opaque']                        );

my $message = join "\n",
  "Hello from Platypus!",
  "Welcome to the fun",
  "world of FFI";

notify_init('Platypus Hello');
my $n = notify_notification_new('Platypus Hello World', $message, 'dialog-information');
notify_notification_show($n, undef);
notify_uninit();
```

### Execute

```
$ perl notify.pl
```

<div>
    <p>And this is what it will look like:</p>
    <div style="display: flex">
    <div style="margin: 3px; flex: 1 1 50%">
    <img alt="Test" src="/examples//notify.png">
    </div>
    </div>
</div>

### Discussion

The GNOME project provides an API to send notifications to its desktop environment.
Nothing here is particularly new: all of the types and techniques are ones that we
have seen before, except we are using a third party library, instead of using our
own C code or the standard C library functions.

When using a third party library you have to know the name or location of it, which
is not typically portable, so here we use [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib)'s
[find\_lib\_or\_die function](https://metacpan.org/pod/FFI::CheckLib#find_lib_or_die).  If the library is not
found the script will die with a useful diagnostic.  [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) has a number
of useful features and will integrate nicely with [Alien::Build](https://metacpan.org/pod/Alien::Build) based [Alien](https://metacpan.org/pod/Alien)s.

## The Win32 API with MessageBoxW

### Win32 API

[MessageBoxW function (winuser.h)](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-messageboxw)

### Perl Source

```perl
use utf8;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api  => 2,
  lib  => [undef],
);

# see FFI::Platypus::Lang::Win32
$ffi->lang('Win32');

# Send a Unicode string to the Windows API MessageBoxW function.
use constant MB_OK                   => 0x00000000;
use constant MB_DEFAULT_DESKTOP_ONLY => 0x00020000;
$ffi->attach( [MessageBoxW => 'MessageBox'] => [ 'HWND', 'LPCWSTR', 'LPCWSTR', 'UINT'] => 'int' );
MessageBox(undef, "I ❤️ Platypus", "Confession", MB_OK|MB_DEFAULT_DESKTOP_ONLY);
```

### Execute

```
$ perl win32_messagebox.pl
```

<div>
    <p>And this is what it will look like:</p>
    <div style="display: flex">
    <div style="margin: 3px; flex: 1 1 50%">
    <img alt="Test" src="/examples/win32_messagebox.png">
    </div>
    </div>
</div>

### Discussion

The API used by Microsoft Windows presents some unique
challenges.  On 32 bit systems a different ABI is used than what
is used by the standard C library.  It also provides a rats nest of
type aliases.  Finally if you want to talk Unicode to any of the
Windows API you will need to use `UTF-16LE` instead of `UTF-8`
which is native to Perl.  (The Win32 API refers to these as
`LPWSTR` and `LPCWSTR` types).  As much as possible the Win32
"language" plugin attempts to handle these challenges transparently.
For more details see [FFI::Platypus::Lang::Win32](https://metacpan.org/pod/FFI::Platypus::Lang::Win32).

### Discussion

The libnotify library is a desktop GUI notification system for the
GNOME Desktop environment. This script sends a notification event that
should show up as a balloon, for me it did so in the upper right hand
corner of my screen.

## structured data records

```perl
use FFI::Platypus 2.00;
use FFI::C;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => [undef],
);
FFI::C->ffi($ffi);

package Unix::TimeStruct {

  FFI::C->struct(tm => [
    tm_sec    => 'int',
    tm_min    => 'int',
    tm_hour   => 'int',
    tm_mday   => 'int',
    tm_mon    => 'int',
    tm_year   => 'int',
    tm_wday   => 'int',
    tm_yday   => 'int',
    tm_isdst  => 'int',
    tm_gmtoff => 'long',
    _tm_zone  => 'opaque',
  ]);

  # For now 'string' is unsupported by FFI::C, but we
  # can cast the time zone from an opaque pointer to
  # string.
  sub tm_zone {
    my $self = shift;
    $ffi->cast('opaque', 'string', $self->_tm_zone);
  }

  # attach the C localtime function
  $ffi->attach( localtime => ['time_t*'] => 'tm', sub {
    my($inner, $class, $time) = @_;
    $time = time unless defined $time;
    $inner->(\$time);
  });
}

# now we can actually use our Unix::TimeStruct class
my $time = Unix::TimeStruct->localtime;
printf "time is %d:%d:%d %s\n",
  $time->tm_hour,
  $time->tm_min,
  $time->tm_sec,
  $time->tm_zone;
```

**Discussion**: C and other machine code languages frequently provide
interfaces that include structured data records (known as "structs" in
C).  They sometimes provide an API in which you are expected to
manipulate these records before and/or after passing them along to C
functions.  For C pointers to structs, unions and arrays of structs and
unions, the easiest interface to use is via [FFI::C](https://metacpan.org/pod/FFI::C).  If you are
working with structs that must be passed as values (not pointers),
then you want to use the [FFI::Platypus::Record](https://metacpan.org/pod/FFI::Platypus::Record) class instead.
We will discuss this class later.

The C `localtime` function takes a pointer to a C struct.  We simply define
the members of the struct using the [FFI::C](https://metacpan.org/pod/FFI::C) `struct` method.  Because
we used the `ffi` method to tell [FFI::C](https://metacpan.org/pod/FFI::C) to use our local instance of
[FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) it registers the `tm` type for us, and we can just start
using it as a return type!

## structured data records by-value

## libuuid

```perl
use FFI::CheckLib;
use FFI::Platypus 2.00;
use FFI::Platypus::Memory qw( malloc free );

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(find_lib_or_die lib => 'uuid');
$ffi->type('string(37)*' => 'uuid_string');
$ffi->type('record(16)*' => 'uuid_t');

$ffi->attach(uuid_generate => ['uuid_t'] => 'void');
$ffi->attach(uuid_unparse  => ['uuid_t','uuid_string'] => 'void');

my $uuid = "\0" x $ffi->sizeof('uuid_t');
uuid_generate($uuid);

my $string = "\0" x $ffi->sizeof('uuid_string');
uuid_unparse($uuid, $string);

print "$string\n";
```

**Discussion**: libuuid is a library used to generate unique identifiers
(UUID) for objects that may be accessible beyond the local system.  The
library is or was part of the Linux e2fsprogs package.

Knowing the size of objects is sometimes important.  In this example, we
use the [sizeof](#sizeof) function to get the size of 16 characters (in
this case it is simply 16 bytes).  We also know that the strings
"deparsed" by `uuid_unparse` are exactly 37 bytes.

## puts and getpid

```perl
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(undef);

$ffi->attach(puts => ['string'] => 'int');
$ffi->attach(getpid => [] => 'int');

puts(getpid());
```

**Discussion**: `puts` is part of standard C library on all platforms.
`getpid` is available on Unix type platforms.

## Math library

```perl
use FFI::Platypus 2.00;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(undef);
$ffi->attach(puts => ['string'] => 'int');
$ffi->attach(fdim => ['double','double'] => 'double');

puts(fdim(7.0, 2.0));

$ffi->attach(cos => ['double'] => 'double');

puts(cos(2.0));

$ffi->attach(fmax => ['double', 'double'] => 'double');

puts(fmax(2.0,3.0));
```

**Discussion**: On UNIX the standard c library math functions are
frequently provided in a separate library `libm`, so you could search
for those symbols in "libm.so", but that won't work on non-UNIX
platforms like Microsoft Windows.  Fortunately Perl uses the math
library so these symbols are already in the current process so you can
use `undef` as the library to find them.

## Strings

```perl
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(undef);
$ffi->attach(puts => ['string'] => 'int');
$ffi->attach(strlen => ['string'] => 'int');

puts(strlen('somestring'));

$ffi->attach(strstr => ['string','string'] => 'string');

puts(strstr('somestring', 'string'));

#attach puts => [string] => int;

puts(puts("lol"));

$ffi->attach(strerror => ['int'] => 'string');

puts(strerror(2));
```

**Discussion**: ASCII and UTF-8 Strings are not a native type to `libffi`
but the are handled seamlessly by Platypus.  If you need to talk to an
API that uses so called "wide" strings (APIs which use `const wchar_t*`
or `wchar_t*`), then you will want to use the wide string type plugin
[FFI::Platypus::Type::WideString](https://metacpan.org/pod/FFI::Platypus::Type::WideString).  APIs which use other arbitrary
encodings can be accessed by converting your Perl strings manually with
the [Encode](https://metacpan.org/pod/Encode) module.

## Attach function from pointer

```perl
use FFI::TinyCC;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );
my $tcc = FFI::TinyCC->new;

$tcc->compile_string(q{
  int
  add(int a, int b)
  {
    return a+b;
  }
});

my $address = $tcc->get_symbol('add');

$ffi->attach( [ $address => 'add' ] => ['int','int'] => 'int' );

print add(1,2), "\n";
```

**Discussion**: Sometimes you will have a pointer to a function from a
source other than Platypus that you want to call.  You can use that
address instead of a function name for either of the
[function](#function) or [attach](#attach) methods.  In this example we
use [FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC) to compile a short piece of C code and to give us the
address of one of its functions, which we then use to create a perl xsub
to call it.

[FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC) embeds the Tiny C Compiler (tcc) to provide a
just-in-time (JIT) compilation service for FFI.

## libzmq

```perl
use constant ZMQ_IO_THREADS  => 1;
use constant ZMQ_MAX_SOCKETS => 2;
use constant ZMQ_REQ => 3;
use constant ZMQ_REP => 4;
use FFI::CheckLib qw( find_lib_or_die );
use FFI::Platypus 2.00;
use FFI::Platypus::Memory qw( malloc );
use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );

my $endpoint = "ipc://zmq-ffi-$$";
my $ffi = FFI::Platypus->new( api => 2 );

$ffi->lib(undef); # for puts
$ffi->attach(puts => ['string'] => 'int');

$ffi->lib(find_lib_or_die lib => 'zmq');
$ffi->attach(zmq_version => ['int*', 'int*', 'int*'] => 'void');

my($major,$minor,$patch);
zmq_version(\$major, \$minor, \$patch);
puts("libzmq version $major.$minor.$patch");
die "this script only works with libzmq 3 or better" unless $major >= 3;

$ffi->type('opaque'       => 'zmq_context');
$ffi->type('opaque'       => 'zmq_socket');
$ffi->type('opaque'       => 'zmq_msg_t');
$ffi->attach(zmq_ctx_new  => [] => 'zmq_context');
$ffi->attach(zmq_ctx_set  => ['zmq_context', 'int', 'int'] => 'int');
$ffi->attach(zmq_socket   => ['zmq_context', 'int'] => 'zmq_socket');
$ffi->attach(zmq_connect  => ['opaque', 'string'] => 'int');
$ffi->attach(zmq_bind     => ['zmq_socket', 'string'] => 'int');
$ffi->attach(zmq_send     => ['zmq_socket', 'opaque', 'size_t', 'int'] => 'int');
$ffi->attach(zmq_msg_init => ['zmq_msg_t'] => 'int');
$ffi->attach(zmq_msg_recv => ['zmq_msg_t', 'zmq_socket', 'int'] => 'int');
$ffi->attach(zmq_msg_data => ['zmq_msg_t'] => 'opaque');
$ffi->attach(zmq_errno    => [] => 'int');
$ffi->attach(zmq_strerror => ['int'] => 'string');

my $context = zmq_ctx_new();
zmq_ctx_set($context, ZMQ_IO_THREADS, 1);

my $socket1 = zmq_socket($context, ZMQ_REQ);
zmq_connect($socket1, $endpoint);

my $socket2 = zmq_socket($context, ZMQ_REP);
zmq_bind($socket2, $endpoint);

do { # send
  our $sent_message = "hello there";
  my($pointer, $size) = scalar_to_buffer $sent_message;
  my $r = zmq_send($socket1, $pointer, $size, 0);
  die zmq_strerror(zmq_errno()) if $r == -1;
};

do { # recv
  my $msg_ptr  = malloc 100;
  zmq_msg_init($msg_ptr);
  my $size     = zmq_msg_recv($msg_ptr, $socket2, 0);
  die zmq_strerror(zmq_errno()) if $size == -1;
  my $data_ptr = zmq_msg_data($msg_ptr);
  my $recv_message = buffer_to_scalar $data_ptr, $size;
  print "recv_message = $recv_message\n";
};
```

**Discussion**: ØMQ is a high-performance asynchronous messaging library.
There are a few things to note here.

Firstly, sometimes there may be multiple versions of a library in the
wild and you may need to verify that the library on a system meets your
needs (alternatively you could support multiple versions and configure
your bindings dynamically).  Here we use `zmq_version` to ask libzmq
which version it is.

`zmq_version` returns the version number via three integer pointer
arguments, so we use the pointer to integer type: `int *`.  In order to
pass pointer types, we pass a reference. In this case it is a reference
to an undefined value, because zmq\_version will write into the pointers
the output values, but you can also pass in references to integers,
floating point values and opaque pointer types.  When the function
returns the `$major` variable (and the others) has been updated and we
can use it to verify that it supports the API that we require.

Notice that we define three aliases for the `opaque` type:
`zmq_context`, `zmq_socket` and `zmq_msg_t`.  While this isn't
strictly necessary, since Platypus and C treat all three of these types
the same, it is useful form of documentation that helps describe the
functionality of the interface.

Finally we attach the necessary functions, send and receive a message.
If you are interested, there is a fully fleshed out ØMQ Perl interface
implemented using FFI called [ZMQ::FFI](https://metacpan.org/pod/ZMQ::FFI).

## libarchive

```perl
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );

# This example uses FreeBSD's libarchive to list the contents of any
# archive format that it suppors.  We've also filled out a part of
# the ArchiveWrite class that could be used for writing archive formats
# supported by libarchive

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(find_lib_or_die lib => 'archive');
$ffi->type('object(Archive)'      => 'archive_t');
$ffi->type('object(ArchiveRead)'  => 'archive_read_t');
$ffi->type('object(ArchiveWrite)' => 'archive_write_t');
$ffi->type('object(ArchiveEntry)' => 'archive_entry_t');

package Archive;

# base class is "abstract" having no constructor or destructor

$ffi->mangler(sub {
  my($name) = @_;
  "archive_$name";
});
$ffi->attach( error_string => ['archive_t'] => 'string' );

package ArchiveRead;

our @ISA = qw( Archive );

$ffi->mangler(sub {
  my($name) = @_;
  "archive_read_$name";
});

$ffi->attach( new                   => ['string']                        => 'archive_read_t' );
$ffi->attach( [ free => 'DESTROY' ] => ['archive_t']                     => 'void' );
$ffi->attach( support_filter_all    => ['archive_t']                     => 'int' );
$ffi->attach( support_format_all    => ['archive_t']                     => 'int' );
$ffi->attach( open_filename         => ['archive_t','string','size_t']   => 'int' );
$ffi->attach( next_header2          => ['archive_t', 'archive_entry_t' ] => 'int' );
$ffi->attach( data_skip             => ['archive_t']                     => 'int' );
# ... define additional read methods

package ArchiveWrite;

our @ISA = qw( Archive );

$ffi->mangler(sub {
  my($name) = @_;
  "archive_write_$name";
});

$ffi->attach( new                   => ['string'] => 'archive_write_t' );
$ffi->attach( [ free => 'DESTROY' ] => ['archive_write_t'] => 'void' );
# ... define additional write methods

package ArchiveEntry;

$ffi->mangler(sub {
  my($name) = @_;
  "archive_entry_$name";
});

$ffi->attach( new => ['string']     => 'archive_entry_t' );
$ffi->attach( [ free => 'DESTROY' ] => ['archive_entry_t'] => 'void' );
$ffi->attach( pathname              => ['archive_entry_t'] => 'string' );
# ... define additional entry methods

package main;

use constant ARCHIVE_OK => 0;

# this is a Perl version of the C code here:
# https://github.com/libarchive/libarchive/wiki/Examples#List_contents_of_Archive_stored_in_File

my $archive_filename = shift @ARGV;
unless(defined $archive_filename)
{
  print "usage: $0 archive.tar\n";
  exit;
}

my $archive = ArchiveRead->new;
$archive->support_filter_all;
$archive->support_format_all;

my $r = $archive->open_filename($archive_filename, 1024);
die "error opening $archive_filename: ", $archive->error_string
  unless $r == ARCHIVE_OK;

my $entry = ArchiveEntry->new;

while($archive->next_header2($entry) == ARCHIVE_OK)
{
  print $entry->pathname, "\n";
  $archive->data_skip;
}
```

**Discussion**: libarchive is the implementation of `tar` for FreeBSD
provided as a library and available on a number of platforms.

One interesting thing about libarchive is that it provides a kind of
object oriented interface via opaque pointers.  This example creates an
abstract class `Archive`, and concrete classes `ArchiveWrite`,
`ArchiveRead` and `ArchiveEntry`.  The concrete classes can even be
inherited from and extended just like any Perl classes because of the
way the custom types are implemented.  We use Platypus's `object`
type for this implementation, which is a wrapper around an `opaque`
(can also be an integer) type that is blessed into a particular class.

Another advanced feature of this example is that we define a mangler
to modify the symbol resolution for each class.  This means we can do
this when we define a method for Archive:

```perl
$ffi->attach( support_filter_all => ['archive_t'] => 'int' );
```

Rather than this:

```perl
$ffi->attach(
  [ archive_read_support_filter_all => 'support_read_filter_all' ] =>
  ['archive_t'] => 'int' );
);
```

## unix open

```perl
use FFI::Platypus 2.00;

{
  package FD;

  use constant O_RDONLY => 0;
  use constant O_WRONLY => 1;
  use constant O_RDWR   => 2;

  use constant IN  => bless \do { my $in=0  }, __PACKAGE__;
  use constant OUT => bless \do { my $out=1 }, __PACKAGE__;
  use constant ERR => bless \do { my $err=2 }, __PACKAGE__;

  my $ffi = FFI::Platypus->new( api => 2, lib => [undef]);

  $ffi->type('object(FD,int)' => 'fd');

  $ffi->attach( [ 'open' => 'new' ] => [ 'string', 'int', 'mode_t' ] => 'fd' => sub {
    my($xsub, $class, $fn, @rest) = @_;
    my $fd = $xsub->($fn, @rest);
    die "error opening $fn $!" if $$fd == -1;
    $fd;
  });

  $ffi->attach( write => ['fd', 'string', 'size_t' ] => 'ssize_t' );
  $ffi->attach( read  => ['fd', 'string', 'size_t' ] => 'ssize_t' );
  $ffi->attach( close => ['fd'] => 'int' );
}

my $fd = FD->new("$0", FD::O_RDONLY);

my $buffer = "\0" x 10;

while(my $br = $fd->read($buffer, 10))
{
  FD::OUT->write($buffer, $br);
}

$fd->close;
```

**Discussion**: The Unix file system calls use an integer handle for
each open file.  We can use the same `object` type that we used
for libarchive above, except we let platypus know that the underlying
type is `int` instead of `opaque` (the latter being the default for
the `object` type).  Mainly just for demonstration since Perl has much
better IO libraries, but now we have an OO interface to the Unix IO
functions.

## bzip2

```perl
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );
use FFI::Platypus::Memory qw( malloc free );

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(find_lib_or_die lib => 'bz2');

$ffi->attach(
  [ BZ2_bzBuffToBuffCompress => 'compress' ] => [
    'opaque',                           # dest
    'unsigned int *',                   # dest length
    'opaque',                           # source
    'unsigned int',                     # source length
    'int',                              # blockSize100k
    'int',                              # verbosity
    'int',                              # workFactor
  ] => 'int',
  sub {
    my $sub = shift;
    my($source,$source_length) = scalar_to_buffer $_[0];
    my $dest_length = int(length($source)*1.01) + 1 + 600;
    my $dest = malloc $dest_length;
    my $r = $sub->($dest, \$dest_length, $source, $source_length, 9, 0, 30);
    die "bzip2 error $r" unless $r == 0;
    my $compressed = buffer_to_scalar($dest, $dest_length);
    free $dest;
    $compressed;
  },
);

$ffi->attach(
  [ BZ2_bzBuffToBuffDecompress => 'decompress' ] => [
    'opaque',                           # dest
    'unsigned int *',                   # dest length
    'opaque',                           # source
    'unsigned int',                     # source length
    'int',                              # small
    'int',                              # verbosity
  ] => 'int',
  sub {
    my $sub = shift;
    my($source, $source_length) = scalar_to_buffer $_[0];
    my $dest_length = $_[1];
    my $dest = malloc $dest_length;
    my $r = $sub->($dest, \$dest_length, $source, $source_length, 0, 0);
    die "bzip2 error $r" unless $r == 0;
    my $decompressed = buffer_to_scalar($dest, $dest_length);
    free $dest;
    $decompressed;
  },
);

my $original = "hello compression world\n";
my $compressed = compress($original);
print decompress($compressed, length $original);
```

**Discussion**: bzip2 is a compression library.  For simple one shot
attempts at compression/decompression when you expect the original and
the result to fit within memory it provides two convenience functions
`BZ2_bzBuffToBuffCompress` and `BZ2_bzBuffToBuffDecompress`.

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
last argument to the ["attach"](#attach) method.  The first argument to this
wrapper will be a code reference to the C function.  The Perl arguments
will come in after that.  This allows you to modify / convert the
arguments to conform to the C API.  What ever value you return from the
wrapper function will be returned back to the original caller.

## bundle your own code

`ffi/foo.c`:

```
#include <ffi_platypus_bundle.h>
#include <string.h>

typedef struct {
  char *name;
  int value;
} foo_t;

foo_t*
foo__new(const char *class_name, const char *name, int value)
{
  (void)class_name;
  foo_t *self = malloc( sizeof( foo_t ) );
  self->name = strdup(name);
  self->value = value;
  return self;
}

const char *
foo__name(foo_t *self)
{
  return self->name;
}

int
foo__value(foo_t *self)
{
  return self->value;
}

void
foo__DESTROY(foo_t *self)
{
  free(self->name);
  free(self);
}
```

`lib/Foo.pm`:

```perl
package Foo;

use strict;
use warnings;
use FFI::Platypus 2.00;

{
  my $ffi = FFI::Platypus->new( api => 2 );

  $ffi->type('object(Foo)' => 'foo_t');
  $ffi->mangler(sub {
    my $name = shift;
    $name =~ s/^/foo__/;
    $name;
  });

  $ffi->bundle;

  $ffi->attach( new =>     [ 'string', 'string', 'int' ] => 'foo_t'  );
  $ffi->attach( name =>    [ 'foo_t' ]                   => 'string' );
  $ffi->attach( value =>   [ 'foo_t' ]                   => 'int'    );
  $ffi->attach( DESTROY => [ 'foo_t' ]                   => 'void'   );
}

1;
```

You can bundle your own C (or other compiled language) code with your
Perl extension.  Sometimes this is helpful for smoothing over the
interface of a C library which is not very FFI friendly.  Sometimes
you may want to write some code in C for a tight loop.  Either way,
you can do this with the Platypus bundle interface.  See
[FFI::Platypus::Bundle](https://metacpan.org/pod/FFI::Platypus::Bundle) for more details.

Also related is the bundle constant interface, which allows you to
define Perl constants in C space.  See [FFI::Platypus::Constant](https://metacpan.org/pod/FFI::Platypus::Constant)
for details.

# FAQ

## How do I get constants defined as macros in C header files

This turns out to be a challenge for any language calling into C, which
frequently uses `#define` macros to define constants like so:

```
#define FOO_STATIC  1
#define FOO_DYNAMIC 2
#define FOO_OTHER   3
```

As macros are expanded and their definitions are thrown away by the C pre-processor
there isn't any way to get the name/value mappings from the compiled dynamic
library.

You can manually create equivalent constants in your Perl source:

```perl
use constant FOO_STATIC  => 1;
use constant FOO_DYNAMIC => 2;
use constant FOO_OTHER   => 3;
```

If there are a lot of these types of constants you might want to consider using
a tool ([Convert::Binary::C](https://metacpan.org/pod/Convert::Binary::C) can do this) that can extract the constants for you.

See also the "Integer constants" example in [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type).

You can also use the new Platypus bundle interface to define Perl constants
from C space.  This is more reliable, but does require a compiler at install
time.  It is recommended mainly for writing bindings against libraries that
have constants that can vary widely from platform to platform.  See
[FFI::Platypus::Constant](https://metacpan.org/pod/FFI::Platypus::Constant) for details.

## What about enums?

The C enum types are integers.  The underlying type is up to the platform, so
Platypus provides `enum` and `senum` types for unsigned and singed enums
respectively.  At least some compilers treat signed and unsigned enums as
different types.  The enum _values_ are essentially the same as macro constants
described above from an FFI perspective.  Thus the process of defining enum values
is identical to the process of defining macro constants in Perl.

For more details on enumerated types see ["Enum types" in FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type#Enum-types).

There is also a type plugin ([FFI::Platypus::Type::Enum](https://metacpan.org/pod/FFI::Platypus::Type::Enum)) that can be helpful
in writing interfaces that use enums.

## Memory leaks

There are a couple places where memory is allocated, but never deallocated that may
look like memory leaks by tools designed to find memory leaks like valgrind.  This
memory is intended to be used for the lifetime of the perl process so there normally
this isn't a problem unless you are embedding a Perl interpreter which doesn't closely
match the lifetime of your overall application.

Specifically:

- type cache

    some types are cached and not freed.  These are needed as long as there are FFI
    functions that could be called.

- attached functions

    Attaching a function as an xsub will definitely allocate memory that won't be freed
    because the xsub could be called at any time, including in `END` blocks.

The Platypus team plans on adding a hook to free some of this "leaked" memory
for use cases where Perl and Platypus are embedded in a larger application
where the lifetime of the Perl process is significantly smaller than the
overall lifetime of the whole process.

## I get seg faults on some platforms but not others with a library using pthreads.

On some platforms, Perl isn't linked with `libpthreads` if Perl threads are not
enabled.  On some platforms this doesn't seem to matter, `libpthreads` can be
loaded at runtime without much ill-effect.  (Linux from my experience doesn't seem
to mind one way or the other).  Some platforms are not happy about this, and about
the only thing that you can do about it is to build Perl such that it links with
`libpthreads` even if it isn't a threaded Perl.

This is not really an FFI issue, but a Perl issue, as you will have the same
problem writing XS code for the such libraries.

## Doesn't work on Perl 5.10.0.

I try as best as possible to support the same range of Perls as the Perl toolchain.
That means all the way back to 5.8.1.  Unfortunately, 5.10.0 seems to have a problem
that is difficult to diagnose.  Patches to fix are welcome, if you want to help
out on this, please see:

[https://github.com/PerlFFI/FFI-Platypus/issues/68](https://github.com/PerlFFI/FFI-Platypus/issues/68)

Since this is an older buggy version of Perl it is recommended that you instead
upgrade to 5.10.1 or later.

# CAVEATS

Platypus and Native Interfaces like libffi rely on the availability of
dynamic libraries.  Things not supported include:

- Systems that lack dynamic library support

    Like MS-DOS

- Systems that are not supported by libffi

    Like OpenVMS

- Languages that do not support using dynamic libraries from other languages

    This used to be the case with Google's Go, but is no longer the case.  This is
    a problem for C / XS code as well.

- Languages that do not compile to machine code

    Like .NET based languages and Java.

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

# SUPPORT

IRC: #native on irc.perl.org

[(click for instant chat room login)](http://chat.mibbit.com/#native@irc.perl.org)

If something does not work the way you think it should, or if you have a
feature request, please open an issue on this project's GitHub Issue
tracker:

[https://github.com/perlFFI/FFI-Platypus/issues](https://github.com/perlFFI/FFI-Platypus/issues)

# CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a
pull request on this project's GitHub repository:

[https://github.com/PerlFFI/FFI-Platypus/pulls](https://github.com/PerlFFI/FFI-Platypus/pulls)

This project is developed using [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).  The project's git
repository also comes with the `Makefile.PL` file necessary
for building, testing (and even installing if necessary) without
[Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).  Please keep in mind though that these files are
generated so if changes need to be made to those files they should be
done through the project's `dist.ini` file.  If you do use
[Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) and already have the necessary plugins installed, then I
encourage you to run `dzil test` before making any pull requests.  This
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

The Platypus distribution comes with a test library named `libtest`
that is normally automatically built by `./Build test`.  If you prefer
to use `prove` or run tests directly, you can use the `./Build
libtest` command to build it.  Example:

```
% perl Makefile.PL
% make
% make ffi-test
% prove -bv t
# or an individual test
% perl -Mblib t/ffi_platypus_memory.t
```

The build process also respects these environment variables:

- FFI\_PLATYPUS\_DEBUG\_FAKE32

    When building Platypus on 32 bit Perls, it will use the [Math::Int64](https://metacpan.org/pod/Math::Int64) C
    API and make [Math::Int64](https://metacpan.org/pod/Math::Int64) a prerequisite.  Setting this environment
    variable will force Platypus to build with both of those options on a 64
    bit Perl as well.

    ```
    % env FFI_PLATYPUS_DEBUG_FAKE32=1 perl Makefile.PL
    DEBUG_FAKE32:
      + making Math::Int64 a prereq
      + Using Math::Int64's C API to manipulate 64 bit values
    Generating a Unix-style Makefile
    Writing Makefile for FFI::Platypus
    Writing MYMETA.yml and MYMETA.json
    %
    ```

- FFI\_PLATYPUS\_NO\_ALLOCA

    Platypus uses the non-standard and somewhat controversial C function
    `alloca` by default on platforms that support it.  I believe that
    Platypus uses it responsibly to allocate small amounts of memory for
    argument type parameters, and does not use it to allocate large
    structures like arrays or buffers.  If you prefer not to use `alloca`
    despite these precautions, then you can turn its use off by setting this
    environment variable when you run `Makefile.PL`:

    ```perl
    helix% env FFI_PLATYPUS_NO_ALLOCA=1 perl Makefile.PL
    NO_ALLOCA:
      + alloca() will not be used, even if your platform supports it.
    Generating a Unix-style Makefile
    Writing Makefile for FFI::Platypus
    Writing MYMETA.yml and MYMETA.json
    ```

- V

    When building platypus may hide some of the excessive output when
    probing and building, unless you set `V` to a true value.

    ```
    % env V=1 perl Makefile.PL
    % make V=1
    ...
    ```

## Coding Guidelines

- Do not hesitate to make code contribution.  Making useful contributions
is more important than following byzantine bureaucratic coding
regulations.  We can always tweak things later.
- Please make an effort to follow existing coding style when making pull
requests.
- Platypus supports all production Perl releases since 5.8.1.  For that
reason, please do not introduce any code that requires a newer version
of Perl.

## Performance Testing

As Mark Twain was fond of saying there are four types of lies: lies,
damn lies, statistics and benchmarks.  That being said, it can sometimes
be helpful to compare the runtime performance of Platypus if you are
making significant changes to the Platypus Core.  For that I use
\`FFI-Performance\`, which can be found in my GitHub repository here:

- [https://github.com/Perl5-FFI/FFI-Performance](https://github.com/Perl5-FFI/FFI-Performance)

## System integrators

This distribution uses [Alien::FFI](https://metacpan.org/pod/Alien::FFI) in fallback mode, meaning if
the system doesn't provide `pkg-config` and `libffi` it will attempt
to download `libffi` and build it from source.  If you are including
Platypus in a larger system (for example a Linux distribution) you
only need to make sure to declare `pkg-config` or `pkgconf` and
the development package for `libffi` as prereqs for this module.

# SEE ALSO

## Extending Platypus

- [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type)

    Type definitions for Platypus.

- [FFI::C](https://metacpan.org/pod/FFI::C)

    Interface for defining structured data records for use with
    Platypus.  It supports C `struct`, `union`, nested structures
    and arrays of all of those.  It only supports passing these
    types by reference or pointer, so if you need to pass structured
    data by value see [FFI::Platypus::Record](https://metacpan.org/pod/FFI::Platypus::Record) below.

- [FFI::Platypus::Record](https://metacpan.org/pod/FFI::Platypus::Record)

    Interface for defining structured data records for use with
    Platypus.  Included in the Platypus core.  Supports pass by
    value which is uncommon in C, but frequently used in languages
    like Rust and Go.  Consider using [FFI::C](https://metacpan.org/pod/FFI::C) instead if you
    don't need to pass by value.

- [FFI::Platypus::API](https://metacpan.org/pod/FFI::Platypus::API)

    The custom types API for Platypus.

- [FFI::Platypus::Memory](https://metacpan.org/pod/FFI::Platypus::Memory)

    Memory functions for FFI.

## Languages

- [FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC)

    JIT C compiler for FFI.

- [FFI::Platypus::Lang::C](https://metacpan.org/pod/FFI::Platypus::Lang::C)

    Documentation and tools for using Platypus with the C programming
    language

- [FFI::Platypus::Lang::CPP](https://metacpan.org/pod/FFI::Platypus::Lang::CPP)

    Documentation and tools for using Platypus with the C++ programming
    language

- [FFI::Platypus::Lang::Fortran](https://metacpan.org/pod/FFI::Platypus::Lang::Fortran)

    Documentation and tools for using Platypus with Fortran

- [FFI::Platypus::Lang::Go](https://metacpan.org/pod/FFI::Platypus::Lang::Go)

    Documentation and tools for using Platypus with Go

- [FFI::Platypus::Lang::Pascal](https://metacpan.org/pod/FFI::Platypus::Lang::Pascal)

    Documentation and tools for using Platypus with Free Pascal

- [FFI::Platypus::Lang::Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust)

    Documentation and tools for using Platypus with the Rust programming
    language

- [FFI::Platypus::Lang::ASM](https://metacpan.org/pod/FFI::Platypus::Lang::ASM)

    Documentation and tools for using Platypus with the Assembly

- [FFI::Platypus::Lang::Win32](https://metacpan.org/pod/FFI::Platypus::Lang::Win32)

    Documentation and tools for using Platypus with the Win32 API.

- [FFI::Platypus::Lang::Zig](https://metacpan.org/pod/FFI::Platypus::Lang::Zig)

    Documentation and tools for using Platypus with the Zig programming
    language

- [Wasm](https://metacpan.org/pod/Wasm) and [Wasm::Wasmtime](https://metacpan.org/pod/Wasm::Wasmtime)

    Modules for writing WebAssembly bindings in Perl.  This allows you to call
    functions written in any language supported by WebAssembly.  These modules
    are also implemented using Platypus.

## Other Tools Related Tools Useful for FFI

- [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib)

    Find dynamic libraries in a portable way.

- [Convert::Binary::C](https://metacpan.org/pod/Convert::Binary::C)

    A great interface for decoding C data structures, including `struct`s,
    `enum`s, `#define`s and more.

- [pack and unpack](https://metacpan.org/pod/perlpacktut)

    Native to Perl functions that can be used to decode C `struct` types.

- [C::Scan](https://metacpan.org/pod/C::Scan)

    This module can extract constants and other useful objects from C header
    files that may be relevant to an FFI application.  One downside is that
    its use may require development packages to be installed.

## Other Foreign Function Interfaces

- [Dyn](https://metacpan.org/pod/Dyn)

    A wrapper around [dyncall](https://dyncall.org), which is itself an alternative to
    [libffi](https://sourceware.org/libffi/).

- [NativeCall](https://metacpan.org/pod/NativeCall)

    Promising interface to Platypus inspired by Raku.

- [Win32::API](https://metacpan.org/pod/Win32::API)

    Microsoft Windows specific FFI style interface.

- [FFI](https://metacpan.org/pod/FFI)

    Older, simpler, less featureful FFI.  It used to be implemented
    using FSF's `ffcall`.  Because `ffcall` has been unsupported for
    some time, I reimplemented this module using [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).

- [C::DynaLib](https://metacpan.org/pod/C::DynaLib)

    Another FFI for Perl that doesn't appear to have worked for a long time.

- [C::Blocks](https://metacpan.org/pod/C::Blocks)

    Embed a tiny C compiler into your Perl scripts.

- [P5NCI](https://metacpan.org/pod/P5NCI)

    Yet another FFI like interface that does not appear to be supported or
    under development anymore.

## Other

- [Alien::FFI](https://metacpan.org/pod/Alien::FFI)

    Provides libffi for Platypus during its configuration and build stages.

# ACKNOWLEDGMENTS

In addition to the contributors mentioned below, I would like to
acknowledge Brock Wilcox (AWWAIID) and Meredith Howard (MHOWARD) whose
work on `FFI::Sweet` not only helped me get started with FFI but
significantly influenced the design of Platypus.

Dan Book, who goes by Grinnz on IRC for answering user questions about
FFI and Platypus.

In addition I'd like to thank Alessandro Ghedini (ALEXBIO) whose work
on another Perl FFI library helped drive some of the development ideas
for [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

Dylan Cali (calid)

pipcet

Zaki Mughal (zmughal)

Fitz Elliott (felliott)

Vickenty Fesunov (vyf)

Gregor Herrmann (gregoa)

Shlomi Fish (shlomif)

Damyan Ivanov

Ilya Pavlov (Ilya33)

Petr Písař (ppisar)

Mohammad S Anwar (MANWAR)

Håkon Hægland (hakonhagland, HAKONH)

Meredith (merrilymeredith, MHOWARD)

Diab Jerius (DJERIUS)

Eric Brine (IKEGAMI)

szTheory

José Joaquín Atria (JJATRIA)

Pete Houston (openstrike, HOUSTON)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
