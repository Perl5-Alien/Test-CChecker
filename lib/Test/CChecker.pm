package Test::CChecker;

use strict;
use warnings;
use base qw( Test::Builder::Module );
use ExtUtils::CChecker;
use Capture::Tiny qw( capture_merged );
use Text::ParseWords qw( shellwords );
use Env qw( @LD_LIBRARY_PATH );
use File::Spec;
use FindBin ();
use Scalar::Util qw( blessed );

our @EXPORT = qw(
  cc
  compile_run_ok
  compile_with_alien
  compile_output_to_nowhere
  compile_output_to_diag
  compile_output_to_note
);

# ABSTRACT: test-time utilities for checking C headers, libraries, or OS features
# VERSION

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module is a very thin convenience wrapper around L<ExtUtils::CChecker> to make
it useful for use in a test context.  It is intended for use with Alien modules
which need to verify that libraries work as intended with the Compiler and
flags used by Perl to build XS modules.

By default this module is very quiet, hiding all output using L<Capture::Tiny>
unless there is a failure, in which case you will see the commands, flags and
output used.

=head1 FUNCTIONS

All documented functions are exported into your test's namespace

=head2 cc

 my $cc = cc;

Returns the ExtUtils::CChecker object used for testing.

This is mainly useful for adding compiler or linker flags:

 cc->push_extra_compiler_flags('-DFOO=1');
 cc->push_extra_linker_flags('-L/foo/bar/baz', '-lfoo')

=cut

do {
  my $cc;
  sub cc ()
  {
    unless(defined $cc)
    {
      $cc = ExtUtils::CChecker->new;
    }
    $cc;
  }
};

=head2 compile_run_ok

 compile_run_ok $c_source, $message;

 compile_run_ok {
   source => $c_source,
   extra_compiler_flags => \@cflags,
   extra_linker_flags => \@libs,
 }, $message;

This test attempts to compile the given c_source and passes if it
runs with return value of zero.  The first argument can be either
a string containing the C source code, or a hashref (which will
be passed unmodified as a hash to L<ExtUtils::CChecker> C<try_compile_run>).

If the test fails, then the complete output will be reported using
L<Test::More> C<diag>.

You can have it report the output on success with L<#compile_output_to_diag>
or L<#compile_output_to_note>.

=cut

my $output = '';

sub compile_run_ok ($;$)
{
  my($args, $message) = @_;
  $message ||= "compile ok";
  my $cc = cc();
  my $tb = __PACKAGE__->builder;
  
  # TODO: fix in CChecker so that we don't have to do this.
  local $cc->cbuilder->{quiet} = 0;
  
  my $ok;
  my $out = capture_merged { $ok = $cc->try_compile_run(ref($args) eq 'HASH' ? %$args : $args) };
  
  $tb->ok($ok, $message);
  if(!$ok || $output eq 'diag')
  {
    $tb->diag($out);
  }
  elsif($output eq 'note')
  {
    $tb->note($out);
  }
}

=head2 compile_with_alien

 use Alien::Foo;
 compile_with_alien 'Alien::Foo';

Specifies an Alien module to use to get compiler flags and libraries.  You
may pass in either the name of the class (it must already be loaded), or
an instance of that class.  The instance of the Alien class is expected to
implement C<cflags> and C<libs> methods that return the compiler and library
flags respectively.

If you are testing an Alien module after it has been built, but before it has
been installed (for example if you are writing the test suite FOR the Alien
module itself), you need to install to a temporary directory named C<_test>.
If you are using L<Alien::Base>, the easiest way to do this is to add a 
C<make install> with C<DISTDIR> set to C<_test>:

 Alien::Base::Module::Build->new(
   ...
   "alien_build_commands" => [
     "%pconfigure --prefix=%s",
     "make",
     "make DESTDIR=`pwd`/../../_test install",
   ],
   ...
 )->create_build_script;

or if you are using L<Dist::Zilla>, something like this:

 [Alien]
 build_command = %pconfigure --prefix=%s --disable-bsdtar --disable-bsdcpio
 build_command = make
 build_command = make DESTDIR=`pwd`/../../_test install

=cut

sub compile_with_alien ($)
{
  my $alien = shift;
  $alien = $alien->new unless ref $alien;

  if($alien->can('dist_dir'))
  {
    my $dir = File::Spec->catdir($alien->dist_dir, 'lib');
    unshift @LD_LIBRARY_PATH, $dir if -d $dir;
  }
  
  my $tdir = File::Spec->catdir($FindBin::Bin, File::Spec->updir, '_test');
  if(-d $tdir)
  {
    cc->push_extra_compiler_flags(map {
      /^-I(.*)$/ ? ("-I".File::Spec->catdir($tdir, $1), $_) : ($_)
    } shellwords $alien->cflags);
    cc->push_extra_linker_flags(map {
      /^-L(.*)$/ ? ( map { push @LD_LIBRARY_PATH, $_; "-L$_" } File::Spec->catdir($tdir, $1), $_) : ($_)
    } shellwords $alien->libs);
  }
  else
  {
    cc->push_extra_compiler_flags(shellwords $alien->cflags);
    cc->push_extra_linker_flags(shellwords $alien->libs);
  }

  return;
}

=head2 compile_output_to_nowhere

 compile_output_to_nowhere

Do not report output unless there is a failure.  This is the default behavior.

=cut

sub compile_output_to_nowhere ()
{
  $output = '';
}

=head2 compile_output_to_diag

 compile_output_to_diag;

Report output using L<Test::More> C<diag> on success (output is always reported on failure using C<daig>).

=cut

sub compile_output_to_diag ()
{
  $output = 'diag';
}

=head2 compile_output_to_note

 compile_output_to_note;

Report output using L<Test::More> C<note> on success (output is always reported on failure using C<diag>).

=cut

sub compile_output_to_note ()
{
  $output = 'note';
}

1;
