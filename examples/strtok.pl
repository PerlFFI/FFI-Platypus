use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => undef,
);

$ffi->attach( strtok => ['string','string'] => 'string' );

my $orig = "foo:bar:baz";

my @tokens;
my $token = strtok($orig, ":");
while(defined $token) {
  push @tokens, $token;
  $token = strtok(undef, ":");
}

my $escaped = $orig;
$escaped =~ s/([^[:print:]])/"\\".ord($1)/eg;

print "token: $_\n" for @tokens;
print "orig:  $escaped\n";
