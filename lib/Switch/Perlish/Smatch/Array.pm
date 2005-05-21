package Switch::Perlish::Smatch::Array;

$VERSION = '1.0.0';

use strict;
use warnings;

use Switch::Perlish::Smatch 'smatch';

## DESC - smatch for $m in @$t
sub _VALUE {
  my($t, $m) = @_;
  smatch($m, $_) and return 1
    for @$t;
  return;
}

## DESC - return false as $t is already defined
sub _UNDEF { return }

## DESC - check if $m points to an element of @$t
sub _SCALAR {
  my($t, $m) = @_;
  \$_ == $m and return 1
    for @$t;
  return;
}

## this also doesn't feel right
## DESC - smatch for an element of @$m in @$t
sub _ARRAY {
  my($t, $m) = @_;
  for my $el (@$t) {
    smatch($el, $_) and return 1
      for @$m;
  }
  return;
}

## this is what I get for JFDI
## DESC - check if an element of @$t exists as a key in %$m
sub _HASH {
  my($t, $m) = @_;
  exists $m->{$_} and return 1
    for @$t;
  return;
}

## this looks kinda right at least ...
## DESC - call &$m with @$t
sub _CODE {
  my($t, $m) = @_;
  return $m->(@$t);
}

## more uncertainty
## DESC - check if an element of @$t exists as a method of $m
sub _OBJECT {
  my($t, $m) = @_;
  $m->can($_) and return 1
    for @$t;
  return;
}

## DESC - match $m against the elements of @$t
sub _Regexp {
  my($t, $m) = @_;
  /$m/ and return 1
    for @$t;
  return;
}

Switch::Perlish::Smatch->register_package( __PACKAGE__, 'ARRAY' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Array -  the C<ARRAY> comparatory category package

=head1 VERSION

1.0.0 - initial release

=head1 DESCRIPTION

This package provides the default implementation for the C<ARRAY> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Array">.

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
