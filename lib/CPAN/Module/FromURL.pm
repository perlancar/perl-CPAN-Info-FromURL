package CPAN::Module::FromURL;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use CPAN::Info::FromURL qw(extract_cpan_info_from_url);

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_module_from_url);

our %SPEC;

$SPEC{extract_cpan_module_from_url} = {
    v => 1.1,
    summary => 'Extract/guess CPAN module from a URL',
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
            result => 'Foo::Bar',
        },
        {
            name => 'mcpan/release/DIST',
            args => {url=>'https://metacpan.org/release/Foo-Bar'},
            result => 'Foo::Bar',
        },
        {
            name => 'unknown',
            args => {url=>'https://www.google.com/'},
            result => undef,
        },

    ],
};
sub extract_cpan_module_from_url {
    my $url = shift;

    my $ecires = extract_cpan_info_from_url($url);
    return undef unless $ecires;
    return $ecires->{module} if defined $ecires->{module};
    if (defined(my $mod = $ecires->{dist})) {
        $mod =~ s/-/::/g;
        return $mod;
    }
    undef;
}

1;
# ABSTRACT:

=head1 SEE ALSO

L<CPAN::Info::FromURL>, the more generic module which is used by this module.

L<CPAN::Author::FromURL>

L<CPAN::Dist::FromURL>

L<CPAN::Release::FromURL>
