package FFI::Platypus::Lang::Win32;

use strict;
use warnings;
use 5.008004;
use Config;

# ABSTRACT: Documentation and tools for using Platypus with the Windows API
# VERSION

=head1 SYNOPSIS

 use utf8;
 use FFI::Platypus 1.00;
 
 my $ffi = FFI::Platypus->new(
   api  => 1,
   lib  => [undef],
 );
 
 # load this plugin
 $ffi->lang('Win32');
 
 use constant MB_OK                   => 0x00000000;
 use constant MB_DEFAULT_DESKTOP_ONLY => 0x00020000;
 $ffi->attach( [MessageBoxW => 'MessageBox'] => [ 'HWND', 'LPCWSTR', 'LPCWSTR', 'UINT'] => 'int' );
 MessageBox(undef, "I ❤️ Platypus", "Confession", MB_OK|MB_DEFAULT_DESKTOP_ONLY);
 
 $ffi->attach( [GetCurrentDirectoryW => 'GetCurrentDirectory'] => ['DWORD', 'LPWSTR'] => 'DWORD');
 my $buf_size = GetCurrentDirectory(0,undef);
 my $dir = "\0" x ($buf_size*2);
 GetCurrentDirectory($buf_size, \$dir) or die $^E;
 print "$dir\n";

=head1 DESCRIPTION

This module provides the Windows datatypes used by the Windows API.
This means that you can use things like C<DWORD> as an alias for
C<uint32>.  The full list of type aliases is not documented here as
it may change over time or be dynamic.  You can get the list for your
current environment with this one-liner:

 perl -MFFI::Platypus::Lang::Win32 -E "say for sort keys %{ FFI::Platypus::Lang::Win32->native_type_map }"

You also get C<LPCWSTR> and C<LPWSTR> "wide" string types which are
implemented using L<FFI::Platypus::Type::WideString>.  For full details,
please see the documentation for that module, and note that C<LPCWSTR>
is a wide string in the read-only string mode and C<LPWSTR> is a wide
string in the read-write buffer mode.

=head1 METHODS

=head2 abi

 my $abi = FFI::Platypus::Lang::Win32->abi;

This is called internally when the type plugin is loaded by Platypus.
It selects the appropriate ABI to make Win32 API function calls.

=cut

sub abi
{
  $^O =~ /^(cygwin|MSWin32|msys)$/ && $Config{ptrsize} == 4
  ? 'stdcall'
  : 'default_abi';
}

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Win32->native_type_map;

This is called internally when the type plugin is loaded by Platypus.
It provides types aliases useful on the Windows platform, so it may
also be useful for introspection.

This returns a hash reference containing the native aliases for the
Windows API.  That is the keys are native Windows API C types and the
values are libffi native types.

This will includes types like C<DWORD> and C<HWND>, and others.  The
full list may be adjusted over time and may be computed dynamically.
To get the full list for your install you can use this one-liner:

 perl -MFFI::Platypus::Lang::Win32 -E "say for sort keys %{ FFI::Platypus::Lang::Win32->native_type_map }"

=cut

my %map;

