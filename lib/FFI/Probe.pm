package FFI::Probe;

use strict;
use warnings;
use File::Basename qw( dirname );
use Data::Dumper ();
use FFI::Build;
use FFI::Build::File::C;
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );

# ABSTRACT: System detection and probing for FFI extensions.
# VERSION

sub new
{
  my($class, %args) = @_;

  $args{log}           ||= "ffi-probe.log";
  $args{data_filename} ||= "ffi-probe.pl";

  unless(ref $args{log})
  {
    my $fn = $args{log};
    my $fh;
    open $fh, '>>', $fn;
    $args{log} = $fh;
  }

  my $data;

  if(-r $args{data_filename})
  {
    my $fn = $args{data_filename};
    unless($data = do $fn)
    {
      die "couldn't parse configuration $fn $@" if $@;
      die "couldn't do $fn $!"                  if $!;
      die "bad or missing config file $fn";
    }
  }

  $data ||= {};

  my $self = bless {
    headers => [],
    log           => $args{log},
    data_filename => $args{data_filename},
    data          => $data,
  }, $class;

  $self;
}

sub check_header
{
  my($self, $header) = @_;

  return if defined $self->{data}->{header}->{$header};

  my $code = '';
  $code .= "#include <$_>\n" for @{ $self->{headers} }, $header;

  my $build = FFI::Build->new('frooble', verbose => 1 );
  my $file = FFI::Build::File::C->new(
    \$code,
    dir => tempdir( CLEANUP => 1 ),
    build => $build,
  );
  my($out, $o) = capture_merged {
    eval { $file->build_item };
  };
  $self->log_code($code);
  $self->log($out);
  if($o)
  {
    $self->set('header', $header => 1);
    push @{ $self->{headers} }, $header;
  }
  else
  {
    $self->set('header', $header => 0);
  }
}

sub _set
{
  my($data, $value, @key) = @_;
  my $key = shift @key;
  if(@key > 0)
  {
    _set($data->{$key}, $value, @key);
  }
  else
  {
    $data->{$key} = $value;
  }
}

sub set
{
  my $self = shift;
  my $value = pop;
  my @key = @_;

  my $key = join ".", map { /\./ ? "\"$_\"" : $_ } @key;
  print "$key=$value\n";
  $self->log("$key=$value");
  _set($self->{data}, $value, @key);
}

sub save
{
  my($self) = @_;

  my $dir = dirname($self->{data_filename});
  
  my $dd = Data::Dumper->new([$self->{data}],['x'])
    ->Indent(1)
    ->Terse(0)
    ->Purity(1)
    ->Sortkeys(1)
    ->Dump;

  mkpath( $dir, 0, 0755 ) unless -d $dir;

  my $fh;
  open($fh, '>', $self->{data_filename}) || die "error writing @{[ $self->{data_filename} ]}";
  print $fh 'do { my ';
  print $fh $dd;
  print $fh '$x;}';
  close $fh;
}

sub data { shift->{data} }

sub log
{
  my($self, $string) = @_;
  my $fh = $self->{log};
  print $fh $string, "\n";
}

sub log_code
{
  my($self, $code) = @_;
  my @code = split /\n/, $code;
  chomp for @code;
  $self->log("code: $_") for @code;
}

sub DESTROY
{
  my($self) = @_;
  $self->save;
  my $fh = $self->{log};
  return unless defined $fh;
  close $fh;
}

1;

__DATA__
#include <stdio.h>

##HEADERS##

int
dlmain(int argc, char *argv[])
{
##BODY##
  return 0;
}
