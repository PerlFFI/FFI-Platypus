use strict;
use warnings;
use Test::More;
use FFI::Build::MM;
use Capture::Tiny qw( capture_merged );
use FFI::Platypus 0.51;
use File::Glob qw( bsd_glob );

sub dont_save_prop (&)
{
   my($code) = @_;
   sub {
    my $save = \&FFI::Build::MM::save_prop;
    {
      no warnings 'redefine';
      *FFI::Build::MM::save_prop = sub {};
    };
    my $ret = eval { $code->() };
    my $error = $@;
    {
      no warnings 'redefine';
      *FFI::Build::MM::save_prop = $save;
    }
    die $error if $error;
    $ret;
  };
}

sub slurp ($)
{
  my $fn = shift;
  open my $fh, '<', $fn;
  my $content = do { local $/; <$fh> };
  close $fh;
  $content;
}

subtest 'basic' => dont_save_prop {

  my $mm = FFI::Build::MM->new;
  isa_ok $mm, 'FFI::Build::MM';
  
  $mm->mm_args( DISTNAME => 'Foo-Bar-Baz' );

  is( $mm->distname, 'Foo-Bar-Baz' );
  is( $mm->sharedir, 'blib/lib/auto/share/dist/Foo-Bar-Baz' );
  is( $mm->archdir,  'blib/arch/auto/Foo/Bar/Baz' );

  subtest 'build with fbx file' => sub {
    my $build = $mm->load_build('corpus/ffi_build_mm/lb1', undef, undef);
    isa_ok $build, 'FFI::Build';
    is_deeply [sort map { $_->basename } $build->source], ['hello1.c','hello2.c']
  };

  subtest 'build with default' => sub {
    my $build = $mm->load_build('corpus/ffi_build_mm/lb2', undef, undef);
    isa_ok $build, 'FFI::Build';
    is_deeply [sort map { $_->basename } $build->source], ['hello1.c','hello2.c']
  };
  
  my $postamble = $mm->mm_postamble;
  ok $postamble;
  note "[postamble]\n$postamble\n";
  
  $mm->sharedir('share');
  is( $mm->sharedir, 'share' );
  
  $mm->archdir(0);
  ok( !$mm->archdir );
};

subtest 'with a build!' => sub {

  chdir 'corpus/ffi_build_mm/project1';

  unlink 'fbx.json' if -f 'fbx.json';

  subtest 'namespace is clean' => sub {
    ok( ! main->can($_), "$_ not imported yet" ) for qw( fbx_build fbx_test fbx_clean );
  };

  subtest 'perl Makefile.PL' => sub {
  
    my $mm = FFI::Build::MM->new;
    $mm->mm_args( DISTNAME => 'Crock-O-Stimpy' );
    ok -f 'fbx.json';
  
  };

  subtest 'import' => sub {
    FFI::Build::MM->import('cmd');
    ok( main->can($_), "$_ not imported yet" ) for qw( fbx_build fbx_test fbx_clean );
  };

  subtest 'make' => sub {
    my($out, $err) = capture_merged {
      eval { fbx_build() };
      $@;
    };
    note $out;
    is $err, '';
    
    is slurp 'blib/arch/auto/Crock/O/Stimpy/Stimpy.txt', "FFI::Build\@auto/share/dist/Crock-O-Stimpy/lib/libCrock-O-Stimpy@{[ scalar FFI::Build::Platform->library_suffix]}\n";
    
    my $ffi = FFI::Platypus->new;
    $ffi->lib(bsd_glob 'blib/lib/auto/share/dist/Crock-O-Stimpy/lib/*');
    is(
      $ffi->function('frooble_runtime' => [] => 'int')->call,
      47,
    );
  };
  
  subtest 'make test' => sub {
    my($out, $err) = capture_merged {
      eval { fbx_test() };
      $@;
    };
    note $out;
    is $err, '';
  };
  
  subtest 'make clean' => sub {
    fbx_clean();
    ok !-f 'fbx.json';
  };
  File::Path::rmtree('blib', 0, 0755);
  
  chdir(File::Spec->updir) for 1..3;

};

subtest 'alien' => sub {
  plan skip_all => 'todo';
};

done_testing;
