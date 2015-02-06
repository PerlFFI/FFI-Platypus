# FFI::Platypus

Write Perl bindings to non-Perl libraries with FFI. No XS required.

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

Platypus provides a method for creating interfaces to machine code 
libraries.  This implementation uses `libffi`, a library that provides 
Foreign Function Interfaces for a number of other languages, including 
Ruby and Python.  Platypus can be used in stand alone scripts, or to 
create Perl extensions for CPAN.  There are a number of reasons why you 
might want to write extensions with FFI instead of XS:

- FFI / Platypus does not require messing with the guts of Perl

    XS is less of an API and more of the guts of perl splayed out to do 
    whatever you want.  That may at times be very powerful, but it may also 
    sometimes be very dangerous to your mental health.

- FFI / Platypus is portable

    Lots of languages have FFI interfaces, and it is subjectively easier to 
    port an extension written in FFI in Perl or another language to FFI in 
    another language or Perl.  One goal of the Platypus Project is to reduce 
    common interface specifications to a common format like JSON that could 
    be shared between different languages.

- FFI / Platypus could be a bridge to Perl 6

    One of those "other" languages could be Perl 6 and Perl 6 already has an 
    FFI interface I am told.

- FFI / Platypus is pure perl (sorta)

    One Platypus script or module works on any platform where the libraries 
    it uses are available.  That means you can deploy your Platypus script 
    in a shared filesystem where they may be run on different platforms.  It 
    also means that Platypus modules do not need to be installed in the 
    platform specific Perl library path.

