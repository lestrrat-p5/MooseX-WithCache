#line 1
use strict;
use warnings;

package SVN::Ra;
use SVN::Base qw(Ra);
use File::Temp;

#line 470

require SVN::Client;

my $ralib = SVN::_Ra::svn_ra_init_ra_libs(SVN::Core->gpool);

# Ra methods that returns reporter
my %reporter = map { $_ => 1 } qw(do_diff do_switch do_status do_update);
our $AUTOLOAD;

sub AUTOLOAD {
    my $class = ref($_[0]);
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return unless $method =~ m/[^A-Z]/;

    my $self = shift;
    no strict 'refs';

    my $func = $self->{session}->can($method)
        or die "no such method $method";

    my @ret = $func->($self->{session}, @_);
    # XXX - is there any reason not to use \@ret in this line:
    return bless [@ret], 'SVN::Ra::Reporter' if $reporter{$method};
    return $#ret == 0 ? $ret[0] : @ret;
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    %$self = $#_ ? @_ : (url => $_[0]);

    if (defined($self->{auth})) {
        if (ref($self->{auth}) ne '_p_svn_auth_baton_t') {
            # If the auth is already set to a auth_baton ignore it
            # otherwise make an auth_baton and store the callbacks
            my ($auth_baton, $auth_callbacks) =
                                SVN::Core::auth_open_helper($self->{auth});
            $self->{auth} = $auth_baton;
            $self->{auth_provider_callbacks} = $auth_callbacks;
        }
    } else {
        # no callback to worry about with a username provider so just call
        # auth_open directly
        $self->{auth} = SVN::Core::auth_open(
                             [SVN::Client::get_username_provider()]);
    }

    my $pool = $self->{pool} ||= SVN::Pool->new;
    my $callback = 'SVN::Ra::Callbacks';

    # custom callback namespace
    if ($self->{callback} && !ref($self->{callback})) {
        $callback = delete $self->{callback};
    }
    # instantiate callbacks
    $callback = (delete $self->{callback}) || $callback->new(auth => $self->{auth});

    $self->{session} = SVN::_Ra::svn_ra_open($self->{url}, $callback, $self->{config} || {}, $pool);
    return $self;
}

sub DESTROY { }

package _p_svn_ra_session_t;
use SVN::Base qw(Ra svn_ra_);

package SVN::Ra::Reporter;
use SVN::Base qw(Ra svn_ra_reporter2_);

#line 608

our $AUTOLOAD;
sub AUTOLOAD {
    my $class = ref($_[0]);
    $AUTOLOAD =~ s/^${class}::(SUPER::)?//;
    return if $AUTOLOAD =~ m/^[A-Z]/;

    my $self = shift;
    no strict 'refs';

    my $method = $self->can("invoke_$AUTOLOAD")
        or die "no such method $AUTOLOAD";

    no warnings 'uninitialized';
    $method->(@$self, @_);
}

package SVN::Ra::Callbacks;

#line 634

require SVN::Core;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    %$self = @_;
    return $self;
}

sub open_tmp_file {
    local $^W; # silence the warning for unopened temp file
    my ($self, $pool) = @_;
    my ($fd, $name) = SVN::Core::io_open_unique_file(
        ( File::Temp::tempfile(
            'XXXXXXXX', OPEN => 0, DIR => File::Spec->tmpdir
        ))[1], 'tmp', 1, $pool
    );
    return $fd;
}

sub get_wc_prop {
    return undef;
}

#line 678

1;
