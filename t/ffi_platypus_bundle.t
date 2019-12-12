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
    my $ffi = FFI::Platypus->new( api => 1, lang => 'ASM' );
    $ffi->bundle;
    $ffi->attach("bar1" => [] => 'sint32');
    1;
EOF

  my $build = FFI::Build->new(
    'bar1',
    source => [ [ C => \"int bar1(void) { return 42; }\n" ]],
    verbose => 2,
    dir => "$root/lib/auto/share/dist/Foo-Bar1",
    export => ["bar1"],
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
    my $ffi = FFI::Platypus->new( api => 1, lang => 'ASM' );
    $ffi->bundle;
    $ffi->attach("bar2" => [] => 'sint32');
    1;
EOF

  my $build = FFI::Build->new(
    'bar2',
    source => [ [ C => \"int bar2(void) { return 43; }\n" ]],
    verbose => 2,
    dir => "$root/lib/auto/share/dist/Foo-Bar2",
    export => ['bar2'],
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
    export => ['bar3'],
  );

  my($build_out,$lib) = capture_merged {
    $build->build;
  };
  note $build_out;

  spew("$root/lib/auto/Foo/Bar3/Bar3.txt",
       'FFI::Build@' . File::Spec->abs2rel("$lib", "$root/lib"));

  unshift @INC, "$root/lib";

  my $ffi = FFI::Platypus->new( api => 1, lang => 'ASM' );
  $ffi->bundle('Foo::Bar3');
  $ffi->attach("bar3" => [] => 'sint32');
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
    my $ffi = FFI::Platypus->new( api => 1, lang => 'ASM' );
    $ffi->bundle;
    $ffi->attach("bar4" => [] => 'sint32');
    1;
EOF

  spew("$root/ffi/foo.c", "int bar4(void) { return 45; }" );
  spew("$root/ffi/foo.fbx", <<'EOF');
use strict;
use warnings;
our $DIR;
{ export => ['bar4'], source => ["$DIR/*.c"] };
EOF

  unshift @INC, "$root/lib";

  eval " require Foo::Bar4; ";
  is "$@", '';
  is( Foo::Bar4::bar4(), 45 );

};

subtest 'entry points' => sub {

  my $root = FFI::Temp->newdir;

  our @log;
  our $log_closure = do {
    my $ffi = FFI::Platypus->new;
    $ffi->closure(sub {
      my($str) = @_;
      push @log, $str;
    });
  };

  spew("$root/lib/Foo/Bar5.pm", <<'EOF');
    package Foo::Bar5;
    use strict;
    use warnings;
    use FFI::Platypus;
    our $ffi = FFI::Platypus->new( api => 1, lang => 'ASM' );
    $ffi->bundle([$ffi->cast('(string)->void' => 'opaque', $main::log_closure)]);
    1;
EOF

  spew("$root/ffi/foo.c", <<'EOF');
#include <ffi_platypus_bundle.h>
#include <stdio.h>

typedef void (*log_t)(const char *);
log_t logit;
char buffer[1024];

void
ffi_pl_bundle_init(const char *package, int c, void **args)
{
  int i;
  logit = (log_t) args[0];
  logit("ffi_pl_bundle_init (enter)");
  sprintf(buffer, "package = %s", package);
  logit(buffer);
  sprintf(buffer, "c = %d", c);
  logit(buffer);
  for(i=0; args[i] != NULL; i++)
  {
    sprintf(buffer, "args[%d] = %d", i, args[i]);
    logit(buffer);
  }
  logit("ffi_pl_bundle_init (leave)");
}

void
ffi_pl_bundle_fini(const char *package)
{
  logit("ffi_pl_bundle_fini (enter)");
  sprintf(buffer, "package = %s", package);
  logit(buffer);
  logit("ffi_pl_bundle_fini (leave)");
}

EOF

  spew("$root/ffi/foo.fbx", <<'EOF');
use strict;
use warnings;
our $DIR;
{ export => ['ffi_pl_bundle_init','ffi_pl_bundle_fini'], source => ["$DIR/*.c"] };
EOF

  unshift @INC, "$root/lib";

  local $@ = '';
  eval " require Foo::Bar5; ";
  is "$@", '';

  note "log:$_" for @log;

  is(scalar(@log), 5);
  is($log[0], 'ffi_pl_bundle_init (enter)');
  is($log[1], 'package = Foo::Bar5');
  is($log[2], 'c = 1');
  like($log[3], qr/^args\[0\] = -?[0-9]+$/);
  is($log[4], 'ffi_pl_bundle_init (leave)');

  @log = ();

  ok 1;

  {
    no warnings 'once';
    undef $Foo::Bar5::ffi;
  }

  note "log:$_" for @log;

  is_deeply(
    \@log,
    [
      'ffi_pl_bundle_fini (enter)',
      'package = Foo::Bar5',
      'ffi_pl_bundle_fini (leave)',
    ],
  );

  @log = ();

};

done_testing;

sub spew
{
  my($fn, $content) = @_;

  note "spew(start)[$fn]\n";
  note $content;
  note "spew(end)\n";

  my $dir = dirname $fn;
  mkpath $dir, 0, oct(755) unless -d $dir;
  open my $fh, '>', $fn;
  print $fh $content;
  close $fh;
}