sub native_type_map
{
  unless(%map)
  {
    require FFI::Platypus::ShareConfig;
    %map = %{ FFI::Platypus::ShareConfig->get('type_map') };

    my %win32_map = qw(
      BOOL                      int
      BOOLEAN                   BYTE
      BYTE                      uchar
      CCHAR                     char
      CHAR                      char
      COLORREF                  DWORD
      DWORD                     uint
      DWORDLONG                 uint64
      DWORD_PTR                 ULONG_PTR
      DWORD32                   uint32
      DWORD64                   uint64
      FLOAT                     float
      HACCEL                    HANDLE
      HANDLE                    PVOID
      HBITMAP                   HANDLE
      HBRUSH                    HANDLE
      HCOLORSPACE               HANDLE
      HCONV                     HANDLE
      HCONVLIST                 HANDLE
      HCURSOR                   HICON
      HDC                       HANDLE
      HDDEDATA                  HANDLE
      HDESK                     HANDLE
      HDROP                     HANDLE
      HDWP                      HANDLE
      HENHMETAFILE              HANDLE
      HFILE                     int
      HFONT                     HANDLE
      HGDIOBJ                   HANDLE
      HGLOBAL                   HANDLE
      HHOOK                     HANDLE
      HICON                     HANDLE
      HINSTANCE                 HANDLE
      HKEY                      HANDLE
      HKL                       HANDLE
      HLOCAL                    HANDLE
      HMENU                     HANDLE
      HMETAFILE                 HANDLE
      HMODULE                   HINSTANCE
      HMONITOR                  HANDLE
      HPALETTE                  HANDLE
      HPEN                      HANDLE
      HRESULT                   LONG
      HRGN                      HANDLE
      HRSRC                     HANDLE
      HSZ                       HANDLE
      HWINSTA                   HANDLE
      HWND                      HANDLE
      INT                       int
      INT8                      sint8
      INT16                     sint16
      INT32                     sint32
      INT64                     sint64
      LANGID                    WORD
      LCID                      DWORD
      LCTYPE                    DWORD
      LGRPID                    DWORD
      LONG                      sint32
      LONGLONG                  sint64
      LONG32                    sint32
      LONG64                    sint64
      LPCSTR                    string
      LPCVOID                   opaque
      LPVOID                    opaque
      LRESULT                   LONG_PTR
      PSTR                      string
      PVOID                     opaque
      QWORD                     uint64
      SC_HANDLE                 HANDLE
      SC_LOCK                   LPVOID
      SERVICE_STATUS_HANDLE     HANDLE
      SHORT                     sint16
      SIZE_T                    ULONG_PTR
      SSIZE_T                   LONG_PTR
      UCHAR                     uint8
      UINT                      uint
      UINT8                     uint8
      UINT16                    uint16
      UINT32                    uint32
      UINT64                    uint64
      ULONG                     uint32
      ULONGLONG                 uint64
      ULONG32                   uint32
      ULONG64                   uint64
      USHORT                    uint16
      USN                       LONGLONG
      VOID                      void
      WORD                      uint16
      WPARAM                    UINT_PTR

    );

    if($Config{ptrsize} == 4)
    {
      $win32_map{HALF_PTR}  = 'sint16';
      $win32_map{INT_PTR}   = 'sint32';
      $win32_map{LONG_PTR}  = 'sint16';
      $win32_map{UHALF_PTR} = 'uint16';
      $win32_map{UINT_PTR}  = 'uint32';
      $win32_map{ULONG_PTR} = 'uint16';
    }
    elsif($Config{ptrsize} == 8)
    {
      $win32_map{HALF_PTR}  = 'sint16';
      $win32_map{INT_PTR}   = 'sint32';
      $win32_map{LONG_PTR}  = 'sint16';
      $win32_map{UHALF_PTR} = 'uint16';
      $win32_map{UINT_PTR}  = 'uint32';
      $win32_map{ULONG_PTR} = 'uint16';
    }
    else
    {
      die "interesting word size you have";
    }

    foreach my $alias (keys %win32_map)
    {
      my $type = $alias;
      while(1)
      {
        if($type =~ /^(opaque|[us]int(8|16|32|64)|float|double|string|void)$/)
        {
          $map{$alias} = $type;
          last;
        }
        if(defined $map{$type})
        {
          $map{$alias} = $map{$type};
          last;
        }
        if(defined $win32_map{$type})
        {
          $type = $win32_map{$type};
          next;
        }
        die "unable to resolve $alias => ... => $type";
      }
    }

    # stuff we are not yet dealing with
    # LPCTSTR is unicode string, not currently supported
    # LPWSTR 16 bit unicode string
    # TBYTE TCHAR UNICODE_STRING WCHAR
    # Not supported: POINTER_32 POINTER_64 POINTER_SIGNED POINTER_UNSIGNED
  }
  \%map;
}

=head2 load_custom_types

 FFI::Platypus::Lang::Win32->load_custom_types($ffi);

This is called internally when the type plugin is loaded by Platypus.
It provides custom types useful on the Windows platform.  For now
that means the C<LPWSTR> and C<LPCWSTR> types.

=cut

sub load_custom_types
{
  my(undef, $ffi) = @_;
  $ffi->load_custom_type('::WideString' => 'LPCWSTR', access => 'read'  );
  $ffi->load_custom_type('::WideString' => 'LPWSTR',  access => 'write' );
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Platypus::Type::WideString>

The wide string type plugin use for C<LPWSTR> and C<LPCWSTR> types.

=item L<Win32::API>

Another FFI, but for Windows only.

=back

=cut
