use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');

my $closure = $ffi->closure(sub {
  die "omg i don't want to die!";
});

$ffi->attach([pointer_set_closure => 'set_closure'] => ['(opaque)->opaque'] => 'void');
$ffi->attach([pointer_call_closure => 'call_closure'] => ['opaque'] => 'opaque');

set_closure($closure);

my $warning;
do {
  local $SIG{__WARN__} = sub { $warning = $_[0] };
  call_closure(undef);
};

like $warning, qr{omg i don't want to die};
pass 'does not exit';
note "warning = '$warning'";

done_testing;
