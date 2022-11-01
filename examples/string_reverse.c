#include <string.h>
#include <stdlib.h>

const char *
string_reverse(const char *input)
{
  static char *output = NULL;
  int i, len;

  if(output != NULL)
    free(output);

  if(input == NULL)
    return NULL;

  len = strlen(input);
  output = malloc(len+1);

  for(i=0; input[i]; i++)
    output[len-i-1] = input[i];
  output[len] = '\0';

  return output;
}