- FFI / Platypus is not C or C++ centric

    XS is implemented primarily as a bunch of C macros, which requires at 
    least some understanding of C, the C pre-processor, and some C++ 
    caveats (since on some platforms Perl is compiled and linked with a C++ 
    compiler). Platypus on the other hand could be used to call other 
    compiled languages, like Fortran, [Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust),
    [Pascal](https://metacpan.org/pod/FFI::Platypus::Lang::Pascal), [C++](https://metacpan.org/pod/FFI::Platypus::Lang::CPP),
    Go or even [assembly](https://metacpan.org/pod/FFI::Platypus::Lang::ASM), allowing you to focus
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

Platypus also provides an declarative interface you may want to use 
instead of the object oriented interface called 
[FFI::Platypus::Declare](https://metacpan.org/pod/FFI::Platypus::Declare).

Platypus has extensive documentation of types at [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type) 
and its custom types API at [FFI::Platypus::API](https://metacpan.org/pod/FFI::Platypus::API).

# CONSTRUCTORS

## new

    my $ffi = FFI::Platypus->new(%options);

Create a new instance of [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).

Any types defined with this instance will be valid for this instance 
only, so you do not need to worry about stepping on the toes of other 
CPAN FFI / Platypus Authors.

Any functions found will be out of the list of libraries specified with 
the [lib](#lib) attribute.

### options

- lib

    Either a pathname (string) or a list of pathnames (array ref of strings) 
    to pre-populate the [lib](#lib) attribute.

- ignore\_not\_found

    \[version 0.15\]

    Set the [ignore\_not\_found](#ignore_not_found) attribute.

- lang

    \[version 0.18\]

    Set the [lang](#lang) attribute.

# ATTRIBUTES

## lib

    $ffi->lib($path1, $path2, ...);
    my @paths = $ffi->lib;

The list of libraries to search for symbols in.

The most portable and reliable way to find dynamic libraries is by using 
[FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib), like this:

    use FFI::CheckLib 0.06;
    $ffi->lib(find_lib_or_die lib => 'archive'); 
      # finds libarchive.so on Linux
      #       libarchive.bundle on OS X
      #       libarchive.dll (or archive.dll) on Windows
      #       cygarchive-13.dll on Cygwin
      #       ...
      # and will die if it isn't found

[FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) has a number of options, such as checking for specific 
symbols, etc.  You should consult the documentation for that module.

As a special case, if you add `undef` as a "library" to be searched, 
Platypus will also search the current process for symbols. This is 
mostly useful for finding functions in the standard C library, without 
having to know the name of the standard c library for your platform (as 
it turns out it is different just about everywhere!).

You may also use the ["find\_lib"](#find_lib) method as a shortcut:

    $ffi->find_lib( lib => 'archive' );

## ignore\_not\_found

\[version 0.15\]

    $ffi->ignore_not_found(1);
    my $ignore_not_found = $ffi->ignore_not_found;

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

    $ffi->lang($language);

Specifies the foreign language that you will be interfacing with. The 
default is C.  The foreign language specified with this attribute 
changes the default native types (for example, if you specify 
[Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust), you will get `i32` as an alias for 
`sint32` instead of `int` as you do with [C](https://metacpan.org/pod/FFI::Platypus::Lang::C)).

If the foreign language plugin supports it, this will also enable 
Platypus to find symbols using the demangled names (for example, if you 
specify [CPP](https://metacpan.org/pod/FFI::Platypus::Lang::CPP) for C++ you can use method names 
like `Foo::get_bar()` with ["attach"](#attach) or ["function"](#function).

# METHODS

## type

    $ffi->type($typename);
    $ffi->type($typename => $alias);

Define a type.  The first argument is the native or C name of the type.  
The second argument (optional) is an alias name that you can use to 
refer to this new type.  See [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type) for legal type 
definitions.

Examples:

    $ffi->type('sint32'); # oly checks to see that sint32 is a valid type
    $ffi->type('sint32' => 'myint'); # creates an alias myint for sint32
    $ffi->type('bogus'); # dies with appropriate diagnostic

## custom\_type

    $ffi->custom_type($alias => {
      native_type         => $native_type,
      native_to_perl      => $coderef,
      perl_to_native      => $coderef,
      perl_to_native_post => $coderef,
    });

Define a custom type.  See [FFI::Platypus::Type#Custom-Types](https://metacpan.org/pod/FFI::Platypus::Type#Custom-Types) for details.

## load\_custom\_type

    $ffi->load_custom_type($name => $alias, @type_args);

Load the custom type defined in the module _$name_, and make an alias 
_$alias_. If the custom type requires any arguments, they may be passed 
in as _@type\_args_. See [FFI::Platypus::Type#Custom-Types](https://metacpan.org/pod/FFI::Platypus::Type#Custom-Types) for 
details.

If _$name_ contains `::` then it will be assumed to be a fully 
qualified package name. If not, then `FFI::Platypus::Type::` will be 
prepended to it.

## types

    my @types = $ffi->types;
    my @types = FFI::Platypus->types;

Returns the list of types that FFI knows about.  This will include the 
native `libffi` types (example: `sint32`, `opaque` and `double`) and 
the normal C types (example: `unsigned int`, `uint32_t`), any types 
that you have defined using the [type](#type) method, and
custom types.

The list of types that Platypus knows about varies somewhat from 
platform to platform, [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type) includes a list of the core 
types that you can always count on having access to.

It can also be called as a class method, in which case, no user defined 
or custom types will be included in the list.

## type\_meta

    my $meta = $ffi->type_meta($type_name);
    my $meta = FFI::Platypus->type_meta($type_name);

Returns a hash reference with the meta information for the given type.

It can also be called as a class method, in which case, you won't be 
able to get meta data on user defined types.

Examples:

    my $meta = $ffi->type_meta('int');        # standard int type
    my $meta = $ffi->type_meta('int[64]');    # array of 64 ints
    $ffi->type('int[128]' => 'myintarray');
    my $meta = $ffi->type_meta('myintarray'); # array of 128 ints

## function

    my $function = $ffi->function($name => \@argument_types => $return_type);
    my $function = $ffi->function($address => \@argument_types => $return_type);

Returns an object that is similar to a code reference in that it can be 
called like one.

Caveat: many situations require a real code reference, so at the price 
of a performance penalty you can get one like this:

    my $function = $ffi->function(...);
    my $coderef = sub { $function->(@_) };

It may be better, and faster to create a real Perl function using the 
[attach](#attach) method.

In addition to looking up a function by name you can provide the address 
of the symbol yourself:

    my $address = $ffi->find_symbol('my_functon');
    my $function = $ffi->function($address => ...);

Under the covers, [function](#function) uses 
[find\_symbol](#find_symbol) when you provide it with a 
name, but it is useful to keep this in mind as there are alternative 
ways of obtaining a functions address.  Example: a C function could 
return the address of another C function that you might want to call, or 
modules such as [FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC) produce machine code at runtime that you 
can call from Platypus.

Examples:

    my $function = $ffi->function('my_function_name', ['int', 'string'] => 'string');
    my $return_string = $function->(1, "hi there");

## attach

    $ffi->attach($name => \@argument_types => $return_type);
    $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type);
    $ffi->attach([$address => $perl_name] => \@argument_types => $return_type);
    $ffi->attach($name => \@argument_types => $return_type, sub { ... });
    $ffi->attach([$c_name => $perl_name] => \@argument_types => $return_type, sub { ... });
    $ffi->attach([$address => $perl_name] => \@argument_types => $return_type, sub { ... });

Find and attach a C function as a real live Perl xsub.  The advantage of 
attaching a function over using the [function](#function) 
method is that it is much much much faster since no object resolution 
needs to be done.  The disadvantage is that it locks the function and 
the [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instance into memory permanently, since there is no 
way to deallocate an xsub.

If just one _$name_ is given, then the function will be attached in 
Perl with the same name as it has in C.  The second form allows you to 
give the Perl function a different name.  You can also provide an 
address (the third form), just like with the 
[function](#function) method.

Examples:

    $ffi->attach('my_functon_name', ['int', 'string'] => 'string');
    $ffi->attach(['my_c_functon_name' => 'my_perl_function_name'], ['int', 'string'] => 'string');
    my $string1 = my_function_name($int);
    my $string2 = my_perl_function_name($int);

\[version 0.20\]

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

## closure

    my $closure = $ffi->closure($coderef);

Prepares a code reference so that it can be used as a FFI closure (a 
Perl subroutine that can be called from C code).  For details on 
closures, see [FFI::Platypus::Type#Closures](https://metacpan.org/pod/FFI::Platypus::Type#Closures).

## cast

    my $converted_value = $ffi->cast($original_type, $converted_type, $original_value);

The `cast` function converts an existing _$original\_value_ of type 
_$original\_type_ into one of type _$converted\_type_.  Not all types 
are supported, so care must be taken.  For example, to get the address 
of a string, you can do this:

    my $address = $ffi->cast('string' => 'opaque', $string_value);

Something that won't work is trying to cast an array to anything:

    my $address = $ffi->cast('int[10]' => 'opaque', \@list);  # WRONG

## attach\_cast

    $ffi->attach_cast("cast_name", $original_type, $converted_type);
    my $converted_value = cast_name($original_value);

This function attaches a cast as a permanent xsub.  This will make it 
faster and may be useful if you are calling a particular cast a lot.

## sizeof

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

## alignof

\[version 0.21\]

    my $align = $ffi->alignof($type);

Returns the alignment of the given type in bytes.

## find\_lib

\[version 0.20\]

    $ffi->find_lib( lib => $libname );

This is just a shortcut for calling [FFI::CheckLib#find\_lib](https://metacpan.org/pod/FFI::CheckLib#find_lib) and
updating the ["lib"](#lib) attribute appropriately.  Care should be taken
though, as this method simply passes its arguments to
[FFI::CheckLib#find\_lib](https://metacpan.org/pod/FFI::CheckLib#find_lib), so if your module or script is depending
on a specific feature in [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) then make sure that you
update your prerequisites appropriately.

## find\_symbol

    my $address = $ffi->find_symbol($name);

Return the address of the given symbol (usually function).

## package

\[version 0.15\]

    $ffi->package($package, $file); # usually __PACKAGE__ and __FILE__ can be used
    $ffi->package;                  # autodetect

If you have used [Module::Build::FFI](https://metacpan.org/pod/Module::Build::FFI) to bundle C code with your
distribution, you can use this method to tell the [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instance
to look for symbols that came with the dynamic library that was built
when your distribution was installed.

# EXAMPLES

Here are some examples.  Some of them use the [FFI::Platypus::Declare](https://metacpan.org/pod/FFI::Platypus::Declare) 
interface, but the principles apply to the OO interface.  These examples 
are provided in full with the Platypus distribution in the "examples" 
directory.  There are also some more examples in [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type) 
that are related to types.

## Integer conversions

    use FFI::Platypus::Declare qw( int string );
    
    lib undef;
    attach puts => [string] => int;
    attach atoi => [string] => int;
    
    puts(atoi('56'));

**Discussion**: `puts` and `atoi` should be part of the standard C 
library on all platforms.  `puts` prints a string to standard output, 
and `atoi` converts a string to integer.  Specifying `undef` as a 
library tells Platypus to search the current process for symbols, which 
includes the standard c library.

## libnotify

    use FFI::CheckLib;
    use FFI::Platypus::Declare qw( void string opaque );
    
    # NOTE: I ported this from the like named eg/notify.pl that came with FFI::Raw
    # and it seems to work most of the time, but also seems to SIGSEGV sometimes.
    # I saw the same behavior in the FFI::Raw version, and am not really familiar
    # with the libnotify API to say what is the cause.  Patches welcome to fix it.
    
    lib find_lib_or_exit lib => 'notify';
    
    attach notify_init   => [string] => void;
    attach notify_uninit => []       => void;
    attach [notify_notification_new    => 'notify_new']    => [string,string,string]           => opaque;
    attach [notify_notification_update => 'notify_update'] => [opaque, string, string, string] => void;
    attach [notify_notification_show   => 'notify_show']   => [opaque, opaque]                 => void;
    
    notify_init('FFI::Platypus');
    my $n = notify_new('','','');
    notify_update($n, 'FFI::Platypus', 'It works!!!', 'media-playback-start');
    notify_show($n, undef);
    notify_uninit();

**Discussion**: libnotify is a desktop GUI notification library for the 
GNOME Desktop environment. This script sends a notification event that 
should show up as a balloon, for me it did so in the upper right hand 
corner of my screen.

The most portable way to find the correct name and location of a dynamic 
library is via the [FFI::CheckLib#find\_lib](https://metacpan.org/pod/FFI::CheckLib#find_lib) family of functions.  If 
you are putting together a CPAN distribution, you should also consider 
using [FFI::CheckLib#check\_lib\_or\_exit](https://metacpan.org/pod/FFI::CheckLib#check_lib_or_exit) function in your `Build.PL` or 
`Makefile.PL` file (If you are using [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla), check out the 
[Dist::Zilla::Plugin::FFI::CheckLib](https://metacpan.org/pod/Dist::Zilla::Plugin::FFI::CheckLib) plugin). This will provide a user 
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

Later, when we call `notify_new`:

    my $n = notify_new('','','');

We are really calling the C function `notify_notification_new`.

## Allocating and freeing memory

    use FFI::Platypus::Declare;
    use FFI::Platypus::Memory qw( malloc free memcpy );
    
    my $buffer = malloc 12;
    
    memcpy $buffer, cast('string' => 'opaque', "hello there"), length "hello there\0";
    
    print cast('opaque' => 'string', $buffer), "\n";
    
    free $buffer;

**Discussion**: `malloc` and `free` are standard memory allocation 
functions available from the standard c library and.  Interfaces to 
these and other memory related functions are provided by the 
[FFI::Platypus::Memory](https://metacpan.org/pod/FFI::Platypus::Memory) module.

## libuuid

    use FFI::CheckLib;
    use FFI::Platypus::Declare qw( void opaque string );
    use FFI::Platypus::Memory qw( malloc free );
    
    lib find_lib_or_exit lib => 'uuid';
    
    attach uuid_generate => [opaque] => void;
    attach uuid_unparse  => [opaque,opaque] => void;
    
    my $uuid = malloc sizeof 'char[16]';  # uuid_t
    uuid_generate($uuid);
    
    my $string_opaque = malloc 37;       # 36 bytes to store a UUID string
    uuid_unparse($uuid, $string_opaque);
    
    print cast( opaque => string, $string_opaque), "\n";

**Discussion**: libuuid is a library used to generate unique identifiers 
(UUID) for objects that may be accessible beyond the local system.  The 
library is or was part of the Linux e2fsprogs package.

Knowing the size of objects is sometimes important.  In this example, we 
use the [sizeof](#sizeof) function to get the size of 16 
characters (in this case it is simply 16 bytes).  We also know that the 
strings "deparsed" by `uuid_unparse` are exactly 37 bytes.

## puts and getpid

    use FFI::Platypus::Declare qw( string int );
    
    lib undef;
    attach puts => [string] => int;
    attach getpid => [] => int;
    
    puts(getpid());

**Discussion**: `puts` is part of standard C library on all platforms.  
`getpid` is available on Unix type platforms.

## Math library

    use FFI::Platypus::Declare qw( string int double );
    use FFI::CheckLib;
    
    lib undef;
    attach puts => [string] => int;
    attach fdim => [double,double] => double;
    
    puts(fdim(7.0, 2.0));
    
    attach cos => [double] => double;
    
    puts(cos(2.0));
    
    attach fmax => [double, double] => double;
    
    puts(fmax(2.0,3.0));

**Discussion**: On UNIX the standard c library math functions are 
frequently provided in a separate library `libm`, so you could search 
for those symbols in "libm.so", but that won't work on non-UNIX 
platforms like Microsoft Windows.  Fortunately Perl uses the math 
library so these symbols are already in the current process so you can 
use `undef` as the library to find them.

## Strings

    use FFI::Platypus::Declare qw( int string );
    
    lib undef;
    attach puts => [string] => int;
    attach strlen => [string] => int;
    
    puts(strlen('somestring'));
    
    attach strstr => [string,string] => string;
    
    puts(strstr('somestring', 'string'));
    
    #attach puts => [string] => int;
    
    puts(puts("lol"));
    
    attach strerror => [int] => string;
    
    puts(strerror(2));

**Discussion**: Strings are not a native type to `libffi` but the are 
handled seamlessly by Platypus.

## Attach function from pointer

    use FFI::TinyCC;
    use FFI::Platypus;
    
    my $ffi = FFI::Platypus->new;
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

**Discussion**: Sometimes you will have a pointer to a function from a 
source other than Platypus that you want to call.  You can use that 
address instead of a function name for either of the 
[function](#function) or [attach](#attach) 
methods.  In this example we use [FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC) to compile a short piece 
of C code and to give us the address of one of its functions, which we 
then use to create a perl xsub to call it.

[FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC) embeds the Tiny C Compiler (tcc) to provide a 
just-in-time (JIT) compilation service for FFI.

## libzmq

    use constant ZMQ_IO_THREADS  => 1;
    use constant ZMQ_MAX_SOCKETS => 2;
    use constant ZMQ_REQ => 3;
    use constant ZMQ_REP => 4;
    use FFI::CheckLib qw( find_lib_or_exit );
    use FFI::Platypus;
    use FFI::Platypus::Memory qw( malloc );
    use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );
    
    my $endpoint = "ipc://zmq-ffi-$$";
    my $ffi = FFI::Platypus->new;
    
    $ffi->lib(undef); # for puts
    $ffi->attach(puts => ['string'] => 'int');
    
    $ffi->lib(find_lib_or_exit lib => 'zmq');
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

    use FFI::Platypus      ();
    use FFI::Platypus::API ();
    use FFI::CheckLib      ();
    
    # This example uses FreeBSD's libarchive to list the contents of any
    # archive format that it suppors.  We've also filled out a part of
    # the ArchiveWrite class that could be used for writing archive formats
    # supported by libarchive
    
    my $ffi = My::Platypus->new;
    $ffi->lib(FFI::CheckLib::find_lib_or_exit lib => 'archive');
    
    $ffi->custom_type(archive => {
      native_type    => 'opaque',
      perl_to_native => sub { ${$_[0]} },
      native_to_perl => sub {
        # this works because archive_read_new ignores any arguments
        # and we pass in the class name which we can get here.
        my $class = FFI::Platypus::API::arguments_get_string(0);
        bless \$_[0], $class;
      },
    });
    
    $ffi->custom_type(archive_entry => {
      native_type => 'opaque',
      perl_to_native => sub { ${$_[0]} },
      native_to_perl => sub {
        # works likewise for archive_entry objects
        my $class = FFI::Platypus::API::arguments_get_string(0);
        bless \$_[0], $class,
      },
    });
    
    package My::Platypus;
    
    use base qw( FFI::Platypus );
    
    sub find_symbol
    {
      my($self, $name) = @_;
      my $prefix = lcfirst caller(2);
      $prefix =~ s{([A-Z])}{"_" . lc $1}eg;
      $self->SUPER::find_symbol(join '_', $prefix, $name);
    }
    
    package Archive;
    
    # base class is "abstract" having no constructor or destructor
    
    $ffi->attach( error_string => ['archive'] => 'string' );
    
    package ArchiveRead;
    
    our @ISA = qw( Archive );
    
    $ffi->attach( new                   => ['string']                    => 'archive' );
    $ffi->attach( [ free => 'DESTROY' ] => ['archive']                   => 'void' );
    $ffi->attach( support_filter_all    => ['archive']                   => 'int' );
    $ffi->attach( support_format_all    => ['archive']                   => 'int' );
    $ffi->attach( open_filename         => ['archive','string','size_t'] => 'int' );
    $ffi->attach( next_header2          => ['archive', 'archive_entry' ] => 'int' );
    $ffi->attach( data_skip             => ['archive']                   => 'int' );
    # ... define additional read methods
    
    package ArchiveWrite;
    
    our @ISA = qw( Archive );
    
    $ffi->attach( new                   => ['string'] => 'archive' );
    $ffi->attach( [ free => 'DESTROY' ] => ['archive'] => 'void' );
    # ... define additional write methods
    
    package ArchiveEntry;
    
    $ffi->attach( new => ['string']     => 'archive_entry' );
    $ffi->attach( [ free => 'DESTROY' ] => ['archive_entry'] => 'void' );
    $ffi->attach( pathname              => ['archive_entry'] => 'string' );
    # ... define additional entry methods
    
    package main;
    
    use constant ARCHIVE_OK => 0;
    
    # this is a Perl version of the C code here:
    # https://github.com/libarchive/libarchive/wiki/Examples#List_contents_of_Archive_stored_in_File
    
    my $archive_filename = shift @ARGV;
    die "usage: $0 archive.tar" unless defined $archive_filename;
    
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

**Discussion**: libarchive is the implementation of `tar` for FreeBSD 
provided as a library and available on a number of platforms.

One interesting thing about libarchive is that it provides a kind of 
object oriented interface via opaque pointers.  This example creates an 
abstract class `Archive`, and concrete classes `ArchiveWrite`, 
`ArchiveRead` and `ArchiveEntry`.  The concrete classes can even be 
inherited from and extended just like any Perl classes because of the 
way the custom types are implemented.  For more details on custom types 
see [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type) and [FFI::Platypus::API](https://metacpan.org/pod/FFI::Platypus::API).

Another advanced feature of this example is that we extend the 
[FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) class to define our own find\_symbol method that prefixes
the symbol names depending on the class in which they are defined.
This means we can do this when we define a method for Archive:

    $ffi->attach( support_filter_all => ['archive'] => 'int' );

Rather than this:

    $ffi->attach(
      [ archive_read_support_filter_all => 'support_read_filter_all' ] => 
      ['archive'] => 'int' );
    );

If you didn't want to create an entire new class just for this little
trick you could also use something like [Object::Method](https://metacpan.org/pod/Object::Method) to extend
`find_symbol`.

## bzip2

    use FFI::Platypus 0.20 (); # 0.20 required for using wrappers
    use FFI::CheckLib qw( find_lib_or_die );
    use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );
    use FFI::Platypus::Memory qw( malloc free );
    
    my $ffi = FFI::Platypus->new;
    $ffi->lib(find_lib_or_die lib => 'bz2');
    
    $ffi->attach(
      [ BZ2_bzBuffToBuffCompress => 'compress' ] => [
        'opaque',                          # dest
        'unsigned int *',                  # dest length
        'opaque',                          # source
        'unsigned int',                    # source length
        'int',                             # blockSize100k
        'int',                             # verbosity
        'int',                             # workFactor
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
        'opaque',                          # dest
        'unsigned int *',                  # dest length
        'opaque',                          # source
        'unsigned int',                    # source length
        'int',                             # small
        'int',                             # verbosity
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

**Discussion**: bzip2 is a compression library.  For simple one shot
attempts at compression/decompression when you expect the original
and the result to fit within memory it provides two convenience functions
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

# SUPPORT

If something does not work the way you think it should, or if you have a 
feature request, please open an issue on this project's GitHub Issue 
tracker:

[https://github.com/plicease/FFI-Platypus/issues](https://github.com/plicease/FFI-Platypus/issues)

# CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a 
pull request on this project's GitHub repository:

[https://github.com/plicease/FFI-Platypus/pulls](https://github.com/plicease/FFI-Platypus/pulls)

This project is developed using [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).  The project's git 
repository also comes with `Build.PL` and `cpanfile` files necessary 
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

    % perl Build.PL
    % ./Build
    % ./Build libtest
    % prove -bv t
    # or an individual test
    % perl -Mblib t/ffi_platypus_memory.t

The build process also respects these environment variables:

- FFI\_PLATYPUS\_DEBUG

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

- FFI\_PLATYPUS\_DEBUG\_FAKE32

    When building Platypus on 32 bit Perls, it will use the [Math::Int64](https://metacpan.org/pod/Math::Int64) C 
    API and make [Math::Int64](https://metacpan.org/pod/Math::Int64) a prerequisite.  Setting this environment 
    variable will force Platypus to build with both of those options on a 64 
    bit Perl as well.

        % env FFI_PLATYPUS_DEBUG_FAKE32=1 perl Build.PL
        
        
        DEBUG_FAKE32:
          + making Math::Int64 a prerequsite (not normally done on 64 bit Perls)
          + using Math::Int64's C API to manipulate 64 bit values (not normally done on 64 bit Perls)
        
        Created MYMETA.yml and MYMETA.json
        Creating new 'Build' script for 'FFI-Platypus' version '0.10'

- FFI\_PLATYPUS\_NO\_ALLOCA

    Platypus uses the non-standard and somewhat controversial C function 
    `alloca` by default on platforms that support it.  I believe that 
    Platypus uses it responsibly to allocate small amounts of memory for 
    argument type parameters, and does not use it to allocate large 
    structures like arrays or buffers.  If you prefer not to use `alloca` 
    despite these precautions, then you can turn its use off by setting this 
    environment variable when you run `Build.PL`:

        % env FFI_PLATYPUS_NO_ALLOCA=1 perl Build.PL 
        
        
        NO_ALLOCA:
          + alloca() will not be used, even if your platform supports it.
        
        
         Created MYMETA.yml and MYMETA.json
         Creating new 'Build' script for 'FFI-Platypus' version '0.10'

# SEE ALSO

- [FFI::Platypus::Declare](https://metacpan.org/pod/FFI::Platypus::Declare)

    Declarative interface to Platypus.

- [FFI::Platypus::Type](https://metacpan.org/pod/FFI::Platypus::Type)

    Type definitions for Platypus.

- [FFI::Platypus::API](https://metacpan.org/pod/FFI::Platypus::API)

    The custom types API for Platypus.

- [FFI::Platypus::Memory](https://metacpan.org/pod/FFI::Platypus::Memory)

    Memory functions for FFI.

- [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib)

    Find dynamic libraries in a portable way.

- [Module::Build::FFI](https://metacpan.org/pod/Module::Build::FFI)

    Bundle C code with your FFI extension.

- [FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC)

    JIT compiler for FFI.

- [FFI::Platypus::Lang::C](https://metacpan.org/pod/FFI::Platypus::Lang::C)

    Documentation and tools for using Platypus with the C programming 
    language

- [FFI::Platypus::Lang::CPP](https://metacpan.org/pod/FFI::Platypus::Lang::CPP)

    Documentation and tools for using Platypus with the C++ programming 
    language

- [FFI::Platypus::Lang::Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust)

    Documentation and tools for using Platypus with the Rust programming 
    language

- [FFI::Platypus::Lang::ASM](https://metacpan.org/pod/FFI::Platypus::Lang::ASM)

    Documentation and tools for using Platypus with the Assembly

- [Convert::Binary::C](https://metacpan.org/pod/Convert::Binary::C)

    An interface for interacting with C `struct` types.  Unfortunately it 
    appears to be unmaintained, and has a failing pod test, so I cannot 
    recommend it for use by CPAN modules.

- [pack and unpack](https://metacpan.org/pod/perlpacktut)

    Native to Perl functions that can be used to decode C `struct` types.

- [FFI::Raw](https://metacpan.org/pod/FFI::Raw)

    Alternate interface to libffi with fewer features.  It notably lacks the 
    ability to create real xsubs, which may make [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) much 
    faster.  Also lacking are pointers to native types, arrays and custom 
    types.  In its favor, it has been around for longer that Platypus, and 
    has been battle tested to some success.

- [Win32::API](https://metacpan.org/pod/Win32::API)

    Microsoft Windows specific FFI style interface.

- [Ctypes](https://gitorious.org/perl-ctypes)

    Ctypes was intended as a FFI style interface for Perl, but was never 
    part of CPAN, and at least the last time I tried it did not work with 
    recent versions of Perl.

- [FFI](https://metacpan.org/pod/FFI)

    Foreign function interface based on (nomenclature is everything) FSF's 
    `ffcall`. It hasn't worked for quite some time, and `ffcall` is no 
    longer supported or distributed.

- [C::DynaLib](https://metacpan.org/pod/C::DynaLib)

    Another FFI for Perl that doesn't appear to have worked for a long time.

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
