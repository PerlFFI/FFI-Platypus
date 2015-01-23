package Module::Build::FFI;

use strict;
use warnings;
use ExtUtils::CBuilder;
use File::Glob       qw( bsd_glob );
use File::Spec       ();
use File::ShareDir   ();
use File::Path       ();
use Text::ParseWords ();
use Config;
use base qw( Module::Build );

# ABSTRACT: Build Perl extensions in C with FFI
# VERSION

=head1 SYNOPSIS

In your C<Build.PL>

 use Modue::Build::FFI 0.04;
 Module::Build::FFI->new(
   module_name => 'Foo::Bar',
   ...
 )->create_build_script;

or C<dist.ini>:

 [ModuleBuild]
 mb_class = Module::Build::FFI
 
 [Prereqs / ConfigureRequires]
 Module::Build::FFI = 0.04

Put your .c and .h files in C<ffi> (C<ffi/example.c>):

 #include <ffi_util.h>
 #include <stdio.h>
 
 FFI_UTIL_EXPORT void
 print_hello(void)
 {
   printf("hello world\n");
 }

Attach it to Perl in your main module (C<lib/Foo/Bar.pm>):

 package Foo::Bar;
 
 use FFI::Platypus::Declare qw( void );
 use FFI::Util qw( locate_module_share_lib );
 
 lib locate_module_share_lib();
 attach hello_world => [] => void;

Use it from your perl script or module:

 use Foo::Bar;
 Foo::Bar::hello_world();  # prints "hello world\n"

=head1 DESCRIPTION

Module::Build variant for writing Perl extensions in C and FFI (sans XS).

=head1 PROPERTIES

=over 4

=item ffi_libtest_dir

=item ffi_include_dir

=item ffi_libtest_optional

=item ffi_source_dir

=back

=head1 MACROS

Defined in C<ffi_util.h>

=over 4

=item FFI_UTIL_VERSION

[version 0.04]

This is the L<FFI::Platypus> (prior to version 0.15 it was the 
L<FFI::Util> version number) version number multiplied by 100 (so it 
would be 4 for 0.04 and 101 for 1.01).

=item FFI_UTIL_EXPORT

[version 0.04]

The appropriate attribute needed to export functions from shared 
libraries / DLLs.  For now this is only necessary on Windows when using 
Microsoft Visual C++, but it may be necessary elsewhere in the future.

=back

=cut

__PACKAGE__->add_property( ffi_libtest_dir =>
  default => 'libtest',
);

__PACKAGE__->add_property( ffi_include_dir =>
  default => 'include',
);

__PACKAGE__->add_property( ffi_libtest_optional =>
  default => 1,
);

__PACKAGE__->add_property( ffi_source_dir => 
  default => 'ffi',
);

sub _ffi_headers ($$)
{
  my($self, $dir) = @_;

  my @headers;
  push @headers, bsd_glob($self->ffi_include_dir . "/*.h")
    if -d $self->ffi_include_dir;
  push @headers, bsd_glob("$dir/*.h");
  
  \@headers;
}

sub _ffi_include_dirs ($$)
{
  my($self, $dir) = @_;
  
  my @includes = ($dir);

  push @includes, $self->ffi_include_dir
    if defined $self->ffi_include_dir;

  push @includes, $ENV{FFI_PLATYPUS_INCLUDE_DIR} || File::Spec->catdir(File::ShareDir::dist_dir('FFI-Platypus'), 'include');

  push @includes, ref($self->include_dirs) ? @{ $self->include_dirs } : $self->include_dirs
    if defined $self->include_dirs;
  
  \@includes;
}

