#!/usr/bin/env perl
use strict;
use warnings;
use Imager::QRCode;
use FindBin;

my $qrcode = Imager::QRCode->new(
    size          => 2,
    margin        => 2,
    version       => 1,
    level         => 'M',
    casesensitive => 1,
    lightcolor    => Imager::Color->new(255, 255, 255),
    darkcolor     => Imager::Color->new(0, 0, 0),
);

my $image = $qrcode->plot('http://foo-magazin.de?is=cool');

$image->write(
    file => "$FindBin::Bin/images/qrcode.png", 
);
