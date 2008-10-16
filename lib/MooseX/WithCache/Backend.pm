package MooseX::WithCache::Backend;
use Moose;
use constant DEBUG => $ENV{MOOSEX_WITHCACHE_DEBUG};

has 'cache_name' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'cache_get_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
    lazy => 1,
    builder => 'build_cache_get_method'
);

has 'cache_set_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
    lazy => 1,
    builder => 'build_cache_set_method'
);

has 'cache_del_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
    lazy => 1,
    builder => 'build_cache_del_method'
);

has 'cache_debug_method' => (
    is => 'rw',
    isa => 'Moose::Meta::Method',
    lazy => 1,
    builder => 'build_cache_debug_method'
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
    my ($self, $class) = @_;

    $class->meta->add_attribute( cache_disabled => ( is => 'rw', isa => 'Bool', default => 0 ) );
    $self->install_cache_attr($class);
    $self->install_methods($class);
}

sub install_cache_attr { Carp::confess("install_cache_attr not provided") }
sub build_cache_get_method { Carp::confess("build_cache_get_method not provided") }
sub build_cache_set_method { Carp::confess("build_cache_set_method not provided") }
sub build_cache_del_method { Carp::confess("build_cache_del_method not provided") }
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

sub install_methods {
    my ($self, $class) = @_;

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
