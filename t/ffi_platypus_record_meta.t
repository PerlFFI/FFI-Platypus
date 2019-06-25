use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Record::Meta;
use Data::Dumper qw( Dumper );

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);

subtest 'basic' => sub {

  my $meta = FFI::Platypus::Record::Meta->new(
    [ 'uint8', 'uint8', 'pointer', 'float', 'double' ],
  );
  isa_ok $meta, 'FFI::Platypus::Record::Meta';
  like $meta->ffi_type, qr/^-?[0-9]+$/, "meta->ffi_type = @{[ $meta->ffi_type ]}";
  is $meta->size, 0, 'meta->size';
  is $meta->alignment, 0, 'meta->alignment';

  my $got = $meta->element_pointers;
  my $exp = [map { FFI::Platypus::Record::Meta::_find_symbol($_) } qw( uint8 uint8 pointer float double )];

  is_deeply
    $got,
    $exp,
    'meta->element_pointers'
  or diag Dumper([[map { sprintf "0x%x", $_ } @$got],[ map { sprintf "0x%x", $_ } @$exp]]);
};

subtest 'bogus types' => sub {

  {
    local $@ = '';
    eval { FFI::Platypus::Record::Meta->new(qw( completely bogsu )) };
    like "$@", qr/passed something other than a array ref/;
  }

  {
    local $@ = '';
    eval { FFI::Platypus::Record::Meta->new([qw( completely bogsu )]) };
    like "$@", qr/unknown type: completely/;
  }

};

done_testing;
