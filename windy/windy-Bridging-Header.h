//
//  bridgedHeader.h
//  windy
//
//  Created by Lyndon Leong on 01/01/2023.
//  https://stackoverflow.com/questions/6178860/getting-window-number-through-osx-accessibility-api

#ifndef bridgedHeader_h
#define bridgedHeader_h

#import <AppKit/AppKit.h>

AXError _AXUIElementGetWindow(AXUIElementRef element, uint32_t *identifier);

#endif /* bridgedHeader_h */

