package Defers;
use 5.16.1;
our $VERSION = '0.0.4';
use Exporter qw(import);
use List::Util qw(any pairs);

use subs qw(__check_and_load);

our @EXPORT_OK = qw/defers/;
our @EXPORT = ();

sub defers {
    state $by_defer_descr_ref_type = {
        'ARRAY'  => sub {
            my $pck_and_args = $_[0];
            sub { 
                __check_and_load(my $pkg = $pck_and_args->[0]);
                $pkg->new(@{$pck_and_args}[1..$#{$pck_and_args}])
            }
        },
        'HASH'	=> sub {
            my $pars = $_[0];
            my $pkg = $pars->{'pack'} // $pars->{'package'};
            my $args = $pars->{'args'} // $pars->{'pars'} // [];
            ! ref($args) and $args = [$args];
            sub {
                __check_and_load($pkg);
                $pkg->new(@{$args})
            }
        },
        'CODE' 	 => sub { $_[0] },
        'SCALAR' => sub { 
            my $expl_val = ${$_[0]};
            sub { $expl_val }
        },
        'REF'	=>  sub { 
            my $expl_val = ${$_[0]};
            sub { $expl_val }
        },
        ''	 => sub {        
            my $pkg = $_[0];
            sub { 
                __check_and_load($pkg);
                $pkg->new
            }
        },        
    };
    my $caller_pkg = (caller)[0];
    for (pairs @_) {
        no strict 'refs';
        my ($defer_name, $defer_descr) = @{$_};
        my $init_sub = (
            $by_defer_descr_ref_type->{ref $defer_descr}
            // sub { die 'invalid deferred object description type: ', ref($defer_descr) }
        )->($defer_descr);
        my $func_fq_name = join('::' => $caller_pkg, $defer_name);
        *{$func_fq_name} = sub {
            state $lazy_instance = $init_sub->()
        };
        if ( ref($defer_descr) eq 'HASH' and my $opts = $defer_descr->{'opts'} // $defer_descr->{'options'} ) {
            &{$func_fq_name}() if ref($opts) eq 'HASH' and $opts->{'init_now'}
        }
    }
}

sub __check_and_load {
    no strict 'refs';
    state $checks = [
        sub { $INC{($_[0] =~ s%::%/%gr) . '.pm'} },
        sub { defined ${join('::' => $_[0], 'VERSION')} },
        sub { eval(sprintf 'my %s $x = 1', $_[0]) },
        sub {
            no strict;
            *stash = *{$_[0] . '::'};
            $_[0] eq 'JSON'
                ? $stash{'from_json'}
                : scalar keys %stash
        },
    ];
    my $package = $_[0];
    any { &{$_} } @{$checks} and return 1;
    say __PACKAGE__, ': loading ', $package, ' package';
    my $rv = eval 'require ' . $package;
    $@ 
        ? do { say "Ooops. We're failed to load $package finally: $@"; 0 }
        : $rv
}

1;
