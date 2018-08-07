use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::Cleanup;
use FFI::Build;
use FFI::Build::Platform;
use File::Temp qw( tempdir );
use Capture::Tiny qw( capture_merged );
use File::Spec;
use File::Path qw( rmtree );
use FFI::Platypus;

subtest 'basic' => sub {

  my $lib = FFI::Build->new('foo');
  isa_ok $lib, 'FFI::Build';
  like $lib->file->path, qr/foo/, 'foo is somewhere in the native name for the lib';
  note "lib.file.path = @{[ $lib->file->path ]}";

  ok(-d $lib->file->dirname, "dir is a dir" );
  isa_ok $lib->platform, 'FFI::Build::Platform';

  $lib->source('corpus/*.c');
  
  my($cfile) = $lib->source;
  isa_ok $cfile, 'FFI::Build::File::C';

};

subtest 'file classes' => sub {
  {
    package FFI::Build::File::Foo1;
    use base qw( FFI::Build::File::Base );
    $INC{'FFI/Build/File/Foo1.pm'} = __FILE__;
  }

  {
    package FFI::Build::File::Foo2;
    use base qw( FFI::Build::File::Base );
  }

  my @list = FFI::Build::_file_classes();
  ok( @list > 0, "at least one" );
  note "class = $_" for @list;
};

subtest 'build' => sub {

  my $lib = FFI::Build->new('foo', 
    dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project1' ),
    buildname => "tmpbuild.tmpbuild.$$.@{[ time ]}",
    verbose   => 1,
  );
  
  $lib->source('corpus/ffi_build/project1/*.c');
  note "$_" for $lib->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $lib->build };
    ($dll, $@);
  };

  ok $error eq '', 'no error';

  if($error)
  {
    diag $out;
    return;
  }
  else
  {
    note $out;
  }
  
  my $ffi = FFI::Platypus->new;
  $ffi->lib($dll);
  
  is(
    $ffi->function(foo1 => [] => 'int')->call,
    42,
  );

  is(
    $ffi->function(foo2 => [] => 'string')->call,
    "42",
  );

  cleanup(
    $lib->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project1 ), $lib->buildname)
  );

};

subtest 'build c++' => sub {

  plan skip_all => 'Test requires C++ compiler'
    unless eval { FFI::Build::Platform->which(FFI::Build::Platform->cxx) };

  my $lib = FFI::Build->new('foo', 
    dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project-cxx' ),
    buildname => "tmpbuild.$$.@{[ time ]}",,
    verbose   => 1,
  );
  
  $lib->source('corpus/ffi_build/project-cxx/*.cxx');
  $lib->source('corpus/ffi_build/project-cxx/*.cpp');
  note "$_" for $lib->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $lib->build };
    ($dll, $@);
  };

  ok $error eq '', 'no error';

  if($error)
  {
    diag $out;
    return;
  }
  else
  {
    note $out;
  }
  
  my $ffi = FFI::Platypus->new;
  $ffi->lib($dll);
  
  is(
    $ffi->function(foo1 => [] => 'int')->call,
    42,
  );

  is(
    $ffi->function(foo2 => [] => 'string')->call,
    "42",
  );

  cleanup(
    $lib->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project-cxx ), $lib->buildname)
  );

};

subtest 'Fortran' => sub {

  plan skip_all => 'Test requires Fortran compiler'
    unless eval { FFI::Build::Platform->which(FFI::Build::Platform->for) };
  
  plan skip_all => 'Test requires FFI::Platypus::Lang::Fortran'
    unless eval { require FFI::Platypus::Lang::Fortran };
  

  my $lib = FFI::Build->new('foo', 
    dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project-fortran' ),
    buildname => "tmpbuild.$$.@{[ time ]}",
    verbose   => 1,
  );
  
  $lib->source('corpus/ffi_build/project-fortran/add*.f*');
  note "$_" for $lib->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $lib->build };
    ($dll, $@);
  };

  ok $error eq '', 'no error';

  if($error)
  {
    diag $out;
    return;
  }
  else
  {
    note $out;
  }
  
  my $ffi = FFI::Platypus->new;
  $ffi->lang('Fortran');
  $ffi->lib($dll);

  is(
    $ffi->function( add1 => [ 'integer*', 'integer*' ] => 'integer' )->call(\1,\2),
    3,
    'FORTRAN 77',
  );

  is(
    $ffi->function( add2 => [ 'integer*', 'integer*' ] => 'integer' )->call(\1,\2),
    3,
    'Fortran 90',
  );
  
  is(
    $ffi->function( add3 => [ 'integer*', 'integer*' ] => 'integer' )->call(\1,\2),
    3,
    'Fortran 95',
  );
  
  cleanup(
    $lib->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project-fortran ), $lib->buildname)
  );

};

subtest 'alien' => sub {

  plan skip_all => 'Test requires Acme::Alien::DontPanic 1.03'
    unless eval { require Acme::Alien::DontPanic; Acme::Alien::DontPanic->VERSION("1.03") };


  my $lib = FFI::Build->new('bar',
    dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project2' ),
    buildname => "tmpbuild.$$.@{[ time ]}",
    verbose   => 1,
    alien     => ['Acme::Alien::DontPanic'],
  );
  
  $lib->source('corpus/ffi_build/project2/*.c');
  note "$_" for $lib->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $lib->build };
    ($dll, $@);
  };

  ok $error eq '', 'no error';

  if($error)
  {
    diag $out;
    return;
  }
  else
  {
    note $out;
  }
  
  my $ffi = FFI::Platypus->new;
  $ffi->lib($dll);

  is(
    $ffi->function(myanswer => [] => 'int')->call,
    42,
  );

  cleanup(
    $lib->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project2 ), $lib->buildname)
  );
};

done_testing;
