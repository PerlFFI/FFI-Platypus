use strict;
use warnings;
use Test::More skip_all => 'needs fixing!';
use Test::More tests => 2;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub ffi_closure );

my $void = ffi_type c => 'void';
BEGIN { isa_ok $void, 'FFI::Platypus::Type' }
ffi_signature($void);
isa_ok $void, 'FFI::Platypus::Type';
