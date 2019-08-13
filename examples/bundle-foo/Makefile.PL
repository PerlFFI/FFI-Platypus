use ExtUtils::MakeMaker;
use FFI::Build::MM;
my $fbmm = FFI::Build::MM->new;
WriteMakefile(
  $fbmm->mm_args(
    NAME     => 'Foo',
    DISTNAME => 'Foo',
    VERSION  => '1.00',
    # ...
  )
);

sub MY::postamble
{
  $fbmm->mm_postamble;
}
