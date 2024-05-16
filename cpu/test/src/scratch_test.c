volatile int* scratch = (int *)0xFF000000;

int main() {
  *scratch = 42;
  if (*scratch == 42) {
    putchar('a');
  } else {
    putchar('b');
  }
  return 0;
}