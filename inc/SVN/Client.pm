#line 1
use strict;
use warnings;

use SVN::Core;
use SVN::Wc;

package SVN::Client;
my @_all_fns;
BEGIN {
    @_all_fns =
        qw( version diff_summarize_dup create_context checkout3
            checkout2 checkout update3 update2 update switch2 switch
            add4 add3 add2 add mkdir3 mkdir2 mkdir delete3 delete2
            delete import3 import2 import commit4 commit3 commit2
            commit status3 status2 status log4 log3 log2 log blame4
            blame3 blame2 blame diff4 diff3 diff2 diff diff_peg4
            diff_peg3 diff_peg2 diff_peg diff_summarize2
            diff_summarize diff_summarize_peg2 diff_summarize_peg
            merge3 merge2 merge merge_peg3 merge_peg2 merge_peg
            cleanup relocate revert2 revert resolve resolved copy4
            copy3 copy2 copy move5 move4 move3 move2 move propset3
            propset2 propset revprop_set propget3 propget2
            propget revprop_get proplist3 proplist2 proplist
            revprop_list export4 export3 export2 export list2 list
            ls3 ls2 ls cat2 cat add_to_changelist
            remove_from_changelist lock unlock info2 info
            url_from_path uuid_from_url uuid_from_path open_ra_session
            invoke_blame_receiver2 invoke_blame_receiver
            invoke_diff_summarize_func
          );

    require SVN::Base;
    import SVN::Base (qw(Client svn_client_), @_all_fns);
}

#line 192

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;

    $self->{'ctx'} = SVN::_Client::svn_client_create_context ();

    if (defined($args{'auth'}))
    {
        $self->auth($args{'auth'});
    } else {
        $self->auth([SVN::Client::get_username_provider(),
                     SVN::Client::get_simple_provider(),
                     SVN::Client::get_ssl_server_trust_file_provider(),
                     SVN::Client::get_ssl_client_cert_file_provider(),
                     SVN::Client::get_ssl_client_cert_pw_file_provider(),
                    ]);
    }

    {
        my $pool_type = ref($args{'pool'});
        if ($pool_type eq 'SVN::Pool' ||
            $pool_type eq '_p_apr_pool_t')
        {
            $self->{'pool'} = $args{'pool'};
        } else {
            $self->{'pool'} = new SVN::Pool();
        }
    }

    # If we're passed a config use it, otherwise get the default
    # config.
    if (defined($args{'config'}))
    {
        if (ref($args{'config'}) eq 'HASH')
        {
            $self->config($args{'config'});
        }
    } else {
        $self->config(SVN::Core::config_get_config(undef));
    }

    if (defined($args{'notify'}))
    {
        $self->notify($args{'notify'});
    }

    if (defined($args{'log_msg'}))
    {
        $self->log_msg($args{'log_msg'});
    }

    if (defined($args{'cancel'}))
    {
        $self->cancel($args{'cancel'});
    }

    return $self;
}

#line 857

