#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Path::Class;

{
    package Thumbnail;
    use Moose;
    use Imager;

    has image => (
        is  => 'rw',
        isa => 'Imager',
    );

    sub load {
        my ($class, $file) = @_;

        my $self = $class->new;
        
        $self->image(Imager->new(file => $file));

        return $self;
    }

    sub scale {
        my ($self, $width, $height) = @_;

        # skalieren.
        my $image = $self->image->scale(
            xpixels => $width,
            ypixels => $height,
            type    => 'max',
            qtype   => 'mixing',
        );

        # in 16:9 Format bringen
        my $left = int(($image->getwidth  - $width)  / 2);
        my $top  = int(($image->getheight - $height) / 2);
        $image = $image->crop(
            left   => $left,
            right  => $left + $width,
            top    => $top,
            bottom => $top + $height,
        );

        $self->image($image);

        return $self;
    }

    sub add_play_icon {
        my ($self, $radius) = @_;

        my $center_x = int($self->image->getwidth  / 2);
        my $center_y = int($self->image->getheight / 2);

        $self->image->circle(
            color => '#000000', # schwarz
            r     => $radius + 2,
            x     => $center_x,
            y     => $center_y,
            aa    => 1,
        );

        $self->image->circle(
            color => '#ffffff', # weiss
            r     => $radius,
            x     => $center_x,
            y     => $center_y,
            aa    => 1,
        );

        my $delta = ($radius - 2) / sqrt(2);
        $self->image->polygon(
            color  => '#000000',
            points => [
                [ $center_x - $delta,      $center_y - $delta],
                [ $center_x + $radius - 2, $center_y ],
                [ $center_x - $delta,      $center_y + $delta],
            ],
            aa     => 1,
        );

        return $self;
    }

    sub add_logo {
        my ($self, $file) = @_;

        my $logo = Imager->new(file => $file);
        $self->image->paste(
            left => $self->image->getwidth  - $logo->getwidth  - 1,
            top  => $self->image->getheight - $logo->getheight - 1,
            src  => $logo,
        );

        return $self;
    }

    sub add_copyright {
        my $self = shift;
        
        my $text = 'WKI';
        my $font = Imager::Font->new(
            file => "$FindBin::Bin/Twister.ttf",
        );
        
        $self->image->string(
            string => $text,
            x      => 5,
            y      => $self->image->getheight - 10,
            color  => '#ffffff',
            font   => $font,
            size   => 20,
            aa     => 1,
        );
        
        return $self;
    }

    sub save {
        my ($self, $file) = @_;

        $self->image->write(
            file => $file,
        );

        return $self;
    }
}

use constant THUMBNAIL_WIDTH  => 160; # 16:9 format
use constant THUMBNAIL_HEIGHT => 90;
use constant PLAY_ICON_RADIUS => 20;
use constant SOURCE_IMAGE     => '16mpixel.jpg';
use constant LOGO_IMAGE       => 'logo.png';
use constant THUMBNAIL_IMAGE  => 'button.png';

my $image_dir      = dir($FindBin::Bin)->subdir('images')->resolve;
my $source_file    = $image_dir->file(SOURCE_IMAGE);
my $logo_file      = $image_dir->file(LOGO_IMAGE);
my $thumbnail_file = $image_dir->file(THUMBNAIL_WIDTH);

Thumbnail
    ->load($source_file)
    ->scale(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
    ->add_play_icon(PLAY_ICON_RADIUS)
    ->add_logo($logo_file)
    ->add_copyright
    ->save($thumbnail_file);
