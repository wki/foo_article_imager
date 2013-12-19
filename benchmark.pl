#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use FindBin;
use Path::Class;
use Benchmark ':all';

use Image::Epeg ':constants';
use Imager;
use Image::Magick;
use GD;

use constant THUMBNAIL_SIZE => 150;

my $image_dir = dir($FindBin::Bin)->subdir('images')->resolve;
my ($source_path, %thumbnail_path_for);

my $converters = {
  # Load   => \&slurp_image_file,
    Epeg   => \&epeg_converter,
    Imager => \&imager_converter,
    Magick => \&magick_converter,
    GD     => \&gd_converter,
};

# simple try:
# prepare_paths(16); gd_converter(); exit;
# prepare_paths(16); magick_converter(); exit;
# prepare_paths(16); imager_converter(); exit;

if (1) {
    say '';
    say '16 mpixel:';

    prepare_paths(16);
    cmpthese(10, $converters);
}

if (1) {
    say '';
    say '1 mpixel:';
    
    prepare_paths(1);
    cmpthese(500, $converters);
}

sub prepare_paths {
    my $size = shift;

    $source_path = $image_dir->file("${size}mpixel.jpg");
    %thumbnail_path_for = (
        map { ($_ => $image_dir->file("$_-$size.jpg")->stringify) }
        qw(epeg imager magick gd)
    );
}

sub slurp_image_file {
    open my $file, '<', $source_path;
    while (<$file>) {}
    close $file;
}

sub epeg_converter {
    my $image = Image::Epeg->new($source_path);
    $image->resize(THUMBNAIL_SIZE, THUMBNAIL_SIZE, MAINTAIN_ASPECT_RATIO);
    $image->set_quality(100);
    $image->write_file($thumbnail_path_for{epeg});
}

sub imager_converter {
    my $image = Imager->new(file => $source_path);
    my $scaled_image = $image->scale(
        xpixels => THUMBNAIL_SIZE, 
        ypixels => THUMBNAIL_SIZE, 
        type    => 'min',
        qtype   => 'mixing', # normal / preview / mixing
    );
    $scaled_image->write(
        file        => $thumbnail_path_for{imager}, 
        jpegquality => 100,
    );
}

sub magick_converter {
    my $image = Image::Magick->new;
    $image->Read($source_path);
    $image->Resize(geometry => "${\THUMBNAIL_SIZE}x${\THUMBNAIL_SIZE}");
    $image->Write(
        filename => $thumbnail_path_for{magick}, 
        quality  => 100,
    );
}

sub gd_converter {
    open my $source_file, '<', $source_path;
    my $image = GD::Image->new($source_file);
    close $source_file;
    
    my ($width,$height) = $image->getBounds;
    my $dest_height = THUMBNAIL_SIZE * $height / $width;
    
    my $thumbnail = GD::Image->new(THUMBNAIL_SIZE, $dest_height);
    $thumbnail->copyResized(
        $image, 
        0,0, # dest x,y
        0,0, # source x,y
        THUMBNAIL_SIZE, $dest_height, # dest w,h
        $width, $height
    );
    open my $jpeg_file, '>', $thumbnail_path_for{gd};
    print $jpeg_file $thumbnail->jpeg(100);
    close $jpeg_file;
}
