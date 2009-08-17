#line 1
use strict;
use warnings;

package SVN::Core;
use SVN::Base qw(Core svn_ VERSION);
# Some build tool hates VERSION assign across two lines.
$SVN::Core::VERSION = "$SVN::Core::VER_MAJOR.$SVN::Core::VER_MINOR.$SVN::Core::VER_MICRO";

#line 47

BEGIN {
    SVN::_Core::apr_initialize();
}

my $gpool = SVN::Pool->new_default;
sub gpool { $gpool } # holding the reference to gpool
SVN::Core::utf_initialize($gpool);

END {
    SVN::_Core::apr_terminate();
}

#line 84

sub auth_open_helper {
    my $args = shift;
    my (@auth_providers,@auth_callbacks);

    foreach my $arg (@{$args}) {
        if (ref($arg) eq '_p_svn_auth_provider_object_t') {
            push @auth_providers, $arg;
        } else {
            push @auth_callbacks, $arg;
        }
    }
    my $auth_baton = SVN::Core::auth_open(\@auth_providers);
    return ($auth_baton,\@auth_callbacks);
}

# import the INVALID and IGNORED constants
our $INVALID_REVNUM = $SVN::_Core::SWIG_SVN_INVALID_REVNUM;
our $IGNORED_REVNUM = $SVN::_Core::SWIG_SVN_IGNORED_REVNUM;

package _p_svn_stream_t;
use SVN::Base qw(Core svn_stream_);

package SVN::Stream;
use IO::Handle;
our @ISA = qw(IO::Handle);

#line 127

use Symbol ();

sub new
{
    my $class = shift;
    my $self = bless Symbol::gensym(), ref($class) || $class;
    tie *$self, $self;
    *$self->{svn_stream} = shift;
    $self;
}

sub svn_stream {
    my $self = shift;
    *$self->{svn_stream};
}

sub TIEHANDLE
{
    return $_[0] if ref($_[0]);
    my $class = shift;
    my $self = bless Symbol::gensym(), $class;
    *$self->{svn_stream} = shift;
    $self;
}

sub CLOSE
{
    my $self = shift;
    *$self->{svn_stream}->close
	if *$self->{svn_stream};
    undef *$self->{svn_stream};
}

sub GETC
{
    my $self = shift;
    my $buf;
    return $buf if $self->read($buf, 1);
    return undef;
}

sub print
{
    my $self = shift;
    $self->WRITE ($_[0], length ($_[0]));
}

sub PRINT
{
    my $self = shift;
    if (defined $\) {
        if (defined $,) {
	    $self->print(join($,, @_).$\);
        } else {
            $self->print(join("",@_).$\);
        }
    } else {
        if (defined $,) {
            $self->print(join($,, @_));
        } else {
            $self->print(join("",@_));
        }
    }
}

sub PRINTF
{
    my $self = shift;
    my $fmt = shift;
    $self->print(sprintf($fmt, @_));
}

sub getline
{
    my $self = shift;
    *$self->{pool} ||= SVN::Core::pool_create (undef);
    my ($buf, $eof) = *$self->{svn_stream}->readline ($/, *$self->{pool});
    return undef if $eof && !length($buf);
    return $eof ? $buf : $buf.$/;
}

sub getlines
{
    die "getlines() called in scalar context\n" unless wantarray;
    my $self = shift;
    my($line, @lines);
    push @lines, $line while defined($line = $self->getline);
    return @lines;
}

sub READLINE
{
    my $self = shift;
    unless (defined $/) {
	my $buf = '';
	while (length( my $chunk = *$self->{svn_stream}->read
	       ($SVN::Core::STREAM_CHUNK_SIZE)) ) {
	    $buf .= $chunk;
	}
	return $buf;
    }
    elsif (ref $/) {
        my $buf = *$self->{svn_stream}->read (${$/});
	return length($buf) ? $buf : undef;
    }
    return wantarray ? $self->getlines : $self->getline;
}

