use strict;
use warnings;
use Test::More tests => 14;
use FFI::Platypus;

# this tests the private OO type API used only internally
# to FFI::Platypus.  DO NOT USE FFI::Platypus::type
# its interface can and WILL change.

my @names = qw(
void
uint8
sint8
uint16
sint16
uint32
sint32
uint64
sint64
float 
double
longdouble
pointer
);

foreach my $name (@names)
{
  subtest $name => sub {
    plan tests => 3;
    my $type = eval { FFI::Platypus::type->new($name) };
    is $@, '', "type = FFI::Platypus::type->new($name)";
    isa_ok $type, 'FFI::Platypus::type';
    is eval { $type->ffi_type }, $name;
  }
}

subtest string => sub {
  plan tests => 3;
  my $type = eval { FFI::Platypus::type->new('string') };
  is $@, '', "type = FFI::Platypus::type->new(string)";
  isa_ok $type, 'FFI::Platypus::type';
  is eval { $type->ffi_type }, 'pointer';
};
