#!/usr/bin/perl -w
use strict;
use Test::More;
use Finance::Quote;

if (not $ENV{ONLINE_TEST}) {
    plan skip_all => 'Set $ENV{ONLINE_TEST} to run this test';
}

plan tests => 12;

# Test currency conversion, both explicit requests and automatic
# conversion.

my $q      = Finance::Quote->new();

# Explicit conversion...
ok($q->currency("USD","AUD"));			# Test 1
ok($q->currency("EUR","JPY"));			# Test 2
ok(! defined($q->currency("XXX","YYY")));	# Test 3

# test for thousands : GBP -> IQD. This should be > 1000
ok($q->currency("GBP","IQD")>1000) ;            # Test 4

# Test 5
ok(($q->currency("10 AUD","AUD")) == (10 * ($q->currency("AUD","AUD"))));

# Euros into French Francs are fixed at a conversion rate of
# 1:6.559576 .  We can use this knowledge to test that a stock is
# converting correctly.

# Test 6
my %baseinfo = $q->fetch("yahoo_europe","UG.PA");
ok($baseinfo{"UG.PA","success"});

$q->set_currency("AUD");	# All new requests in Aussie Dollars.

my %info = $q->fetch("yahoo_europe","UG.PA");
ok($info{"UG.PA","success"});		# Test 7
ok($info{"UG.PA","currency"} eq "AUD");	# Test 8
ok($info{"UG.PA","price"} > 0);		# Test 9


# Test 10
# Yahoo sometimes return rates that are multiplied by 100,
# but only in one direction
my $nokgbp=$q->currency("NOK", "GBP");
my $gbpnok=$q->currency("GBP", "NOK");
my $ratio = $gbpnok / (1.0 / $nokgbp);
ok(abs(1-$ratio) < 0.05); 
# warn "Mismatch: NOK/GBP=$nokgbp GBP/NOK=$gbpnok ratio=$ratio"

# Test 11 
# What if secondary URL is down? (We'll temporarily break it)
my $old_url = $Finance::Quote::YAHOO_CURRENCY_QUOTES_URL;
$Finance::Quote::YAHOO_CURRENCY_QUOTES_URL = "http://uk.finance.yahoo.com/q?ss=";
ok($q->currency("EUR", "GBP"));
$Finance::Quote::YAHOO_CURRENCY_QUOTES_URL = $old_url;

# Test 12
# What if primary URL is down? (We'll temporarily break it)
$old_url = $Finance::Quote::YAHOO_CURRENCY_URL;
$Finance::Quote::YAHOO_CURRENCY_URL = "http://uk.finance.yahoo.com/q?ss=";
ok($q->currency("EUR", "GBP"));
$Finance::Quote::YAHOO_CURRENCY_URL = $old_url;

