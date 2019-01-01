package My::ShareConfig;

use strict;
use warnings;
use Data::Dumper ();
use File::Spec;
use File::Path qw( mkpath );

my $dir  = File::Spec->catdir( qw( blib lib auto share dist FFI-Platypus ));
my $file = File::Spec->catfile( $dir, qw( config.pl ));

sub new
{
  my $data;
  if(-e $file)
  {
    $data = do "./$file";
  }
  else
  {
    $data = { 'test-key' => 'test-value' };
  }
  bless { data => $data }, __PACKAGE__;
}

sub get
{
  my($self, $name) = @_;
  $self->{data}->{$name};
}

sub set
{
  my($self, $name, $value) = @_;
  $self->{data}->{$name} = $value;

  my $dd = Data::Dumper->new([$self->{data}],['x'])
    ->Indent(1)
    ->Terse(0)
    ->Purity(1)
    ->Sortkeys(1)
    ->Dump;

  mkpath( $dir, 0, 0755 ) unless -d $dir;

  my $fh;
  open($fh, '>', $file) || die "error writing $file";
  print $fh 'do { my ';
  print $fh $dd;
  print $fh '$x;}';
  close $fh;
}

1;
