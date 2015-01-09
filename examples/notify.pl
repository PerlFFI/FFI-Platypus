# FIXME
use feature 'say';

use strict;
use warnings;

use FFI::Raw;

my $libnotify = 'libnotify.so.4';

my $notify_init = FFI::Raw -> new(
	$libnotify, 'notify_init',
	FFI::Raw::void, FFI::Raw::str
);

my $notify_uninit = FFI::Raw -> new(
	$libnotify, 'notify_uninit',
	FFI::Raw::void
);

my $notify_new = FFI::Raw -> new(
	$libnotify, 'notify_notification_new',
	FFI::Raw::ptr, FFI::Raw::str, FFI::Raw::str, FFI::Raw::str
);

my $notify_update = FFI::Raw -> new(
	$libnotify, 'notify_notification_update',
	FFI::Raw::void,
	FFI::Raw::ptr, FFI::Raw::str, FFI::Raw::str, FFI::Raw::str
);

my $notify_show = FFI::Raw -> new(
	$libnotify, 'notify_notification_show',
	FFI::Raw::void, FFI::Raw::ptr, FFI::Raw::ptr
);

$notify_init -> call('FFI::Raw');

my $n = $notify_new -> call('', '', '');

$notify_update -> call($n, 'FFI::Raw', 'It works!!!', 'media-playback-start');
$notify_show -> call($n, 0);

$notify_uninit -> call();
