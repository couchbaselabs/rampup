#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
  int n = _SC_CLK_TCK;
  if (argc > 1) {
    n = atoi(argv[1]);
  }
  printf("%zd", n);
  return 0;
}
