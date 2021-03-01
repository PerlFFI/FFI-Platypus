package FFI::Platypus::Type::WideString;

use strict;
use warnings;
use 5.008004;
use FFI::Platypus;
use FFI::Platypus::Memory qw( memcpy );
use FFI::Platypus::Buffer qw( buffer_to_scalar scalar_to_pointer scalar_to_buffer );
use Encode qw( decode encode find_encoding );
use Carp ();

# ABSTRACT: Platypus custom type for Unicode "wide" strings
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus 1.00;
 
 my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
 $ffi->load_custom_type('::WideString' => 'wstring', access => 'read' );
 $ffi->load_custom_type('::WideString' => 'wstring_w', access => 'write' );
 
 # call function that takes a constant wide string
 $ffi->attach( wcscmp => ['wstring', 'wstring'] => 'int' );
 my $diff = wcscmp("I ❤ perl + Platypus", "I ❤ perl + Platypus"); # returns 0
 
 # call a function that takes a wide string for writing
 $ffi->attach( wcscpy => ['wstring_w', 'wstring'] );
 my $buf;
 wcscpy(\$buf, "I ❤ perl + Platypus");
 print $buf, "\n";  # prints "I ❤ perl + Platypus"
 
 # call a function that takes a wide string for modification
 $ffi->attach( wcscat => ['wstring_w', 'wstring'] );
 my $buf;
 wcscat( [ \$buf, "I ❤ perl" ], " + Platypus");
 print $buf, "\n";  # prints "I ❤ perl + Platypus"

On Windows use with C<LPCWSTR>:

 use FFI::Platypus 1.00;
 
 my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
 
 # define some custom Win32 Types
 # to get these automatically see FFI::Platypus::Lang::Win32
 $ffi->load_custom_type('::WideString' => 'LPCWSTR', access => 'read' );
 $ffi->type('opaque' => 'HWND');
 $ffi->type('uint'   => 'UINT');
 
 use constant MB_OK                   => 0x00000000;
 use constant MB_DEFAULT_DESKTOP_ONLY => 0x00020000;
 
 $ffi->attach( [MessageBoxW => 'MessageBox'] => [ 'HWND', 'LPCWSTR', 'LPCWSTR', 'UINT'] => 'int' );
 
 MessageBox(undef, "I ❤️ Platypus", "Confession", MB_OK|MB_DEFAULT_DESKTOP_ONLY);

=head1 DESCRIPTION

This custom type plugin for L<FFI::Platypus> provides support for the native
"wide" string type on your platform, if it is available.

Wide strings are made of up wide characters (C<wchar_t>, also known as C<WCHAR>
on Windows) and have enough bits to represent character sets that require
larger than the traditional one byte C<char>.

These strings are most commonly used on Windows where they are referred to as
C<LPWSTR> and C<LPCWSTR> (The former for read/write buffers and the latter for
const read-only strings), where they are encoded as C<UTF-16LE>.

They are also supported by libc on many modern Unix systems where they are usually
C<UTF-32> of the native byte-order of the system.  APIs on Unix systems more
commonly use UTF-8 which provides some compatibility with ASCII, but you may
occasionally find APIs that talk in wide strings.  (libarchive, for example,
can work in both).

This plugin will detect the native wide string format for you and transparently
convert Perl strings, which are typically encoded internally as UTF-8.  If for
some reason it cannot detect the correct encoding, or if your platform is
currently supported, an exception will be thrown (please open a ticket if this
is the case).  It can be used either for read/write buffers, for const read-only
strings, and for return values.  It supports these options:

Options:

=over 4

=item access

Either C<read> or C<write> depending on if you are using a read/write buffer
or a const read-only string.

=item size

For read/write buffer, the size of the buffer to create, if not provided by
the caller.

=back

=head2 read-only

Read-only strings are the easiest of all, are converted to the native wide
string format in a buffer and are freed after that function call completes.

 $ffi->load_custom_type('::WideString' => 'wstring' );
 $ffi->function( wprintf => [ 'wstring' ] => [ 'wstring' ] => 'int' )
      ->call("I %s perl + Platypus", "❤");

This is the mode that you want to use when you are calling a function that
takes a C<const wchar_t*> or a C<LPCWSTR>.

=head2 return value

For return values the C<access> and C<size> options are ignored.  The string
is simply copied into a Perl native string.

 $ffi->load_custom_type('::WideString' => 'wstring' );
 # see note below in CAVEATS about wcsdup
 my $str = $ffi->function( wcsdup => [ 'wstring' ] => 'wstring' )
               ->call("I ❤ perl + Platypus");

This is the mode that you want to use when you are calling a function that
returns a C<const wchar_t*>, C<wchar_t>, C<LPWSTR> or C<LPCWSTR>.

=head2 read/write

Read/write strings can be passed in one of two ways.  Which you choose
depends on if you want to initialize the read/write buffer or not.

=over 4

=item default buffer size

