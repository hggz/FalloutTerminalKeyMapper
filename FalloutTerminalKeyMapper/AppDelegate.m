//
//  AppDelegate.m
//  FalloutTerminalKeyMapper
//
//  Created by Hugo Gonzalez on 2/28/15.
//  Copyright (c) 2015 mdt. All rights reserved.
//

#import "AppDelegate.h"
#import <ApplicationServices/ApplicationServices.h>

@interface AppDelegate ()
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (nonatomic, retain) NSArray *supportedBundles;
@property BOOL isMuted;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	self.isMuted = NO;
	self.supportedBundles = @[@"com.googlecode.iterm2", @"com.apple.Terminal", @"io.cool-retro-term"];
	NSArray *soundFiles = @[@"k2", @"k3", @"k4"];
	
	[NSEvent addGlobalMonitorForEventsMatchingMask:(NSKeyDownMask) handler:^(NSEvent *event){
		
		BOOL terminalIsActive = NO;
		
		// Keyboard shortcuts
		if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSShiftKeyMask) && (event.modifierFlags & NSControlKeyMask)) {
			if (event.keyCode == kVK_ANSI_K) {		//Toggle Mute
				[self toggleMute];
			}else if (event.keyCode == kVK_ANSI_L){		//Toggle Terminals Only setting
				[self togglePlayMode];
			}
		}
		
		BOOL onlyPlayOnTerminal = [[[NSUserDefaults standardUserDefaults] objectForKey:@"terminalsOnly"] boolValue];
		if (onlyPlayOnTerminal) { //Determine if terminal is active
			for (NSRunningApplication *currApp in [[NSWorkspace sharedWorkspace] runningApplications]) {
				if ([currApp isActive] && [self.supportedBundles containsObject:currApp.bundleIdentifier]) {
					
					terminalIsActive = YES; break;
				}
			}
		}
		
		if (!self.isMuted && (terminalIsActive || !onlyPlayOnTerminal)) {
			uint32_t random_index = arc4random_uniform((uint32_t)soundFiles.count);
			NSString *resoucePath = [[NSBundle mainBundle] pathForResource:event.keyCode != 36 ? soundFiles[random_index] : @"kenter" ofType:@"mp3"];
			NSSound *sound = [[NSSound alloc] initWithContentsOfFile:resoucePath byReference:YES];
			[sound play];
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
	
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:28];
	[self.statusItem setMenu:self.statusMenu];
    NSImage *icon = [NSImage imageNamed:@"pipboy_icon"];
    icon.size = CGSizeMake(self.statusMenu.size.height, self.statusMenu.size.height);
	[self.statusItem setImage:icon];
    
	[self.statusItem setHighlightMode:YES];
	
	[self setMenuItems];
    
    if (!AXIsProcessTrusted()) { // Listening for keyboard input requires this app to have accessibility permission.
        [self requestAccessibilityPermission]; // Pops up a dialog asking user to grant the app accessibility status.
    }
}

-(void)setMenuItems{
	NSMenu *menu = [[NSMenu alloc] init];
	
	NSMenuItem *muteItem = [[NSMenuItem alloc]initWithTitle:@"" action:@selector(toggleMute) keyEquivalent:@"k"];
	if (self.isMuted) {
		[muteItem setTitle:@"Unmute SFX"];
	}else{
		[muteItem setTitle:@"Mute SFX"];
	}
	[muteItem setKeyEquivalentModifierMask: NSShiftKeyMask | NSCommandKeyMask | NSControlKeyMask];
	[menu addItem:muteItem];
	
	BOOL onlyPlayOnTerminal = [[[NSUserDefaults standardUserDefaults] objectForKey:@"terminalsOnly"] boolValue];
	NSMenuItem *playModeItem = [[NSMenuItem alloc]initWithTitle:@"" action:@selector(togglePlayMode) keyEquivalent:@"l"];
	if (onlyPlayOnTerminal) {
		[playModeItem setTitle:@"Play SFX always"];
	}else{
		[playModeItem setTitle:@"Play SFX in terminal only"];
	}
	[playModeItem setKeyEquivalentModifierMask: NSShiftKeyMask | NSCommandKeyMask | NSControlKeyMask];
	[menu addItem:playModeItem];
	
	[menu addItem:[NSMenuItem separatorItem]]; // A thin grey line
	[menu addItemWithTitle:@"Quit Fallout Terminal SFX" action:@selector(terminate:) keyEquivalent:@""];
	_statusItem.menu = menu;
}

