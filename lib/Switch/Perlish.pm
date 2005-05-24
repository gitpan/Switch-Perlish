package Switch::Perlish;

require Exporter;
@ISA     = 'Exporter';
@EXPORT  = qw/ switch case default fallthrough stop /;
$VERSION = '1.0.1';

use Switch::Perlish::Smatch;

use strict;
use warnings;

use vars qw/ $MATCH $TOPIC $SWITCH $CASE $FALLING $CSTYLE /;

use constant SUCCESS     => 'Switch::Perlish::Control::_success';
use constant FALLTHROUGH => 'Switch::Perlish::Control::_fallthrough';
use constant STOP        => 'Switch::Perlish::Control::_stop';

sub import {
  no warnings;
  $CSTYLE = pop(@_) eq 'C';
  Switch::Perlish->export_to_level(1, @_);
}

use Carp 'croak';
use Scalar::Util 'reftype';

sub called_by {
  my $name  = $_[0];
  my $depth = defined( $_[1] ) ? $_[1] : 3;
  return +(caller $depth)[3] !~ /::$name$/;
}

## did we leave the switch() from a successful case()?
sub left_ok {
  return ref($_[0]) and ( UNIVERSAL::isa($_[0], SUCCESS)
                     or   UNIVERSAL::isa($_[0], STOP    ) );
}

sub switch {
  local($TOPIC, $SWITCH)  = @_;
  my $line_no = (caller)[2];

  croak "Invalid code block provided: '$SWITCH'"
    unless reftype($SWITCH) eq 'CODE';

  ## restore this if we exit successfully so as not to make debugging trickier
  my $olderr = $@;
  
  ## topicalize the topic for the switch block
  local *_ = \$TOPIC;

  ## we're not falling through until a successful match
  local $FALLING = 0;
  
  ## evaluate switch statement - a successful case (that doesn't fallthrough)
  ## will leave the block with an error object blessed into SUCCESS, but the
  ## user might want to return early for whatever reason, so keep that result
  my @result = eval { $SWITCH->() };
  my $err    = $@;

  ## if something was returned from the block explicitly or a case
  ## succeeded then try to return what seems most appropriate
  if( ( @result and !$err ) or left_ok($err) ) {
    $@ = $olderr;
    my @r = @result ? @result : @$err;
    return defined wantarray ? wantarray ? @r : $r[-1] : ();
  }
  
  die $err
    if $@;
}

{
  package Switch::Perlish::Control::_success;
  package Switch::Perlish::Control::_fallthrough;
  package Switch::Perlish::Control::_stop;
}

## exit the switch block and set $@ to an object containing the resulting code
## btw, this blessing trickery is for people who want the result propagated
sub end_case { die bless \@_, SUCCESS }

sub fallthrough {
  ## make sure we're not called out of context
  croak "Not called within a case statement\n"
    if !called_by('case');
  die bless( \do{
    my $msg = "The fallthrough control exception from Switch::Perlish"
  }, FALLTHROUGH );
}

sub stop {
  ## make sure we're not called out of context
  croak "Not called within a case statement\n"
    if !called_by('case');
  die bless(["The stop control exception from Switch::Perlish"], STOP );
}

sub _exec_block {
  my @ret = eval { $CASE->() };

  ## check for fallthrough control exception
  return
    if ref($@) and UNIVERSAL::isa($@, FALLTHROUGH);

  ## check for stop control exception
  die $@
    if ref($@) and UNIVERSAL::isa($@, STOP);

  ## propagate non-control exception
  die $@
    if $@;
  
  end_case @ret
    unless $CSTYLE and $FALLING;

  return @ret;
}

## have value specific case functions?
sub case {
  ## if you want smatching, use S::P::Smatch::match not S::P::case
  croak "Not called within a switch statement\n"
    if !called_by('switch');
  
  local($MATCH, $CASE) = @_;

  return
    ## keep going if we're falling, otherwise smatch
    unless $CSTYLE and $FALLING
        or Switch::Perlish::Smatch->match($TOPIC, $MATCH);

  ## there's been a match, so keep on falling
  $FALLING = 1
    if $CSTYLE;

  _exec_block;
}

