use strict;
use warnings;
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