# import methods into our name space and wrap them in a closure
# to support method calling style $ctx->log()
foreach my $function (@_all_fns)
{
    no strict 'refs';
    my $real_function = \&{"SVN::_Client::svn_client_$function"};
    *{"SVN::Client::$function"} = sub
    {
        my ($self, $ctx);
        my @args;

        # Don't shift the first param if it isn't a SVN::Client
        # object.  This lets the old style interface still work.
        # And is useful for functions like url_from_path which
        # don't take a ctx param, but might be called in method
        # invocation style or as a normal function.
        for (my $index = $[; $index <= $#_; $index++)
        {
            if (ref($_[$index]) eq 'SVN::Client')
            {
                ($self) = splice(@_,$index,1);
                $ctx = $self->{'ctx'};
                last;
            } elsif (ref($_[$index]) eq '_p_svn_client_ctx_t') {
                $self = undef;
                ($ctx) = splice(@_,$index,1);
                last;
            }
        }

        if (!defined($ctx))
        {
            # Allows import to work while not breaking use SVN::Client.
            if ($function eq 'import')
            {
                return;
            }
        }

        if (ref($_[$#_]) eq '_p_apr_pool_t' ||
            ref($_[$#_]) eq 'SVN::Pool')
        {
            # if we got a pool passed to us we need to
            # leave it off until we add the ctx first
            # so we push only the first arg to the next
            # to last arg.
            push @args, @_[$[ .. ($#_ - 1)];
            unless ($function =~ /^(?:propset|url_from_path)$/)
            {
                # propset and url_from_path don't take a ctx argument
                push @args, $ctx;
            }
            push @args, $_[$#_];
        } else {
            push @args, @_;
            unless ($function =~ /^(?:propset|url_from_path)$/)
            {
                push @args,$ctx;
            }
            if (defined($self->{'pool'}) &&
                (ref($self->{'pool'}) eq '_p_apr_pool_t' ||
                 ref($self->{'pool'}) eq 'SVN::Pool'))
            {
                # allow the pool entry in the SVN::Client
                # object to override the default pool.
                push @args, $self->{'pool'};
            }
        }
        return $real_function->(@args);
    }
}

#line 953

sub auth
{
    my $self = shift;
    my $args;
    if (scalar(@_) == 0)
    {
        return $self->{'ctx'}->auth_baton();
    } elsif (scalar(@_) > 1) {
        $args = \@_;
    } else {
        $args = shift;
        if (ref($args) eq '_p_svn_auth_baton_t')
        {
            # 1 arg as an auth_baton so just set
            # the baton.
            $self->{'ctx'}->auth_baton($args);
            return $self->{'ctx'}->auth_baton();
        }
    }

    my ($auth_baton,$callbacks) = SVN::Core::auth_open_helper($args);
    $self->{'auth_provider_callbacks'} = $callbacks;
    $self->{'ctx'}->auth_baton($auth_baton);
    return $self->{'ctx'}->auth_baton();
}

#line 1002

sub notify {
    my $self = shift;
    if (scalar(@_) == 1) {
        $self->{'notify_callback'} = $self->{'ctx'}->notify_baton(shift);
    }
    return ${$self->{'notify_callback'}};
}

#line 1034

sub log_msg {
    my $self = shift;

    if (scalar(@_) == 1) {
        $self->{'log_msg_callback'} = $self->{'ctx'}->log_msg_baton3(shift);
    }
    return ${$self->{'log_msg_callback'}};
}

#line 1067

sub cancel {
    my $self = shift;

    if (scalar(@_) == 1) {
        $self->{'cancel_callback'} = $self->{'ctx'}->cancel_baton(shift);
    }
    return ${$self->{'cancel_callback'}};
}

#line 1086

sub pool
{
    my $self = shift;

    if (scalar(@_) == 0)
    {
        $self->{'pool'};
    } else {
        return $self->{'pool'} = shift;
    }
}
#line 1112

sub config
{
    my $self = shift;
    if (scalar(@_) == 0) {
        return $self->{'ctx'}->config();
    } else {
        $self->{'ctx'}->config(shift);
        return $self->{'ctx'}->config();
    }
}


#line 1259

package _p_svn_info_t;
use SVN::Base qw(Client svn_info_t_);

#line 1338

package _p_svn_client_commit_info_t;
use SVN::Base qw(Client svn_client_commit_info_t_);

#line 1394

package _p_svn_client_commit_item3_t;
use SVN::Base qw(Client svn_client_commit_item3_t_);

#line 1417

package _p_svn_client_ctx_t;
use SVN::Base qw(Client svn_client_ctx_t_);

package _p_svn_client_proplist_item_t;
use SVN::Base qw(Client svn_client_proplist_item_t_);

#line 1439

package SVN::Client::Summarize;
use SVN::Base qw(Client svn_client_diff_summarize_kind_);

#line 1453

package _p_svn_client_diff_summarize_t;
use SVN::Base qw(Client svn_client_diff_summarize_t_);

#line 1509

1;
