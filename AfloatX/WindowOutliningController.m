//
//  WindowOutliningController.m
//  AfloatX
//
//  Created by j on 1/19/20.
//  Copyright © 2020 j. All rights reserved.
//

#import "WindowOutliningController.h"
#import "NSWindow+AfloatX.h"

@interface WindowOutliningController ()
@property (strong) NSColor *NSColorWhite;
@property (strong) NSColor *NSColorBlack;
@property (strong) NSColor *NSColorRed;
@property (strong) NSColor *NSColorGreen;
@property (strong) NSColor *NSColorBlue;
@property (strong) NSColor *NSColorYellow;
@property (strong) NSColor *NSColorOrange;
@property (strong) NSColor *NSColorPurple;
@property (assign) NSMenuItem *lastColorItem;
@end

@implementation WindowOutliningController

- (NSView *)themeFrameToModify {
    return [[[NSWindow topWindow] contentView] superview];
}

- (CALayer *)themeFrameLayer {
    NSView *themeFrame = [self themeFrameToModify];
    themeFrame.wantsLayer = YES;
    return themeFrame.layer;
}

- (void)toggleColor:(NSColor *)color forItem:(NSMenuItem *)item {
    CALayer *layer = [self themeFrameLayer];
    if(item.state == NSControlStateValueOn) {
        layer.borderWidth = 0.0f;
        item.state = NSControlStateValueOff;
    } else {
        layer.borderWidth = 1.5;
        layer.borderColor = color.CGColor;
        item.state = NSControlStateValueOn;
    }
    
    if(self.lastColorItem)
        self.lastColorItem.state = NSControlStateValueOff;
    
    self.lastColorItem = item;
}

- (void)toggleWhiteColor:(NSMenuItem *)sender {
    [self toggleColor:self.NSColorWhite forItem:sender];
}

- (void)toggleBlackColor:(NSMenuItem *)sender {
    [self toggleColor:self.NSColorBlack forItem:sender];
}

- (void)toggleRedColor:(NSMenuItem *)sender {
    [self toggleColor:self.NSColorRed forItem:sender];
}

- (void)toggleGreenColor:(NSMenuItem *)sender {
    [self toggleColor:self.NSColorGreen forItem:sender];
}

- (void)toggleBlueColor:(NSMenuItem *)sender {
    [self toggleColor:self.NSColorBlue forItem:sender];
}

- (void)toggleYellowColor:(NSMenuItem *)sender {
    [self toggleColor:self.NSColorYellow forItem:sender];
}

- (void)toggleOrangeColor:(NSMenuItem *)sender {
    [self toggleColor:self.NSColorOrange forItem:sender];
}

- (void)togglePurpleColor:(NSMenuItem *)sender {
    [self toggleColor:self.NSColorPurple forItem:sender];
}

- (instancetype)init {
    self = [super init];
    if(self) {
        self.NSColorWhite = [NSColor whiteColor];
        self.NSColorBlack = [NSColor blackColor];
        self.NSColorRed = [NSColor systemRedColor];
        self.NSColorGreen = [NSColor systemGreenColor];
        self.NSColorBlue = [NSColor systemBlueColor];
        self.NSColorYellow = [NSColor systemYellowColor];
        self.NSColorOrange = [NSColor systemOrangeColor];
        self.NSColorPurple = [NSColor systemPurpleColor];

        self.whiteItem = [[NSMenuItem alloc] initWithTitle:@"White" action:@selector(toggleWhiteColor:) keyEquivalent:@""];
        [self.whiteItem setTarget:self];
        
        self.blackItem = [[NSMenuItem alloc] initWithTitle:@"Black" action:@selector(toggleBlackColor:) keyEquivalent:@""];
        [self.blackItem setTarget:self];
        
        self.redItem = [[NSMenuItem alloc] initWithTitle:@"Red" action:@selector(toggleRedColor:) keyEquivalent:@""];
        [self.redItem setTarget:self];
        
        self.greenItem = [[NSMenuItem alloc] initWithTitle:@"Green" action:@selector(toggleGreenColor:) keyEquivalent:@""];
        [self.greenItem setTarget:self];
        
        self.blueItem = [[NSMenuItem alloc] initWithTitle:@"Blue" action:@selector(toggleBlueColor:) keyEquivalent:@""];
        [self.blueItem setTarget:self];
        
        self.yellowItem = [[NSMenuItem alloc] initWithTitle:@"Yellow" action:@selector(toggleYellowColor:) keyEquivalent:@""];
        [self.yellowItem setTarget:self];
        
        self.orangeItem = [[NSMenuItem alloc] initWithTitle:@"Orange" action:@selector(toggleOrangeColor:) keyEquivalent:@""];
        [self.orangeItem setTarget:self];
        
        self.purpleItem = [[NSMenuItem alloc] initWithTitle:@"Purple" action:@selector(togglePurpleColor:) keyEquivalent:@""];
        [self.purpleItem setTarget:self];
        
        self.colorItems = [[NSArray alloc] initWithObjects: self.whiteItem,
                                                            self.blackItem,
                                                            self.redItem,
                                                            self.greenItem,
                                                            self.blueItem,
                                                            self.yellowItem,
                                                            self.orangeItem,
                                                            self.purpleItem,
                                                            nil];
    }
    return self;
}
@end