sub default {
  ## make sure we're in a switch block
  croak "Not called within a switch statement\n"
    if !called_by('switch');
  
  local $CASE = $_[0];

  _exec_block;
}

1;

=pod

=head1 NAME

Switch::Perlish - A Perlish implementation of the C<switch> statement.

=head1 VERSION

1.0.1 - Now with C<C> style switch behaviour.

=head1 SYNOPSIS

  use Switch::Perlish;

  switch $var, sub {
    case 'foo',
      sub { print "$var is equal to 'foo'\n" };
    case 42,
      sub { print "$var is equal to 42\n";
            fallthrough };
    case [qw/ foo bar baz /],
      sub { print "$var found in list\n" };
    case { foo => 'bar' },
      sub { print "$var key found in hash\n" };
    case \&func,
      sub { print "$var as arg to func() returned true\n" };
    case $obj,
      sub { print "$var is method in $obj and returned true\n" };
    case qr/\bfoo\b/,
      sub { print "$var matched against foo\n" };
    default
      sub { print "$var did not find a match\n" };
  };

=head1 BACKGROUND

If you're unfamiliar with C<switch> then this is the best place to start. A
C<switch> statement is essentially syntactic sugar for an C<if>/C<elsif>/C<else>
chain where the same C<$variable> is tested in every conditional e.g:

  my $foo = 'a string';
  if($foo eq 'something') {
    print '$foo matched "something"';
  } elsif($foo eq 'a string') {
    print '$foo matched "a string"';
  } else {
    print '$foo matched nothing';
  }

This simply matches C<$foo> against a series of strings, then defaulting to the
last C<else> block if nothing matched. An equivalent C<switch> statement (using
this module) would be:

  use Switch::Perlish;
  my $foo = 'a string';
  switch $foo, sub {
    case 'something',
      sub { print '$foo matched "something"' };
    case 'a string',
      sub { print '$foo matched "a string"'  };
    default
      sub { print '$foo matched nothing' };
  };

So the first argument to C<switch> is the thing to be tested (in code above,
C<$foo>), and the second argument is the block of tests. Each C<case> statement
matches its first argument against C<$foo>, and if the match is successful,
the associated block is executed, so running the above code outputs: C<$foo
matched "a string">.  Note the use of semi-colon at the end of the C<switch>,
C<case> and C<default> calls - they're just simple subroutine calls.

=head1 DESCRIPTION

This is a Perl-oriented implementation of the C<switch> statement. It uses
smart-matching in C<case>s which can be configured and extended by the user.
There is no magical syntax so C<switch>/C<case>/C<default> expect coderefs,
which are most simply provided by anonymous subroutines. By default successful
C<case> statements do not fall through[1]. To fall through a C<case> block
call the C<fallthrough> subroutine explicitly. For C<C> style switch
behaviour[2] simply call the module with an upper-case I<C> i.e

  use Switch::Perlish 'C';

I<< [1] To 'fall through' in a C<case> block means that the C<switch> block
isn't exited upon success >>

I<< [2] upon a C<case> succesfully matching all subsequent C<case>s succeed, to
break from the C<switch> completely use C<end> >>

=head2 Smart Matching

The idea behind I<smart matching> is that the given values are matched
in an intelligent manner, so as to get a meaningful result I<regardless>
of the values' types. This allows for flexible code and a certain amount of
"just do it" when using I<smart matching>. Below is a basic example using
I<smart matching> (which is done implictly in C<case>) where a simple value
is being matched against an array e.g

  use Switch::Perlish;

  my $num = $ARGV[0];
  
  switch $num, sub {
    case undef,
      sub { die "Usage: $0 NUM\n" };
    case [0 .. 10],
      sub { print "Your number was between 0 and 10" };
    case [11 .. 100],
      sub { print "Your number was between 11 and 100" };
    case [101 .. 1000],
      sub { print "Your number was between 101 and 1000" };
    default
      sub { print "Your number was less than 0 or greater than 1000" };
  };

So here the I<smart matching> is checking for the existence of C<$num> in the
provided arrays. In the above code ranges happen to be used, but any array
would suffice. To see how different value types compare with each other see.
L<Switch::Perlish::Smatch::Comparators>, which provides descriptions for all
the default comparator.

