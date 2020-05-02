use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::C;

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => [undef],
);
FFI::C->ffi($ffi);

package Unix::TimeStruct {

  FFI::C->struct(tm => [
    tm_sec    => 'int',
    tm_min    => 'int',
    tm_hour   => 'int',
    tm_mday   => 'int',
    tm_mon    => 'int',
    tm_year   => 'int',
    tm_wday   => 'int',
    tm_yday   => 'int',
    tm_isdst  => 'int',
    tm_gmtoff => 'long',
    _tm_zone  => 'opaque',
  ]);

  # For now 'string' is unsupported by FFI::C, but we
  # can cast the time zone from an opaque pointer to
  # string.
  sub tm_zone {
    my $self = shift;
    $ffi->cast('opaque', 'string', $self->_tm_zone);
  }

  # attach the C localtime function
  $ffi->attach( localtime => ['time_t*'] => 'tm', sub {
    my($inner, $class, $time) = @_;
    $time = time unless defined $time;
    $inner->(\$time);
  });
}

# now we can actually use our My::UnixTime class
my $time = Unix::TimeStruct->localtime;
printf "time is %d:%d:%d %s\n",
  $time->tm_hour,
  $time->tm_min,
  $time->tm_sec,
  $time->tm_zone;
