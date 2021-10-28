//
//  AppDelegate.m
//  SCDynamicStoreViewer
//
//  Created by Danil Korotenko on 10/27/21.
//

#import "AppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet NSTextView *textView;

@end

@implementation AppDelegate
{
    NSMutableDictionary *_outlineViewItems;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self refreshItems];
    [self.outlineView reloadData];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app
{
    return YES;
}

#pragma mark Outline view data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
    NSDictionary *currentItem = nil;

    if ([item isKindOfClass:[NSString class]])
    {
        currentItem = [_outlineViewItems objectForKey:item];
    }
    else
    {
        currentItem = (item == nil) ? _outlineViewItems : (NSDictionary*)item;
    }

    return [[currentItem[@"children"] allKeys] count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
    NSDictionary *currentItem = nil;

    if ([item isKindOfClass:[NSString class]])
    {
        currentItem = [_outlineViewItems objectForKey:item];
    }
    else
    {
        currentItem = (item == nil) ? _outlineViewItems : (NSDictionary*)item;
    }

    NSString *itemKey = [[currentItem[@"children"] allKeys] objectAtIndex:index];
    return [currentItem[@"children"] objectForKey:itemKey];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    NSDictionary *currentItem = nil;

    if ([item isKindOfClass:[NSString class]])
    {
        currentItem = [_outlineViewItems objectForKey:item];
    }
    else
    {
        currentItem = (item == nil) ? _outlineViewItems : (NSDictionary*)item;
    }

    return [currentItem[@"children"] count] > 0;
}

- (nullable id)outlineView:(NSOutlineView *)outlineView
    objectValueForTableColumn:(nullable NSTableColumn *)tableColumn byItem:(nullable id)item
{
    NSDictionary *currentItem = (item == nil) ? _outlineViewItems : (NSDictionary*)item;

    return [currentItem objectForKey:@"title"];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSDictionary *selectedItem = [self.outlineView itemAtRow:[self.outlineView selectedRow]];

    NSString *fullPath = selectedItem[@"fullPath"];

    if (fullPath != nil)
    {
        CFStringRef fullPathRef = (__bridge CFStringRef)(fullPath);
        CFPropertyListRef propertyList = SCDynamicStoreCopyValue(NULL, fullPathRef);
        NSDictionary *value = CFBridgingRelease(propertyList);

        [self.textView setString:[value description]];
    }
    else
    {
        [self.textView setString:@""];
    }
}

#pragma mark -

- (void)refreshItems
{
    if (_outlineViewItems == nil)
    {
        _outlineViewItems = [NSMutableDictionary dictionary];
        _outlineViewItems[@"children"] = [NSMutableDictionary dictionary];
    }

    CFArrayRef keysRef = SCDynamicStoreCopyKeyList(NULL, CFSTR(".*"));

    NSArray *keys = CFBridgingRelease(keysRef);

//    NSLog(@"%@", keys);

    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@":/"];

    NSMutableDictionary *currentDictionary = _outlineViewItems;

    for (NSString *item in keys)
    {
        currentDictionary = _outlineViewItems;
        NSArray *components = [item componentsSeparatedByCharactersInSet:charSet];
        for (NSString *component in components)
        {
            if (component.length == 0)
            {
                continue;
            }
            NSMutableDictionary *currentItem = currentDictionary[@"children"][component];
            if (currentItem == nil )
            {
                NSMutableDictionary *newItem = [NSMutableDictionary dictionary];
                if ([[components lastObject] isEqualTo:component]) // it is a last item
                {
                    newItem[@"fullPath"] = item;
                }
                newItem[@"title"] = component;
                newItem[@"children"] = [NSMutableDictionary dictionary];

                currentDictionary[@"children"][component] = newItem;

                currentDictionary = newItem;
            }
            else
            {
                currentDictionary = currentItem;
            }
        }
    }

}

@end
