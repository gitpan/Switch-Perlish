package Switch::Perlish::Smatch;

$VERSION = '1.0.0';

require Exporter;
@EXPORT_OK = qw/ smatch value_cmp /;
@ISA       = 'Exporter';

use strict;
use warnings;

use vars '%REGISTER';
use warnings::register;

use Carp 'croak';
use Scalar::Util 'blessed';

## XXX: move this into a separate module ???

## XXX: convert %REGISTRY to a class heirarchy?
## XXX: make tests more consistent?
## XXX: provide an easy way to default to existing comparators?

## XXX: should this be done 'smartly?'
require Switch::Perlish::Smatch::Value;
require Switch::Perlish::Smatch::Undef;
require Switch::Perlish::Smatch::Scalar;
require Switch::Perlish::Smatch::Array;
require Switch::Perlish::Smatch::Hash;
require Switch::Perlish::Smatch::Code;
require Switch::Perlish::Smatch::Object;
require Switch::Perlish::Smatch::Regexp;

## thanks to merlyn for this snippet
sub _is_num {
  no warnings;
  return ($_[0] & ~ $_[0]) eq "0";
}

sub value_cmp {
  my($a,$b) = @_;
  ## try to compare 2 strings then 2 numbers then do a regexp guesstimate
  !_is_num($a) and !_is_num($b) and return $a eq $b;
   _is_num($a) and  _is_num($b) and return $a == $b;
  no warnings;
  return $a =~ /\A$b\z/;
}

sub match {
  my $self   = @_ == 3 ? shift : __PACKAGE__;
  my($t, $m) = @_;
  my($t_type, $m_type) = map _get_type($_), $t, $m;
   
  ## default to OBJECT if we don't have a registered class comparator
  $t_type = 'OBJECT'
    if blessed($t) and !$self->is_registered($t_type);
  $m_type = 'OBJECT'
    if blessed($m) and !$self->is_registered($t_type, $m_type);
  ## treat REF the same as SCALAR, i.e KISS
  $_ eq 'REF' and $_ = 'SCALAR'
    for $t_type, $m_type;
  
  return $self->dispatch( $t_type, $m_type, $t, $m );
}

## for exporting
*smatch = \&match;

## make this public?
sub _get_type {
  my $foo  = shift;
  ## XXX: is this the best way to check?
  ## get the class name, or the reference type, or we're a value/undef
  return blessed($foo) || ref($foo) || ( defined($foo) ? 'VALUE' : 'UNDEF' );
}

sub dispatch {
  my($self, $t_type, $m_type) = @_;
  croak "No comparator found for topic '$t_type' => match '$m_type'"
    unless $self->is_registered( $t_type, $m_type );
  my($t,$m) = @_ == 5 ?
    @_[3,4] : ( $Switch::Perlish::TOPIC, $Switch::Perlish::MATCH );

  ## XXX: subvert the stack with a goto?
  $REGISTER{ $t_type }{ $m_type }->( $t, $m );
}

sub register {
  my($self, %comp) = @_;
  my($t_type, $m_type, $compare) = @comp{qw/ topic match compare /};

  warnings::warn("Overriding existing comparator for $t_type<=>$m_type")
    if $self->is_registered($t_type, $m_type) and warnings::enabled;

  $REGISTER{ $t_type }{ $m_type } = $compare;
  $REGISTER{ $m_type }{ $t_type } = sub { $compare->(reverse @_) }
    if exists $comp{reversible} and $comp{reversible};
}

sub register_package {
  my($self, $pkg, $topic) = @_;
  my $prefix  = defined($_[3]) ? $_[3] : '_';
  my $reverse = defined($_[4]) ? $_[4] : 0;

  croak "An empty prefix was provided (registering all subs is not desirable)"
    if length($prefix) == 0;

  ## let perl do the look-up
  my $tbl = do { no strict; \%{"$pkg\::"} };

  for( grep /^$prefix/, keys %$tbl  ) {
    my $sub;
    next
      unless $sub = *{$tbl->{$_}}{CODE};

    Switch::Perlish::Smatch->register(
      topic      => $topic,
      match      => substr($_, 1),
      compare    => $sub,
      reversible => $reverse,
    );
  }
}

sub is_registered {
  my($self, $t_type, $m_type) = @_;

  return ( exists $REGISTER{ $t_type } and defined $REGISTER{ $t_type } )
    if @_ == 2;
  return (     exists  $REGISTER{ $t_type } and defined $REGISTER{ $t_type }
           and exists  $REGISTER{ $t_type }{ $m_type }
           and defined $REGISTER{ $t_type }{ $m_type } )
    if @_ == 3;

  croak sprintf "Incorrect number of arguments for is_registered(%s)",
                join(', ', @_);
}

1;

=pod

=head1 NAME

Switch::Perlish::Smatch - the 'smart' behind the matching in S::P

=head1 VERSION

1.0.0 - Initial release

=head1 SYNOPSIS

  use Switch::Perlish::Smatch 'smatch';

  print 'yep'
    if smatch $foo => \@bar;

=head1 DESCRIPTION

Given two values compare them in an intelligent fashion (i.e I<smart match>)
regardless of type. This is done by discerning the types of the values and
delegating to the associated subroutine, or C<croak>ing if one isn't available.

=head2 Glossary

=over 4

=item comparators

When talking about the subroutine that compares the two values in the document
below it will referred to as a I<comparator>

=item topic/comparator category

A topic/comparator category holds all the comparators for a given type.

=item comparator notation

Some handy notation for referring to specific I<comparators> is
C<< FOOE<lt>=>BAR >>, where C<FOO> is the topic and C<BAR> is the match (i.e the
first and second arguments, respectively).

=back

=head1 METHODS

