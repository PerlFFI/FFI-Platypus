package FFI::Build::File::Base;

use strict;
use warnings;
use 5.008004;
use Carp ();
use FFI::Temp;
use File::Basename ();
use FFI::Build::Platform;
use FFI::Build::PluginData;
use overload '""' => sub { $_[0]->path }, bool => sub { 1 }, fallback => 1;

# ABSTRACT: Base class for File::Build files
# VERSION

=head1 SYNOPSIS

Create your own file class

 package FFI::Build::File::Foo;
 use parent qw( FFI::Build::File::Base );
 use constant default_suffix => '.foo';
 use constant default_encoding => ':utf8';

Use it:

 # use an existing file in the filesystem
 my $file = FFI::Build::File::Foo->new('src/myfile.foo');
 
 # generate a temp file with provided content
 # file will be deletd when $file falls out of scope.
 my $file = FFI::Build::File::Foo->new(\'content for a temp foo');


=head1 DESCRIPTION

This class is the base class for other C<FFI::Build::File::*> classes.

=head1 CONSTRUCTOR

=head2 new

 my $file = FFI::Build::File::Base->new(\$content, %options);
 my $file = FFI::Build::File::Base->new($filename, %options);

Create a new instance of the file class.  You may provide either the
content of the file as a scalar reference, or the path to an existing
filename.  Options:

=over 4

=item base

The base name for any temporary file C<ffi_build_> by default.

=item build

The L<FFI::Build> instance to use.

=item dir

The directory to store any temporary file.

=item platform

The L<FFI::Build::Platform> instance to use.

=back

=cut

sub new
{
  my($class, $content, %config) = @_;

  my $base     = $config{base} || 'ffi_build_';
  my $dir      = $config{dir};
  my $build    = $config{build};
  my $platform = $config{platform} || FFI::Build::Platform->new;

  my $self = bless {
    platform => $platform,
    build    => $build,
  }, $class;

  if(!defined $content)
  {
    Carp::croak("content is required");
  }
  elsif(ref($content) eq 'ARRAY')
  {
    $self->{path} = File::Spec->catfile(@$content);
  }
  elsif(ref($content) eq 'SCALAR')
  {
    my %args;
    $args{TEMPLATE} = "${base}XXXXXX";
    $args{DIR}      = $dir if $dir;
    $args{SUFFIX}   = $self->default_suffix;
    $args{UNLINK}   = 0;

    my $fh = $self->{fh} = FFI::Temp->new(%args);

    binmode( $fh, $self->default_encoding );
    print $fh $$content;
    close $fh;

    $self->{path} = $fh->filename;
    $self->{temp} = 1;
  }
  elsif(ref($content) eq '')
  {
    $self->{path} = $content;
  }

  if($self->platform->osname eq 'MSWin32')
  {
    $self->{native} = File::Spec->catfile($self->{path});
    $self->{path} =~ s{\\}{/}g;
  }

  $self;
}

=head1 METHODS

=head2 default_suffix

 my $suffix = $file->default_suffix;

B<MUST> be overridden in the subclass.  This is the standard extension for the file type.  C<.c> for a C file, C<.o> or C<.obj> for an object file depending on platform.  etc.

=head2 default_encoding

 my $encoding = $file->default_encoding;

B<MUST> be overridden in the subclass.  This is the passed to C<binmode> when the file is opened for reading or writing.

=head2 accept_suffix

 my @suffix_list = $file->accept_suffix;

Returns a list of regexes that recognize the file type.

=cut

sub default_suffix    { die "must define a default extension in subclass" }
sub default_encoding  { die "must define an encoding" }
sub accept_suffix     { () }

=head2 path

 my $path = $file->path;

The full or relative path to the file.

=head2 basename

 my $basename = $file->basename;

The base filename part of the path.

=head2 dirname

 my $dir = $file->dirname;

The directory part of the path.

=head2 is_temp

 my $bool = $file->is_temp;

Returns true if the file is temporary, that is, it will be deleted when the file object falls out of scope.
You can call C<keep>, to keep the file.

=head2 platform

 my $platform = $file->platform;

The L<FFI::Build::Platform> instance used for this file object.

=head2 build

 my $build = $file->build;

The L<FFI::Build> instance used for this file object, if any.

=cut

sub path      { shift->{path}                          }
sub basename  { File::Basename::basename shift->{path} }
sub dirname   { File::Basename::dirname  shift->{path} }
sub is_temp   { shift->{temp}                          }
sub platform  { shift->{platform}                      }
sub build     { shift->{build}                         }

=head2 native

 my $path = $file->native;

Returns the operating system native version of the filename path.  On Windows, this means that forward slash C<\> is
used instead of backslash C</>.

=cut

sub native {
  my($self) = @_;
  $self->platform->osname eq 'MSWin32'
    ? $self->{native}
    : $self->{path};
}

=head2 slurp

 my $content = $file->slurp;

Returns the content of the file.

=cut

sub slurp
{
  my($self) = @_;
  my $fh;
  open($fh, '<', $self->path) || Carp::croak "Error opening @{[ $self->path ]} for read $!";
  binmode($fh, $self->default_encoding);
  my $content = do { local $/; <$fh> };
  close $fh;
  $content;
}

=head2 keep

 $file->keep;

Turns off the temporary flag on the file object, meaning it will not automatically be deleted when the
file object is deallocated or falls out of scope.

=cut

sub keep
{
  delete shift->{temp};
}

=head2 build_item

 $file->build_item;

Builds the file into its natural output type, usually an object file.  It returns a new file instance,
or if the file is an object file then it returns empty list.

=cut

sub build_item
{
  Carp::croak("Not implemented!");
}

=head2 build_all

 $file->build_all;

If implemented the file in question can directly create a shared or dynamic library
without needing a link step.  This is useful for languages that have their own build
systems.

=head2 needs_rebuild

 my $bool = $file->needs_rebuild

=cut

sub needs_rebuild
{
  my($self, @source) = @_;
  # if the target doesn't exist, then we definitely
  # need a rebuild.
  return 1 unless -f $self->path;
  my $target_time = [stat $self->path]->[9];
  foreach my $source (@source)
  {
    my $source_time = [stat "$source"]->[9];
    return 1 if ! defined $source_time;
    return 1 if $source_time > $target_time;
  }
  return 0;
}

=head2 ld

=cut

sub ld
{
  return undef;
}

sub DESTROY
{
  my($self) = @_;

  if($self->{temp})
  {
    unlink($self->path);
  }
}

1;
