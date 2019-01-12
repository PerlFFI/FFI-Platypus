package My::ConfigH;

use strict;
use warnings;
use File::Basename qw( basename );

sub new
{
  my($class, $filename) = @_;

  $filename ||= "include/ffi_platypus_config.h";

  my $self = bless {
    content  => '',
    filename => $filename,
  }, $class;

  $self;
}

sub define_var
{
  my($self, $key, $value) = @_;
  $self->{content} .= "#define $key $value\n";
}

sub write_config_h
{
  my($self) = @_;

  my $once = uc basename($self->{filename});
  $once =~ s/\./_/g;

  my $fh;
  my $fn = $self->{filename};
  open $fh, '>', $fn or die "unable to write to $fn $!";
  print $fh "#ifndef $once\n";
  print $fh "#define $once\n\n";
  print $fh "@{[ $self->{content} ]}\n";
  print $fh "#endif\n";
  close $fh;
}

1;
