use strict;
use warnings;
use FFI::Platypus;

{
  package FD;

  use constant O_RDONLY => 0;
  use constant O_WRONLY => 1;
  use constant O_RDWR   => 2;

  use constant IN  => bless \do { my $in=0  }, __PACKAGE__;
  use constant OUT => bless \do { my $out=1 }, __PACKAGE__;
  use constant ERR => bless \do { my $err=2 }, __PACKAGE__;

  my $ffi = FFI::Platypus->new( api => 1, lib => [undef]);

  $ffi->type('object(FD,int)' => 'fd');

  $ffi->attach( [ 'open' => 'new' ] => [ 'string', 'int', 'mode_t' ] => 'fd' => sub {
    my($xsub, $class, $fn, @rest) = @_;
    my $fd = $xsub->($fn, @rest);
    die "error opening $fn $!" if $$fd == -1;
    $fd;
  });

  $ffi->attach( write => ['fd', 'string', 'size_t' ] => 'ssize_t' );
  $ffi->attach( read  => ['fd', 'string', 'size_t' ] => 'ssize_t' );
  $ffi->attach( close => ['fd'] => 'int' );
}

my $fd = FD->new("$0", FD::O_RDONLY);

my $buffer = "\0" x 10;

while(my $br = $fd->read($buffer, 10))
{
  FD::OUT->write($buffer, $br);
}

$fd->close;
