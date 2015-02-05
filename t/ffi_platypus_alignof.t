use strict;
use warnings;
use Test::More tests => 4;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;

my $pointer_align = $ffi->alignof('opaque');

subtest 'ffi types' => sub {

  plan tests => 45;

  foreach my $type (qw( sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double opaque string ))
  {
    my $align = $ffi->alignof($type);
    like $align, qr{^[0-9]$}, "alignof $type = $align";
    
    next if $type eq 'string';

    my $align2 = $ffi->alignof("$type [2]");
    is $align2, $align, "alignof $type [2] = $align";
    
    my $align3 = $ffi->alignof("$type *");
    is $align3, $pointer_align, "alignof $type * = $pointer_align";
    
    $ffi->custom_type("custom_$type" => {
      native_type => $type,
      native_to_perl => sub {},
    });
    
    my $align4 = $ffi->alignof("custom_$type");
    is $align4, $align, "alignof custom_$type = $align";
  }
};


subtest 'aliases' => sub {
  plan tests => 2;

  $ffi->type('ushort' => 'foo');
  
  my $align = $ffi->alignof('ushort');
  like $align, qr{^[0-9]$}, "alignof ushort = $align";

  my $align2 = $ffi->alignof('foo');
  is $align2, $align, "alignof foo = $align";

};

subtest 'closure' => sub {
  plan tests => 1;

  $ffi->type('(int)->int' => 'closure_t');
  
  my $align = $ffi->alignof('closure_t');
  is $align, $pointer_align, "sizeof closure_t = $pointer_align";

};

subtest 'record' => sub {
  plan tests => 1;

  eval { $ffi->alignof('record(22)') };
  isnt $@, '', "generic record alignment not supported";
  note $@;

};
