use strict;
use warnings;
use Convert::Binary::C;
use FFI::Platypus;
use Data::Dumper qw( Dumper );

my $c = Convert::Binary::C->new;

# Alignment of zero (0) means use
# the alignment of your CPU
$c->configure( Alignment => 0 );

# parse the tm record structure so
# that Convert::Binary::C knows
# what to spit out and suck in
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

# get the size of tm so that we can give it
# to Platypus
my $tm_size = $c->sizeof("tm");

# create the Platypus instance and create the appropriate
# types and functions
my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(undef);
$ffi->type("record($tm_size)*" => 'tm');
$ffi->attach( [ localtime => 'my_localtime' ] => ['time_t*'] => 'tm'     );
$ffi->attach( [ time      => 'my_time'      ] => ['tm']      => 'time_t' );

# ===============================================
# get the tm struct from the C localtime function
# note that we pass in a reference to the value that time
# returns because localtime takes a pointer to time_t
# for some reason.
my $time_hashref = $c->unpack( tm => my_localtime(\time) );

# tm_zone comes back from Convert::Binary::C as an opaque,
# cast it into a string.  We localize it to just this do
# block so that it will be a pointer when we pass it back
# to C land below.
do {
  local $time_hashref->{tm_zone} = $ffi->cast(opaque => string => $time_hashref->{tm_zone});
  print Dumper($time_hashref);
};

# ===============================================
# convert the tm struct back into an epoch value
my $time = my_time( $c->pack( tm => $time_hashref ) );

print "time      = $time\n";
print "perl time = ", time, "\n";
