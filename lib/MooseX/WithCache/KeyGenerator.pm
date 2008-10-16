# $Id: /mirror/coderepos/lang/perl/MooseX-WithCache/trunk/lib/MooseX/WithCache/KeyGenerator.pm 88178 2008-10-16T07:50:55.595631Z daisuke  $

package MooseX::WithCache::KeyGenerator;
use Moose::Role;

requires 'generate';

no Moose::Role;

1;

__END__

=head1 NAME

MooseX::WithCache::KeyGenerator - KeyGenerator Role

=head1 SYNOPSIS

    package MyKeyGenerator;
    use Moose;

    with 'MooseX::WithCache::KeyGenerator';

    no Moose;

    sub generate {
        my $key = ...;
        return $key;
    }

=cut