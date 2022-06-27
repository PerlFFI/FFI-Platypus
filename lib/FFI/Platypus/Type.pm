package FFI::Platypus::Type;

use strict;
use warnings;
use 5.008004;
use Carp qw( croak );
require FFI::Platypus;

# ABSTRACT: Defining types for FFI::Platypus
# VERSION

# The TypeParser and Type classes are used internally ONLY and
# are not to be exposed to the user.  External users should
# not under any circumstances rely on the implementation of
# these classes.

sub alignof
{
  my($self) = @_;
  my $meta = $self->meta;

  # TODO: it is possible, though complicated
  #       to compute the alignment of a struct
  #       type record.
  croak "cannot determine alignment of record"
    if $meta->{type} eq 'record'
    && $meta->{ref} == 1;

  my $ffi_type;
  if($meta->{type} eq 'pointer')
  {
    $ffi_type = 'pointer';
  }
  elsif($meta->{type} eq 'record')
  {
    $ffi_type = 'uint8';
  }
  else
  {
    $ffi_type = $meta->{ffi_type};
  }

  require FFI::Platypus::ShareConfig;
  FFI::Platypus::ShareConfig->get('align')->{$ffi_type};
}

1;

=begin stopwords

tm

=end stopwords

=head1 SYNOPSIS

OO Interface:

 use FFI::Platypus 2.00;
 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->type('int' => 'my_int');

=head1 DESCRIPTION

B<Note>: This document assumes that you are using C<api =E<gt> 1>,
which you should be using for all new code.

This document describes how to define types using L<FFI::Platypus>.
Types may be "defined" ahead of time, or simply used when defining or
attaching functions.

 # Example of defining types
 use FFI::Platypus 2.00;
 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->type('int');
 $ffi->type('string');
 
 # Example of simply using types in function declaration or attachment
 my $f = $ffi->function(puts => ['string'] => 'int');
 $ffi->attach(puts => ['string'] => 'int');

Unless you are using aliases the L<FFI::Platypus#type> method is not
necessary, but they will throw an exception if the type is incorrectly
specified or not supported, which may be helpful for determining if
the types are available or not.

Note: This document sometimes uses the term "C Function" as short hand
for function implemented in a compiled language.  Unless the term is
referring literally to a C function example code, you can assume that
it should also work with another compiled language.

=head2 meta information about types

You can get the size of a type using the L<FFI::Platypus#sizeof> method.

 my $intsize = $ffi->sizeof('int');           # usually 4
 my $intarraysize = $ffi->sizeof('int[64]');  # usually 256

=head2 converting types

Sometimes it is necessary to convert types.  In particular various
pointer types often need to be converted for consumption in Perl.  For
this purpose the L<FFI::Platypus#cast> method is provided.  It needs to
be used with care though, because not all type combinations are
supported.  Here are some useful ones:

 my $address = $ffi->cast('string' => 'opaque', $string);

This converts a Perl string to a pointer address that can be used
by functions that take an C<opaque> type.  Be carefully though that
the Perl string is not resized or free'd while in use from C code.

 my $string  = $ffi->cast('opaque' => 'string', $pointer);

This does the opposite, converting a null terminated string (the
type of strings used by C) into a Perl string.  In this case the
string is copied, so the other language is free to deallocate or
otherwise manipulate the string after the conversion without adversely
affecting the Perl.

=head2 aliases

Some times using alternate names is useful for documenting the purpose
of an argument or return type.  For this "aliases" can be helpful.  The
second argument to the L<FFI::Platypus#type> method can be used to
define a type alias that can later be used by function declaration
and attachment.

 use FFI::Platypus 2.00;
 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->type('int'    => 'myint');
 $ffi->type('string' => 'mystring');
 my $f = $ffi->function( puts => ['mystring'] => 'myint' );
 $ffi->attach( puts => ['mystring'] => 'myint' );

Aliases are contained without the L<FFI::Platypus> object, so feel free
to define your own crazy types without stepping on the toes of other
CPAN developers using Platypus.

One useful application of an alias is when you know types are different
on two different platforms:

 if($^O eq 'MSWin32')
 {
   $type->type('sint16' => 'foo_t');
 } elsif($^O eq 'linux')
 {
   $type->type('sint32' => 'foo_t');
 }
 
 # function foo takes 16 bit signed integer on Windows
 # and a 32 bit signed integer on Linux.
 $ffi->attach( foo => [ 'foo_t' ] => 'void' );

=head1 TYPE CATEGORIES

