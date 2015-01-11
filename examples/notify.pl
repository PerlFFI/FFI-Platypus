use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Declare qw( void string pointer );

# NOTE: I ported this from the like named eg/notify.pl that came with FFI::Raw
# and it seems to work most of the time, but also seems to SIGSEGV sometimes.
# I saw the same behavior in the FFI::Raw version, and am not really familiar
# with the libnotify API to say what is the cause.  Patches welcome to fix it.

lib find_lib_or_exit lib => 'notify';

function notify_init   => [string] => void;
function notify_uninit => []       => void;
function [notify_notification_new    => 'notify_new']    => [string,string,string]            => pointer;
function [notify_notification_update => 'notify_update'] => [pointer, string, string, string] => void;
function [notify_notification_show   => 'notify_show']   => [pointer, pointer]                => void;

notify_init('FFI::Platypus');
my $n = notify_new('','','');
notify_update($n, 'FFI::Platypus', 'It works!!!', 'media-playback-start');
notify_show($n, undef);
notify_uninit();
