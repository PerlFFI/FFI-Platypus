use strict;
use warnings;

package My::UnixTime;

use FFI::Platypus;
use FFI::TinyCC;
use FFI::TinyCC::Inline 'tcc_eval';

# store the source of the tm struct
# for repeated use later
my $tm_source = <<ENDTM;
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
ENDTM

# calculate the size of the tm struct
# this time using Tiny CC
my $tm_size = tcc_eval qq{
  $tm_source
  int main()
  {
    return sizeof(struct tm);
  }
};

# To use My::UnixTime as a record class, we need to
# specify a size for the record, a function called
# either ffi_record_size or _ffi_record_size should
# return the size in bytes.  This function has to
# be defined before you try to define it as a type.
sub _ffi_record_size { $tm_size };

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(undef);
# define a record class My::UnixTime and alias it
# to "tm"
$ffi->type("record(My::UnixTime)*" => 'tm');

# attach the C localtime function as a constructor
$ffi->attach( [ localtime => '_new' ] => ['time_t*'] => 'tm' );

# the constructor needs to be wrapped in a Perl sub,
# because localtime is expecting the time_t (if provided)
# to come in as the first argument, not the second.
# We could also acomplish something similar using
# custom types.
sub new { _new(\($_[1] || time)) }

# for each attribute that we are interested in, create
# get and set accessors.  We just make accessors for
# hour, minute and second, but we could make them for
# all the fields if we needed.
foreach my $attr (qw( hour min sec ))
{
  my $tcc = FFI::TinyCC->new;
  $tcc->compile_string(qq{
    $tm_source
    int
    get_$attr (struct tm *tm)
    {
      return tm->tm_$attr;
    }
    void
    set_$attr (struct tm *tm, int value)
    {
      tm->tm_$attr = value;
    }
  });
  $ffi->attach( [ $tcc->get_symbol("get_$attr") => "get_$attr" ] => [ 'tm' ] => 'int' );
  $ffi->attach( [ $tcc->get_symbol("set_$attr") => "set_$attr" ] => [ 'tm' ] => 'int' );
}

package main;

# now we can actually use our My::UnixTime class
my $time = My::UnixTime->new;
printf "time is %d:%d:%d\n", $time->get_hour, $time->get_min, $time->get_sec;
