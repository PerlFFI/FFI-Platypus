#include "libtest.h"

typedef struct _color {
  uint8_t red, green, blue;
} color;


EXTERN color *
color_new(int red, int green, int blue)
{
  static color _self;
  color *self = &_self;
  self->red   = red;
  self->green = green;
  self->blue  = blue;
  return self;
}

EXTERN int
color_get_red(color *self)
{
  return self->red;
}

EXTERN void
color_set_red(color *self, int value)
{
  self->red = value;
}

EXTERN int
color_get_green(color *self)
{
  return self->green;
}

EXTERN void
color_set_green(color *self, int value)
{
  self->green = value;
}

EXTERN int
color_get_blue(color *self)
{
  return self->blue;
}

EXTERN void
color_set_blue(color *self, int value)
{
  self->blue = value;
}

EXTERN void
color_DESTROY(color *self)
{
  free(self);
}

EXTERN size_t
color_ffi_record_size()
{
  return sizeof(color);
}
