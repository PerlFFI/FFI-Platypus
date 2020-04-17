use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

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
    like "$@", qr/\Q$type\E is not a legal basis for a custom type/;
  }

};

subtest 'records' => sub {

  plan skip_all => 'todo';

  {
    package Foo;
    use FFI::Platypus::Record;
    record_layout qw(
      string(16) name
      sint32 value
    );
  }

  my $ffi = FFI::Platypus->new( api => 1, lib => $libtest );
  $ffi->custom_type(
    'foo_t' => {
      native_type => 'record(Foo)',
      perl_to_native => sub {
        my $var = shift;
        if(ref $var eq 'ARRAY')
        {
          return Foo->new(name => $var->[0], value => $var->[1]);
        }
        elsif(ref $var eq 'Foo')
        {
          return $var;
        }
      },
    },
  );

  ok 1;

};

done_testing;
