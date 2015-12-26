# Test::CChecker [![Build Status](https://secure.travis-ci.org/plicease/Test-CChecker.png)](http://travis-ci.org/plicease/Test-CChecker)

Test-time utilities for checking C headers, libraries, or OS features

# SYNOPSIS

    use Alien::Foo;
    use Test::CChecker;
    
    compile_with_alien 'Alien::Foo';
    
    compile_run_ok <<C_CODE, "basic compile test";
    int
    main(int argc, char *argv[])
    {
      return 0;
    }
    C_CODE

# DESCRIPTION

**NOTE**: The intention of this module was always to test [Alien](https://metacpan.org/pod/Alien) modules
(both [Alien::Base](https://metacpan.org/pod/Alien::Base) based and non-[Alien::Base](https://metacpan.org/pod/Alien::Base) based modules).  It has a number
of shortcomings that I believe to be better addressed by [Test::Alien](https://metacpan.org/pod/Test::Alien),
so please consider using that for new projects, or even migrating existing code.

This module is a very thin convenience wrapper around [ExtUtils::CChecker](https://metacpan.org/pod/ExtUtils::CChecker) to make
it useful for use in a test context.  It is intended for use with Alien modules
which need to verify that libraries work as intended with the Compiler and
flags used by Perl to build XS modules.

By default this module is very quiet, hiding all output using [Capture::Tiny](https://metacpan.org/pod/Capture::Tiny)
unless there is a failure, in which case you will see the commands, flags and
output used.

# FUNCTIONS

All documented functions are exported into your test's namespace

## cc

    my $cc = cc;

Returns the ExtUtils::CChecker object used for testing.

This is mainly useful for adding compiler or linker flags:

    cc->push_extra_compiler_flags('-DFOO=1');
    cc->push_extra_linker_flags('-L/foo/bar/baz', '-lfoo')

## compile\_run\_ok

    compile_run_ok $c_source, $message;

    compile_run_ok {
      source => $c_source,
      extra_compiler_flags => \@cflags,
      extra_linker_flags => \@libs,
    }, $message;

This test attempts to compile the given c\_source and passes if it
runs with return value of zero.  The first argument can be either
a string containing the C source code, or a hashref (which will
be passed unmodified as a hash to [ExtUtils::CChecker](https://metacpan.org/pod/ExtUtils::CChecker) `try_compile_run`).

If the test fails, then the complete output will be reported using
[Test::More](https://metacpan.org/pod/Test::More) `diag`.

You can have it report the output on success with ["compile\_output\_to\_diag"](#compile_output_to_diag)
or ["compile\_output\_to\_note"](#compile_output_to_note).

In addition to the pass/fail and diagnostic output, this function
will return true or false on success and failure respectively.

## compile\_ok

    compile_ok $c_source, $message;

    compile_ok {
      source => $c_source,
      extra_compiler_flags => \@cflags,
    }, $message;

This is like ["compile\_run\_ok"](#compile_run_ok), except it stops after compiling and
does not attempt to link or run.

## compile\_with\_alien

    use Alien::Foo;
    compile_with_alien 'Alien::Foo';

Specifies an Alien module to use to get compiler flags and libraries.  You
may pass in either the name of the class (it must already be loaded), or
an instance of that class.  The instance of the Alien class is expected to
implement `cflags` and `libs` methods that return the compiler and library
flags respectively.

If you are testing an Alien module after it has been built, but before it has
been installed (for example if you are writing the test suite FOR the Alien
module itself), you need to install to a temporary directory named `_test`.
If you are using [Alien::Base](https://metacpan.org/pod/Alien::Base), the easiest way to do this is to add a 
`make install` with `DISTDIR` set to `_test`:

    Alien::Base::Module::Build->new(
      ...
      "alien_build_commands" => [
        "%pconfigure --prefix=%s",
        "make",
        "make DESTDIR=`pwd`/../../_test install",
      ],
      ...
    )->create_build_script;

or if you are using [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla), something like this:

    [Alien]
    build_command = %pconfigure --prefix=%s --disable-bsdtar --disable-bsdcpio
    build_command = make
    build_command = make DESTDIR=`pwd`/../../_test install

## compile\_output\_to\_nowhere

    compile_output_to_nowhere

Do not report output unless there is a failure.  This is the default behavior.

## compile\_output\_to\_diag

    compile_output_to_diag;

Report output using [Test::More](https://metacpan.org/pod/Test::More) `diag` on success (output is always reported on failure using `daig`).

## compile\_output\_to\_note

    compile_output_to_note;

Report output using [Test::More](https://metacpan.org/pod/Test::More) `note` on success (output is always reported on failure using `diag`).

# AUTHOR

Graham Ollis &lt;plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