The simplest way is to fallback on the default buffer size, which can
be specified using the C<size> option when creating the custom type.

 my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
 $ffi->load_custom_type('::WideString' => 'wstring',   access => 'read' );
 $ffi->load_custom_type('::WideString' => 'wstring_w', access => 'write', size => 512 );

 $ffi->attach( wcscpy => ['wstring_w', 'wstring'] );
 my $buf;
 wcscpy(\$buf, "I ❤ perl + Platypus");
 print $buf, "\n";  # prints "I ❤ perl + Platypus"

B<Discussion>: This is the most sensical approach when the exact size of the
buffer is known for all usages of the string type.  It can also be sensical
if the buffer size is larger than any possible output, though care should
be taken since this may be hard to determine reliably.

The default size if none is specified when creating the custom type is 2048,
which is probably large enough for many uses, but also probably wastes
memory for many of them.

=item allocate your buffer of a specific size

The safest and most memory efficient method is of course to allocate exactly
the amount of memory that you need.

 my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
 $ffi->load_custom_type('::WideString' => 'wstring',   access => 'read'  );
 $ffi->load_custom_type('::WideString' => 'wstring_w', access => 'write' );

 $ffi->attach( wcscpy => ['wstring_w', 'wstring'] );
 my $width = $ffi->sizeof('wchar_t');
 my $buf = "\0" x ( (length ("I ❤ perl + Platypus") + 1)*$width);
 wcscpy(\$buf, "I ❤ perl + Platypus");
 print $buf, "\n";  # prints "I ❤ perl + Platypus"

B<Discussion>: By assigning C<$buf> to a string of null characters the
length of the source string, plus one (for the null at the end) and then
multiplying that by the size of C<wchar_t>, you get the exact number of
bytes needed for the destination buffer.

Note that although we pass in a reference to a buffer, what comes back
is converted to a Perl string, which will be internally UTF-8, not stored
at the original buffer location.  This is slightly awkward, but what you
need most of the time.

=item initialize the read/write buffer

Some functions don't expect empty null padded buffers though, in this
case you will want to initialize the buffer.

 my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
 $ffi->load_custom_type('::WideString' => 'wstring',   access => 'read'  );
 $ffi->load_custom_type('::WideString' => 'wstring_w', access => 'write' );

 $ffi->attach( wcscat => ['wstring_w', 'wstring'] );
 my $buf;
 wcscat( [ \$buf, "I ❤ perl" ], " + Platypus");
 print $buf, "\n";  # prints "I ❤ perl + Platypus"

B<Discussion>: To initialize we pass in an array reference instead of a
scalar reference.  The first element is a scalar reference to the buffer
(which can be pre-allocated or not; if it is not allocated then it will
be allocated to the default size for the type).  The second argument is
what the buffer should be initialized to before the underlying C function
is called.  The Perl string is encoded into wide string format before
being used to initialize the buffer.

As before a reference to the translated string is returned, and the
buffer that was used to pass in is freed.

=item allocate memory using C<malloc> or C<wcsdup> etc.

You can also allocate memory using C<malloc> or C<wcsdup> to return
an opaque type and manipulate it using the libc C<wcs*> functions.
It will still probably be useful to use this plugin to cast the
opaque back to a Perl string.  The CAVEATS section below includes
several examples.

=back

This is the mode that you want to use when you are calling a function that
takes a <wchar_t*> or a C<LPWSTR>.

=head1 CAVEATS

As with the Platypus built in C<string> type, return values are copied into
a Perl scalar.  This is usually what you want anyway, but some APIs expect
the caller to take responsibility for freeing the pointer to the wide string
that it returns.  For example, C<wcsdup> works in this way.  The workaround
is to return an opaque pointer, cast it from a wide string and free the
pointer.

 use FFI::Platypus::Memory qw( free );
 $ffi->load_custom_type('::WideString' => 'wstring' );
 my $ptr = $ffi->function( wcsdup => [ 'wstring' ] => 'opaque' )
               ->call("I ❤ perl + Platypus");
 my $str = $ffi->cast('opaque', 'wstring', $ptr);
 free $ptr;

Because of the order in which objects are freed you cannot return a wide
string if it is also a wide string argument to a function.  For example
C<wcscpy> may crash if you specify the return value as a wide string:

 # wchar_t *wcscpy(wchar_t *dest, const wchar_t *src);
 $ffi->attach( wcscpy => [ 'wstring_w', 'wstring' ] => 'wstring' ); # no
 my $str;
 wcscpy( \$str, "I ❤ perl + Platypus");  # may crash on memory error

This is because the order in which things are done here are 1. C<$str> is allocated
2. C<$str> is re-encoded as utf and the old buffer is freed 3. the return value
is computed based on the C<$str> buffer that was freed.

If you look at C<wcscpy> though you don't actually need the return value.
To make this code work, you can just ignore the return value:

 $ffi->attach( wcscpy => [ 'wstring_w', 'wstring' ] => 'void' ); # yes
 my $str;
 wcscpy( \$str, "I ❤ perl + Platypus"); # good!

