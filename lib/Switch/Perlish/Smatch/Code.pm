package Switch::Perlish::Smatch::Code;

$VERSION = '1.0.0';

use strict;
use warnings;

## DESC - call $t with $m
sub _VALUE {
  my($t, $m) = @_;
  return $t->($m);
}

## DESC - call $t with $m
*_UNDEF = \&_VALUE;

## DESC - check if $m refers to $t
sub _SCALAR {
  my($t, $m) = @_;
  return $t == $$m;
}

## DESC - pass @$m to $t
sub _ARRAY {
  my($t, $m) = @_;
  return $t->(@$m);
}

## DESC - pass %$m to $t
sub _HASH {
  my($t, $m) = @_;
  return $t->(%$m);
}

## DESC - pass $m to $t
sub _CODE {
  my($t, $m) = @_;
  return $t->($m);
}

## DESC - pass $m to $t
sub _OBJECT {
  my($t, $m) = @_;
  return $t->($m);
}

## DESC - pass $m to $t
sub _Regexp {
  my($t, $m) = @_;
  return $t->($m);
}

Switch::Perlish::Smatch->register_package( __PACKAGE__, 'CODE' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Code -  the C<CODE> comparatory category package

=head1 VERSION

1.0.0 - initial release

=head1 DESCRIPTION

This package provides the default implementation for the C<CODE> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Code">.

=head1 SEE. ALSO

L<Switch::Perlish::Smatch>

L<Switch::Perlish::Smatch::Comparators>

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 COPYRIGHT

Copyright (c) 2005, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.

=cut
