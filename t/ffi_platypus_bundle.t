use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Temp;
use FFI::Build;
use File::Basename qw( dirname );
use File::Path qw( mkpath );
use File::Spec;
use Capture::Tiny qw( capture_merged );

subtest 'from installed' => sub {

  local @INC = @INC;

  my $root = FFI::Temp->newdir;

  spew("$root/lib/Foo/Bar1.pm", <<'EOF');
    package Foo::Bar1;
    use strict;
    use warnings;
    use FFI::Platypus;
    my $ffi = FFI::Platypus->new( api => 1, experimental => 1 );
    $ffi->bundle;
    $ffi->attach("bar1" => [] => 'int');
    1;
EOF

  my $build = FFI::Build->new(
    'bar1',
    source => [ [ C => \"int bar1(void) { return 42; }\n" ]],
    verbose => 2,
    dir => "$root/lib/auto/share/dist/Foo-Bar1",
  );

  my($build_out,$lib) = capture_merged {
    $build->build;
  };
  note $build_out;

  spew("$root/lib/auto/Foo/Bar1/Bar1.txt",
       'FFI::Build@' . File::Spec->abs2rel("$lib", "$root/lib"));

  ok( !  FFI::Platypus->can('_bundle') );

  unshift @INC, "$root/lib";
  local $@ = '';
  eval " require Foo::Bar1; ";
  is "$@", '';
  is( Foo::Bar1::bar1(), 42 );

  ok( !! FFI::Platypus->can('_bundle') );

  $build->clean;

};

subtest 'from blib' => sub {

  local @INC = @INC;

  my $root = FFI::Temp->newdir;

  spew("$root/lib/Foo/Bar2.pm", <<'EOF');
    package Foo::Bar2;
    use strict;
    use warnings;
    use FFI::Platypus;
    my $ffi = FFI::Platypus->new( api => 1, experimental => 1 );
    $ffi->bundle;
    $ffi->attach("bar2" => [] => 'int');
    1;
EOF

  my $build = FFI::Build->new(
    'bar2',
    source => [ [ C => \"int bar2(void) { return 43; }\n" ]],
    verbose => 2,
    dir => "$root/lib/auto/share/dist/Foo-Bar2",
  );

  my($build_out,$lib) = capture_merged {
    $build->build;
  };
  note $build_out;

  spew("$root/arch/auto/Foo/Bar2/Bar2.txt",
       'FFI::Build@' . File::Spec->abs2rel("$lib", "$root/lib"));

  unshift @INC, "$root/lib";
  local $@ = '';
  eval " require Foo::Bar2; ";
  is "$@", '';
  is( Foo::Bar2::bar2(), 43 );

  $build->clean;
};

subtest 'not loaded yet' => sub {

  local @INC = @INC;

  my $root = FFI::Temp->newdir;

  spew("$root/lib/Foo/Bar3.pm", <<'EOF');
    package Foo::Bar3;
    die;
    1;
EOF

  my $build = FFI::Build->new(
    'bar3',
    source => [ [ C => \"int bar3(void) { return 44; }\n" ]],
    verbose => 2,
    dir => "$root/lib/auto/share/dist/Foo-Bar3",
  );

  my($build_out,$lib) = capture_merged {
    $build->build;
  };
  note $build_out;

  spew("$root/lib/auto/Foo/Bar3/Bar3.txt",
       'FFI::Build@' . File::Spec->abs2rel("$lib", "$root/lib"));

  unshift @INC, "$root/lib";

  my $ffi = FFI::Platypus->new( api => 1, experimental => 1 );
  $ffi->bundle('Foo::Bar3');
  $ffi->attach("bar3" => [] => 'int');
  is( bar3(), 44 );

  $build->clean;

};

subtest 'with a ffi dir' => sub {

  local @INC = @INC;

  my $root = FFI::Temp->newdir;

  spew("$root/lib/Foo/Bar4.pm", <<'EOF');
    package Foo::Bar4;
    use strict;
    use warnings;
    use FFI::Platypus;
    my $ffi = FFI::Platypus->new( api => 1, experimental => 1 );
    $ffi->bundle;
    $ffi->attach("bar4" => [] => 'int');
    1;
EOF

  spew("$root/ffi/foo.c", "int bar4(void) { return 45; }" );

  unshift @INC, "$root/lib";

  eval " require Foo::Bar4; ";
  is "$@", '';
  is( Foo::Bar4::bar4(), 45 );

};

done_testing;

sub spew
{
  my($fn, $content) = @_;

  note "spew(start)[$fn]\n";
  note $content;
  note "spew(end)\n";

  my $dir = dirname $fn;
  mkpath $dir, 0, 0755 unless -d $dir;
  open my $fh, '>', $fn;
  print $fh $content;
  close $fh;
}