=head2 Native types

So called native types are the types that the CPU understands that can
be passed on the argument stack or returned by a function.  It does not
include more complicated types like arrays or structs, which can be
passed via pointers (see the opaque type below).  Generally native types
include void, integers, floats and pointers.

=head3 the void type

This can be used as a return value to indicate a function does not
return a value (or if you want the return value to be ignored).

 $ffi->type( foo => [] => 'void' );

Newer versions of Platypus also allow you to omit the return type and
C<void> is assumed.

 $ffi->type( foo => [] );

It doesn't really make sense to use C<void> in any other context.  However,
because of historical reasons involving older versions of Perl.

It doesn't really make sense for C<void> to be passed in as an argument.
However, because C functions that take no arguments frequently are specified
as taking C<void> as this was required by older C compilers, as a special
case you can specify a function's arguments as taking a single C<void> to
mean it takes no arguments.

 # C: void foo(void);
 $ffi->type( foo => ['void'] );
 # same (but probably better)
 $ffi->type( foo => [] );

=head3 integer types

The following native integer types are always available (parentheticals
indicates the usual corresponding C type):

=over 4

=item sint8

Signed 8 bit byte (C<signed char>, C<int8_t>).

=item uint8

Unsigned 8 bit byte (C<unsigned char>, C<uint8_t>).

=item sint16

Signed 16 bit integer (C<short>, C<int16_t>)

=item uint16

Unsigned 16 bit integer (C<unsigned short>, C<uint16_t>)

=item sint32

Signed 32 bit integer (C<int>, C<int32_t>)

=item uint32

Unsigned 32 bit integer (C<unsigned int>, C<uint32_t>)

=item sint64

Signed 64 bit integer (C<long long>, C<int64_t>)

=item uint64

Unsigned 64 bit integer (C<unsigned long long>,
C<uint64_t>)

=back

You may also use C<uchar>, C<ushort>, C<uint> and C<ulong> as short
names for C<unsigned char>, C<unsigned short>, C<unsigned int> and
C<unsigned long>.

These integer types are also available, but there actual size and sign
may depend on the platform.

=over 4

=item char

Somewhat confusingly, C<char> is an integer type!  This is really an
alias for either C<sint8_t> or C<uint8_t> depending on your platform.
If you want to pass a character (not integer) in to a C function that
takes a character you want to use the perl L<ord|perlfunc#ord> function.
Here is an example that uses the standard libc C<isalpha>, C<isdigit>
type functions:

# EXAMPLE: examples/char.pl

=item size_t

