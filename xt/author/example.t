use Test2::V0 -no_srand => 1;

eval { require FFI::Platypus; FFI::Platypus->VERSION('1.00') };
skip_all 'Test requires FFI::Platypus 1.00' if $@;
eval { require Test::Script; Test::Script->import('script_compiles') };
skip_all 'Test requires Test::Script' if $@;
eval { require Convert::Binary::C };
skip_all 'Test requires Convert::Binary::C' if $@;
skip_all 'Test requires version defined for FFI::Platypus' unless defined $FFI::Platypus::VERSION;

opendir my $dir, 'examples';
my @examples = sort grep /\.pl$/, readdir $dir;
closedir $dir;

foreach my $script (@examples)
{
  next if $script eq 'attach_from_pointer.pl';
  script_compiles("examples/$script")
}

done_testing;
