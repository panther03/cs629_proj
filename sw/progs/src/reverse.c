int main() {
  char s[256];
  int i;
  int c = 0;// getchar();

  for (i = 0; c != -1 && i < 256; i++) {
    s[i] = c;
    c = 0;//getchar();
  }

  for (; i > 0; i--) {
    putchar(s[i-1]);
  }

  putchar('\n');

  return 0;
}
