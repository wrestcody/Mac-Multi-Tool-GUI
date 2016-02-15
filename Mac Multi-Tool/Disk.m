/*
 * The MIT License (MIT)
 *
 * Application: NTFS OS X
 * Copyright (c) 2015 Jeevanandam M. (jeeva@myjeeva.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

//
//  Disk.m
//  NTFS-OSX
//
//  Created by Jeevanandam M. on 6/5/15.
//  Copyright (c) 2015 myjeeva.com. All rights reserved.
//


#import "Disk.h"
#import "Arbitration.h"
#import <IOKit/kext/KextManager.h>
//#import "CommandLine.h"
//#import "STPrivilegedTask.h"
#include <sys/param.h>
#include <sys/mount.h>


@implementation Disk

@synthesize BSDName;
@synthesize icon;
@synthesize desc;
@synthesize volumeUUID;
@synthesize diskUUID;
@synthesize volumeName;
@synthesize volumePath;
@synthesize mediaName;
//@synthesize favoriteItem;
@synthesize description;

@synthesize parent;
@synthesize children;
@synthesize isExpanded;


#pragma mark - Public Methods

+ (Disk *)getDiskForDisk:(Disk *)theDisk {
    for (Disk *disk in allDisks) {
        if ([disk isEqual:theDisk]) {
            return disk;
        }
    }
    
    return nil;
}

+ (Disk *)getDiskForDARef:(DADiskRef)diskRef {
	for (Disk *disk in allDisks) {
		if (disk.hash == CFHash(diskRef)) {
			return disk;
		}
	}

	return nil;
}

+ (Disk *)getDiskForUserInfo:(NSDictionary *)userInfo {
	NSString *devicePath = [userInfo objectForKey:@"NSDevicePath"];

	for (Disk *disk in allDisks) {
		if ([disk.volumePath isEqualToString:devicePath]) {
			return disk;
		}
	}

	return nil;
}

# pragma mark - Other methods

- (DADiskRef)getDiskRef {
    if (_diskRef) return (DADiskRef)_diskRef;
    return nil;
}

# pragma mark - Instance Methods

- (id)initWithDADiskRef:(DADiskRef)diskRef {

	NSAssert(diskRef, @"Disk reference cannot be NULL");
    
	// using existing reference
	Disk *foundOne = [Disk getDiskForDARef:diskRef];
	if (foundOne) {
		return foundOne;
	}

	self = [self init];
	if (self) {
        isExpanded = NO;
        if (!children) children = [[NSMutableArray alloc] init];
        
        //Create self stuff
		_diskRef = CFRetain(diskRef);

		CFDictionaryRef diskDesc = DADiskCopyDescription(diskRef);
		desc = CFRetain(diskDesc);
        
        description = (NSDictionary *)CFBridgingRelease(diskDesc);
        
		BSDName = [[NSString alloc] initWithUTF8String:DADiskGetBSDName(diskRef)];

		CFUUIDRef uuidRef = CFDictionaryGetValue(diskDesc, kDADiskDescriptionVolumeUUIDKey);
        if (uuidRef != NULL) {
            volumeUUID = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidRef));
        } else {
            volumeUUID = @"";
        }
        
        CFUUIDRef diskUuidRef = CFDictionaryGetValue(diskDesc, kDADiskDescriptionMediaUUIDKey);
        if (diskUuidRef != NULL) {
            diskUUID = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, diskUuidRef));
        } else {
            diskUUID = @"";
        }
        //Check if has parent - and create parent if necessary
        if (self.isWholeDisk == NO) {
            
            DADiskRef parentRef = DADiskCopyWholeDisk(diskRef);
            
            if (parentRef) {
                Disk *parentDisk = [[Disk alloc] initWithDADiskRef:parentRef];
                if (parentDisk) {
                    parent = parentDisk;
                    //[[parent mutableSetValueForKey:@"children"] addObject:self];
                    [parent.children addObject:self];
                }
                CFRelease(parentRef);
            }
        } else {
            [diskArray addObject:self];
        }
        [allDisks addObject:self];
	}

	return self;
}

- (void)dealloc {
    if (desc != NULL) CFRelease(desc);
	if (_diskRef != NULL) CFRelease(_diskRef);
	//if (favoriteItem != NULL) CFRelease(favoriteItem);
}

- (void)disappeared {
    //Remove self from total list - and from parent's children list
	[diskArray removeObject:self];
    [allDisks removeObject:self];
    [parent.children removeObject:self];
    
    //Remove all children
    self.parent = nil;
    [children removeAllObjects];
}

/*- (void)mount {
	[CommandLine run:[NSString stringWithFormat:@"diskutil mount /dev/%@", self.BSDName]];
}

- (void)unmount {
	[CommandLine run:[NSString stringWithFormat:@"diskutil unmount /dev/%@", self.BSDName]];
}*/

