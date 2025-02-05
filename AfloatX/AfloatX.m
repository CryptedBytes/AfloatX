//
//  AfloatX.m
//  AfloatX
//
//  Created by Jeremy Legendre on 10/11/19.
//Copyright © 2019 Jeremy Legendre. All rights reserved.
//

@import AppKit;
#import "AfloatX.h"
#import "NSWindow+AfloatX.h"
#import "NSApplication+Private.h"
#import "WindowTransparencyController.h"
#import "WindowOutliningController.h"
#import "ZKSwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>

AfloatX *plugin = NULL;

NSMenu *AfloatXMenu;
NSMenuItem *AfloatXItem;
NSMenu *AfloatXSubmenu;
NSMenuItem *floatItem;
NSMenuItem *dropItem;
NSMenuItem *transparencyItem;
NSMenuItem *transientItem;
NSMenuItem *stickyItem;
NSMenuItem *invertColorItem;
NSMenuItem *clickPassthroughItem;
NSMenuItem *windowOutlineItem;
NSMenu *windowOutlineSubmenu;
NSArray *afloatXItems;
CIFilter* colorInvertFilter;
NSMenuItem *lastColorItem;
NSColor* colorWithHexColorString;

@implementation AfloatX

+ (instancetype)sharedInstance {
    if (!plugin) {
        plugin = [[self alloc] init];
    }
    
    return plugin;
}

 /*
  * Blocks all mouse/keyboard actions. Not really worth implementing IMO, but it's here if you want to
- (void)blockMainWindow {
    objc_msgSend([self windowToModify], sel_getUid("_setDisableInteraction:"), YES);
}

- (void)unblockMainWindow {
    objc_msgSend([self windowToModify], sel_getUid("_setDisableInteraction:"), NO);
}
*/

- (BOOL)isWindowTransient:(NSWindow *)window {
    NSUInteger collectionBehavior = [window collectionBehavior];
    if ((NSWindowCollectionBehaviorMoveToActiveSpace & collectionBehavior) ==
        NSWindowCollectionBehaviorMoveToActiveSpace) {
        return YES;
    }
    return NO;
}

- (BOOL)isWindowSticky:(NSWindow *)window {
    NSUInteger collectionBehavior = [window collectionBehavior];
    if ((NSWindowCollectionBehaviorCanJoinAllSpaces & collectionBehavior) ==
        NSWindowCollectionBehaviorCanJoinAllSpaces) {
        return YES;
    }
    return NO;
}

- (BOOL)isMainWindowFloating {
    return [[NSWindow topWindow] isAtCGWindowLevel:kCGFloatingWindowLevel];
}

- (BOOL)isMainWindowDropped {
    return [[NSWindow topWindow] isAtCGWindowLevel:kCGBackstopMenuLevel];
}

- (void)toggleTransientMainWindow {
    if(![self isWindowTransient:[NSWindow topWindow]]) {
        [[NSWindow topWindow] setCollectionBehavior:
            ([[NSWindow topWindow] collectionBehavior] | NSWindowCollectionBehaviorMoveToActiveSpace)];
    } else {
        [[NSWindow topWindow] setCollectionBehavior:
            ([[NSWindow topWindow] collectionBehavior] & ~NSWindowCollectionBehaviorMoveToActiveSpace)];
    }
}

- (void)toggleStickyMainWindow {
    if(![self isWindowSticky:[NSWindow topWindow]]) {
        [[NSWindow topWindow] setCollectionBehavior:
            ([[NSWindow topWindow] collectionBehavior] | NSWindowCollectionBehaviorCanJoinAllSpaces)];
    } else {
        [[NSWindow topWindow] setCollectionBehavior:
            ([[NSWindow topWindow] collectionBehavior] & ~NSWindowCollectionBehaviorCanJoinAllSpaces)];
    }
}

