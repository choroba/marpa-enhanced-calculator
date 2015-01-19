#!/usr/bin/perl
use warnings;
use strict;
use feature qw{ say };

use Data::Dumper;
use Marpa::R2;

my $rules = << '__G__';
lexeme default = latm => 1
:default ::= action => single

:start   ::= Expression
Expression ::= ('(') Expression (')')                            assoc => group
             | number                      action => numify
            || Expression ('^') Expression action => power       assoc => right
            || Expression ('*') Expression action => multiply
             | Expression ('/') Expression action => divide
            || Expression ('+') Expression action => add
             | Expression ('-') Expression action => subtract

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

empty      ~
:discard   ~ whitespace
whitespace ~ [ \t]+

__G__

my %vars;

sub single      { $_[1] }
sub numify      { 0 + $_[1] }
sub multiply    { $_[1] * $_[2] }
sub divide      { $_[1] / $_[2] }
sub add         { $_[1] + $_[2] }
sub subtract    { $_[1] - $_[2] }
sub power       { $_[1] ** $_[2] }

my $input = shift;

my $grammar = 'Marpa::R2::Scanless::G'->new({ source => \$rules });
my $value   = $grammar->parse(\$input, { semantics_package => 'main' });

print Dumper $$value;