#pragma mark - Disk commands

- (void)mount
{
    [self mountAtPath:nil withArguments:[NSArray array]];
}

- (void)mountWhole
{
    [self mountWholeDiskAtPath:nil withArguments:[NSArray array]];
}

- (void)mountAtPath:(NSString *)path withArguments:(NSArray *)args
{
    NSAssert(self.isMountable, @"Disk isn't mountable.");
    NSAssert(self.isMounted == NO, @"Disk is already mounted.");
    
    self.isMounting = YES;
    
    //Log(LOG_DEBUG, @"%s mount %@ at mountpoint: %@ arguments: %@", __func__, BSDName, path, args.description);
    
    // ensure arg list is NULL terminated
    CFStringRef *argv = calloc(args.count + 1, sizeof(CFStringRef));
    NSURL *url = path ? [NSURL fileURLWithPath:path.stringByExpandingTildeInPath] : NULL;
    
    CFArrayGetValues((__bridge CFArrayRef)args, CFRangeMake(0, args.count), (const void **)argv );
    DADiskMountWithArguments((DADiskRef) _diskRef, (CFURLRef) url, kDADiskMountOptionDefault,
                             DiskMountCallback, (__bridge void * _Nullable)(self), argv);
    
    free(argv);
}

- (void)mountWholeDiskAtPath:(NSString *)path withArguments:(NSArray *)args
{
    //NSAssert(self.isMountable, @"Disk isn't mountable.");
    //NSAssert(self.isMounted == NO, @"Disk is already mounted.");
    
    self.isMounting = YES;
    
    // ensure arg list is NULL terminated
    CFStringRef *argv = calloc(args.count + 1, sizeof(CFStringRef));
    NSURL *url = path ? [NSURL fileURLWithPath:path.stringByExpandingTildeInPath] : NULL;
    
    CFArrayGetValues((__bridge CFArrayRef)args, CFRangeMake(0, args.count), (const void **)argv );
    DADiskMountWithArguments((DADiskRef) _diskRef, (CFURLRef) url, kDADiskMountOptionWhole,
                             DiskMountCallback, (__bridge void * _Nullable)(self), argv);
    
    free(argv);
}

- (void)unmountWithOptions:(NSUInteger)options
{
    NSAssert(self.isMountable, @"Disk isn't mountable.");
    NSAssert(self.isMounted, @"Disk isn't mounted.");
    
    DADiskUnmount((DADiskRef) _diskRef, (DADiskUnmountOptions)options, DiskUnmountCallback, (__bridge void * _Nullable)(self));
}

- (void)eject
{
    NSAssert1(self.isEjectable, @"Disk is not ejectable: %@", self);
    
    DADiskEject((DADiskRef) _diskRef, kDADiskEjectOptionDefault, DiskEjectCallback, (__bridge void * _Nullable)(self));
}

#pragma mark - Properties

- (NSUInteger)hash {
	return CFHash(_diskRef);
}

- (BOOL)isEqual:(id)object {
	return (CFHash(_diskRef) == [object hash]);
}

- (void)setDesc:(CFDictionaryRef)descUpdate {
	if (descUpdate && descUpdate != desc) {
		if (desc != NULL) CFRelease(desc);
		desc = CFRetain(descUpdate);
	}
}

- (CFDictionaryRef)desc {
	return desc;
}

- (NSString *)volumeName {
	CFStringRef nameRef = CFDictionaryGetValue(desc, kDADiskDescriptionVolumeNameKey);
	return (__bridge NSString *)nameRef;
}

- (NSString *)volumePath {
    CFURLRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionVolumePathKey) : NULL;
    NSURL *url = (__bridge NSURL *)value;
    return [url path];
}

- (NSString *)mediaName {
    CFStringRef mediaRef = CFDictionaryGetValue(desc, kDADiskDescriptionMediaNameKey);
    return (__bridge NSString *)mediaRef;
}

- (NSNumber *)mediaSize {
    return (NSNumber *) CFDictionaryGetValue(desc, kDADiskDescriptionMediaSizeKey);
}

- (NSString *)volumeKind {
    return (NSString *) CFDictionaryGetValue(desc, kDADiskDescriptionVolumeKindKey);
}

- (NSString *)deviceProtocol {
    return (NSString *) CFDictionaryGetValue(desc, kDADiskDescriptionDeviceProtocolKey);
}

- (NSString *)mediaContent {
    return (NSString *) CFDictionaryGetValue(desc, kDADiskDescriptionMediaContentKey);
}

- (NSString *)volumeFS {
    return (NSString *) CFDictionaryGetValue(desc, CFSTR("DAVolumeType"));
}

- (NSNumber *)freeSpace {
    if (![self volumePath]) return nil;
    
    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[self volumePath] error:nil];
    
    unsigned long long size = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
    
    return [NSNumber numberWithLongLong:size];
}

