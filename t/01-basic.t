use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.003001 qw( dztest );
use Test::Fatal;

my $test = dztest();
$test->add_file(
  'dist.ini',
  simple_ini(
    [ 'Prereqs' => { 'Test::More' => 0 } ],
    [ 'Prereqs::MatchInstalled', { module => ['Test::More'] } ],
    ['MetaConfig'],
  )
);

$test->build_ok;

$test->meta_path_deeply( '/prereqs/runtime/requires', { 'Test::More' => $Test::More::VERSION } );
note explain $test->builder->log_messages;

done_testing;

