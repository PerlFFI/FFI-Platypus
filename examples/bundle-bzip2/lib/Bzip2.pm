package Bzip2;

use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::Platypus::Memory qw( free );

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->bundle;

$ffi->mangler(sub {
  my $name = shift;
  $name =~ s/^/bzip2__/ unless $name =~ /^BZ2_/;
  $name;
});

=head2 new

 my $bzip2 = Bzip2->new($block_size_100k, $verbosity, $work_flow);

=cut

$ffi->attach( new => ['opaque*', 'int', 'int', 'int'] => 'int' => sub {
  my $xsub = shift;
  my $class = shift;
  my $ptr;
  my $ret = $xsub->(\$ptr, @_);
  return bless \$ptr, $class;
});

$ffi->attach( [ BZ2_bzCompressEnd => 'DESTROY' ] => ['opaque'] => 'int' => sub {
  my $xsub = shift;
  my $self = shift;
  my $ret = $xsub->($$self);
  free $$self;
});

1;