- (NSNumber *)usedSpace {
    if (![self freeSpace]) return nil;
    
    long mediaSize = [[self mediaSize] longValue];
    long freeSpace = [[self freeSpace] longValue];
    
    long usedSpace = (mediaSize-freeSpace);
    
    return [NSNumber numberWithLongLong:usedSpace];
}

- (NSString *)formattedUsedSpace {
    NSNumber *usedSpace = [self usedSpace];
    NSString *sizeDisplayValue = nil;
    if (usedSpace) {
        double size = [usedSpace doubleValue];
        if (size > 999 && size < 1000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f KB", (size / 1000.0)];
        else if (size > 999999 && size < 1000000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f MB", (size / 1000000.0)];
        else if (size > 999999999 && size < 1000000000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f GB", (size / 1000000000.0)];
        else if (size > 999999999999)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f TB", (size / 1000000000000.0)];
    }
    return sizeDisplayValue;
}

- (NSString *)formattedFreeSpace {
    NSNumber *freeSpace = [self freeSpace];
    NSString *sizeDisplayValue = nil;
    if (freeSpace) {
        double size = [freeSpace doubleValue];
        if (size > 999 && size < 1000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f KB", (size / 1000.0)];
        else if (size > 999999 && size < 1000000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f MB", (size / 1000000.0)];
        else if (size > 999999999 && size < 1000000000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f GB", (size / 1000000000.0)];
        else if (size > 999999999999)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f TB", (size / 1000000000000.0)];
    }
    return sizeDisplayValue;
}

- (NSString *)formattedSize {
    NSNumber *mediaSize = [self mediaSize];
    NSString *sizeDisplayValue = nil;
    if (mediaSize) {
        double size = [mediaSize doubleValue];
        if (size > 999 && size < 1000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f KB", (size / 1000.0)];
        else if (size > 999999 && size < 1000000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f MB", (size / 1000000.0)];
        else if (size > 999999999 && size < 1000000000000)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f GB", (size / 1000000000.0)];
        else if (size > 999999999999)
            sizeDisplayValue = [NSString stringWithFormat:@"%03.02f TB", (size / 1000000000000.0)];
    }
    return sizeDisplayValue;
}
    
- (NSImage *)icon
{
    if (!icon) {
        if (desc) {
            CFDictionaryRef iconRef = CFDictionaryGetValue(desc, kDADiskDescriptionMediaIconKey);
            if (iconRef) {
                
                CFStringRef identifier = CFDictionaryGetValue(iconRef, CFSTR("CFBundleIdentifier"));
                NSURL *url = (__bridge NSURL *)KextManagerCreateURLForBundleIdentifier(kCFAllocatorDefault, identifier);
                if (url) {
                    NSString *bundlePath = [url path];
                    
                    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
                    if (bundle) {
                        NSString *filename = (NSString *) CFDictionaryGetValue(iconRef, CFSTR("IOBundleResourceFile"));
                        NSString *basename = [filename stringByDeletingPathExtension];
                        NSString *fileext =  [filename pathExtension];
                        
                        NSString *path = [bundle pathForResource:basename ofType:fileext];
                        if (path) {
                            icon = [[NSImage alloc] initWithContentsOfFile:path];
                        }
                    }
                    else {
                        NSLog(@"Failed to load bundle with URL: %@", [url absoluteString]);
                        //CFShow(diskDescription);
                    }
                }
                else {
                    NSLog(@"Failed to create URL for bundle identifier: %@", (__bridge NSString *)identifier);
                    //CFShow(diskDescription);
                }
            }
        }
    }
    
    return icon;
}

- (BOOL)isMountable
{
    CFBooleanRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionVolumeMountableKey) : NULL;
    
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isMounted
{
    CFStringRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionVolumePathKey) : NULL;
    
    return value ? YES : NO;
}

- (BOOL)isWholeDisk
{
    CFBooleanRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionMediaWholeKey) : NULL;
    
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isLeaf
{
    CFBooleanRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionMediaLeafKey) : NULL;
    
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isInternal
{
    CFBooleanRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionDeviceInternalKey) : NULL;
    
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isNetworkVolume
{
    CFBooleanRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionVolumeNetworkKey) : NULL;
    
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isWritable
{
    CFBooleanRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionMediaWritableKey) : NULL;
    
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isEjectable
{
    CFBooleanRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionMediaEjectableKey) : NULL;
    
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isRemovable
{
    CFBooleanRef value = desc ? CFDictionaryGetValue(desc, kDADiskDescriptionMediaRemovableKey) : NULL;
    
    return value ? CFBooleanGetValue(value) : NO;
}

#pragma mark - Private Methods

- (NSString *)ntfsConfig {
	return [NSString stringWithFormat:@"UUID=%@ none ntfs rw,auto,nobrowse", self.volumeUUID];
}

@end
