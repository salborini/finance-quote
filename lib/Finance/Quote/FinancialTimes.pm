#!/usr/bin/perl -w
#
#    Copyright (C) 2012, Sebastien Alborini <salborini@gmail.com>

#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#    02111-1307, USA
#
#
# This code derived from Padzensky's work on package Finance::YahooQuote,
# but extends its capabilites to encompas a greater number of data sources.
#
# This code was developed as part of GnuCash <http://www.gnucash.org/>

package Finance::Quote::FinancialTimes;
require 5.004;

use strict;

use vars qw($VERSION $FT_FUNDS_URL);

use LWP::UserAgent;
use HTTP::Request::Common;
use HTML::TableExtract;
use HTML::TreeBuilder;
use Encode;
use Date::Manip;

$VERSION = '1.17';

# URLs of where to obtain information.
#$FT_FUNDS_URL = "http://markets.ft.com/Research/Markets/Tearsheets/Summary?s=";
$FT_FUNDS_URL = "http://markets.ft.com/Research//Tearsheets/PriceHistoryPopup?symbol=";
sub methods { return (uk_unit_trusts => \&ft_funds, ft_funds => \&ft_funds); }

{
    my @labels = qw/exchange method source name currency nav price/;
    sub labels { return (ft_funds => \@labels, 
			 uk_unit_trusts => \@labels); }
}

sub ft_funds
{
    my $quoter = shift;
    my @symbols = @_;
    return unless @symbols;

    my (%info,$ua);
    $ua = $quoter->user_agent;

    for (@symbols) {
	my $symbol = $_;
	my $url = $FT_FUNDS_URL . $symbol;
	# print STDERR "GET $url\n";
	my $reply = $ua->request(GET $url);
	unless ($reply->is_success) {
	    $info { $symbol, "success" } = 0;
	    $info { $symbol, "errormsg" } = "Could not get page";
	    next;
	}
	my $data = $reply->content;
	# find currency
	$data =~ /\bNAV in (\w\w\w)/;
	my $currency = $1;
	unless (defined $currency) {
	    $info { $symbol, "success" } = 0;
	    $info { $symbol, "errormsg" } = "Cannot find currency";
	    next;
	}
	# find nav
	my $te = new HTML::TableExtract( headers => ["NAV", "Date", "Change"] );
	my $tbl = $te->parse(decode_utf8($data));
	unless (defined $tbl) {
	    $info { $symbol, "success" } = 0;
	    $info { $symbol, "errormsg" } = "Cannot find price";
	    next;
	}
	my $nav = $tbl->rows->[0]->[0];
	if ($currency eq 'GBX') {
	    $currency = 'GBP';
	    $nav /= 100;
	}
	$info { $symbol, "success" } = 1;
	$info { $symbol, "nav" } = $nav;
	$info { $symbol, "currency" } = $currency;
	$info { $symbol, "exchange"} = "LSE";
	$info { $symbol, "method"} = "ft_funds";
	$info { $symbol, "source"} = $url;
	$info { $symbol, "symbol"} = $symbol;
	$quoter->store_date(\%info, $symbol, { today => 1 }); # default date
	if ($data =~ /As of market close \w\w\w \d\d (\d\d\d\d)/) {
	    my $year = $1;
	    if ($tbl->rows->[0]->[1] =~ /(\w\w\w)\w* (\d\d)/) {
		$quoter->store_date(\%info, $symbol, { year=>$year, month=>$1, day=>$2 });
	    }
	}
	
    }
    return wantarray() ? %info : \%info;
}

1;

=head1 NAME

Finance::Quote::FinancialTimes  -  Obtain unit trust prices from ft.com

=head1 SYNOPSIS

    use Finance::Quote;

    $q = Finance::Quote->new;

    %stockinfo = $q->fetch("uk_unit_trusts","isin"); # Can failover to other methods
    %stockinfo = $q->fetch("ft_funds","isin"); # Use this module only.

=head1 DESCRIPTION

This module obtains information about UK unit trust prices from
www.ft.com.  The information source "uk_unit_trusts" can be used
if the source of prices is irrelevant, and "ft_funds" if you
specifically want to use FinancialTimes.

=head1 LABELS RETURNED

Information available from ft.com may include the following labels:
exchange method source name currency nav.

=head1 SEE ALSO

Financial Times website - http://www.ft.com/

=cut
