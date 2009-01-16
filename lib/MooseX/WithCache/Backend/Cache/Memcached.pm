# $Id: /mirror/coderepos/lang/perl/MooseX-WithCache/trunk/lib/MooseX/WithCache/Backend/Cache/Memcached.pm 98660 2009-01-16T08:37:55.393178Z daisuke  $

package MooseX::WithCache::Backend::Cache::Memcached;
use Moose;
use Cache::Memcached;
use constant DEBUG => $ENV{MOOSEX_WITHCACHE_DEBUG};

extends 'MooseX::WithCache::Backend';

around 'build_method_list' => sub {
    my ($next, $self, @args) = @_;
    my $list = $next->($self, @args);
    push @$list, qw(cache_incr cache_decr cache_get_multi);
    return $list;
};

has 'cache_get_multi_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

has 'cache_incr_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

has 'cache_decr_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub install_cache_attr {
    my ($self, $args) = @_;

    my $name = $args->{cache_name};
    my $class = $args->{package};
    my $meta = $class->meta;
    $meta->add_attribute($name => (
        is => 'rw',
        isa => 'Cache::Memcached',
    ) );
}

sub build_cache_incr_method {
    my ($self, $args) = @_;
    my $name = $args->{cache_name};
    return Moose::Meta::Method->wrap(
        name => 'cache_incr',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                if (DEBUG) {
                    $self->cache_debug("cache_incr: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            return $cache->incr($cache_key);
        }
    );
}

sub build_cache_decr_method {
    my ($self, $args) = @_;
    my $name = $args->{cache_name};
    return Moose::Meta::Method->wrap(
        name => 'cache_decr',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                if (DEBUG) {
                    $self->cache_debug("cache_decr: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            return $cache->decr($cache_key);
        }
    );
}

sub build_cache_get_multi_method {
    my ($self, $args) = @_;
    my $name = $args->{cache_name};
    return Moose::Meta::Method->wrap(
        name => 'cache_get_multi',
        package_name => ref $self,
        body => sub {
            my ($self, @keys) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                if (DEBUG) {
                    $self->cache_debug("cache_get_multi: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;

            my @cache_keys = $keygen ? 
                map { $keygen->generate($_) } @keys :
                @keys;
            my %cache_ret = %{ $cache->get_multi(@cache_keys) };
            if (DEBUG) {
                foreach my $key (@cache_keys) {
                    $self->cache_debug(
                        "cache_get_multi: ",
                        exists $cache_ret{$key} ? "[HIT]" : "[MISS]",
                        "key =", ($key || '(null)'),
                    );
                }
            }
            return @cache_ret{ @cache_keys };
        }
    );
}

1;

__END__

=head1 NAME

MooseX::WithCache::Backend::Cache::Memcached - Cache::Memcached Backend

=head1 SYNOPSIS

    package MyObject;
    use MooseX::WithCache;
    with_cache(
        backend => 'Cache::Memcached'
    );

    package main;

    my $obj = MyObject->new(
        cache => Cache::Memcached->new({ ... });
    );

    $obj->cache_get($key);
    $obj->cache_set($key);
    $obj->cache_del($key);
    $obj->cache_incr($key);
    $obj->cache_decr($key);

    # Be careful! 
    #    1. this returns a list!
    #    2. this method is NOT finalized.
    #       its semantics /MIGHT/ be changed!
    my @list = $obj->cache_get_multi(@keys);

=head1 METHODS

=head2 build_cache_decr_method

=head2 build_cache_del_method

=head2 build_cache_get_method

=head2 build_cache_get_multi_method

=head2 build_cache_incr_method

=head2 build_cache_set_method

=head2 install_cache_attr

=cut
