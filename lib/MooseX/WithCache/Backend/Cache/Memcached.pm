# $Id: /mirror/coderepos/lang/perl/MooseX-WithCache/trunk/lib/MooseX/WithCache/Backend/Cache/Memcached.pm 88178 2008-10-16T07:50:55.595631Z daisuke  $

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
    lazy => 1,
    builder => 'build_cache_get_multi_method'
);

has 'cache_incr_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
    lazy => 1,
    builder => 'build_cache_incr_method'
);

has 'cache_decr_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
    lazy => 1,
    builder => 'build_cache_decr_method'
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub install_cache_attr {
    my ($self, $caller) = @_;

    my $name = $self->cache_name;
    my $meta = $caller->meta;
    $meta->add_attribute($name => (
        is => 'rw',
        isa => 'Cache::Memcached',
    ) );
}

sub build_cache_incr_method {
    my $self = shift;
    my $name = $self->cache_name;
    return Moose::Meta::Method->wrap(
        name => 'cache_incr',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                $self->cache_debug("cache_incr: Cache disabled");
                return ();
            }

            my $keygen = $self->key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            return $cache->incr($cache_key);
        }
    );
}

sub build_cache_decr_method {
    my $self = shift;
    my $name = $self->cache_name;
    return Moose::Meta::Method->wrap(
        name => 'cache_decr',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                $self->cache_debug("cache_decr: Cache disabled");
                return ();
            }

            my $keygen = $self->key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            return $cache->decr($cache_key);
        }
    );
}

sub build_cache_get_multi_method {
    my $self = shift;
    my $name = $self->cache_name;
    return Moose::Meta::Method->wrap(
        name => 'cache_get_multi',
        package_name => ref $self,
        body => sub {
            my ($self, @keys) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                $self->cache_debug("cache_get_multi: Cache disabled");
                return ();
            }

            my $keygen = $self->key_generator;

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

sub build_cache_get_method {
    my $self = shift;
    my $name = $self->cache_name;
    return Moose::Meta::Method->wrap(
        name => 'cache_get',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                $self->cache_debug("cache_get: Cache disabled");
                return ();
            }

            my $keygen = $self->key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            my $cache_ret =  $cache->get($cache_key);
            if (DEBUG) {
                $self->cache_debug(
                    "cache_get: ",
                    defined $cache_ret ? "[HIT]" : "[MISS]",
                    "key =", ($cache_key || '(null)'),
                );
            }
            return $cache_ret;
        }
    );
}

sub build_cache_set_method {
    my $self = shift;
    my $name = $self->cache_name;
    return Moose::Meta::Method->wrap(
        name => 'cache_set',
        package_name => ref $self,
        body => sub {
            my ($self, $key, $value, $expire) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                if (DEBUG) {
                    $self->cache_debug("cache_set: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            if (DEBUG) {
                $self->cache_debug(
                    "cache_set: key =",
                    ($cache_key || '(null)'),
                    ", value =",
                    ($value || '(null)'),
                    ", expire =",
                    ($expire || '(null)')
                );
            }
            return $cache->set($cache_key, $value, $expire);
        }
    );
}

sub build_cache_del_method {
    my $self = shift;
    my $name = $self->cache_name;
    return Moose::Meta::Method->wrap(
        name => 'cache_del',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if (! $cache) {
                return ();
            }

            my $keygen = $self->key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            if (DEBUG) {
                $self->cache_debug(
                    "cache_del: key =",
                    ($cache_key || '(null)'),
                );
            }
            return $cache->delete($cache_key);
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
