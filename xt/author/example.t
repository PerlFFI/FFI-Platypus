use Test2::V0 -no_srand => 1;
use Test2::Require::EnvVar 'FFI_PLATYPUS_TEST_EXAMPLES';

BEGIN {
  eval {
    require FFI::Platypus;
    FFI::Platypus->VERSION('2.00');
    require Convert::Binary::C;
    require YAML;
    require Capture::Tiny;
    Capture::Tiny->import('capture_merged');
    require Path::Tiny;
    Path::Tiny->import('path');
    require File::chdir;
    File::chdir->import();
    require Test::Script;
    Test::Script->import('script_compiles');
  };

  if($@)
  {
    note "error = $@";
    skip_all 'Test requires FFI::Platypus 2.00, Capture::Tiny, Test::Script, Path::Tiny, Convert::Binary::C and YAML';
  }
}

my @skipped;

foreach my $dir (qw( examples ))
{
  subtest "$dir" => sub {

    local $CWD = $dir;

    my @c_source = grep { $_->basename =~ /\.c$/ } path('.')->children;

    if(@c_source)
    {
      subtest 'Compile C' => sub {
        foreach my $c_source (@c_source)
        {
          my $so_file = $c_source->parent->child(do {
            my $basename = $c_source->basename;
            $basename =~ s/\.c$/.so/;
            $basename;
          });
          my @cmd = ('cc', '-fPIC', '-shared', -o => "$so_file", "$c_source");
          my($out, $ret) = capture_merged {
            system @cmd;
          };

          ok $ret == 0, "@cmd";
          if($ret == 0)
          {
            note $out if $out ne '';
          }
          else
          {
            diag $out if $out ne '';
          }
        }
      };
    }

    my @pl_source = grep { $_->basename =~ /\.pl$/ } path('.')->children;

    if(@pl_source)
    {
      subtest 'Run Perl' => sub {

        foreach my $pl_source (@pl_source)
        {
          subtest "$pl_source" => sub {

            script_compiles "$pl_source";

            my $key = join '/', $dir, $pl_source->basename;

            if($^O ne 'MSWin32' && $pl_source->basename =~ /^win32_/)
            {
              push @skipped, [$key, 'Microsoft Windows Only'];
              return;
            }

            my @cmd = ($^X, $pl_source);
            my($out, $ret) = capture_merged {
              system @cmd;
            };

            ok $ret == 0, "@cmd";
            if($ret == 0)
            {
              note $out if $out ne '';
            }
            else
            {
              diag $out if $out ne '';
            }
          };
        }

      };
    }

    unlink $_ for grep { $_->basename =~ /\.so$/ || $_->basename =~ /^zmq-ffi-/ } path('.')->children;

  }

}

foreach my $bundle (grep { -d $_ && $_->basename =~ /^bundle-/ } path('examples')->children)
{
  subtest $bundle->basename => sub {

    local $CWD = $bundle;

    my @cmd = ('prove', '-lvm');
    my($out, $ret) = capture_merged {
      system @cmd;
    };

    ok $ret == 0, "@cmd";
    if($ret == 0)
    {
      note $out if $out ne '';
    }
    else
    {
      diag $out if $out ne '';
    }
  };
}

if(@skipped)
{
  diag '';
  diag '';
  diag '';

  my $max = 5;
  foreach my $skip (@skipped)
  {
    $max = length($skip->[0])
      if $max < length($skip->[0]);
  }

  diag 'Skipped these examples:';

  foreach my $skip (@skipped)
  {
    diag sprintf "%-${max}s %s", $skip->[0], $skip->[1];
  }

  diag '';
  diag '';
}

done_testing;
