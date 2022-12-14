# -*- cperl -*-
use ExtUtils::testlib;
use Test::More;

use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use Config::Model::SimpleUI;

use warnings;
use strict;
use lib "t/lib";
use utf8;
use open      qw(:std :utf8);    # undeclared streams in UTF-8

use Data::Dumper;

my ($model, $trace, $args) = init_test('interactive');

note("you can run the test in interactive mode by passing '--interactive' option, e.g. perl -Ilib t/simple_ui.t --interactive");

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata"';
ok( $root->load( step => $step ), "set up data in tree with '$step'" );

# this test test only execution of user command, not their actual
# input
my $prompt = 'Test Prompt';

my $ui = Config::Model::SimpleUI->new(
    root   => $root,
    title  => 'Test Title',
    prompt => $prompt,
);

my $expected_prompt = $prompt . ':$ ';

ok( $ui, "Created ui" );

if ($args->{interactive}) {
    $ui->run_loop;
    done_testing;
    exit;
}

my $path = $ui->list_cd_path;

is_deeply(
    $path,
    [
        qw/std_id:ab std_id:bc tree_macro warp slave_y
            string_with_def a_uniline a_string int_v my_check_list
            a_boolean yes_no_boolean my_reference/
    ],
    'check list cd path at root'
);

is( $ui->prompt, $expected_prompt, 'test prompt at root' );

my @test = (
    [ 'vf std_id:ab', "Unexpected command 'vf'", $expected_prompt ],
    [
        'ls',
        join(' ', $root->get_element_names() ),
        $expected_prompt
    ],
    [ 'ls hash*', 'hash_a hash_b', $expected_prompt],
    [
        'll hash*',
        "name   │ type       │ value       \n".
        "───────┼────────────┼─────────────\n".
        "hash_a │ value hash │ [empty hash]\n".
        "hash_b │ value hash │ [empty hash]\n",
        $expected_prompt
    ],
    [ 'set a_string="some value with space"', "",   $expected_prompt ],
    [ 'cd std_id:ab',                         "",   $prompt . ': std_id:ab $ ' ],
    [ 'set X=Av',                             "",   $prompt . ': std_id:ab $ ' ],
    [ 'display X',                            "Av", $prompt . ': std_id:ab $ ' ],
    [ 'cd !',                                 "",   $expected_prompt ],
    [ 'delete std_id:ab',                     "",   $expected_prompt ],
);

foreach my $a_test (@test) {
    my ( $cmd, $expect, $expect_prompt ) = @$a_test;

    my $res = $ui->run($cmd);
    is($res , $expect, "exec $cmd" );

    is( $ui->prompt, $expect_prompt, "test prompt is $expect_prompt" );
}

memory_cycle_ok($model, "memory cycle");

done_testing;

