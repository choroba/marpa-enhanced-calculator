#!/usr/bin/perl
use warnings;
use strict;
use feature qw{ say };

use Data::Dumper;
use Marpa::R2;

my $rules = << '__G__';
lexeme default = latm => 1
:default ::= action => single

:start     ::= Program
Program    ::= Statement+                    action => none
Statement  ::= Assign separ                  action => none
             | Output separ                  action => none
Assign     ::= Var (eq) Expression           action => store
Output     ::= (print) List                  action => show
List       ::= Expression (comma) List       action => concat
             | Expression
             | String (comma) List           action => concat
             | String
Expression ::= (left_par) Expression (right_par)                 assoc => group
             | number                        action => numify
             | Var                           action => interpolate
            || Expression (power) Expression action => power     assoc => right
            || Expression (times) Expression action => multiply
             | Expression (slash) Expression action => divide
            || Expression (plus)  Expression action => add
             | Expression (minus) Expression action => subtract
String     ::= (quote) string (quote)
Var        ::= varname

sign_maybe ~ [+-] | empty
digit      ~ [0-9]
non_zero   ~ [1-9]
digit_any  ~ digit*
digit_many ~ digit+
E          ~ [Ee] sign_maybe digit_many
E_maybe    ~ E | empty

number     ~ sign_maybe digit_many E
           | sign_maybe digit_any '.' digit_many E_maybe
           | sign_maybe digit_many E_maybe
           | sign_maybe non_zero digit_any

print      ~ 'print'
eq         ~ '='
comma      ~ ','
left_par   ~ '('
right_par  ~ ')'
quote      ~ '"'
power      ~ '^'
times      ~ '*'
slash      ~ '/'
plus       ~ '+'
minus      ~ '-'

varname    ~ alpha
varname    ~ alpha alnum
alpha      ~ [a-zA-Z]
alnum      ~ [a-zA-Z0-9]+

string     ~ [^"]*
empty      ~
separ      ~ [\n;]+
:discard   ~ whitespace
whitespace ~ [ \t]+

__G__

my %vars;

sub none        {}
sub single      { $_[1] }
sub numify      { 0 + $_[1] }
sub show        { say $_[1] }
sub concat      { $_[1] . $_[2] }
sub multiply    { $_[1] * $_[2] }
sub divide      { $_[1] / $_[2] }
sub add         { $_[1] + $_[2] }
sub subtract    { $_[1] - $_[2] }
sub power       { $_[1] ** $_[2] }
sub store       { $vars{ $_[1] } = $_[2] }
sub interpolate { $vars{ $_[1] } // die "Unknown variable $_[1]" }

my $input = shift . ';';

my $grammar = 'Marpa::R2::Scanless::G'->new({ source => \$rules });
my $recce = 'Marpa::R2::Scanless::R'->new({ grammar           => $grammar,
                                            semantics_package => 'main',
                                            rejection         => 'event',
                                          });
my $last_pos = -1;
for ( $recce->read(\$input);
      $recce->pos < length $input;
      $recce->resume
    ) {
    if (grep 'separ' eq $_, @{ $recce->terminals_expected }) {
        $recce->lexeme_read('separ', $recce->pos, 0);
        $last_pos = $recce->pos;
        warn 'Semicolon inserted at ', $last_pos;

    } else {
        my $context = substr $input, $recce->pos;
        my ($line, $col) = $recce->line_column;
        my @expected = @{ $recce->terminals_expected };

        die "Parse error on line $line column $col at '$context', ",
            "expecting: @expected\n";
    }
}
$recce->value;
