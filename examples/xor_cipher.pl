use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::Platypus::Buffer qw( buffer_to_scalar );
use YAML ();

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './xor_cipher.so',
);

$ffi->attach( string_crypt_free => ['opaque'] );

$ffi->attach( string_crypt => ['string','int','string'] => 'opaque' => sub{
  my($xsub, $input, $key) = @_;
  my $ptr = $xsub->($input, length($input), $key);
  my $output = buffer_to_scalar $ptr, length($input);
  string_crypt_free($ptr);
  return $output;
});

my $orig = "hello world";
my $key  = "foobar";

print YAML::Dump($orig);
my $encrypted = string_crypt($orig, $key);
print YAML::Dump($encrypted);
my $decrypted = string_crypt($encrypted, $key);
print YAML::Dump($decrypted);
