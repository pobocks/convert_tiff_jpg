#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use File::Find;

my %opts;
getopts('w:s:d:p:h', \%opts); #Options stand for width, source, and destination respectively

$opts{s} = "./" unless $opts{s};

if ($opts{h}){
  print <<EOD;
Usage: convert_tiff_jpg.pl -w WIDTH_IN_PIXELS -d DESTINATION_DIRECTORY [-s source/directory (Default: "./"]

Convert a number of .tif files to a number of .jpg files, resizing where larger than -w

Options:
  
-w INT        Desired width to resize pictures to. Any already under the limit will not be resized.
-s STRING     Directory to recursively search for pictures. (Default ./)
-d STRING     Directory to place all pictures after conversion. 
-p INT        Number of processes to run (Default 3) 
-h VOID       Produce this help text
EOD
exit;
}

die "Destination directory is required - use -d option to set\n" unless $opts{d};
if ($opts{d} =~ /\/$/){
  chop $opts{d};
}

$opts{p} = 3 unless $opts{p};

die "No Width set - use -w option to set\n" unless $opts{w};

my @files;
find(sub {push @files, $File::Find::name unless -d}, $opts{s});

my $pid;
my @children;
my $parent = $$;
my $batch_size = int(($#files / $opts{p}) + $opts{p});

sub resize {
  for my $infile (@_){
    if ($infile =~ m/(p\d\d\-\d\d-\d\d)\.tif/){
      system('/opt/local/bin/convert', '-resize', "$opts{w}x>", $infile, "$opts{d}/$1.jpg");
    }
    else {
      warn "File ($infile) does not match naming convention; skipping.";
    }
  }
}

while (my @batch = splice(@files, 0 , $batch_size)) {
  unless ($pid = fork()) {
    resize(@batch);
    exit;
  }
  if (defined $pid){
    push @children, $pid;
  }
  else {
    die "Failed to fork!";
  }
}
foreach (@children){
  wait;
}


