use strict;
use warnings;
use autodie;
use Template;

my $tt2 = Template->new(
  INCLUDE_PATH => 'inc/template',
);

my @list = map {
  (
    { ffi_type => "uint$_", c_type => "uint${_}_t", perl_type => "UV", zero => "0" },
    { ffi_type => "sint$_", c_type =>  "int${_}_t", perl_type => "IV", zero => "0" },
  )
} (8,16,32,64);

push @list, map { { ffi_type => $_, c_type => $_, perl_type => "NV", zero => "0.0" } } qw( float double );

my $content = '';

foreach my $config (@list)
{
  $tt2->process("accessor.tt", $config, \$content) || die $tt2->error;
}

open my $fh, '>', 'xs/record_simple.c';
$tt2->process("accessor_wrapper.tt", { content => $content }, $fh);
close $fh;
