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
  isa => ArrayRef [Str] =>,
  lazy    => 1,
  default => sub { [qw(build test runtime configure develop)] },
);

has applyto_relation => (
  is => ro => isa => ArrayRef [Str],
  lazy    => 1,
  default => sub { [qw(requires recommends suggests)] },
);

has applyto => (
  is => ro =>,
  isa => ArrayRef [Str] =>,
  lazy    => 1,
  builder => _build_applyto =>,
);
has _applyto_list => (
  is => ro =>,
  isa => ArrayRef [ ArrayRef [Str] ],
  lazy    => 1,
  builder => _build__applyto_list =>,
);

has modules => (
  is => ro =>,
  isa => ArrayRef [Str],
  lazy    => 1,
  default => sub { [] },
);
has _modules_hash => (
  is      => ro                   =>,
  isa     => HashRef,
  lazy    => 1,
  builder => _build__modules_hash =>,
);

sub _build_applyto {
  my $self = shift;
  my @out;
  for my $phase ( @{ $self->applyto_phase } ) {
    for my $relation ( @{ $self->applyto_relation } ) {
      push @out, $phase . q[.] . $relation;
    }
  }
  return \@out;
}

sub _build__applyto_list {
  my $self = shift;
  my @out;
  for my $type ( @{ $self->applyto } ) {
    if ( $type =~ /^ ([^.]+) [.] ([^.]+) $/msx ) {
      push @out, [ "$1", "$2" ];
      next;
    }
    return $self->log_fatal(["<<%s>> does not match << <phase>.<relation> >>", $type ]);
  }
  return \@out;
}

sub _build__modules_hash {
  my $self = shift;
  return { map { $_, 1 } @{ $self->modules } };
}
sub mvp_multivalue_args { qw(applyto applyto_relation applyto_phase modules) }
sub mvp_aliases { return { 'module' => 'modules' } }

sub current_version_of {
  my ( $self, $package ) = @_;
  if ( $package eq 'perl' ) {

    # Thats not going to work, Dave.
    return $];
  }
  require Module::Data;
  my $data = Module::Data->new($package);
  return if not $data;
  return if not -e -f $data->path;
  return $data->version;
}
around dump_config => sub {
  my ( $orig, $self ) = @_;
  my $config      = $self->$orig;
  my $this_config = {
    applyto_phase    => $self->applyto_phase,
    applyto_relation => $self->applyto_relation,
    applyto          => $self->applyto,
    modules          => $self->modules,
  };
  $config->{ '' . __PACKAGE__ } = $this_config;
  return $config;
};

sub register_prereqs {
  my ($self)  = @_;
  my $zilla   = $self->zilla;
  my $prereqs = $zilla->prereqs;
  my $guts = $prereqs->cpan_meta_prereqs->{prereqs} || {};
  my $anted = $self->_modules_hash;

  for my $applyto ( @{ $self->_applyto_list } ) {
    my ( $phase, $rel ) = @{$applyto};
    next if not exists $guts->{$phase};
    next if not exists $guts->{$phase}->{$rel};
    my $reqs = $guts->{$phase}->{$rel}->as_string_hash;
    for my $module ( keys %{$reqs} ) {
      next if not exists $self->_modules_hash->{$module};
      my $latest = $self->current_version_of($module);
      if ( not defined $latest ) {
        $self->log([q[You asked for the installed version of %s, and it is a dependency but it is apparently not installed], $module ]);
        next;
      }
      $zilla->register_prereqs( { phase => $phase, type => $rel }, $module, $latest );
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

    [Prereqs::MatchInstalled]
    module = My::Module

B<NOTE:> Dependencies will only be upgraded to match the I<Installed> version if they're found elsewhere in the dependency tree.

This is designed so that it integrates with other automated version provisioning.

If you're hard-coding module deps instead, you will want to place this module I<after> other modules that declare deps.

For instance:

    [Prereqs]
    Foo = 0

    [Prereqs::MatchInstalled]
    module = Foo

^^ C<Foo> will be upgraded to the version installed.

By default, dependencies that match values of C<module> will be upgraded when they are found in:

    phase: build, test, runtime, configure, develop
    relation: depends, suggests, recommends

To change this behavior, specify one or more of the following parameters:

    applyto_phase = build
    applyto_phase = configure

    applyto_relation = requires

etc.

For more complex demands, this also works:

    applyto = build.requires
    applyto = configure.recommends

And that should hopefully be sufficient to cover any conceivable usecase.

Also note, we don't do any sort of sanity checking on the module list you provide.

For instance,

    module = strict
    module = warning

Will both upgrade the strict and warnings dependencies on your module, regardless of how daft an idea that may be.

And with a little glue

    module = perl

Does what you want, but you probably shouldn't rely on that =).

=begin MetaPOD::JSON v1.1.0

    {
        "namespace":"Dist::Zilla::Plugin::Prereqs::MatchInstalled",
        "interface":"class",
        "inherits":"Moose::Object",
        "does":["Dist::Zilla::Role::PrereqSource","Dist::Zilla::Role::Plugin","Dist::Zilla::Role::ConfigDumper"]
    }


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