- (void)toggleColorInvert {
    NSWindow *window = [NSWindow topWindow];
    [[window.contentView superview] setWantsLayer:YES];
    
    if (![objc_getAssociatedObject(window, "isColorInverted") boolValue]) {
        [window addFilter:colorInvertFilter];
        objc_setAssociatedObject(window, "isColorInverted", [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
    } else {
        [window removeFilter:colorInvertFilter];
        objc_setAssociatedObject(window, "isColorInverted", [NSNumber numberWithBool:false], OBJC_ASSOCIATION_RETAIN);
    }
}

- (void)toggleEventPassthrough {
    NSWindow *window = [NSWindow topWindow];
    if([window hasLowTag:CGSTagTransparent]) {
        [window removeLowTag:CGSTagTransparent];
    } else {
        [window addLowTag:CGSTagTransparent];
    }
}

- (NSView *)themeFrameToModify {
    return [[[NSWindow topWindow] contentView] superview];
}

- (CALayer *)themeFrameLayer {
    NSView *themeFrame = [self themeFrameToModify];
    themeFrame.wantsLayer = YES;
    return themeFrame.layer;
}

- (void)toggleColor:(NSColor *)color isVisible:(bool)isVisible {
    CALayer *layer = [self themeFrameLayer];
    if(isVisible){
        layer.borderWidth = 3;
        layer.cornerRadius = 10.0f;
        layer.borderColor = color.CGColor;
    }
    else {
        layer.borderWidth = 0.0f;
    }

}


- (void)toggleFloatMainWindow {
    if([self isMainWindowFloating]) {

        [NSWindow setTopWindowCGWindowLevel:kCGNormalWindowLevel];
        [self toggleColor:NULL isVisible:false];
        
    } else {
        [NSWindow setTopWindowCGWindowLevel:kCGFloatingWindowLevel];
        NSColor *outlineColor = NSColor.systemPinkColor;
        //used https://corecoding.com/utilities/rgb-or-hex-to-float.php for color conversion
        NSColor *customOutlineColor = [NSColor colorWithRed:0.922 green:0.655 blue:0.949 alpha:1.0];
        [self toggleColor:customOutlineColor isVisible:true];
    }
}

- (void)toggleDropMainWindow {
    if([self isMainWindowDropped]) {
        [NSWindow setTopWindowCGWindowLevel:kCGNormalWindowLevel];
    } else {
        [NSWindow setTopWindowCGWindowLevel:kCGBackstopMenuLevel];
    }
}

- (void)showTransparencySheet {
    [[WindowTransparencyController sharedInstance] runSheetForWindow:[NSWindow topWindow]];
    if([self isMainWindowFloating]) {
        [NSWindow setTopWindowCGWindowLevel:kCGFloatingWindowLevel];
    }
}

+ (void)load {
    if([NSBundle mainBundle] == NULL)
        return;
    
    if(NSBundle.mainBundle.bundleIdentifier == NULL)
        return;
    
    NSArray *blackList = [[NSArray alloc] initWithObjects:@"com.apple.dock", @"com.vmware.vmware-vmx", @"com.apple.loginwindow", @"com.apple.Spotlight", @"com.apple.SystemUIServer", @"com.apple.screencaptureui", nil];
    if ([blackList containsObject:NSBundle.mainBundle.bundleIdentifier])
        return;
    
    AfloatX *plugin = [AfloatX sharedInstance];
    
    colorInvertFilter = [CIFilter filterWithName:@"CIColorInvert"];
    [colorInvertFilter setDefaults];
    
    AfloatXMenu = [NSMenu new];
    AfloatXItem = [NSMenuItem new];
    AfloatXItem.title = @"AfloatX";
    AfloatXSubmenu = [NSMenu new];
    AfloatXItem.submenu = AfloatXSubmenu;
    
    windowOutlineItem = [NSMenuItem new];
    windowOutlineItem.title = @"Outline Window";
    windowOutlineSubmenu = [NSMenu new];
    windowOutlineItem.submenu = windowOutlineSubmenu;
    
    floatItem = [[NSMenuItem alloc] initWithTitle:@"Float Window" action:@selector(toggleFloatMainWindow) keyEquivalent:@"X"];
    [floatItem setTarget:plugin];

    
    dropItem = [[NSMenuItem alloc] initWithTitle:@"Drop Window" action:@selector(toggleDropMainWindow) keyEquivalent:@""];
    [dropItem setTarget:plugin];
    
    transientItem = [[NSMenuItem alloc] initWithTitle:@"Transient Window" action:@selector(toggleTransientMainWindow) keyEquivalent:@""];
    [transientItem setTarget:plugin];
    
    stickyItem = [[NSMenuItem alloc] initWithTitle:@"Sticky Window" action:@selector(toggleStickyMainWindow) keyEquivalent:@""];
    [stickyItem setTarget:plugin];
    
    invertColorItem = [[NSMenuItem alloc] initWithTitle:@"Invert Colors" action:@selector(toggleColorInvert) keyEquivalent:@""];
    [invertColorItem setTarget:plugin];
    
    clickPassthroughItem = [[NSMenuItem alloc] initWithTitle:@"Click-Through Window" action:@selector(toggleEventPassthrough) keyEquivalent:@""];
    [clickPassthroughItem setTarget:plugin];
    
    transparencyItem = [[NSMenuItem alloc] initWithTitle:@"Transparency..." action:@selector(showTransparencySheet) keyEquivalent:@""];
    [transparencyItem setTarget:plugin];
    
    afloatXItems = [[NSArray alloc] initWithObjects:floatItem,
                    dropItem,
                    invertColorItem,
                    stickyItem,
                    transientItem,
                    clickPassthroughItem,
                    windowOutlineItem,
                    transparencyItem,
                    nil];
    
    for(NSMenuItem *item in afloatXItems)
        [AfloatXSubmenu addItem:item];
        
    [AfloatXMenu addItem:[NSMenuItem separatorItem]];
    [AfloatXMenu addItem:AfloatXItem];
    
    
    __block bool hotkeyModifiersActive = false;
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged
                                                  handler:^(NSEvent* aEvent){
        
//        if( [aEvent modifierFlags] == (NSEventModifierFlagCommand | NSEventModifierFlagShift))
        if( [aEvent modifierFlags] == 1179914)
        {
            NSLog( @"Command + shift was pressed " );
           hotkeyModifiersActive = true;
        }
        else {
            hotkeyModifiersActive = false;
        }
        return aEvent;
        }];
    
    
    NSEvent * (^monitorHandler)(NSEvent *);
    monitorHandler = ^NSEvent * (NSEvent * theEvent){
        NSLog(@"keycode: %hu", [theEvent keyCode]);
        switch ([theEvent keyCode]) {
            case 3:
                NSLog(@"F key");
                if(hotkeyModifiersActive){
                    [plugin toggleFloatMainWindow];
                }
                break;
            
            default:
                break;
        }
        // Return the event, a new event, or, to stop
        // the event from being dispatched, nil
       
        return theEvent;
    };

    // Creates an object we do not own, but must keep track of so that
    // it can be "removed" when we're done; therefore, put it in an ivar.
    Ivar eventMon = (__bridge Ivar)([NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                                                          handler:monitorHandler]);
    
}



@end

ZKSwizzleInterface(AXApplication, NSApplication, NSResponder)
@implementation AXApplication
- (CFArrayRef)_createDockMenu:(BOOL)enabled {
    NSWindow *window = [NSWindow topWindow];
    if(!window) {
        return ZKOrig(CFArrayRef, enabled);
    }
    
    // Make any necessary changes to our menu before it is 'flattened'
    if([plugin isWindowTransient:window]) {
        [transientItem setState:NSControlStateValueOn];
    } else {
        [transientItem setState:NSControlStateValueOff];
    }

    if([plugin isWindowSticky:window]) {
        [stickyItem setState:NSControlStateValueOn];
    } else {
        [stickyItem setState:NSControlStateValueOff];
    }

    CGWindowLevel windowLevel = [window getCGWindowLevel];
    if(windowLevel != kCGNormalWindowLevel) {
        if(windowLevel == kCGBackstopMenuLevel) {
            [dropItem setState:NSControlStateValueOn];
            [floatItem setState:NSControlStateValueOff];
        } else if(windowLevel == kCGFloatingWindowLevel) {
            [floatItem setState:NSControlStateValueOn];
            [dropItem setState:NSControlStateValueOff];
        }
    } else {
        [dropItem setState:NSControlStateValueOff];
        [floatItem setState:NSControlStateValueOff];
    }

    if([window hasLowTag:CGSTagTransparent]) {
        [clickPassthroughItem setState:NSControlStateValueOn];
    } else {
        [clickPassthroughItem setState:NSControlStateValueOff];
    }

    /* Create a new WindowOutliningController per window */
    [windowOutlineSubmenu removeAllItems];
    if (!objc_getAssociatedObject(window, "outlineController")) {
        WindowOutliningController *outlineController = [WindowOutliningController new];
        for(NSMenuItem *item in [outlineController colorItems])
            [windowOutlineSubmenu addItem:item];
        objc_setAssociatedObject(window, "outlineController", outlineController, OBJC_ASSOCIATION_RETAIN);
    } else {
        WindowOutliningController *outlineController = objc_getAssociatedObject(window, "outlineController");
        for(NSMenuItem *item in [outlineController colorItems])
            [windowOutlineSubmenu addItem:item];
    }

    if ([objc_getAssociatedObject(window, "isColorInverted") boolValue]) {
        [invertColorItem setState:NSControlStateValueOn];
    } else {
        [invertColorItem setState:NSControlStateValueOff];
    }
    
    CFMutableArrayRef finalMenu = CFArrayCreateMutable(0, 0, &kCFTypeArrayCallBacks);
    
    CFArrayRef flatDockMenu = ZKOrig(CFArrayRef, enabled);
    CFArrayAppendArray(finalMenu, flatDockMenu, CFRangeMake(0, CFArrayGetCount(flatDockMenu)));
    CFRelease(flatDockMenu);
    CFArrayRef flatAfloatXMenu = [(NSApplication*)self _flattenMenu:AfloatXMenu flatList:nil];
    
    CFArrayAppendArray(finalMenu, flatAfloatXMenu, CFRangeMake(0, CFArrayGetCount(flatAfloatXMenu)));
    CFRelease(flatAfloatXMenu);

    return finalMenu;
}
@end
