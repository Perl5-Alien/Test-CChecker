use strict;
use warnings;
use Test::More;
use Test::CChecker;

cc;

subtest 'basic' => sub {

  my $r;

  $r = compile_run_ok <<EOF, "basic compile test";
int main(int argc, char *argv[]) { return 0; }
EOF

  ok $r, 'returns okay';

  $r = compile_run_ok { extra_compiler_flags => ['-DFOO_BAR_BAZ=1'], source => <<EOF }, "define test";
#if ! FOO_BAR_BAZ
#include <stdio.h>
#endif
int
main(int argc, char *argv[])
{
#if FOO_BAR_BAZ
  return 0;
#else
  printf("NOT DEFINED");
  return 1;
#endif
}
EOF

  ok $r, 'returns ok';

};

subtest 'compile only' => sub {

  my $r;

  $r = compile_ok <<EOF, "basic compile only test";
extern int foo(void);
int main(int argc, char *argv[]) { return foo(); }
EOF

  ok $r, 'returns okay';

  $r = compile_ok { extra_compiler_flags => ['-DFOO_BAR_BAZ=1'], source => <<EOF }, "define test";
int
main(int argc, char *argv[])
{
#if FOO_BAR_BAZ
  return 0;
#else
  this constitutes a synatax error
#endif
}
EOF

  ok $r, 'returns ok';

};

done_testing;
