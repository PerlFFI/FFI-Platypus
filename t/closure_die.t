use strict;
use warnings;
use Test::More tests => 2;
use FFI::CheckLib;
use FFI::Platypus::Declare qw( void opaque );

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

my $closure = closure {
  die "omg i don't want to die!";
};

attach [pointer_set_closure => 'set_closure'] => ['(opaque)->opaque'] => void;
attach [pointer_call_closure => 'call_closure'] => [opaque] => opaque;


set_closure($closure);

my $warning;
do {
  local $SIG{__WARN__} = sub { $warning = $_[0] };
  call_closure(undef);
};

like $warning, qr{omg i don't want to die};
pass 'does not exit';
note "warning = '$warning'";
