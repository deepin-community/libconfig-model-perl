# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Test::Warn;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;
use lib "t/lib";

use utf8;
use open      qw(:std :utf8);    # undeclared streams in UTF-8

my ($model, $trace) = init_test();


$model->load(Master => 'Config/Model/models/Master.pl');
ok( 1, "loaded big_model" );

$model->augment_config_class(
    name => 'Master',
    element => [
        "list_with_warn_duplicates" => {
            type => 'list',
            duplicates => 'warn',
            cargo => { type => 'leaf', value_type => 'string'}
        }
    ],
);
ok( 1, "augmented big_model" );

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
ok( $root, "Config root created" );

my $step =
      'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
    . 'hash_a:toto=toto_value hash_a:titi=titi_value '
    . 'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - '
    . 'list_with_warn_duplicates=foo,bar,foo '
    . 'my_check_list=toto my_reference="titi" yes_no_boolean=1';

ok( $root->load( step => $step ), "set up data in tree with '$step'" );

# so that list_with_warn_duplicates comes with '/!\'
warning_like {$root->deep_check;} qr/Duplicated value/,"Found duplicated value";

my $description = $root->describe;
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace;

my $expect = <<'EOF' ;
name                        │ type       │ value
────────────────────────────┼────────────┼─────────────
std_id                      │ node hash  │ <SlaveZ>
lista                       │ list       │ a,b,c,d
listb                       │ list       │
hash_a:titi                 │ string     │ titi_value
hash_a:toto                 │ string     │ toto_value
hash_b                      │ value hash │ [empty hash]
ordered_hash                │ value hash │ [empty hash]
olist                       │ <SlaveZ>   │ node list
tree_macro                  │ enum       │ [undef]
warp                        │ node       │ <SlaveY>
slave_y                     │ node       │ <SlaveY>
string_with_def             │ string     │ "yada yada"
a_uniline                   │ uniline    │ "yada yada"
a_string                    │ string     │ "toto tata"
int_v                       │ integer    │ 10
my_check_list               │ check_list │ toto
a_boolean                   │ boolean    │ [undef]
yes_no_boolean              │ boolean    │ yes
my_reference                │ reference  │ titi
list_with_warn_duplicates ⚠ │ list       │ foo,bar,foo
EOF

is( $description, $expect, "check root description " );


$description = $root->describe(hide_empty => 1, verbose => 1);
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace;

$expect = <<'EOF' ;
name                        │ type       │ value       │ comment
────────────────────────────┼────────────┼─────────────┼─────────────────────
std_id                      │ node hash  │ <SlaveZ>    │ keys: "ab" "bc"
lista                       │ list       │ a,b,c,d     │
hash_a:titi                 │ string     │ titi_value  │
hash_a:toto                 │ string     │ toto_value  │
olist                       │ <SlaveZ>   │ node list   │ indexes: 0 1
warp                        │ node       │ <SlaveY>    │
slave_y                     │ node       │ <SlaveY>    │
string_with_def             │ string     │ "yada yada" │
a_uniline                   │ uniline    │ "yada yada" │
a_string                    │ string     │ "toto tata" │ mandatory
int_v                       │ integer    │ 10          │
my_check_list               │ check_list │ toto        │
yes_no_boolean              │ boolean    │ yes         │
my_reference                │ reference  │ titi        │
list_with_warn_duplicates ⚠ │ list       │ foo,bar,foo │
EOF

is( $description, $expect, "check root description without empty values" );

$description = $root->describe(hide_empty => 1);
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace;

$expect = <<'EOF' ;
name                        │ type       │ value
────────────────────────────┼────────────┼────────────
std_id                      │ node hash  │ <SlaveZ>
lista                       │ list       │ a,b,c,d
hash_a:titi                 │ string     │ titi_value
hash_a:toto                 │ string     │ toto_value
olist                       │ <SlaveZ>   │ node list
warp                        │ node       │ <SlaveY>
slave_y                     │ node       │ <SlaveY>
string_with_def             │ string     │ "yada yada"
a_uniline                   │ uniline    │ "yada yada"
a_string                    │ string     │ "toto tata"
int_v                       │ integer    │ 10
my_check_list               │ check_list │ toto
yes_no_boolean              │ boolean    │ yes
my_reference                │ reference  │ titi
list_with_warn_duplicates ⚠ │ list       │ foo,bar,foo
EOF

is( $description, $expect, "check root description without empty values and non verbose" );

$description = $root->grab('std_id:ab')->describe(verbose => 1);
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace;

$expect = <<'EOF' ;
name │ type │ value   │ comment
─────┼──────┼─────────┼─────────────────────
Z    │ enum │ [undef] │ choice: Av Bv Cv
X    │ enum │ Bv      │ choice: Av Bv Cv
DX   │ enum │ Dv      │ choice: Av Bv Cv Dv
EOF

is( $description, $expect, "check std_id:ab description " );

$description = $root->grab('std_id:ab')->describe(verbose => 1, hide_empty => 1);
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace;

$expect = <<'EOF' ;
name │ type │ value │ comment
─────┼──────┼───────┼─────────────────────
X    │ enum │ Bv    │ choice: Av Bv Cv
DX   │ enum │ Dv    │ choice: Av Bv Cv Dv
EOF

is( $description, $expect, "check std_id:ab description without empty values" );

$expect = <<'EOF' ;
name   │ type      │ value    │ comment
───────┼───────────┼──────────┼─────────────────────
std_id │ node hash │ <SlaveZ> │ keys: "ab" "bc"
EOF

$description = $root->describe(verbose => 1, element => 'std_id' );
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace;
is( $description, $expect, "check root description of std_id" );

$expect = <<'EOF' ;
name        │ type       │ value        │ comment
────────────┼────────────┼──────────────┼─────────────────────
hash_a:titi │ string     │ titi_value   │
hash_a:toto │ string     │ toto_value   │
hash_b      │ value hash │ [empty hash] │
EOF

$description = $root->describe(verbose => 1, pattern => qr/^hash_/ );
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace;
is( $description, $expect, "check root description of std_id" );

memory_cycle_ok($model, "check memory cycles");

done_testing;
