package FFI::Platypus::Lang::Win32;

use strict;
use warnings;
use 5.008004;
use Config;

# ABSTRACT: Documentation and tools for using Platypus with the Windows API
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 use FFI::Platypus::Memory;  # For malloc and free.


 use constant MB_OK => 0;

 my $ffi_user32 = FFI::Platypus->new( api => 1 );
 $ffi_user32->lang('Win32');
 $ffi_user32->find_lib( lib => 'user32' );

 $ffi_user32->attach([MessageBoxW => 'MessageBox'] => ['HWND', 'LPCWSTR', 'LPCWSTR', 'UINT'] => 'int');

 MessageBox(undef, "I ❤️ Platypus", "Confession", MB_OK);


 my $ffi_kernel32 = FFI::Platypus->new( api => 1 );
 $ffi_kernel32->lang('Win32');
 $ffi_kernel32->find_lib( lib => 'kernel32' );

 $ffi_kernel32->attach([GetCurrentDirectoryW => 'GetCurrentDirectory'] => ['DWORD', 'LPWSTR'] => 'DWORD');

 my $buf_size = GetCurrentDirectory(0, undef) or die($^E);
 my $buf = malloc($buf_size * 2);
 GetCurrentDirectory($buf_size, $buf) or die($^E);
 say $ffi_kernel32->cast('opaque' => 'LPCWSTR', $buf);
 free($buf);

=head1 DESCRIPTION

This module provides the Windows datatypes used by the Windows API.
This means that you can use things like C<DWORD> as an alias for
C<uint32>.

=head1 METHODS

=head2 abi

 my $abi = FFI::Platypus::Lang::Win32->abi;

This is automatically called when C<< $ffi->lang('Win32'); >> is used.
It causes the proper ABI to make Windows system calls to be used.

=cut

sub abi
{
  $^O =~ /^(cygwin|MSWin32|msys)$/ && $Config{ptrsize} == 4
  ? 'stdcall'
  : 'default_abi';
}

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Win32->native_type_map;

This is automatically called when C<< $ffi->lang('Win32'); >> is used.
It returns definitions for the following native aliases for the Windows API,
allowing them to be used in function declarations:
C<BOOL>, C<BOOLEAN>, C<BYTE>, C<CCHAR>, C<CHAR>, C<COLORREF>, C<DWORD>, C<DWORDLONG>,
C<DWORD_PTR>, C<DWORD32>, C<DWORD64>, C<FLOAT>, C<HACCEL>, C<HALF_PTR>, C<HANDLE>,
C<HBITMAP>, C<HBRUSH>, C<HCOLORSPACE>, C<HCONV>, C<HCONVLIST>, C<HCURSOR>, C<HDC>,
C<HDDEDATA>, C<HDESK>, C<HDROP>, C<HDWP>, C<HENHMETAFILE>, C<HFILE>, C<HFONT>,
C<HGDIOBJ>, C<HGLOBAL>, C<HHOOK>, C<HICON>, C<HINSTANCE>, C<HKEY>, C<HKL>, C<HLOCAL>,
C<HMENU>, C<HMETAFILE>, C<HMODULE>, C<HMONITOR>, C<HPALETTE>, C<HPEN>, C<HRESULT>,
C<HRGN>, C<HRSRC>, C<HSZ>, C<HWINSTA>, C<HWND>, C<INT>, C<INT_PTR>, C<INT8>, C<INT16>,
C<INT32>, C<INT64>, C<LANGID>, C<LCID>, C<LCTYPE>, C<LGRPID>, C<LONG>, C<LONGLONG>,
C<LONG_PTR>, C<LONG32>, C<LONG64>, C<LPCSTR>, C<LPCVOID>, C<LPVOID>, C<LPWSTR>,
C<LRESULT>, C<PSTR>, C<PVOID>, C<QWORD>, C<SC_HANDLE>, C<SC_LOCK>, C<SERVICE_STATUS_HANDLE>,
C<SHORT>, C<SIZE_T>, C<SSIZE_T>, C<UCHAR>, C<UHALF_PTR>, C<UINT>, C<UINT_PTR>, C<UINT8>,
C<UINT16>, C<UINT32>, C<UINT64>, C<ULONG>, C<ULONGLONG>, C<ULONG_PTR>, C<ULONG32>,
C<ULONG64>, C<USHORT>, C<USN>, C<VOID>, C<WORD> and C<WPARAM>.

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
      LPWSTR                    opaque
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

    # We don't deal with WCHAR. It's simply a uint16_t, but it's
    # semantically a Unicode Code Point. This is no biggie since one
    # should never encounter a WCHAR outside of a LPWSTR or LPCWSTR.

    # Not supported: POINTER_32 POINTER_64 POINTER_SIGNED POINTER_UNSIGNED
  }
  \%map;
}


=head2 load_custom_types

 FFI::Platypus::Lang::Win32->load_custom_types($ffi);

This is automatically called when C<< $ffi->lang('Win32'); >> is used.
It provdes the C<LPCWSTR> type for use in function declarations.
See L<FFI::Platypus::Type::Win32::LPCWSTR> for more information.

=cut

sub load_custom_types
{
  my($class, $ffi) = @_;
  $ffi->load_custom_type('::Win32::LPCWSTR' => 'LPCWSTR');
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=back

=cut
