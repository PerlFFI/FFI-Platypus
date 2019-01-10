package FFI::Probe;

use strict;
use warnings;
use File::Basename qw( dirname );
use Data::Dumper ();
use FFI::Probe::Runner;
use FFI::Build;
use FFI::Build::File::C;
use Capture::Tiny qw( capture_merged capture );
use File::Temp qw( tempdir );

# ABSTRACT: System detection and probing for FFI extensions.
# VERSION

=head1 SYNOPSIS

 use FFI::Probe;

 my $probe = FFI::Probe->new;
 $probe->check_header('foo.h');
 ...

=head1 DESCRIPTION

This class provides an interface for probing for system
capabilities.  It is used internally as part of the
L<FFI::Platypus> build process, but it may also be useful
for extensions that use Platypus as well.

=head1 CONSTRUCTOR

=head2 new

 my $probe = FFI::Probe->new(%args);

Creates a new instance.

=over 4

=item log

Path to a log or file handle to write to.

=item data_filename

Path to a file which will be used to store/cache results.

=back

=cut

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
    dir           => tempdir( CLEANUP => 1, TEMPLATE => 'ffi-probe-XXXXXX', DIR => '.' ),
    counter       => 0,
    runner        => $args{runner} || FFI::Probe::Runner->new,
  }, $class;

  $self;
}

=head1 METHODS

=head2 check_header

 my $bool = $probe->check_header($header);

Checks that the given C header file is available.
Stores the result, and returns a true/false value.

=cut

sub check_header
{
  my($self, $header) = @_;

  return if defined $self->{data}->{header}->{$header};

  my $code = '';
  $code .= "#include <$_>\n" for @{ $self->{headers} }, $header;

  my $build = FFI::Build->new("hcheck@{[ ++$self->{counter} ]}",
    verbose => 1,
    dir => $self->{dir},
  );
  my $file = FFI::Build::File::C->new(
    \$code,
    dir => $self->{dir},
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
    return 1;
  }
  else
  {
    $self->set('header', $header => 0);
    return;
  }
}

=head2 check_eval

 my %values = $probe>check_eval(%args);

=over 4

=item headers

Any additional headers.

=item decl

Any C declarations that need to be made before the C<dlmain> function.

=item stmt

Any C statements that should be made before the evaluation.

=item eval

Any evaluations that should be returned.

=back

=cut

sub check_eval
{
  my($self, %args) = @_;

  my $headers = join "\n", map { "#include <$_>\n" } (@{ $self->{headers} }, @{ $args{headers} || [] });
  my @decl    = @{ $args{decl} || [] };
  my @stmt    = @{ $args{eval} || [] };
  my %eval    = %{ $args{eval} || {} };

  my $code = $self->template;

  $code =~ s/##HEADERS##/$headers/;
  $code =~ s/##DECL##/join "\n", @decl/e;
  $code =~ s/##STMT##/join "\n", @stmt/e;

  my $eval = '';
  my $i=0;
  my %map;
  foreach my $key (sort keys %eval)
  {
    $i++;
    $map{$key} = "eval$i";
    my($format,$expression) = @{ $eval{$key} };
    eval .= "  printf(\"eval$i=<<<$format>>>\\n\", $expression);\n";
  }

  $code =~ s/##EVAL##/$eval/;

  my $build = FFI::Build->new("eval@{[ ++$self->{counter} ]}",
    verbose => 1,
    dir => $self->{dir},
  );
  $build->source(
    FFI::Build::File::C->new(
      \$code,
      dir => $self->{dir},
      build => $build,
    ),
  );

  my $lib = do {
    my($out, $lib, $error) = capture {
      my $lib = eval {
        $build->build;
      };
      ($lib, $@);
    };

    $self->log_code($code);
    $self->log($out);
    if($error)
    {
      $self->log("exception: $error");
      return;
    }
    elsif(!$lib)
    {
      $self->log("failed");
      return;
    }
    $lib;
  };

  my $result = $self->{runner}->run($lib->path);

  $self->log("[stdout]");
  $self->log($result->stdout);
  $self->log("[stderr]");
  $self->log($result->stderr);
  $self->log("rv  = @{[ $result->rv ]}");
  $self->log("sig = @{[ $result->signal ]}") if $result->signal;

  if($result->pass)
  {
    
  }
  else
  {
    return;
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

=head2 set

 $probe->set(@key, $value);

Used internally to store a value.

=cut

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

=head2 save

 $probe->save;

Saves the values already detected.

=cut

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

=head2

 my $data = $probe->data;

Returns a hashref of the data already detected.

=cut

sub data { shift->{data} }

=head2 log

 $probe->log($string);

Sends the given string to the log.

=cut

sub log
{
  my($self, $string) = @_;
  my $fh = $self->{log};
  print $fh $string, "\n";
}

=head2 log_code

 $prbe->log_code($string);

Sends the given multi-line code block to the log.

=cut

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

my $template;

=head2 template

 my $template = $probe->template;

Returns the C code template used for C<check_eval> and other
C<check_> methods.

=cut

sub template
{
  unless(defined $template)
  {
    local $/;
    $template = <DATA>;
  }

  $template;
}

1;

__DATA__
#include <stdio.h>
##HEADERS##
##DECL##


int
dlmain(int argc, char *argv[])
{
##STMT##

##EVAL##
  return 0;
}
