#ifndef CAXPRIVATE_H
#define CAXPRIVATE_H
#include <ApplicationServices/ApplicationServices.h>

/// Private API that returns the CGWindowID of an AX window element.
AXError _AXUIElementGetWindow(AXUIElementRef element, uint32_t *identifier);

#endif
