use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => find_lib_or_die(lib => 'notify'),
);

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
