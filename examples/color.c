#include <stdint.h>
#include <string.h>

typedef struct color_t {
   char    name[8];
   uint8_t red;
   uint8_t green;
   uint8_t blue;
} color_t;

color_t
color_increase_red(color_t color, uint8_t amount)
{
  strcpy(color.name, "reddish");
  color.red += amount;
  return color;
}