-(void)toggleMute{
	self.isMuted = !self.isMuted;
	[self setMenuItems];
}
-(void)togglePlayMode{
	BOOL onlyPlayOnTerminal = [[[NSUserDefaults standardUserDefaults] objectForKey:@"terminalsOnly"] boolValue];
	[[NSUserDefaults standardUserDefaults] setObject:@(!onlyPlayOnTerminal)
											  forKey:@"terminalsOnly"];
	[self setMenuItems];
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

-(void)requestAccessibilityPermission{
    // 10.9 and later
    const void * keys[] = { kAXTrustedCheckOptionPrompt };
    const void * values[] = { kCFBooleanTrue };
    
    CFDictionaryRef options = CFDictionaryCreate(kCFAllocatorDefault,
                                                 keys,
                                                 values,
                                                 sizeof(keys) / sizeof(*keys),
                                                 &kCFCopyStringDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);
    AXIsProcessTrustedWithOptions(options);
}

enum {
	kVK_ANSI_A                    = 0x00,
	kVK_ANSI_S                    = 0x01,
	kVK_ANSI_D                    = 0x02,
	kVK_ANSI_F                    = 0x03,
	kVK_ANSI_H                    = 0x04,
	kVK_ANSI_G                    = 0x05,
	kVK_ANSI_Z                    = 0x06,
	kVK_ANSI_X                    = 0x07,
	kVK_ANSI_C                    = 0x08,
	kVK_ANSI_V                    = 0x09,
	kVK_ANSI_B                    = 0x0B,
	kVK_ANSI_Q                    = 0x0C,
	kVK_ANSI_W                    = 0x0D,
	kVK_ANSI_E                    = 0x0E,
	kVK_ANSI_R                    = 0x0F,
	kVK_ANSI_Y                    = 0x10,
	kVK_ANSI_T                    = 0x11,
	kVK_ANSI_1                    = 0x12,
	kVK_ANSI_2                    = 0x13,
	kVK_ANSI_3                    = 0x14,
	kVK_ANSI_4                    = 0x15,
	kVK_ANSI_6                    = 0x16,
	kVK_ANSI_5                    = 0x17,
	kVK_ANSI_Equal                = 0x18,
	kVK_ANSI_9                    = 0x19,
	kVK_ANSI_7                    = 0x1A,
	kVK_ANSI_Minus                = 0x1B,
	kVK_ANSI_8                    = 0x1C,
	kVK_ANSI_0                    = 0x1D,
	kVK_ANSI_RightBracket         = 0x1E,
	kVK_ANSI_O                    = 0x1F,
	kVK_ANSI_U                    = 0x20,
	kVK_ANSI_LeftBracket          = 0x21,
	kVK_ANSI_I                    = 0x22,
	kVK_ANSI_P                    = 0x23,
	kVK_ANSI_L                    = 0x25,
	kVK_ANSI_J                    = 0x26,
	kVK_ANSI_Quote                = 0x27,
	kVK_ANSI_K                    = 0x28,
	kVK_ANSI_Semicolon            = 0x29,
	kVK_ANSI_Backslash            = 0x2A,
	kVK_ANSI_Comma                = 0x2B,
	kVK_ANSI_Slash                = 0x2C,
	kVK_ANSI_N                    = 0x2D,
	kVK_ANSI_M                    = 0x2E,
	kVK_ANSI_Period               = 0x2F,
	kVK_ANSI_Grave                = 0x32,
	kVK_ANSI_KeypadDecimal        = 0x41,
	kVK_ANSI_KeypadMultiply       = 0x43,
	kVK_ANSI_KeypadPlus           = 0x45,
	kVK_ANSI_KeypadClear          = 0x47,
	kVK_ANSI_KeypadDivide         = 0x4B,
	kVK_ANSI_KeypadEnter          = 0x4C,
	kVK_ANSI_KeypadMinus          = 0x4E,
	kVK_ANSI_KeypadEquals         = 0x51,
	kVK_ANSI_Keypad0              = 0x52,
	kVK_ANSI_Keypad1              = 0x53,
	kVK_ANSI_Keypad2              = 0x54,
	kVK_ANSI_Keypad3              = 0x55,
	kVK_ANSI_Keypad4              = 0x56,
	kVK_ANSI_Keypad5              = 0x57,
	kVK_ANSI_Keypad6              = 0x58,
	kVK_ANSI_Keypad7              = 0x59,
	kVK_ANSI_Keypad8              = 0x5B,
	kVK_ANSI_Keypad9              = 0x5C
};

@end
