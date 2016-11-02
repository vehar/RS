#!/usr/bin/env perl
use strict;
use warnings;


my $filename = $ARGV[0];
my $fpi;

if (defined $filename) {
  open($fpi, "<", $filename) or die "Could not open $filename: $!";
}
else {
  $fpi = *STDIN;
}


my $fpo = *STDOUT;


my $line;

my $hms;
my $lat; my $lon; my $alt;
my $NS; my $EW;
my $cs;
my $str;

my $date = 271016; ## (d)dmmyy ohne fuehrende 0 (wenn log kein Datum enthaelt)
my $speed = 0.00;
my $course = 0.00;

while ($line = <$fpi>) {
    if ($line =~ /(\d\d):(\d\d):(\d\d\.?\d?\d?\d?).*\ +lat:\ *(-?\d*)(\.\d*)\ +lon:\ *(-?\d*)(\.\d*)\ +alt:\ *(-?\d*\.\d*).*/) {

print STDERR $line;

        $hms = $1*10000+$2*100+$3;
        $lat = $4*100+$5*60;
        if ($4 < 0) { $NS="S"; $lat *= -1; }
        else        { $NS="N"; }
        $lon = $6*100+$7*60;
        if ($6 < 0) { $EW="W"; $lon *= -1; }
        else        { $EW="E"; }
        $alt = $8;

        if ($line =~ /(\d\d\d\d)-(\d\d)-(\d\d).*/) {
            $date = $3*10000+$2*100+($1%100);
        }

        if ($line =~ /vH:\ *(\d+\.\d+)\ +D:\ *(\d+\.\d+).*/) {
            $speed = $1*3.6/1.852;  ## m/s -> knots
            $course = $2;
        }

        $str = sprintf ("GPRMC,%010.3f,A,%08.3f,$NS,%09.3f,$EW,%.2f,%.2f,%06d,,", $hms, $lat, $lon, $speed, $course, $date);        
        $cs = 0;
        $cs ^= $_ for unpack 'C*', $str;
        printf $fpo "\$$str*%02X\n", $cs;

        ## GPS ueber Ellipsoid; Geoid-Hoehe nicht beruecksichtigt
        $str = sprintf ("GPGGA,%010.3f,%08.3f,$NS,%09.3f,$EW,1,04,0.0,%.3f,M,0.0,M,,", $hms, $lat, $lon, $alt);
        $cs = 0;
        $cs ^= $_ for unpack 'C*', $str;
        printf $fpo "\$$str*%02X\n", $cs;

    }
}

close $fpi;
close $fpo;


#############################################################################################################################################
##
## term-1$ socat -d -d pty,raw,echo=0 pty,raw,b4800,echo=0      #[default baudrate 38400]
## N PTY is /dev/pts/12
## N PTY is /dev/pts/15
##
## term-2$ sox -t oss /dev/dsp -t wav - lowpass 3600 2>/dev/null | ./rs92ecc --ecc --crc --vel2 -e brdc3010.16n | ./pos2nmea.pl > /dev/pts/12
##
## term-3$ gpsd -D2 -b -n -N /dev/pts/15
##
## term-4$ gpspipe -R localhost:2947
##
## Viking: GPS-layer, Realtime Tracking Mode, gpsd-port: 2947
##
#############################################################################################################################################