sub READ {
    my $self = shift;
    my $len = $_[1];
    if (@_ > 2) { # read offset
        substr($_[0],$_[2]) = *$self->{svn_stream}->read ($len);
    } else {
        $_[0] = *$self->{svn_stream}->read ($len);
    }
    return $len;
}

sub WRITE {
    my $self = shift;
    my $slen = length($_[0]);
    my $len = $slen;
    my $off = 0;

    if (@_ > 1) {
        $len = $_[1] if $_[1] < $len;
        if (@_ > 2) {
            $off = $_[2] || 0;
            die "Offset outside string" if $off > $slen;
            if ($off < 0) {
                $off += $slen;
                die "Offset outside string" if $off < 0;
            }
            my $rem = $slen - $off;
            $len = $rem if $rem < $len;
        }
	*$self->{svn_stream}->write (substr ($_[0], $off, $len));
    }
    return $len;
}

*close = \&CLOSE;

sub FILENO {
    return undef;   # XXX perlfunc says this means the file is closed
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

package _p_apr_pool_t;

my %WRAPPED;

sub default {
    my ($pool) = @_;
    my $pobj = SVN::Pool->_wrap ($$pool);
    $WRAPPED{$pool} = $pobj;
    $pobj->default;
}

sub DESTROY {
    my ($pool) = @_;
    delete $WRAPPED{$pool};
}

package SVN::Pool;
use SVN::Base qw(Core svn_pool_);

#line 345

{
    # block is here to restrict no strict refs to this block
    no strict 'refs';
    *{"apr_pool_$_"} = *{"SVN::_Core::apr_pool_$_"}
        for qw/clear destroy/;
}

my @POOLSTACK;

sub new {
    my ($class, $parent) = @_;
    $parent = $$parent if ref ($parent) eq 'SVN::Pool';
    my $self = bless \create ($parent), $class;
    return $self;
}

sub new_default_sub {
    my $parent = ref ($_[0]) ? ${+shift} : $SVN::_Core::current_pool;
    my $self = SVN::Pool->new_default ($parent);
    return $self;
}

sub new_default {
    my $self = new(@_);
    $self->default;
    return $self;
}

sub default {
    my $self = shift;
    push @POOLSTACK, $SVN::_Core::current_pool
	unless $$SVN::_Core::current_pool == 0;
    $SVN::_Core::current_pool = $$self;
}

sub clear {
    my $self = shift;
    apr_pool_clear ($$self);
}

my $globaldestroy;

END {
    $globaldestroy = 1;
}

my %WRAPPOOL;

# Create a cloned _p_apr_pool_t pointing to the same apr_pool_t
# but on different address. this allows pools that are from C
# to have proper lifetime.
sub _wrap {
    my ($class, $rawpool) = @_;
    my $pool = \$rawpool;
    bless $pool, '_p_apr_pool_t';
    my $npool = \$pool;
    bless $npool, $class;
    $WRAPPOOL{$npool} = 1;
    $npool;
}

use Scalar::Util 'reftype';

sub DESTROY {
    return if $globaldestroy;
    my $self = shift;
    # for some reason, REF becomes SCALAR in perl -c or after apr_terminate
    return if reftype($self) eq 'SCALAR';
    if ($$self eq $SVN::_Core::current_pool) {
        $SVN::_Core::current_pool = pop @POOLSTACK;
    }
    if (exists $WRAPPOOL{$self}) {
        delete $WRAPPOOL{$self};
    }
    else {
        apr_pool_destroy ($$self)
    }
}

package _p_svn_error_t;
use SVN::Base qw(Core svn_error_t_);

sub strerror {
	return SVN::Error::strerror($_[$[]->apr_err());
}

sub handle_error {
	return SVN::Error::handle_error(@_);
}

sub expanded_message {
	return SVN::Error::expanded_message(@_);
}

sub handle_warning {
	# need to swap parameter order.
	return SVN::Error::handle_warning($_[$[+1],$_[$[]);
}

foreach my $function (qw(compose clear quick_wrap)) {
    no strict 'refs';
    my $real_function = \&{"SVN::_Core::svn_error_$function"};
    *{"_p_svn_error_t::$function"} = sub {
			  return $real_function->(@_);
		}
}

package SVN::Error;
use SVN::Base qw(Core svn_error_);
use SVN::Base qw(Core SVN_ERR_);
use Carp;
our @CARP_NOT = qw(SVN::Base SVN::Client SVN::Core SVN::Delta
                   SVN::Delta::Editor SVN::Error SVN::Fs SVN::Node
									 SVN::Pool SVN::Ra SVN::Ra::Callbacks SVN::Ra::Reporter
									 SVN::Repos SVN::Stream SVN::TxDelta SVN::Wc);

#line 554

# Permit users to determine if they want automatic croaking or not.
our $handler = \&croak_on_error;

# Import functions that don't follow the normal naming scheme.
foreach my $function (qw(handle_error handle_warning strerror)) {
    no strict 'refs';
    my $real_function = \&{"SVN::_Core::svn_$function"};
	  *{"SVN::Error::$function"} = sub {
	      return $real_function->(@_);
		}
}

#line 574

sub expanded_message {
	  my $svn_error = shift;
    unless (is_error($svn_error)) {
	      return undef;
		}

		my $error_message = $svn_error->strerror();
		while ($svn_error) {
		    $error_message .= ': ' . $svn_error->message();
				$svn_error = $svn_error->child();
		}
		return $error_message;
}


#line 597

sub is_error {
		 return (ref($_[$[]) eq '_p_svn_error_t');
}

#line 620

sub croak_on_error {
		unless (is_error($_[$[])) {
			return @_;
		}
    my $svn_error = shift;

		my $error_message = $svn_error->expanded_message();

		$svn_error->clear();

		croak($error_message);
}

#line 641

sub confess_on_error {
		unless (is_error($_[$[])) {
				return @_;
		}
    my $svn_error = shift;

		my $error_message = $svn_error->expanded_message();

		$svn_error->clear();

		confess($error_message);
}

#line 664

sub ignore_error {
    if (is_error($_[$[])) {
		    my $svn_error = shift;
				$svn_error->clear();
		}

		return @_;
}

package _p_svn_log_changed_path_t;
use SVN::Base qw(Core svn_log_changed_path_t_);

#line 698

package SVN::Node;
use SVN::Base qw(Core svn_node_);

#line 710

package _p_svn_opt_revision_t;
use SVN::Base qw(Core svn_opt_revision_t_);

#line 717

package _p_svn_opt_revision_t_value;
use SVN::Base qw(Core svn_opt_revision_t_value_);

package _p_svn_config_t;
use SVN::Base qw(Core svn_config_);

#line 729

package _p_svn_dirent_t;
use SVN::Base qw(Core svn_dirent_t_);

#line 766

package _p_svn_auth_cred_simple_t;
use SVN::Base qw(Core svn_auth_cred_simple_t_);

#line 789

package _p_svn_auth_cred_username_t;
use SVN::Base qw(Core svn_auth_cred_username_t_);

#line 808

package _p_svn_auth_cred_ssl_server_trust_t;
use SVN::Base qw(Core svn_auth_cred_ssl_server_trust_t_);

#line 827

package _p_svn_auth_ssl_server_cert_info_t;
use SVN::Base qw(Core svn_auth_ssl_server_cert_info_t_);

#line 862

package _p_svn_auth_cred_ssl_client_cert_t;
use SVN::Base qw(Core svn_auth_cred_ssl_client_cert_t_);

#line 881

package _p_svn_auth_cred_ssl_client_cert_pw_t;
use SVN::Base qw(Core svn_auth_cred_ssl_client_cert_pw_t_);

#line 900

#line 931

package SVN::Auth::SSL;
use SVN::Base qw(Core SVN_AUTH_SSL_);

package _p_svn_lock_t;
use SVN::Base qw(Core svn_lock_t_);

#line 978

package SVN::MD5;
use overload
    '""' => sub { SVN::Core::md5_digest_to_cstring(${$_[0]})};

sub new {
    my ($class, $digest) = @_;
    bless \$digest, $class;
}

#line 1007

1;
