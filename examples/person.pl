use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './person.so',
);

$ffi->type( 'opaque' => 'person_t' );

$ffi->attach( person_new =>  ['string','unsigned int'] => 'person_t'       );
$ffi->attach( person_name => ['person_t']              => 'string'       );
$ffi->attach( person_age =>  ['person_t']              => 'unsigned int' );
$ffi->attach( person_free => ['person_t']                                  );

my $person = person_new( 'Roger Frooble Bits', 35 );

print "name = ", person_name($person), "\n";
print "age  = ", person_age($person),  "\n";

person_free($person);
