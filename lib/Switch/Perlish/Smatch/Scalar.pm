package Switch::Perlish::Smatch::Scalar;

$VERSION = '1.0.0';

use strict;
use warnings;

use Switch::Perlish::Smatch 'value_cmp';

## DESC - call C<Switch::Perlish::Smatch::value_cmp()> with $$t and $m
sub _VALUE {
  my($t, $m) = @_;
  return value_cmp($$t, $m);
}

## DESC - check if $$t is undef
sub _UNDEF {
  my($t, $m) = @_;
  return !defined($$t);
}

## DESC - numerically compare the scalar refs
sub _SCALAR {
  my($t, $m) = @_;
  return $t == $m;
}

## not sure if this is the right thing
## DESC - check if $t points to an element of @$m
sub _ARRAY {
  my($t, $m) = @_;
  \$_ == $t and return 1
    for @$m;
  return;
}

## this is an awkward comparator
## DESC - check if $t points to value in %$m
sub _HASH {
  my($t, $m) = @_;
  \$_ == $t and return 1
    for values %$m;
  return;
}

## DESC - check if $t points to $m
sub _CODE {
  my($t, $m) = @_;
  return $t == \$m;
}

## another awkward comparator
## DESC - check if the sref refers to the object
sub _OBJECT {
  my($t, $m) = @_;
  return $$t == $m;
}

## comparing scalar refs with other things doesn't feel right
## DESC - check if the sref refers to the Regexp object
sub _Regexp {
  my($t, $m) = @_;
  return $$t == $m;
}

## they both act the same
Switch::Perlish::Smatch->register_package( __PACKAGE__, 'SCALAR' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Scalar -  the C<SCALAR> comparatory category package

=head1 VERSION

1.0.0 - initial release

=head1 DESCRIPTION

This package provides the default implementation for the C<SCALAR> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Scalar">.

=head1 SEE. ALSO

L<Switch::Perlish::Smatch>.

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 COPYRIGHT

Copyright (c) 2005, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same

=cut
