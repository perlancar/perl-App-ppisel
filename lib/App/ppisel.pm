package App::ppisel;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;
use Scalar::Util qw(blessed);

our %SPEC;

$SPEC{ppisel} = {
    v => 1.1,
    summary => 'Select PPI::Element nodes using CSel syntax',
    args => {
        %App::CSelUtils::foosel_args_common,
    },
};
sub ppisel {
    App::CSelUtils::foosel(
        @_,
        code_read_tree => sub {
            my $args = shift;

            my $src;
            if ($args->{file} eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $src = join "", <>;
            } else {
                require File::Slurper;
                $src = File::Slurper::read_text($args->{file});
            }
            require PPI;
            my $doc = PPI::Document->new(\$src);

          PATCH: {
                last if $App::ppisel::patch_handle;
                require Module::Patch;
                $App::ppisel::patch_handle = Module::Patch::patch_package(
                    'PPI::Element', [
                        {
                            action   => 'add',
                            sub_name => 'children',
                            code     => sub {
                                $_[0]->{children} // [];
                            },
                        },
                    ], # patch actions
                ); # patch_package()
            } # PATCH
            $doc;
        }, # code_read_tree

        csel_opts => {class_prefixes=>['PPI::Token', 'PPI']},

        code_transform_node_actions => sub {
            my $args = shift;

            for my $action (@{$args->{node_actions}}) {
                if ($action eq 'print' || $action eq 'print_as_string') {
                    $action = 'print_method:content';
                } elsif ($action eq 'dump') {
                    $action = 'dump:content';
                }
            }
        }, # code_transform_node_actions
    );
}

1;
#ABSTRACT:

=head1 SYNOPSIS


=head1 SEE ALSO