This is usually an C<unsigned long>, but it is up to the compiler to
decide.  The C<malloc> function is defined in terms of C<size_t>:

 $ffi->attach( malloc => ['size_t'] => 'opaque';

(Note that you can get C<malloc> from L<FFI::Platypus::Memory>).

=item long, unsigned long

On 64 bit systems, this is usually a 64 bit integer.  On 32 bit systems
this is frequently a 32 bit integer (and C<long long> or
C<unsigned long long> are for 64 bit).

=back

There are a number of other types that may or may not be available if
they are detected when L<FFI::Platypus> is installed.  This includes
things like C<wchar_t>, C<off_t>, C<wint_t>. You can use this script to
list all the integer types that L<FFI::Platypus> knows about, plus how
they are implemented.

# EXAMPLE: examples/list_integer_types.pl

If you need a common system type that is not provided, please open a
ticket in the Platypus project's GitHub issue tracker.  Be sure to
include the usual header file the type can be found in.

=head3 Enum types

C provides enumerated types, which are typically implemented as integer
types.

 enum {
   BAR = 1,
   BAZ = 2
 } foo_t;
 
 void f(enum foo_t foo);

Platypus provides C<enum> and C<senum> types for the integer types used
to represent enum and signed enum types respectively.

 use constant BAR => 1;
 use constant BAZ => 2;
 $ffi->attach( f => [ 'enum' ] => 'void' );
 f(BAR);
 f(BAZ);

When do you use C<senum>?  Anytime the enum has negative values:

 enum {
   BAR = -1;
   BAZ = 2;
 } foo_t;
 
 void f(enum foo_t foo);

Perl:

 use constant BAR => -1;
 use constant BAZ => 2;
 $ffi->attach( f => [ 'senum' ] => 'void' );
 f(BAR);
 f(BAZ);

Dealing with enumerated values with FFI can be tricky because these are
usually defined in C header files and cannot be found in dynamic libraries.
For trivial usage you can do as illustrated above, simply define your own
Perl constants.  For more complicated usage, or where the values might vary
from platform to platform you may want to consider the new Platypus bundle
interface to define Perl constants (essentially the same as an enumerated
value) from C space.  This is more reliable, but does require a compiler
at install time.  See L<FFI::Platypus::Constant> for details.

The main FAQ (L<FFI::Platypus/FAQ>) also has a discussion on dealing
with constants and enumerated types.

There is also a type plugin (L<FFI::Platypus::Type::Enum>) that can be helpful
in writing interfaces that use enums.

=head3 Boolean types

At install time Platypus attempts to detect the correct type for C<bool>
for your platform, and you can use that.  C<bool> is really an integer
type, but the type used varies from platform to platform.

C header:

 #include <stdbool.h>
 bool foo();

Platypus

 $ffi->attach( foo => [] => 'bool' );

If you get an exception when trying to use this type it means you either
have a very old version of Platypus, or for some reason it was unable to
detect the correct type at install time.  Please open a ticket if that is
the case.

=head3 floating point types

The following native floating point types are always available
(parentheticals indicates the usual corresponding C type):

=over 4

=item float

Single precision floating point (I<float>)

=item double

Double precision floating point (I<double>)

=item longdouble

Floating point that may be larger than C<double> (I<longdouble>).  This
type is only available if supported by the C compiler used to build
L<FFI::Platypus>.  There may be a performance penalty for using this
type, even if your Perl uses long doubles internally for its number
value (NV) type, because of the way L<FFI::Platypus> interacts with
C<libffi>.

As an argument type either regular number values (NV) or instances of
L<Math::LongDouble> are accepted.  When used as a return type,
L<Math::LongDouble> will be used, if you have that module installed.
Otherwise the return type will be downgraded to whatever your Perl's
number value (NV) is.

=item complex_float

Complex single precision floating point (I<float complex>)

=item complex_double

Complex double precision floating point (I<double complex>)

C<complex_float> and C<complex_double> are only available if supported
by your C compiler and by libffi.  Complex numbers are only supported in
very recent versions of libffi, and as of this writing the latest
production version doesn't work on x86_64.  It does seem to work with
the latest production version of libffi on 32 bit Intel (x86), and with
the latest libffi version in git on x86_64.

=back

=head3 opaque pointers

Opaque pointers are simply a pointer to a region of memory that you do
not manage, and do not know or care about its structure. It is like
a C<void *> in C.  These types are represented in Perl space as integers
and get converted to and from pointers by L<FFI::Platypus>.  You may use
C<pointer> as an alias for C<opaque>, although this is discouraged.
(The Platypus documentation uses the convention of using "pointer"
to refer to pointers to known types (see below) and "opaque" as short
hand for opaque pointer).

As an example, libarchive defines C<struct archive> type in its header
files, but does not define its content.  Internally it is defined as a
C<struct> type, but the caller does not see this.  It is therefore
opaque to its caller.  There are C<archive_read_new> and
C<archive_write_new> functions to create a new instance of this opaque
object and C<archive_read_free> and C<archive_write_free> to destroy
this objects when you are done.

C header:

 struct archive;
 struct archive *archive_read_new(void);
 struct archive *archive_write_new(void);
 int archive_free(struct archive *);
 int archive_write_free(struct archive *);

Perl code:

 $lib->find_lib( lib => 'archive' );
 $ffi->attach(archive_read_new   => []         => 'opaque');
 $ffi->attach(archive_write_new  => []         => 'opaque');
 $ffi->attach(archive_read_free  => ['opaque'] => 'int');
 $ffi->attach(archive_write_free => ['opaque'] => 'int');

It is often useful to alias an C<opaque> type like this so that you know
what the object represents:

 $lib->find_lib( lib => 'archive' );
 $ffi->type('opaque' => 'archive');
 $ffi->attach(archive_read_new   => [] => 'archive');
 $ffi->attach(archive_read_free  => ['archive'] => 'int');
 ...

As a special case, when you pass C<undef> into a function that takes an
opaque type it will be translated into C<NULL> for C.  When a C function
returns a NULL pointer, it will be translated back to C<undef>.

For functions that take a pointer to a void pointer (that is a C<void **>),
you can use a pointer to an opaque type.  Consider the C code:

 struct archive_entry;
 int archive_read_next_header(struct archive *, struvct archive_entry **);

Once again the internals of C<archive_entry> are not provided.  Perl code:

 $ffi->type('opaque' => 'archive_entry');
 $ffi->attach(archive_read_next_header => [ 'archive', 'archive_entry*' ] => 'int');

Now we can call this function

 my $archive = archive_read_new();
 ...  # additional prep for $active is required
 while(1) {
   my $entry;
   archive_read_next_header($archive, \$entry);
   last unless defined $entry;
   # can now use $entry for other archive_entry_ methods.
 }

The way C<archive_read_next_header> works, it will return a pointer to the next
C<archive_entry> object until it gets to the end, when it will return a pointer
to C<NULL> which will be represented in Perl by a C<undef>.

There are a number of useful utility functions for dealing with opaque
types in the L<FFI::Platypus::Memory> module.

=head2 Objects

Object types are thin wrappers around two native types: integer and
C<opaque> types.  They are just blessed references around either of
those two types so that methods can be defined on them, but when they
get passed to a Platypus xsub they are converted into the native
integer or C<opaque> types.  This type is most useful when a API
provides an OO style interface with an integer or C<opaque> value
acting as an instance of a class.  There are two detailed examples
in the main Platypus documentation using libarchive and unix open:

=over 4

=item L<FFI::Platypus/libarchive>

=item L<FFI::Platypus/"unix open">

=back

=head2 Strings

 # used when you need a char * or const char *
 $ffi->attach( puts => [ 'string' ] => 'int' );

The C<string> type is a series of bytes that usually represent a
series of characters.  They will be NULL terminated for C and passed
in as a pointer.  This will typically work for APIs that take ASCII
or UTF-8 strings which are common in Unix environments.

(Note if you need to handle the native "wide" string for example
if you need to talk UTF-16 on Windows see L<FFI::Platypus::Type::WideString>).

(Note if you need to pass in a fixed length string by value (not as
a pointer) then you can do so using L<FFI::Platypus::Record>).

(Note that languages like L<Go|FFI::Platypus::Lang::Go> and L<Rust|FFI::Platypus::Lang::Rust> do not use NULL terminated strings
and need their own string types; see the appropriate language plugins for details)

 # can also be used when you need a void * or const void *
 $ffi->attach( write => ['int', 'string', 'size_t' ] => 'ssizet' );

The C<string> type can also be used to pass in the start of a buffer
of arbitrary bytes stored in a Perl scalar.  Because a C<string> is
passed just as a pointer you will typically need to also pass the
length of the buffer as a separate argument.  This is necessary because
buffers could potentially have a NULL in them.

The pointer passed into C (or other language) is to the content of the
actual scalar, which means it can modify the content of a scalar.

B<NOTE>: When used as a return type, the string is I<copied> into a
new scalar rather than using the original address.  This is due to
the ownership model of scalars in Perl, but it is also most of the
time what you want.

This can be problematic when a function returns a string that the callee
is expected to free.  Consider the functions:

 char *
 get_string()
 {
   char *buffer;
   buffer = malloc(20);
   strcpy(buffer, "Perl");
 }
 
 void
 free_string(char *buffer)
 {
   free(buffer);
 }

This API returns a string that you are expected to free when you are
done with it.  (At least they have provided an API for freeing the
string instead of expecting you to call libc free)!  A simple binding
to get the string would be:

 $ffi->attach( get_string => [] => 'string' );  # memory leak
 my $str = get_string();

Which will work to a point, but the memory allocated by get_string
will leak.  Instead you need to get the opaque pointer, cast it to
a string and then free it.

 $ffi->attach( get_string => [] => 'opaque' );
 $ffi->attach( free_string => ['opaque'] => 'void' );
 my $ptr = get_string();
 my $str = $ffi->cast( 'opaque' => 'string', $ptr );  # copies the string
 free_string($ptr);

If you are doing this sort of thing a lot, it can be worth adding a
custom type:

 $ffi->attach( free_string => ['opaque'] => 'void' );
 $ffi->custom_type( 'my_string' => {
   native_type => 'opaque',
   native_to_perl => sub {
     my($ptr) = @_;
     my $str = $ffi->cast( 'opaque' => 'string', $ptr ); # copies the string
     free_string($ptr);
     $str;
   }
 });
 
 $ffi->attach( get_string => [] => 'my_string' );
 my $str = get_string();

Since version 0.62, pointers and arrays to strings are supported as a
first class type.  Prior to that L<FFI::Platypus::Type::StringArray>
and L<FFI::Platypus::Type::StringPointer> could be used, though their
use in new code is discouraged.

 $ffi->attach( foo => ['string[]'] => 'void' );
 foo( [ 'array', 'of', 'strings' ] );
 
 $ffi->attach( bar => ['string*'] => 'void' );
 my $string = 'baz';
 bar( \$string );  # $string may be modified.

Strings are not allowed as return types from closure.  This, again
is due to the ownership model of scalars in Perl.  (There is no way
for Perl to know when calling language is done with the memory allocated
to the string).  Consider the API:

 typedef const char *(*get_message_t)(void);
 
 void
 print_message(get_message_t get_message)
 {
   const char *str;
   str = get_message();
   printf("message = %s\n", str);
 }

It feels like this should be able to work:

 $ffi->type('()->string' => 'get_message_t'); # not ok
 $ffi->attach( print_message => ['get_message_t'] => 'void' );
 my $get_message = $ffi->closure(sub {
   return "my message";
 });
 print_message($get_message);

If the type declaration for C<get_message_t> were legal, then this
script would likely segfault or in the very least corrupt memory.
The problem is that once C<"my message"> is returned from the closure
Perl doesn't have a reference to it anymore and will free it.
To do this safely, you have to keep a reference to the scalar around
and return an opaque pointer to the string using a cast.

 $ffi->type('()->opaque' => 'get_message_t');
 $ffi->attach( print_message => ['get_message_t'] => 'void' );
 my $get_message => $ffi->closure(sub {
   our $message = "my message";  # needs to be our so that it doesn't
                                 # get free'd
   my $ptr = $ffi->cast('string' => 'opaque', $message);
   return $ptr;
 });
 print_message($get_message);

Another type of string that you may run into with some APIs is the
so called "wide" string.  In your C code if you see C<wchar_t*>
or C<const wchar_t*> or if in Win32 API code you see C<LPWSTR>
or C<LPCWSTR>.  Most commonly you will see these types when working
with the Win32 API, but you may see them in Unix as well.  These
types are intended for dealing with Unicode, but they do not use
the same UTF-8 format used by Perl internally, so they need to be
converted.  You can do this manually by allocating the memory
and using the L<Encode> module, but the easier way is to use
either L<FFI::Platypus::Type::WideString> or
L<FFI::Platypus::Lang::Win32>, which handle the memory allocation
and conversion for you.

String types can be defined to have a fixed length using a trailing
parenthetical like so C<string(10)>.  For arguments this has little
practical effect since the strings are passed as pointers anyway,
but does impact return values.  If a function that returns a C<string(10)>
type returns a string that is not NULL terminated, only the first ten bytes
will be returned in the result.

Internally fixed length strings are implemented the same as
classless record types (that is to say C<string(10)> is identically
internally to C<record(10)*>).

For the 1.00 Platypus API, the C<string(10)> type was specified as
a pointer (that is C<string(10)*>).  This was a mistake, but you
can still use the latter as an alias for the correct form in the
2.00 API.

=head2 Pointers and Arrays of Strings

As of the 1.00 Platypus API, you can specify pointers to strings
(C<string*>) and arrays of strings (C<string[10]>).  Since strings
themselves are passed as pointers, this means these types are
passed in as pointers to pointers.  If the pointer to the string
is changed then when the function returns the scalar or array
will be updated as well.

=head2 Pointer / References

In C you can pass a pointer to a variable to a function in order
accomplish the task of pass by reference.  In Perl the same task is
accomplished by passing a reference (although you can also modify the
argument stack thus Perl supports proper pass by reference as well).

With L<FFI::Platypus> you can define a pointer to any native, string
or record type.  You cannot (at least not yet) define a pointer to
a pointer or a pointer to an array or any other type not otherwise
supported.  When passing in a pointer to something you must make sure
to pass in a reference to a scalar, or C<undef> (C<undef> will be
translated int C<NULL>).

If the C code makes a change to the value pointed to by the pointer, the
scalar will be updated before returning to Perl space.  Example, with C
code.

 /* foo.c */
 void increment_int(int *value)
 {
   if(value != NULL)
     (*value)++;
   else
     fprintf(stderr, "NULL pointer!\n");
 }
 
 # foo.pl
 use FFI::Platypus 2.00;
 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->lib('libfoo.so'); # change to reflect the dynamic lib
                         # that contains foo.c
 $ffi->type('int*' => 'int_p');
 $ffi->attach(increment_int => ['int_p'] => 'void');
 my $i = 0;
 increment_int(\$i);   # $i == 1
 increment_int(\$i);   # $i == 2
 increment_int(\$i);   # $i == 3
 increment_int(undef); # prints "NULL pointer!\n"

Older versions of Platypus did not support pointers to strings or records.

=head2 Records

Records are structured data of a fixed length.  In C they are called
C<struct>s.

For most C structured data, as long as you do not need to a record
by value, L<FFI::C> is the better choice.  Briefly, L<FFI::C> supports
C<struct>, C<union>, and arrays of C<struct> and C<unions>.  L<FFI::C>
does not support passing by value.  The reminder of this section will
discuss only the C<record> type.

To declare a record type, use C<record>:

 $ffi->type( 'record (42)' => 'my_record_of_size_42_bytes' );

The easiest way to mange records with Platypus is by using
L<FFI::Platypus::Record> to define a record layout for a record class.
Here is a brief example:

# EXAMPLE: examples/time_record.pl

For more detailed usage, see L<FFI::Platypus::Record>.

Platypus does not manage the structure of a record (that is up to you),
it just keeps track of their size and makes sure that they are copied
correctly when used as a return type.  A record in Perl is just a string
of bytes stored as a scalar.  In addition to defining a record layout
for a record class, there are a number of tools you can use manipulate
records in Perl, two notable examples are L<pack and unpack|perlpacktut>
and L<Convert::Binary::C>.

Here is an example with commentary that uses L<Convert::Binary::C> to
extract the component time values from the C C<localtime> function, and
then smushes them back together to get the original C<time_t> (an
integer).

# EXAMPLE: examples/time.pl

You can also link a record type to a class.  It will then be accepted
when blessed into that class as an argument passed into a C function,
and when it is returned from a C function it will be blessed into that
class.  Basically:

 $ffi->type( 'record(My::Class)*' => 'my_class' );
 $ffi->attach( my_function1 => [ 'my_class' ] => 'void' );
 $ffi->attach( my_function2 => [ ] => 'my_class' );

The only thing that your class MUST provide is either a
C<ffi_record_size> or C<_ffi_record_size> class method that returns the
size of the record in bytes.

Here is a longer practical example, once again using the tm struct:

# EXAMPLE: examples/time_oo.pl

Contrast a record type which is stored as a scalar string of bytes in
Perl to an opaque pointer which is stored as an integer in Perl.  Both
are treated as pointers in C functions.  The situations when you usually
want to use a record are when you know ahead of time what the size of
the object that you are working with and probably something about its
structure.  Because a function that returns a structure copies the
structure into a Perl data structure, you want to make sure that it is
okay to copy the record objects that you are dealing with if any of your
functions will be returning one of them.

Opaque pointers should be used when you do not know the size of the
object that you are using, or if the objects are created and free'd
through an API interface other than C<malloc> and C<free>.

The examples in this section actually use pointers to records (note
the trailing star C<*> in the declarations).  Most programming languages
allow you to pass or return a record as either pass-by-value or as a
pointer (pass-by-reference).

C code:

 struct { int a; } foo_t;
 void pass_by_value_example( struct foo_t foo );
 void pass_by_reference_example( struct foo_t *foo );

Perl code:

 {
   package Foo;
   use FFI::Platypus::Record;
   record_layout_1( int => 'a' );
 }
 $ffi->type( 'Record(Foo)' => 'foo_t' );
 $ffi->attach( pass_by_value_example => [ 'foo_t' ] => 'void' );
 $ffi->attach( pass_by_reference_example => [ 'foo_t*' ] => 'void' );

As with strings, functions that return a pointer to a record are actually
copied.

C code:

 struct foo_t *return_struct_pointer_example();

Perl code:

 $ffi->attach( return_struct_pointer_example => [] => 'foo_t*' );
 my $foo = return_struct_pointer_example();
 # $foo is a copy of the record returned by the function.

As with strings, if the API expects you to free the record it returns
(it is misbehaving a little, but lets set that aside), then you can
work around this by returning an C<opaque> type, casting to the
record, and finally freeing the original pointer.

 use FFI::Platypus::Memory qw( free );
 $ffi->attach( return_struct_pointer_example => [] => 'opaque' );
 my $foo_ptr = return_struct_pointer_example();
 my $foo = $ffi->cast( 'opaque' => 'foo_t*', $foo_ptr );
 free $foo_ptr;

You can pass records into a closure, but care needs to be taken.
Records passed into a closure are read-only inside the closure,
including C<string rw> members.  Although you can pass a "pointer"
to a record into a closure, because of limitations of the
implementation you actually have a copy, so all records passed
into closures are passed by-value.

Note that a record that does not have a class (classless) and is
defined instead using a length is internally identical to fixed
strings.  That is to say C<string(10)> and C<record(10)*> are
identical.

=head2 Fixed length arrays

Fixed length arrays of native types and strings are supported by
L<FFI::Platypus>.  Like pointers, if the values contained in the
array are updated by the C function these changes will be reflected
when it returns to Perl space.  An example of using this is the
Unix C<pipe> command which returns a list of two file descriptors
as an array.

# EXAMPLE: examples/pipe.pl

Because of the way records are implemented, an array of records
does not make sense and is not currently supported.

=head2 Variable length arrays

[version 0.22]

Variable length arrays are supported for argument types can also be
specified by using the C<[]> notation but by leaving the size empty:

 $ffi->type('int[]' => 'var_int_array');

When used as an argument type it will probe the array reference that you
pass in to determine the correct size.  Usually you will need to
communicate the size of the array to the C code.  One way to do this is
to pass the length of the array in as an additional argument.  For
example the C code:

# EXAMPLE: examples/var_array.c

Can be called from Perl like this:

# EXAMPLE: examples/var_array.pl

Another method might be to have a special value, such as 0 or NULL
indicate the termination of the array.

Because of the way records are implemented, an array of records
does not make sense and is not currently supported.

=head2 Closures

A closure (sometimes called a "callback", we use the C<libffi>
terminology) is a Perl subroutine that can be called from C.  In order
to be called from C it needs to be passed to a C function.  To define
the closure type you need to provide a list of argument types and a
return type.  Currently only native types (integers, floating point
values, opaque), strings and records (by-value; you can pass a pointer
to a record, but due to limitations of the record implementation this
is actually a copy) are supported as closure argument types, and only
native types and records (by-value; pointer records and records with
string pointers cannot be returned from a closure) are supported as
closure return types.  Inside the closure any records passed in are
read-only.

We plan to add other types, though they can be converted using the Platypus
C<cast> or C<attach_cast> methods.

Here is an example, with C code:

# EXAMPLE: examples/closure.c

And the Perl code:

# EXAMPLE: examples/closure.pl

If you have a pointer to a function in the form of an C<opaque> type,
you can pass this in place of a closure type:

# EXAMPLE: examples/closure-opaque.pl

The syntax for specifying a closure type is a list of comma separated
types in parentheticals followed by a narrow arrow C<-E<gt>>, followed
by the return type for the closure.  For example a closure that takes a
pointer, an integer and a string and returns an integer would look like
this:

 $ffi->type('(opaque, int, string) -> int' => 'my_closure_type');

Care needs to be taken with scoping and closures, because of the way
Perl and C handle responsibility for allocating memory differently.
Perl keeps reference counts and frees objects when nothing is
referencing them.  In C the code that allocates the memory is considered
responsible for explicitly free'ing the memory for objects it has
created when they are no longer needed.  When you pass a closure into a
C function, the C code has a pointer or reference to that object, but it
has no way up letting Perl know when it is no longer using it. As a
result, if you do not keep a reference to your closure around it will be
free'd by Perl and if the C code ever tries to call the closure it will
probably SIGSEGV.  Thus supposing you have a C function C<set_closure>
that takes a Perl closure, this is almost always wrong:

 set_closure($ffi->closure({ $_[0] * 2 }));  # BAD

In some cases, you may want to create a closure shouldn't ever be
free'd.  For example you are passing a closure into a C function that
will retain it for the lifetime of your application.  You can use the
sticky method to keep the closure, without the need to keep a reference
of the closure:

 {
   my $closure = $ffi->closure(sub { $_[0] * 2 });
   $closure->sticky;
   set_closure($closure); # OKAY
 }
 # closure still exists and is accesible from C, but
 # not from Perl land.

=head2 Custom Types

=head3 Custom Types in Perl

Platypus custom types are the rough analogue to typemaps in the XS
world.  They offer a method for converting Perl types into native types
that the C<libffi> can understand and pass on to the C code.

=head4 Example 1: Integer constants

Say you have a C header file like this:

 /* possible foo types: */
 #define FOO_STATIC  1
 #define FOO_DYNAMIC 2
 #define FOO_OTHER   3
 
 typedef int foo_t;
 
 void foo(foo_t foo);
 foo_t get_foo();

The challenge is here that once the source is processed by the C
pre-processor the name/value mappings for these C<FOO_> constants
are lost.  There is no way to fetch them from the library once it
is compiled and linked.

One common way of implementing this would be to create and export
constants in your Perl module, like this:

 package Foo;
 
 use FFI::Platypus 2.00;
 use Exporter qw( import );
 
 our @EXPORT_OK = qw( FOO_STATIC FOO_DYNAMIC FOO_OTHER foo get_foo );
 
 use constant FOO_STATIC  => 1;
 use constant FOO_DYNAMIC => 2;
 use constant FOO_OTHER   => 3;
 
 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->attach(foo     => ['int'] => 'void');
 $ffi->attach(get_foo => []      => 'int');

Then you could use the module thus:

 use Foo qw( foo FOO_STATIC );
 foo(FOO_STATIC);

If you didn't want to rely on integer constants or exports, you could
also define a custom type, and allow strings to be passed into your
function, like this:

 package Foo;
 
 use FFI::Platypus 2.00;
 
 our @EXPORT_OK = qw( foo get_foo );
 
 my %foo_types = (
   static  => 1,
   dynamic => 2,
   other   => 3,
 );
 my %foo_types_reverse = reverse %foo_types;
 
 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->custom_type(foo_t => {
   native_type    => 'int',
   native_to_perl => sub {
     $foo_types{$_[0]};
   },
   perl_to_native => sub {
     $foo_types_reverse{$_[0]};
   },
 });
 
 $ffi->attach(foo     => ['foo_t'] => 'void');
 $ffi->attach(get_foo => []        => 'foo_t');

Now when an argument of type C<foo_t> is called for it will be converted
from an appropriate string representation, and any function that returns
a C<foo_t> type will return a string instead of the integer
representation:

 use Foo;
 foo('static');

If the library that you are using has a lot of these constants you can
try using L<Convert::Binary::C> or another C header parser to obtain
the appropriate name/value pairings for the constants that you need.

=head4 Example 2: Blessed references

Supposing you have a C library that uses an opaque pointer with a pseudo
OO interface, like this:

 typedef struct foo_t;
 
 foo_t *foo_new();
 void foo_method(foo_t *, int argument);
 void foo_free(foo_t *);

One approach to adapting this to Perl would be to create a OO Perl
interface like this:

 package Foo;
 
 use FFI::Platypus 2.00;
 use FFI::Platypus::API qw( arguments_get_string );
 
 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->custom_type(foo_t => {
   native_type    => 'opaque',
   native_to_perl => sub {
     my $class = arguments_get_string(0);
     bless \$_[0], $class;
   }
   perl_to_native => sub { ${$_[0]} },
 });
 
 $ffi->attach([ foo_new => 'new' ] => [ 'string' ] => 'foo_t' );
 $ffi->attach([ foo_method => 'method' ] => [ 'foo_t', 'int' ] => 'void');
 $ffi->attach([ foo_free => 'DESTROY' ] => [ 'foo_t' ] => 'void');
 
 my $foo = Foo->new;

Here we are blessing a reference to the opaque pointer when we return
the custom type for C<foo_t>, and dereferencing that reference before we
pass it back in.  The function C<arguments_get_string> queries the C
arguments to get the class name to make sure the object is blessed into
the correct class (for more details on the custom type API see
L<FFI::Platypus::API>), so you can inherit and extend this class like a
normal Perl class.  This works because the C "constructor" ignores the
class name that we pass in as the first argument.  If you have a C
"constructor" like this that takes arguments you'd have to write a
wrapper for new.

A good example of a C library that uses this pattern, including
inheritance is C<libarchive>. Platypus comes with a more extensive
example in C<examples/archive.pl> that demonstrates this.

=head4 Example 3: Pointers with pack / unpack

TODO

See example L<FFI::Platypus::Type::StringPointer>.

=head4 Example 4: Custom Type modules and the Custom Type API

TODO

See example L<FFI::Platypus::Type::PointerSizeBuffer>.

=head4 Example 5: Custom Type on CPAN

You can distribute your own Platypus custom types on CPAN, if you think
they may be applicable to others.  The default namespace is prefix with
C<FFI::Platypus::Type::>, though you can stick it anywhere (under your
own namespace may make more sense if the custom type is specific to your
application).

A good example and pattern to follow is
L<FFI::Platypus::Type::StringArray>.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Main platypus documentation.

=item L<FFI::Platypus::API>

Custom types API.

=item L<FFI::Platypus::Type::StringPointer>

String pointer type.

=back

=cut
