use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::CheckLib qw( find_lib_or_die );

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => [find_lib_or_die lib => 'tcod'],
);

package TCOD::ColorRGB {

  use overload
    '""'     => sub { shift->to_string },
    "+"      => sub { shift->add(@_) },
    bool     => sub { 1 },
    fallback => 1;

  use FFI::Platypus::Record;
  record_layout_1(
    uint8 => 'r',
    uint8 => 'g',
    uint8 => 'b',
  );

  $ffi->type('record(TCOD::ColorRGB)' => 'TCOD_color_t');
  $ffi->attach( [ TCOD_color_add => 'add' ] => ['TCOD_color_t','TCOD_color_t'] => 'TCOD_color_t');

  sub to_string
  {
    my($self) = @_;
    sprintf "[%02x %02x %02x]",
      $self->r,
      $self->g,
      $self->b;
  }

}


$ffi->attach( TCOD_color_RGB => [ 'uint8', 'uint8', 'uint8' ] => 'TCOD_color_t' );

my $red = TCOD_color_RGB(255,0,0);
my $blue = TCOD_color_RGB(0,255,0);
my $purple = $red + $blue;

print "$red\n";       # [ff 00 00]
print "$blue\n";      # [00 00 ff]
print "$purple\n";    # [ff 00 ff]
