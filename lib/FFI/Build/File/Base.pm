package FFI::Build::File::Base;

use strict;
use warnings;
use 5.008001;
use Carp ();
use File::Temp     ();
use File::Basename ();
use FFI::Build::Platform;
use overload '""' => sub { $_[0]->path };

# ABSTRACT: Base class for File::Build files
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

=cut

sub new
{
  my($class, $content, %config) = @_;

  my $base     = $config{base} || 'ffi_build_';
  my $dir      = $config{dir};
  my $library  = $config{library};
  my $platform = $config{platform} || FFI::Build::Platform->new;

  my $self = bless {
    platform => $platform,
    library  => $library,
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
    my @args;
    push @args, "${base}XXXXXX";
    push @args, DIR => $dir if $dir;
    push @args, SUFFIX => $self->default_suffix;
    
    my($fh, $filename) = File::Temp::tempfile(@args);
    
    binmode( $fh, $self->default_encoding );
    print $fh $$content;
    close $fh;
    
    $self->{path} = $filename;
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

=head2 library

 my $library = $file->library;

The L<FFI::Build::Library> instance used for this file object, if any.

=cut

sub path      { shift->{path}                          }
sub basename  { File::Basename::basename shift->{path} }
sub dirname   { File::Basename::dirname  shift->{path} }
sub is_temp   { shift->{temp}                          }
sub platform  { shift->{platform}                      }
sub library   { shift->{library}                       }

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

=head2 build

 $file->build;

Builds the file into its natural output type, usually an object file.  It returns a new file instance,
or if the file is an object file then it returns empty list.

=cut

sub build
{
  Carp::croak("Not implemented!");
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
