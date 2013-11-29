
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4203"
  },
  "configure_requires" => {
    "Module::Build" => "0.4203"
  },
  "dist_abstract" => "Depend on versions of modules the same as you have installed",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-Prereqs-MatchInstalled",
  "dist_version" => "0.1.6",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::Prereqs::MatchInstalled",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla::Role::PrereqSource" => 0,
    "Module::Data" => 0,
    "Moose" => 0,
    "MooseX::Types::Moose" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Cwd" => 0,
    "File::Copy::Recursive" => 0,
    "Path::FindDev" => 0,
    "Path::Tiny" => 0,
    "Test::DZil" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "Cwd" => 0,
  "File::Copy::Recursive" => 0,
  "Module::Build" => "0.4203",
  "Path::FindDev" => 0,
  "Path::Tiny" => 0,
  "Test::DZil" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
