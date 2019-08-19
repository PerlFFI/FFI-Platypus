use strict;
use warnings;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

my $ffi = FFI::Platypus->new();
$ffi->lib( $libtest );
$ffi->type('()->void' => 'callback_t'); 
$ffi->attach( gh174_func1 => [ 'callback_t' ] => 'void' );
my $callback = $ffi->closure(
    sub { print "Perl callback()\n" }
);
gh174_func1( $callback );
