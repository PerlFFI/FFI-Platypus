#include <string.h>
#include <stdlib.h>

char *
string_crypt(const char *input, int len, const char *key)
{
  char *output;
  int i, n;

  if(input == NULL)
    return NULL;

  output = malloc(len+1);
  output[len] = '\0';

  for(i=0, n=0; i<len; i++, n++) {
    if(key[n] == '\0')
      n = 0;
    output[i] = input[i] ^ key[n];
  }

  return output;
}

void
string_crypt_free(char *output)
{
  if(output != NULL)
    free(output);
}
