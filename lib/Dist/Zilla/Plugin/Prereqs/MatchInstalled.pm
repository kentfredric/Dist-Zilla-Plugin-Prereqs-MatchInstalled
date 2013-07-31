use strict;
use warnings;

package Dist::Zilla::Plugin::Prereqs::MatchInstalled;
BEGIN {
  $Dist::Zilla::Plugin::Prereqs::MatchInstalled::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Plugin::Prereqs::MatchInstalled::VERSION = '0.1.0';
}

# ABSTRACT: Depend on versions of modules the same as you have installed

use Moose;
use MooseX::Types::Moose qw( HashRef ArrayRef Str );
with 'Dist::Zilla::Role::PrereqSource';


has applyto_phase => ( 
    is => ro =>,
    isa => ArrayRef[Str] =>,
    lazy => 1,
    default => sub { [qw(build test runtime configure develop)] }
);

has applyto_relation => ( 
    is => ro =>
    isa => ArrayRef[Str],
    lazy => 1,
    default => sub { [qw(requires recommends suggests)] }
);

has applyto => (
    is => ro =>,
    isa => ArrayRef[Str] =>,
    lazy => 1,
    builder => _build_applyto =>,
);
has _applyto_list => (
    is => ro =>,
    isa => ArrayRef[ArrayRef[Str]],
    lazy => 1, 
    builder => _build__applyto_list =>,
);

has modules => (
    is => ro =>,
    isa => ArrayRef[Str],
    lazy => 1,
    default => sub { [] }
);
has _modules_hash => ( 
    is => ro =>,
    isa => HashRef,
    lazy => 1,
    builder => _build__modules_hash =>,
);
sub _build_applyto {
    my $self = shift;
    my @out;
    for my $phase (@{ $self->applyto_phase } ) {
        for my $relation (@{ $self->applyto_relation }){ 
            push @out, $phase . q[.] . $relation;
        }
    }
    return \@out;
}
sub _build__applyto_list {
    my $self = shift;
    my @out; 
    for my $type (@{ $self->applyto }) {
        if ( $type =~ /^([^.]+)[.]([^.]+)$/ ) {
            push @out, ["$1", "$2" ];
            next;
        }
        die "<<$type>> does not match << <phase>.<relation> >>";
    }
    return \@out;
}
sub _build__modules_hash {
    my $self = shift;
    return { map { $_ , 1 } @{ $self->modules } };
}
sub mvp_multivalue_args { qw(applyto applyto_relation applyto_phase modules) }
sub mvp_aliases{  return { 'module' => 'modules' }  }
sub current_version_of {
    my ($self, $package ) = @_;
    if ( $package eq 'perl' ){
        # Thats not going to work, Dave.
        return $];
    }
    require Module::Data;
    my $data = Module::Data->new($package);
    return if not $data;
    return $data->version;
}
around dump_config => sub {
    my ( $orig, $self ) = @_;
    my $config = $self->$orig;
    my $this_config = {
        applyto_phase => $self->applyto_phase,
        applyto_relation => $self->applyto_relation,
        applyto          => $self->applyto,
        modules => $self->modules,
    };
    $config->{'' . __PACKAGE__ } = $this_config;
    return $config;
};
sub register_prereqs {
    my ( $self ) = @_;
    my $zilla = $self->zilla;
    my $prereqs = $zilla->prereqs;
    my $guts = $prereqs->cpan_meta_prereqs->{prereqs} || {};
    my $anted = $self->_modules_hash;

    for my $applyto ( @{ $self->_applyto_list } ) {
        my ( $phase, $rel ) = @{$applyto};
        next if not exists $guts->{$phase};
        next if not exists $guts->{$phase}->{$rel};
        my $reqs = $guts->{$phase}->{$rel}->as_string_hash;
        for my $module ( keys %{ $reqs }) {
            next if not exists $self->_modules_hash->{$module};
            my $latest = $self->current_version_of( $module );
            if ( not defined $latest ) {
                warn "You asked for the installed version of $module, and it is a dependency but it is apparently not installed";
                next;
            }

            $zilla->register_prereqs(
                { phase => $phase, type => $rel },
                $module, $latest
            );
        }
    }
}
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::MatchInstalled - Depend on versions of modules the same as you have installed

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

This is based on the code of L<< C<Dist::Zilla::Plugin::Author::KENTNL::Prereqs::Latest::Selective>|Dist::Zilla::Plugin::Author::KENTNL::Prereqs::Latest::Selective >>, but intended for a wider audience.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
