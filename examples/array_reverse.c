void
array_reverse(int a[], int len) {
  int tmp, i;

  for(i=0; i < len/2; i++) {
    tmp = a[i];
    a[i] = a[len-i-1];
    a[len-i-1] = tmp;
  }
}

void
array_reverse10(int a[10]) {
  array_reverse(a, 10);
}
