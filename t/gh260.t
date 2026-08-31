use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );
use Config qw( %Config );

# https://github.com/PerlFFI/FFI-Platypus/issues/260
#
# Confirm that the minimum and maximum value for each of the standard
# integer types survives a round trip unmolested as a scalar argument
# and return value, as a pointer, as a fixed size array, and as a
# variable size (pointer based) array.  See also gh#258, where a bug
# in a related project was masked for a long time because existing
# tests only ever used small values that happen to fit into any
# integer representation.

my @lib = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

my %minmax = (
  sint8  => [ -128, 127 ],
  uint8  => [ 0, 255 ],
  sint16 => [ -32768, 32767 ],
  uint16 => [ 0, 65535 ],
  sint32 => [ -2147483648, 2147483647 ],
  uint32 => [ 0, 4294967295 ],
);

if($Config{uvsize} >= 8)
{
  $minmax{sint64} = [ -9223372036854775808, 9223372036854775807 ];
  $minmax{uint64} = [ 0, 18446744073709551615 ];
}
else
{
  note 'skipping sint64/uint64 since this Perl does not have 64 bit integer support';
}

foreach my $type (sort keys %minmax)
{
  subtest $type => sub {

    local $SIG{__WARN__} = sub {
      my $message = shift;
      return if $message =~ /^Subroutine main::.* redefined/;
      warn $message;
    };

    my $ffi = FFI::Platypus->new( api => 2, lib => [@lib] );

    $ffi->attach( [ "${type}_add"  => 'add'  ] => [ "$type", "$type" ]           => "$type" );
    $ffi->attach( [ "${type}_inc"  => 'inc'  ] => [ "${type}*", "$type" ]        => "${type}*" );
    $ffi->attach( [ "${type}_sum"  => 'sum'  ] => [ "${type}[10]" ]              => "$type" );
    $ffi->attach( [ "${type}_sum2" => 'sum2' ] => [ "${type}[]", 'size_t' ]      => "$type" );

    foreach my $value (@{ $minmax{$type} })
    {
      subtest "value = $value" => sub {

        is add($value, 0), $value, 'scalar argument and return value';

        my $copy = $value;
        is ${ inc(\$copy, 0) }, $value, 'pointer argument and return value';
        is $copy, $value, 'value pointed to is unmodified by increment of 0';

        my @array10 = ($value, (0) x 9);
        is sum(\@array10), $value, 'fixed size array argument';

        my @array_n = ($value);
        is sum2(\@array_n, scalar @array_n), $value, 'variable size (pointer) array argument';

      };
    }

  };
}

done_testing;
