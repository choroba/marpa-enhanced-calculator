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

number     ~ [-0-9.]+

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

print Dumper $value;
