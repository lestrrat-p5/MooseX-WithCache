#line 1
use strict;
use warnings;

package SVN::Delta;
use SVN::Base qw(Delta svn_delta_);

#line 95

package SVN::TxDelta;
use SVN::Base qw(Delta svn_txdelta_ apply);

*new = *SVN::_Delta::svn_txdelta;

# special case for backward compatibility.  When called with an additional
# argument "md5", it's the old style and don't return the md5.
# Note that since the returned m5 is to be populated upon the last window
# sent to the handler, it's not currently working to magically change things
# in Perl land.
sub apply {
    if (@_ == 5 || (@_ == 4 && ref($_[-1]) ne 'SVN::Pool' && ref($_[-1]) ne '_p_apr_pool_t')) {
	splice(@_, 3, 1);
	my @ret = SVN::_Delta::svn_txdelta_apply(@_);
	return @ret[1,2];
    }
    goto \&SVN::_Delta::svn_txdelta_apply;
}

package _p_svn_txdelta_op_t;
use SVN::Base qw(Delta svn_txdelta_op_t_);

package _p_svn_txdelta_window_t;
use SVN::Base qw(Delta svn_txdelta_window_t_);

package SVN::Delta::Editor;
use SVN::Base qw(Delta svn_delta_editor_);

*invoke_set_target_revision = *SVN::_Delta::svn_delta_editor_invoke_set_target_revision;

sub convert_editor {
    my $self = shift;
    $self->{_editor} = $_[0], return 1
	if UNIVERSAL::isa ($_[0], __PACKAGE__);
    if (ref($_[0]) && $_[0]->isa('_p_svn_delta_editor_t')) {
	@{$self}{qw/_editor _baton/} = @_;
	return 1;
    }
    return 0;
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    unless ($self->convert_editor(@_)) {
	%$self = @_;
	$self->convert_editor (@{$self->{_editor}})
	    if $self->{_editor};
    }

    return $self;
}

our $AUTOLOAD;

sub AUTOLOAD {
    no warnings 'uninitialized';
    return unless $_[0]->{_editor};
    my $class = ref($_[0]);
    my $func = $AUTOLOAD;
    $func =~ s/.*:://;
    warn "$func: ".join(',',@_)."\n" if $_[0]->{_debug};
    return unless $func =~ m/[^A-Z]/;

    my %ebaton = ( set_target_revision => 1,
		   open_root => 1,
		   close_edit => 1,
		   abort_edit => 1,
		 );

    my $self = shift;
    no strict 'refs';

    my @ret = UNIVERSAL::isa ($self->{_editor}, __PACKAGE__) ?
	$self->{_editor}->$func (@_) :
        eval { &{"invoke_$func"}($self->{_editor},
				 $ebaton{$func} ? $self->{_baton} : (), @_) };

    die $@ if $@;

    return @ret ? $#ret == 0 ? $ret[0] : [@ret] : undef;
}

#line 204

1;
