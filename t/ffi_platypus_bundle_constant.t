use strict;
use warnings;
use Test::More;
use FFI::Platypus::Bundle::Constant;
use File::Path qw( mkpath );
use File::Basename qw( dirname );
use FFI::Temp;

subtest 'very very basic...' => sub {

  my $api = FFI::Platypus::Bundle::Constant->new;
  isa_ok $api, 'FFI::Platypus::Bundle::Constant';
  undef $api;
  ok 'did not appear to crash :tada:';

};

subtest 'create constants' => sub {

  my $root = FFI::Temp->newdir;
  spew("$root/lib/Foo/Bar1.pm", <<'EOF');
    package Foo::Bar1;
    use strict;
    use warnings;
    use FFI::Platypus;
    my $ffi = FFI::Platypus->new( api => 1, experimental => 1, lang => 'ASM' );
    $ffi->bundle;
    1;
EOF

  spew("$root/ffi/bar1.c", <<'EOF');
#include <ffi_platypus_bundle.h>
    void ffi_pl_bundle_constant(const char *package, ffi_platypus_constant_t *b)
    {
      b->set_str("FOO1", "VAL1");
      b->set_str("Foo::Bar1::Baz::FOO2", "VAL2");
      b->set_sint("FOO3", -42);
      b->set_uint("FOO4", 512);
      b->set_double("FOO5", 2.5);
      b->set_str("FOO6", package);
    }
EOF

  local @INC = @INC;
  unshift @INC, "$root/lib";
  local $@ = '';
  eval " require Foo::Bar1; ";
  is "$@", '';

  is( Foo::Bar1::FOO1(), "VAL1" );
  is( Foo::Bar1::Baz::FOO2(), "VAL2" );
  is( Foo::Bar1::FOO3(), -42 );
  is( Foo::Bar1::FOO4(), 512 );
  is( Foo::Bar1::FOO5(), 2.5 );
  is( Foo::Bar1::FOO6(), "Foo::Bar1" );

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
