#!/usr/bin/env perl
use strict;
use warnings;
use Imager::Heatmap;
use FindBin;

my $heatmap = Imager::Heatmap->new(
    xsize => 320,
    ysize => 200,
);

for my $x (0..320) {
    for my $y (0..200) {
        $heatmap->insert_datas([$x, $y, abs($x - $y)]);
    }
}

my $image = $heatmap->draw;

$image->write(
    file        => "$FindBin::Bin/images/heatmap.jpg", 
    jpegquality => 100,
);
