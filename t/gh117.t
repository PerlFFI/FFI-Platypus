use Test2::V0 -no_srand => 1;
use Cwd qw( abs_path );
use FFI::CheckLib qw( find_lib );
use FFI::Platypus;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => abs_path('t/ffi');
my $ffi = FFI::Platypus->new;
$ffi->lib($libtest);

my $value64 = $ffi->function('gh117' => [] => 'uint64')->call;
note "value64 = $value64";

is($value64, "1099511627775");

done_testing;