The code behind this I<smart matching> can be found in
L<Switch::Perlish::Smatch> which itself delegates to the appropriate comparator
subroutine depending on the value types. See L<Switch::Perlish::Smatch> for more
details on the I<smart matching> implementation and how it can be extended.

=head1 COMPARISON

Because there is an existing module which implements C<switch> this section
intends to provide clarification of the differences that module, L<Switch>
and this one.

=head2 Native vs. New

To create a more natural C<switch> syntax, L<Switch> uses source filters[3],
which facilitate the creation of this natural syntax. C<Switch::Perlish>
however uses the native syntax of perl, so what you code is what you see.
The big advantage of source filtering is the ability to create new syntax,
but it has several disadvantages - the new syntax can conflict with, and
break, existing code, the filtered code can be difficult to debug and because
you can't easily see the post-filtered code it can be difficult to integrate
into production code. The I<raison d'E<ecirc>tre> for this module is to have
the syntax of C<switch> without the baggage that goes with filtered code.

=head2 Extensibility

The L<Switch> module deals with the Perl's types superbly, however, that is all,
so there is no extensibility as such. This module was designed from the outset
to allow an extensibilty of how types are dealt with, i.e how they are compared,
and this is done through the companion module L<Switch::Perlish::Smatch>.

=head2 The C<sub> keyword

Unlike L<Switch>, C<Switch::Perlish> requires the use of the the C<sub> keyword
when creating blocks. This is because there is no standard way of magically
coercing bare blocks into closures, unless one uses the C<(E<amp>)> prototype,
and that is only applicable where it is the first argument. So, for now, 3 extra
keystrokes are necessary when using blocks with C<Switch::Perlish>.

I<< [3] see. L<Filter::Simple> for more info on source filters >>.

=head1 SUBROUTINES

=over 4

=item switch( $topic, $block );

Execute the given C<$block> allowing C<case> statements to access the C<$topic>.
This, along with C<case> and C<default>, will also attempt to return

=item case( $match, $block );

If C<$topic> smart-matches successfully against C<$match> then execute
C<$block> and exit from C<switch>, but if using C<C> style behaviour, then
continue executing the block and all subsequent C<case> C<$block>s until
the end of the current C<switch> or a call to C<end>. I<NB>: this cannot be
called outside of C<switch>, if you want to use I<smart matching> functionality,
see. L<Switch::Perlish::Smatch>.

=item default( $block )

Execute C<$block> and exit from C<switch>. I<NB>: this cannot be called outside of
C<switch>.

=item fallthrough()

Fall through the the current C<case> block. I<NB>: this cannot be called outside
of C<switch>.

=item end()

Use in C<case> blocks exit the surrounding C<switch> block, ideally used with
the C<C> style behaviour as it mimics C<C>'s C<break>. I<NB>: this cannot be
called outside of C<switch>.

=back

=head2 Globals

=over 4

=item C<$SWITCH>

The current C<switch> block.

=item C<$CASE>

The current C<case> block.

=item C<$TOPIC>

The current topic block, also aliased to C<$_>.

=item C<$MATCH>

The current thing being matched against.

=item C<$CSTYLE>

If C<Switch::Perlish> is called with the I<C> argument, this is set to
true and C<C> style behaviour is enabled.

=item C<$FALLING>

Set to true when falling through the current C<switch> block.

=back

=head1 SEE. ALSO

L<Switch>

L<How do I create a switch or case statement?|perlfaq7/"How_do_I_create_a_switch_or_case_statement?">

L<Basic_BLOCKs_and_Switch_Statements|Switch Statements|perlsyn/"Basic_BLOCKs_and_Switch_Statements">

L<Switch::Perlish::Smatch>

L<Switch::Perlish::Smatch::Comparators>

=head1 TODO

=over 4

=item *

Implement localizing comparators

=item *

Test with earlier versions of C<perl>

=item *

Drop C<warnings> for compatibility with older perls?

=back

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 COPYRIGHT

Copyright (c) 2005, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.

=cut
