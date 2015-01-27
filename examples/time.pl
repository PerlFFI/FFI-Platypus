use strict;
use warnings;
use Convert::Binary::C;
use FFI::Platypus;
use YAML qw( Dump );

my $c = Convert::Binary::C->new;
# Alignment of zero (0) means use
# the alignment of your CPU
$c->configure( Alignment => 0 );
$c->parse(<<ENDC);
struct tm {
  int tm_sec;
  int tm_min;
  int tm_hour;
  int tm_mday;
  int tm_mon;
  int tm_year;
  int tm_wday;
  int tm_yday;
  int tm_isdst;
  long int tm_gmtoff;
  const char *tm_zone;
};
ENDC

my $tm_size = $c->sizeof("tm");

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);
$ffi->type("record($tm_size)" => 'tm');

$ffi->attach( [ localtime => 'my_localtime' ] => ['time_t*'] => 'tm' );

my $packed = my_localtime(\time);
my $unpacked = $c->unpack(tm => $packed);

# tm_zone comes back from Convert::Binary::C as an opaque,
# cast it into a string:
$unpacked->{tm_zone} = $ffi->cast(opaque => string => $unpacked->{tm_zone});

print YAML::Dump($unpacked);

