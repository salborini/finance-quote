#!/usr/bin/perl -w
use strict;
use Test::More;
use Finance::Quote;

if (not $ENV{ONLINE_TEST}) {
    plan skip_all => 'Set $ENV{ONLINE_TEST} to run this test';
}

plan tests => 10;

my $q = Finance::Quote->new();
my $year = (localtime())[5] + 1900;
my $lastyear = $year - 1;

my @stocks = ("GB0000407618", "LU0266117414");

my %quotes = $q->fetch("ft_funds",@stocks);

ok(%quotes);

# For each of our stocks, check to make sure we got back some
# useful information.

foreach my $stock (@stocks) {
  ok($quotes{$stock,"success"});
  ok($quotes{$stock,"nav"});
  ok($quotes{$stock,"currency"});
  ok($quotes{$stock,"isodate"});
}

# Test that a bogus stock gets no success.

%quotes = $q->fetch("trustnet","BOGUS");
ok(! $quotes{"BOGUS","success"});
