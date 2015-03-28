//
//  AppDelegate.m
//  FalloutTerminalKeyMapper
//
//  Created by Hugo Gonzalez on 2/28/15.
//  Copyright (c) 2015 mdt. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (nonatomic, retain) NSArray *supportedBundles;
@property BOOL isMuted;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.isMuted = NO;
    self.supportedBundles = @[@"com.googlecode.iterm2", @"com.apple.Terminal"];
    NSArray *soundFiles = @[@"k2", @"k3", @"k4"];
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSKeyDownMask) handler:^(NSEvent *event){
        if (!self.isMuted) {
            uint32_t random_index = arc4random_uniform((uint32_t)soundFiles.count);
            NSString *resoucePath = [[NSBundle mainBundle] pathForResource:event.keyCode != 36 ? soundFiles[random_index] : @"kenter" ofType:@"mp3"];
            NSSound *sound = [[NSSound alloc] initWithContentsOfFile:resoucePath byReference:YES];
            [sound play];
        }
        
        //Toggle Mute
        if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSShiftKeyMask) && (event.modifierFlags & NSControlKeyMask) && event.keyCode == 3) {
            self.isMuted = !self.isMuted;
        }
    }];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(terminalLaunched:)
                                                               name:NSWorkspaceDidLaunchApplicationNotification
                                                             object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(terminalTerminated:)
                                                               name:NSWorkspaceDidTerminateApplicationNotification
                                                             object:nil];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    [self.statusItem setImage:[NSImage imageNamed:@"pipboy_icon"]];
    [self.statusItem setHighlightMode:YES];
}

- (void)terminalLaunched:(NSNotification *)notification {
    if (!self.isMuted) {
        NSRunningApplication *runApp = [[notification userInfo] valueForKey:@"NSWorkspaceApplicationKey"];
        if ([self.supportedBundles containsObject:runApp.bundleIdentifier]) {
            NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"poweron" ofType:@"mp3"];
            NSSound *sound = [[NSSound alloc] initWithContentsOfFile:resourcePath byReference:YES];
            [sound play];
        }
    }
}

- (void)terminalTerminated:(NSNotification *)notification {
    if (!self.isMuted) {
        NSRunningApplication *runApp = [[notification userInfo] valueForKey:@"NSWorkspaceApplicationKey"];
        if ([self.supportedBundles containsObject:runApp.bundleIdentifier]) {
            NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"poweroff" ofType:@"mp3"];
            NSSound *sound = [[NSSound alloc] initWithContentsOfFile:resourcePath byReference:YES];
            [sound play];
        }
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

@end
