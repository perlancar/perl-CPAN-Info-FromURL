package CPAN::Release::FromURL;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use CPAN::Info::FromURL qw(extract_cpan_info_from_url);

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_release_from_url);

our %SPEC;

$SPEC{extract_cpan_release_from_url} = {
    v => 1.1,
    summary => 'Extract CPAN release (tarball) name from a URL',
    args => {
        url => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str',
    },
    result_naked => 1,
    examples => [

        {
            name => "mcpan/pod/MOD",
            args => {url=>'https://metacpan.org/pod/Foo::Bar'},
            result => undef,
        },
        {
            name => "mcpan/pod/release/AUTHOR/DIST-VERSION/lib/MOD.pm",
            args => {url=>'http://metacpan.org/pod/release/SRI/Mojolicious-6.46/lib/Mojo.pm'},
            result => undef,
        },
        {
            name => "cpan/authors/id/A/AU/AUTHOR/DIST-VER.tar.gz",
            args => {url=>'file:/cpan/authors/id/S/SR/SRI/Mojolicious-6.46.tar.gz'},
            result => 'Mojolicious-6.46.tar.gz',
        },
        {
            name => 'unknown',
            args => {url=>'https://www.google.com/'},
            result => undef,
        },
    ],
};
sub extract_cpan_release_from_url {
    my $url = shift;

    my $ecires = extract_cpan_info_from_url($url);
    return undef unless defined $ecires;
    $ecires->{release};
}

1;
# ABSTRACT:

=head1 SEE ALSO

L<CPAN::Info::FromURL>, the more generic module which is used by this module.

L<CPAN::Author::FromURL>

L<CPAN::Dist::FromURL>

L<CPAN::Module::FromURL>
