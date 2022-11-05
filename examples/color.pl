use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './color.so'
);

package Color {

  use FFI::Platypus::Record;
  use overload
    '""' => sub { shift->as_string },
    bool => sub { 1 }, fallback => 1;

  record_layout_1($ffi,
    'string(8)' => 'name', qw(
    uint8     red
    uint8     green
    uint8     blue
  ));

  sub as_string {
    my($self) = @_;
    sprintf "%s: [red:%02x green:%02x blue:%02x]",
      $self->name, $self->red, $self->green, $self->blue;
  }

}

$ffi->type('record(Color)' => 'color_t');
$ffi->attach( color_increase_red => ['color_t','uint8'] => 'color_t' );

my $gray = Color->new(
  name  => 'gray',
  red   => 0xDC,
  green => 0xDC,
  blue  => 0xDC,
);

my $slightly_red = color_increase_red($gray, 20);

print "$gray\n";
print "$slightly_red\n";
