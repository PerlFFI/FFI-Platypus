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
use FFI::Platypus 0.51;
use File::Glob qw( bsd_glob );

subtest 'basic' => sub {

  my $build = FFI::Build->new('foo');
  isa_ok $build, 'FFI::Build';
  like $build->file->path, qr/foo/, 'foo is somewhere in the native name for the lib';
  note "lib.file.path = @{[ $build->file->path ]}";

  ok(-d $build->file->dirname, "dir is a dir" );
  isa_ok $build->platform, 'FFI::Build::Platform';

  $build->source('corpus/*.c');
  
  my($cfile) = $build->source;
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

  foreach my $type (qw( name object ))
  {
  
    subtest $type => sub {

      my $build = FFI::Build->new('foo', 
        dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project1' ),
        buildname => "tmpbuild.tmpbuild.$$.@{[ time ]}",
        verbose   => 1,
      );

      my @source = $type eq 'name'
        ? ('corpus/ffi_build/project1/*.c')
        : (map { FFI::Build::File::C->new($_) } bsd_glob('corpus/ffi_build/project1/*.c'));
      $build->source(@source);
      note "$_" for $build->source;

      my($out, $dll, $error) = capture_merged {
        my $dll = eval { $build->build };
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
  
      $build->clean;

      cleanup(
        $build->file->dirname,
        File::Spec->catdir(qw( corpus ffi_build project1 ), $build->buildname)
      );
    };
  }

};

subtest 'build c++' => sub {

  plan skip_all => 'Test requires C++ compiler'
    unless eval { FFI::Build::Platform->which(FFI::Build::Platform->cxx) };

  my $build = FFI::Build->new('foo', 
    dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project-cxx' ),
    buildname => "tmpbuild.$$.@{[ time ]}",,
    verbose   => 1,
  );
  
  $build->source('corpus/ffi_build/project-cxx/*.cxx');
  $build->source('corpus/ffi_build/project-cxx/*.cpp');
  note "$_" for $build->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $build->build };
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

  undef $ffi;
  $build->clean;

  cleanup(
    $build->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project-cxx ), $build->buildname)
  );

};

subtest 'Fortran' => sub {

  plan skip_all => 'Test requires Fortran compiler'
    unless eval { FFI::Build::Platform->which(FFI::Build::Platform->for) };
  
  plan skip_all => 'Test requires FFI::Platypus::Lang::Fortran'
    unless eval { require FFI::Platypus::Lang::Fortran };
  

  my $build = FFI::Build->new('foo', 
    dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project-fortran' ),
    buildname => "tmpbuild.$$.@{[ time ]}",
    verbose   => 1,
  );
  
  $build->source('corpus/ffi_build/project-fortran/add*.f*');
  note "$_" for $build->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $build->build };
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
    $build->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project-fortran ), $build->buildname)
  );

};

subtest 'alien' => sub {

  plan skip_all => 'Test requires Acme::Alien::DontPanic 1.03'
    unless eval { require Acme::Alien::DontPanic; Acme::Alien::DontPanic->VERSION("1.03") };


  my $build = FFI::Build->new('bar',
    dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project2' ),
    buildname => "tmpbuild.$$.@{[ time ]}",
    verbose   => 1,
    alien     => ['Acme::Alien::DontPanic'],
  );
  
  $build->source('corpus/ffi_build/project2/*.c');
  note "$_" for $build->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $build->build };
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
    $build->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project2 ), $build->buildname)
  );
};

done_testing;
