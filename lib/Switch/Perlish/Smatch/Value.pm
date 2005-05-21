package Switch::Perlish::Smatch::Value;

$VERSION = '1.0.0';

use strict;
use warnings;

use Switch::Perlish::Smatch 'value_cmp';

## DESC - call C<Switch::Perlish::Smatch::value_cmp()> with $t and $m
sub _VALUE {
  my($t, $m) = @_;
  return value_cmp($t, $m);
}

## DESC - return false, a VALUE is always defined
sub _UNDEF { return }

## DESC - check if what $m points to is the same as $t
sub _SCALAR {
  my($t, $m) = @_;
  return value_cmp($t, $$m);
}

## DESC - check if the $t is in $m
sub _ARRAY {
  my($t, $m) = @_;
  Switch::Perlish::Smatch::value_cmp($t, $_) and return 1
    for @$m;
  return;
}

## provide a wrapper sub to test against hash values?
## DESC - check if the $t exists as a key in $m
sub _HASH {
  my($t, $m) = @_;
  return exists $m->{$t};
}

## DESC - pass $t to &$m
sub _CODE {
  my($t, $m) = @_;
  return $m->($t);
}

## DESC - check if the method $t exists in $m
sub _OBJECT {
  my($t, $m) = @_;
  return UNIVERSAL::can($m, $t);
}

## DESC - regexp match $t against $m
sub _Regexp {
  my($t, $m) = @_;
  return $t =~ /$m/;
}

Switch::Perlish::Smatch->register_package( __PACKAGE__, 'VALUE' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Value -  the C<VALUE> comparatory category package

=head1 VERSION

1.0.0 - initial release

=head1 DESCRIPTION

This package provides the default implementation for the C<VALUE> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Value">.

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
