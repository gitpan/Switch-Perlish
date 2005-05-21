package Switch::Perlish::Smatch::Object;

$VERSION = '1.0.0';

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'reftype';

## DESC - check if $t has $m as a method
sub _VALUE {
  my($t, $m) = @_;
  return UNIVERSAL::can($t, $m);
}

## DESC - croak("Can't compare OBJECT with an undef") # suggestions welcome
sub _UNDEF {
  croak("Can't compare OBJECT with an undef");
}

## DESC - check if the $m points to the $t
sub _SCALAR {
  my($t, $m) = @_;
  return $t == $$m;
}

## just delegate back to the blessed type - this is a quite horrible
## way to compare because it breaks encapsulation, but these are default cmps..
sub do_delegation {
  my($t, $m, $type) = @_;
  return ( reftype($t) eq $type ?
    Switch::Perlish::Smatch->dispatch($type => $type => $t, $m)
  :
    () );
}

## DESC - if the $t is a blessed ARRAY, delegate to the C<< ARRAYE<lt>=E<gt>ARRAY >> comparator
sub _ARRAY { do_delegation @_, 'ARRAY' }

## DESC - if the $t is a blessed HASH, delegate to the C<< HASHE<lt>=E<gt>HASH >> comparator
sub _HASH  { do_delegation @_, 'HASH' }

## DESC - call the $t on &$m i.e C<< $t->$m >>
sub _CODE  {
  my($t, $m) = @_;
  return $t->$m;
}

## DESC - check if the $t->isa($m) or the same class (better suggestions welcome)
sub _OBJECT {
  my($t, $m) = @_;
  return( ref($t) eq ref($m) or UNIVERSAL::isa($t, $m) );
}

## DESC - match the class of $t against the $m
sub _Regexp {
  my($t, $m) = @_;
  return ref($t) =~ /$m/;
}

Switch::Perlish::Smatch->register_package( __PACKAGE__, 'OBJECT' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Object -  the C<OBJECT> comparatory category package

=head1 VERSION

1.0.0 - initial release

=head1 DESCRIPTION

This package provides the default implementation for the C<OBJECT> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Object">.

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
