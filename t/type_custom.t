use strict;
use warnings;
use Test::More;
use FFI::Platypus;

my @legal = qw( float double opaque );
push @legal, map { ("sint$_","uint$_") } qw( 8 16 32 64 );

subtest 'legal custom types' => sub {

  my $ffi = FFI::Platypus->new( api => 1 );

  foreach my $type (@legal)
  {
    local $@ = "";
    eval {
      $ffi->custom_type( "foo_$type" => {
        native_type => $type,
        native_to_perl => sub {},
      });
    };
    is "$@", "";
  }

};

subtest 'illegal types' => sub {

  my $ffi = FFI::Platypus->new( api => 1 );

  foreach my $type (qw( sint8[32] sint8* ))
  {
    local $@ = "";
    my $alias = "foo_$type";
    $alias =~ s/[\*\[\]]/_/g;
    note "alias = $alias";
    eval {
      $ffi->custom_type( $alias => {
        native_type => $type,
        native_to_perl => sub {},
      });
    };
    like "$@", qr/\Q$type\E is not a legal native type for a custom type/;
  }

};

done_testing;
