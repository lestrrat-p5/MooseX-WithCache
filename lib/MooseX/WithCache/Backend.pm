package MooseX::WithCache::Backend;
use Moose;
use constant DEBUG => $ENV{MOOSEX_WITHCACHE_DEBUG};

has 'need_rebuild' => (
    is => 'rw',
    isa => 'Bool',
    default => 1
);

has 'cache_get_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

has 'cache_set_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

has 'cache_del_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

has 'cache_debug_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
);

has 'method_list' => (
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    lazy       => 1,
    builder    => 'build_method_list',
    auto_deref => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub setup {
    my ($self, $args) = @_;

    $self->install_basic_attrs($args);
    $self->install_cache_attr($args);
    $self->install_methods($args);
}

sub install_cache_attr { Carp::confess("install_cache_attr not provided") }
sub build_cache_get_method {
    my ($self, $args) = @_;
    my $name = $args->{cache_name};

    return Moose::Meta::Method->wrap(
        name => 'cache_get',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                if (DEBUG) {
                    $self->cache_debug("cache_get: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
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
    my ($self, $args) = @_;
    my $name = $args->{cache_name};
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

            my $keygen = $self->cache_key_generator;
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
    my ($self, $args) = @_;
    my $name = $args->{cache_name};
    return Moose::Meta::Method->wrap(
        name => 'cache_del',
        package_name => ref $self,
        body => sub {
            my ($self, $key) = @_;
            my $cache = $self->$name;
            if ($self->cache_disabled || ! $cache) {
                if (DEBUG) {
                    $self->cache_debug("cache_set: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
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

sub build_cache_debug_method {
    my $self = shift;
    return Moose::Meta::Method->wrap(
        package_name => Scalar::Util::blessed($self),
        name         => 'cache_debug',
        body         => sub {
            my $self = shift;
            print STDERR "[CACHE]: @_\n";
        }
    );
}

sub install_basic_attrs {
    my ($self, $args) = @_;

    my $class   = $args->{package};
    my $meta    = $class->meta;

    $meta->add_attribute(
        cache_disabled => (
            is => 'rw',
            isa => 'Bool',
            default => 0
        )
    );

    # key generator generates the appropriate cache key from given key(s). 
    $meta->add_attribute(
        cache_key_generator => (
            is      => 'rw',
            does    => 'MooseX::WithCache::KeyGenerator',
        )
    );
}

sub install_methods {
    my ($self, $args) = @_;

    $self->build_methods($args) if $self->need_rebuild;

    my $class   = $args->{package};
    my $meta    = $class->meta;
    my @methods = $self->method_list;
    foreach my $method (@methods) {
        if (DEBUG) {
            print STDERR "[MooseX::WithCache] install method $method on $class\n";
        }
        my $getter = "${method}_method";
        $meta->add_method($method => $self->$getter);
    }
}

sub build_methods {
    my ($self, $args) = @_;

    my @methods = $self->method_list;
    foreach my $method (@methods) {
        my $builder = "build_${method}_method";
        my $setter  = "${method}_method";
        $self->$setter( $self->$builder($args) );
    }
    $self->need_rebuild(0);
}

sub build_method_list { [ qw(cache_get cache_set cache_del cache_debug) ] }

1;

__END__

=head1 NAME

MooseX::WithCache::Backend - Base Class For All Backends

=head1 SYNOPSIS

    package MyBackend;
    use Moose;
    extends 'MooseX::WithCache::Backend';

=head1 METHODS

=head2 build_cache_debug_method

=head2 build_cache_del_method

=head2 build_cache_get_method

=head2 build_cache_set_method

=head2 build_method_list

=head2 install_cache_attr

=head2 install_methods

=head2 setup

=cut