=over 4

=item match( $topic, $match )

Try to smart match the C<$topic> against C<$match> by delegating to the
appopriate comparator. It returns the result of the match per the comparator,
but it can always be assumed that a successful match will evaluate to I<true>
and an unsuccessful one I<false>.

=item register( %hash )

The expected C<%hash> looks like this:

  topic   => $t_type,
  match   => $m_type,
  compare => $sub,

So C<$sub> will be the registered comparator when the topic type is C<$t_type>
and the matching value is of type C<$m_type> e.g

  my $foo = 'a string';
  my $bar = [qw/ an array /];
  smatch $foo, $bar;

In this case the C<$t_type> is C<VALUE> and the C<$m_type> is C<ARRAY>. If
one were to override the default comparator for C<< VALUEE<lt>=>ARRAY >>
using C<register()> then it would be done like this:

  Switch::Perlish::Smatch->register(
    topic   => 'VALUE',
    match   => 'ARRAY',
    compare => sub {
      my($t, $m) = @_;
      return grep /$t/, @$m;
    },
  );

If you run the code above you should get a warning noting that there is an
existing comparator for that type combination. To suppress this and any other
warnings from this module just add C<no warnings 'Switch::Perlish::Smatch'>.

This method is aimed at adding comparators for objects so they can be used
seamlessly in C<switch> calls. So instead of defaulting to the existing
C<OBJECT> comparators a user-defined comparator would be used, with more
desirable results. For more information see L</"Creating a new comparator">
below.

If your comparator is reversible, i.e the arguments can be reversed and the
result will be the same, then you can pass in the C<reversible> argument e.g


  Switch::Perlish::Smatch->register(
    topic   => 'My::Obj',
    match   => 'ARRAY',
    compare => sub {
      my($t, $m) = @_;
      return $t->cmp( $m );
    },
    reversible => 1,
  );

So both the C<< My::Obj<=>VALUE >> and C<< VALUEE<lt>=>My::Obj >> comparators
will be setup, where C<< VALUEE<lt>=>My::Obj >> will behave exactly the same as
C<< My::Obj<=>VALUE >>.

=item register_package( $package, $topic[, $prefix, $reversible] );

Given the package name in C<$package>, register all subroutines beginning with
C<$prefix> (by default an underscore: C<_>) to the topic category C<$topic>.
This is how the standard comparator functions are registered. An empty
C<$prefix> is disallowed as C<register_package()> must be able to know which
subroutines to register. If C<$reversible> is passed in and it evaluates to
true then all comparators for this package will be reversible.

=item is_registered( $t_type[, $m_type] )

If one argument is provided, check if there is a comparator category for
C<$t_type>. If two arguments are provided then check if the comparator for
C<< $t_type<=>$m_type >> has been registered.

=item dispatch( $t_type, $m_type[, $topic, $match] )

Dispatch to the comparator for C<$t_type> and C<$m_type>, passing along
C<$topic> and C<$match> (defaulting to C<$Switch::Perlish::TOPIC> and
C<$Switch::Perlish::MATCH>, respectively).

=back

=head2 Helper subroutines

=over 4

=item value_cmp($t, $m)

Given two simple values try to compare them in the most natural way i.e try to
compare 2 numbers as numbers, 2 strings as strings and any other combination do
a regexp match.

=back

=head1 FURTHER INFO

=head2 Creating a new comparator

If we have a L<CGI> object and want I<smart match> it to something then we need
to create a new comparator. This can be implemented in whatever
way seems most appropriate, so for the sake of this module we will be testing
for the existence of a simple value in C<param()> e.g

  sub cgi_comparator {
    my($cgi, $val) = @_;
    return defined( $cgi->param($val) );
  }

Now that we have our comparator for C<< CGIE<lt>=>VALUE >> (the above subroutine)
and we know what we're comparing (a L<CGI> object and a simple value) we can
register it like this:

  use Switch::Perlish::Smatch 'smatch';

  Switch::Perlish::Smatch->register(
    topic   => 'CGI',
    match   => 'VALUE',
    compare => \&cgi_comparator,
  );

So we can now compare simple values with L<CGI> objects e.g

  my $check = $ARGV[0];
  printf "%s $check in params!\n",
         smatch($q, $check) ? 'found' : q[didn't find];

=head2 The default types

There are currently 8 default types, all of which have a complete set of
comparators implemented. These 8 types are:

=over 4

=item VALUE

This type covers simple values which are just strings or numbers.

=item UNDEF

This covers any C<undef>s.

=item SCALAR

This covers all C<SCALAR> references.

=item ARRAY

Covers arrays.

=item HASH

Covers hashes.

=item CODE

Covers coderefs i.e subroutines.

=item OBJECT

Covers any objects whose comparators haven't been specified already.

=item Regexp

Covers C<Regexp> objects.

=back

=head2 How comparators compare

For info on how each comparator works see.
L<Switch::Perlish::Smatch::Comparators>.

=head1 TODO

=over 4

=item *

Add more helper subroutines for common operations that aren't already the
default, and make them easier to access

=item *

Move into own module if people find it sufficiently useful

=item *

Add object functionality perhaps (but who wants that?)

=item *

Maybe add inheritable comparators

=item *

Set __ANON__ to comparator for debugging purposes

=item *

Add support for C<GLOB> (and possibly C<IO>) types

=item *

Store the smatch result somewhere

=item *

Allow for choice of which comparators are reversible in C<register_package()>

=back

=head1 SEE. ALSO

L<Match::Smart>

L<Data::Compare>

L<Switch::Perlish>

=head1 EXPORT_OK

C<smatch> (an alias to C<match>)

C<value_cmp>

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 COPYRIGHT

Copyright (c) 2005, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.

=cut
