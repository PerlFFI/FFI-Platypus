use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Declare qw( void string pointer );

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
