/* Probe P10: ABI facts observable from NXP powerpc-eabivle GCC 4.9.4 output.
   Compiled with -O2 -S for several -mcpu / float options by run-probes.sh. */
#include <stdarg.h>

struct S3 { char c[3]; };
struct S8 { int a, b; };
struct S16 { double d; int i; };

int sizes[] = { sizeof(long double), sizeof(double), sizeof(long long),
                __alignof__(long long), __alignof__(double),
                __alignof__(struct S16) };

extern void sink(void *);
extern double dsink(double, float, long long, struct S8, struct S3);

int frame_align(int n) {
  char buf[n];
  sink(buf);
  return 0;
}

double call_mix(void) {
  struct S8 s8 = {1, 2};
  struct S3 s3 = {{1, 2, 3}};
  return dsink(1.5, 2.5f, 3LL, s8, s3);
}

float fadd(float a, float b) { return a + b; }
double dadd(double a, double b) { return a + b; }

struct S16 ret_struct(void) { struct S16 r = {1.0, 2}; return r; }

int va(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int r = va_arg(ap, int);
  double d = va_arg(ap, double);
  va_end(ap);
  return r + (int)d;
}

long long mul64(long long a, long long b) { return a * b; }

int big_const(void) { return 0x12345678; }

int loop_sum(const int *p, int n) {
  int s = 0;
  for (int i = 0; i < n; ++i)
    s += p[i];
  return s;
}
