#!/usr/bin/perl
package C;
use 5.16.1;

sub count_inst {
    state $c = 0;
    $c++
}

sub new {
    bless \count_inst(), $_[0]
}

package main;
use 5.16.1;
use Test::More;
use FindBin;
use lib $FindBin::RealBin . '/..';

BEGIN {
    my %some_hash = (very => {long => {path => {in => 'HASH'}}});
    use_ok('Defers', 'defers');
    defers(
        json => 'JSON',
        mochka => ['M', foo => 'bar'],
        finst => sub { F->new },
        expl_v1  => \$some_hash{'very'}{'long'}{'path'}{'in'},
        cow_says => \'Mooo',
        early_burner => {pack => 'C', opts => {init_now => 1}},
    );
}

isa_ok(json, 'JSON');

isa_ok(mochka, 'M');
is(mochka->value, 'bar', 'passing arguments to constructor is working as expected');

isa_ok(finst, 'F');
is(finst->value, 'baz', 'creating lazy instance via custom code reference working as expected');

is(expl_v1, 	'HASH', 'SCALAR refs works as expected');
is(cow_says, 	'Mooo', 'And the cow says "Mooo", so its ok to use REFs too');
ok(C::count_inst, 'Non-lazy instance creating also supported');

done_testing;

package M;

sub new {
    my ($class, %pars) = @_;
    bless \$pars{'foo'}, ref($class) || $class
}

sub value {
    ${$_[0]}
}

package F;

sub new {
    bless \(my $o = 'baz'), $_[0]
}

sub value { ${$_[0]} }

