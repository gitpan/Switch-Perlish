package Switch::Perlish::Smatch::Regexp;

$VERSION = '1.0.0';

use strict;
use warnings;

use Carp 'croak';

## DESC - match $t against $m
sub _VALUE {
  my($t, $m) = @_;
  return $m =~ $t;
}

## DESC - croak("Can't compare Regexp with an undef") # suggestions welcome
sub _UNDEF {
  croak("Can't compare Regexp with an undef");
}

## DESC - check if $m refers to $t
sub _SCALAR {
  my($t, $m) = @_;
  return $t == $$m;
}

## DESC - match $t for every element in @$m
sub _ARRAY {
  my($t, $m) = @_;
  $_ =~ $t and return 1
    for @$m;
  return
}

## DESC - check if any of keys of %$m match the $t
sub _HASH {
  my($t, $m) = @_;
  $_ =~ $t and return 1
    for keys %$m;
  return;
}

## DESC - pass $t to $m
sub _CODE {
  my($t, $m) = @_;
  return $m->($t);
}

## DESC - match $t against $m's class
sub _OBJECT {
  my($t, $m) = @_;
  return ref($m) =~ $t;
}

## DESC - match $m to $t
sub _Regexp {
  my($t, $m) = @_;
  return $m =~ $t;
}

Switch::Perlish::Smatch->register_package( __PACKAGE__, 'Regexp' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Regexp -  the C<REGEXP> comparatory category package

=head1 VERSION

1.0.0 - initial release

=head1 DESCRIPTION

This package provides the default implementation for the C<Regexp> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Regexp">.

=head1 SEE. ALSO

L<Switch::Perlish::Smatch>

L<Switch::Perlish::Smatch::Comparators>

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 COPYRIGHT

Copyright (c) 2005, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same

=cut
