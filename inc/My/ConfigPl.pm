package My::ConfigPl;

use strict;
use warnings;
use Data::Dumper ();
use Carp qw( croak );
use File::Path qw( mkpath );

sub dir  { croak "subclasss requires dir method" }
sub file { croak "subclasss requires file method" }

sub new
{
  my $class = shift;
  my $data;
  if(-e $class->file)
  {
    $data = do "./@{[ $class->file ]}";
  }
  else
  {
    $data = { 'test-key' => 'test-value' };
  }
  bless { data => $data }, $class;
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

  mkpath( $self->dir, 0, 0755 ) unless -d $self->dir;

  my $fh;
  open($fh, '>', $self->file) || die "error writing @{[ $self->file ]}";
  print $fh 'do { my ';
  print $fh $dd;
  print $fh '$x;}';
  close $fh;
}

1;