sub _build_dynamic_lib ($$$;$)
{
  my($self, $dir, $name, $dest_dir) = @_;
  
  $dest_dir ||= $dir;
  
  my $header_time = reverse sort map { (stat $_)[9] } @{ _ffi_headers $self, $dir };
  my $compile_count = 0;
  my $b = ExtUtils::CBuilder->new;

  my @obj = map {
    my $filename = $_;
    my($source_time) = reverse sort ((stat $filename)[9], $header_time);
    my $obj_name = $b->object_file($filename);
    $self->add_to_cleanup($obj_name);
    my $obj_time = -e $obj_name ? ((stat $obj_name)[9]) : 0;
    if($obj_time < $source_time)
    {
      $b->compile(
        source               => $filename,
        include_dirs         => _ffi_include_dirs($self, $dir),
        extra_compiler_flags => $self->extra_compiler_flags,
      );
      $compile_count++;
    }
    $obj_name;
  } bsd_glob("$dir/*.c");

  return unless $compile_count > 0;

  if($^O ne 'MSWin32')
  {
    return $b->link(
      lib_file           => $b->lib_file(File::Spec->catfile($dest_dir, $b->object_file("$name.c"))),
      objects            => \@obj,
      extra_linker_flags => $self->extra_linker_flags,
    );
  }
  else
  {
    # On windows we can't depend on MM::CBuilder to make the .dll file because it creates dlls
    # that export only one symbol (which is used for bootstrapping XS modules).
    my $dll = File::Spec->catfile($dest_dir, "$name.dll");
    $dll =~ s{\\}{/}g;
    my @cmd;
    my $cc = $Config{cc};
    if($cc !~ /cl(.exe)?$/i)
    {
      my $lddlflags = $Config{lddlflags};
      $lddlflags =~ s{\\}{/}g;
      @cmd = ($cc, Text::ParseWords::shellwords($lddlflags), -o => $dll, "-Wl,--export-all-symbols", @obj);
    }
    else
    {
      @cmd = ($cc, @obj, '/link', '/dll', '/out:' . $dll);
    }
    print "@cmd\n";
    system @cmd;
    exit 2 if $?;
    return $dll;
  }
}

sub _ffi_libtest_name ()
{
  $^O eq 'cygwin' ? 'cygtest-1' : 'libtest';
}

sub ACTION_libtest
{
  my $self = shift;
  my $dir = $self->ffi_libtest_dir;
  
  return unless -d $dir;
  
  $self->add_to_cleanup(map { "$dir/$_" } qw(
    *.o
    *.obj
    *.so
    *.dll
    *.bundle
  ));
  
  my $have_compiler = ExtUtils::CBuilder->new->have_compiler;
  
  unless($have_compiler)
  {
    print STDERR "libtest directory is included, but not compiler is available\n";
    print STDERR "some tests may fail if they depend on libtest\n";
    return;
  }
  
  _build_dynamic_lib $self, $dir, _ffi_libtest_name;
}

sub ACTION_ffi
{
  my $self = shift;
  my $dir = $self->ffi_source_dir;
  
  return unless -d $dir;
  
  $self->add_to_cleanup(map { "$dir/$_" } qw(
    *.o
    *.obj
    *.so
    *.dll
    *.bundle
  ));
  
  unless(ExtUtils::CBuilder->new->have_compiler)
  {
    print STDERR "a compiler is required.\n";
    exit 2;
  }

  die "Can't determine module name" unless $self->module_name;
  my @parts = split /::/, $self->module_name;

  my $arch_dir = File::Spec->catdir($self->blib, 'arch', 'auto', @parts);  
  File::Path::mkpath($arch_dir, 0, oct(777)) unless -d $arch_dir;

  my $name = $parts[-1];
  # yes, of course Strawberry has to be "different"
  if($^O eq 'MSWin32' && $Config{dlext} eq 'xs.dll')
  {
    $name = "$name.xs";
  }

  _build_dynamic_lib $self, $dir, $name, $arch_dir;  
}

sub ACTION_build
{
  my $self = shift;
  $self->depends_on('ffi');
  $self->SUPER::ACTION_build(@_);
}

sub ACTION_test
{
  my $self = shift;
  $self->depends_on('libtest');
  $self->SUPER::ACTION_test(@_);
}

1;
