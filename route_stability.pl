#!/usr/bin/env perl

use Storable;

my $last_routes;
if ( -e '/tmp/route_stability.stor' ) {
  $last_routes = retrieve('/tmp/route_stability.stor');
}

my %ret = {
            'CRITICAL' => 2,
            'WARNING' => 1,
            'OK' => 0,
            'UNKNOWN' => -1
            };

my @routes;   #  An array of routes, in which each item is a hashref describing a single route, keyed off the destination.
open(ROUTES, '/proc/net/route');
while(<ROUTES>) {
  next if $_ =~ /^Iface/;
  my $route;
  my @route_info = split(/\s+/, $_);
  my $route_iface = $route_info[0];
  my $dest = $route_info[1];
  my $route_gateway = $route_info[2];
  my $route->{$dest}->{'gateway'} = $route_gateway;
  my $route->{$dest}->{'via'} = $route_iface;
  push(@routes, $route);
}
close(ROUTES);

store \@routes, '/tmp/route_stability.stor';

sub is_equal {
  my ($a, $b) = @_;
  local $Storable::canonical = 1;
  return Storable::freeze($a) eq Storable::freeze($b);
}

if ( ! $last_routes ) {
  print "Missing data from a previous run\n";
  exit $ret{'UNKNOWN'};
}
elsif ( ! is_equal($last_routes, \@routes) ) {
  ## TODO: Do deep inspection to report on *what* changed
  print "Routes have changed!\n";
  exit $ret{'CRITICAL'};
}
else {
  print "Routes looking stable\n";
  exit $ret{'OK'};
}

