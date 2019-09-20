use strict;
use warnings;

package My::UnixTime;

use FFI::Platypus::Record;

record_layout(qw(
    int    tm_sec
    int    tm_min
    int    tm_hour
    int    tm_mday
    int    tm_mon
    int    tm_year
    int    tm_wday
    int    tm_yday
    int    tm_isdst
    long   tm_gmtoff
    string tm_zone
));

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(undef);
# define a record class My::UnixTime and alias it to "tm"
$ffi->type("record(My::UnixTime)*" => 'tm');

# attach the C localtime function as a constructor
$ffi->attach( localtime => ['time_t*'] => 'tm', sub {
  my($inner, $class, $time) = @_;
  $time = time unless defined $time;
  $inner->(\$time);
});

package main;

# now we can actually use our My::UnixTime class
my $time = My::UnixTime->localtime;
printf "time is %d:%d:%d %s\n",
  $time->tm_hour,
  $time->tm_min,
  $time->tm_sec,
  $time->tm_zone;
