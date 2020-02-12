use strict;
use warnings;
use utf8;
use B;

# see https://github.com/Perl5-FFI/FFI-Platypus/issues/85
use if $^O ne 'MSWin32' || $] >= 5.018, 'open', ':std', ':encoding(utf8)';
use Test::More;
use Encode qw( decode );
use FFI::Platypus::Buffer;
use FFI::Platypus::Buffer qw( scalar_to_pointer grow );

subtest simple => sub {
  my $orig = 'me grimlock king';
  my($ptr, $size) = scalar_to_buffer($orig);
  ok $ptr, "ptr = $ptr";
  my $ptr2 = scalar_to_pointer($orig);
  is $ptr2, $ptr, "scalar to pointer matches";
  is $size, 16, 'size = 16';
  my $scalar = buffer_to_scalar($ptr, $size);
  is $scalar, 'me grimlock king', "scalar = $scalar";
};

subtest unicode => sub {
  my $orig = 'привет';
  my($ptr, $size) = scalar_to_buffer($orig);
  ok $ptr, "ptr = $ptr";
  ok $size, "size = $size";
  my $scalar = decode('UTF-8', buffer_to_scalar($ptr, $size));
  is $scalar, 'привет', "scalar = $scalar";
};

subtest grow => sub {
  my $orig = 'me grimlock king';
  my($ptr, $size) = scalar_to_buffer($orig);
  my $sv = B::svref_2object( \$orig );
  is $sv->CUR, $size, "consistent string lengths";

  my $required = 100;
  ok $sv->LEN < $required, "initial buffer size is smaler than required";

  # in my tests, you never get exactly what you ask for
  grow( $orig, $required );
  ok $sv->LEN > $required, "buffer grew as expected";

};

done_testing;