On the other hand you do care about the return value from C<wcschr>, which returns
a pointer to the first occurrence of a character in an argument string:

 # wchar_t *wcschr(const wchar_t *wcs, wchar_t wc);
 $ffi->attach( wcschr => [ 'wstring', 'wchar_t' ] => 'wstring' ); # no
 # this may crash on memory error or return the wrong value
 my $str = wcschr("I ❤ perl + Platypus", ord("❤"));

Instead you need to work with pointers and casts to use this function:

 use FFI::Platypus 1.00;
 use FFI::Platypus::Memory qw( free );
 
 my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
 
 $ffi->attach( wcsdup => ['wstring'] => 'opaque' );
 $ffi->attach( strchr => [ opaque', 'wchar_t' ] => 'wstring' );
 
 # create a wcs string in memory using wcsdup
 my $haystack = wcsdup("I ❤ perl + Platypus");
 # find the heart and return as a wide string
 my $needle = strchr($haystack, ord("❤"));
 # safe to free the pointer to the larger string now
 free $haystack;

=cut

my @stack;  # To keep buffer alive.

sub _compute_wide_string_encoding
{
  foreach my $need (qw( wcslen wcsnlen ))
  {
    die "This type plugin needs $need from libc, and cannot find it"
      unless FFI::Platypus::Memory->can("_$need");
  }

  my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );

  my $size = eval { $ffi->sizeof('wchar_t') };
  die 'no wchar_t' if $@;

  my %orders = (
    join('', 1..$size)         => 'BE',
    join('', reverse 1..$size) => 'LE',
  );

  my $byteorder = join '', @{ $ffi->cast( "wchar_t*", "uint8[$size]", \hex(join '', map { "0$_" } 1..$size) ) };

  my $encoding;

  if($size == 2)
  {
    $encoding = 'UTF-16';
  }
  elsif($size == 4)
  {
    $encoding = 'UTF-32';
  }
  else
  {
    die "not sure what encoding to use for size $size";
  }

  if(defined $orders{$byteorder})
  {
    $encoding .= $orders{$byteorder};
  }
  else
  {
    die "odd byteorder $byteorder not (yet) supported";
  }

  die "Perl doesn't recognize $encoding as an encoding"
    unless find_encoding($encoding);

  return ($encoding, $size);
}

sub ffi_custom_type_api_1
{
  my %args = @_;

  # TODO: it wold be nice to allow arbitrary encodings, but we are
  # relying on a couple of wcs* functions to compute the string, so
  # we will leave that for future development.
  my($encoding, $width) = __PACKAGE__->_compute_wide_string_encoding();

  # it is hard to come up with a default size for write buffers
  # but 2048 is a multiple of 1024 that is large enough to fit
  # any Windows PATH (260*4)+2 = 1042
  #
  # (assuming all characters in the PATH are in the BMP, which is
  #  admitedly unlikely, possilby impossible (?) and and a null
  #  termination of two bytes).
  #
  # it is arbitrary and based on a platform specific windows
  # thing, but windows is where wide strings are most likely
  # to be found, so seems good as anything.
  my $size   = $args{size} || 2048;
  my $access = $args{access} || 'read';

  my %ct = (
    native_type    => 'opaque',
  );

  $ct{native_to_perl} = sub {
    return undef unless defined $_[0];
    return decode($encoding,
      buffer_to_scalar(
        $_[0],
        FFI::Platypus::Memory::_wcslen($_[0])*$width,
      )
    );
  };

  if($access eq 'read')
  {
    $ct{perl_to_native} = sub {
      if(defined $_[0])
      {
        my $buf = encode($encoding, $_[0]."\0");
        push @stack, \$buf;
        return scalar_to_pointer $buf;
      }
      else
      {
        push @stack, undef;
        return undef;
      }
    };

    $ct{perl_to_native_post} = sub {
      pop @stack;
      return;
    };

  }
  elsif($access eq 'write')
  {
    my @stack;

    $ct{perl_to_native} = sub {
      my $ref = shift;
      if(ref($ref) eq 'ARRAY')
      {
        ${ $ref->[0] } = "\0" x $size unless defined ${ $ref->[0] };
        my $ptr = scalar_to_pointer ${ $ref->[0] };
        if(defined $ref->[0])
        {
          my $init = encode($encoding, $ref->[1]);
          my($sptr, $ssize) = scalar_to_buffer($init);
          memcpy($ptr, $sptr, $ssize);
        }
        push @stack, \${ $ref->[0] };
        return $ptr;
      }
      elsif(ref($ref) eq 'SCALAR')
      {
        push @stack, $ref;
        $$ref = "\0" x $size unless defined $$ref;
        return scalar_to_pointer $$ref;
      }
      else
      {
        push @stack, $ref;
        return undef;
      }
    };

    $ct{perl_to_native_post} = sub {
      my $ref = pop @stack;
      return unless defined $ref;
      my $len = length $$ref;
      $len = FFI::Platypus::Memory::_wcsnlen($$ref, $len);
      $$ref = decode($encoding, substr($$ref, 0, $len*$width));
    };

  }
  else
  {
    Carp::croak("Unknown access type $access");
  }

  return \%ct;
}

1;
