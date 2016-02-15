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
//  Disk.h
//  NTFS-OSX
//
//  Created by Jeevanandam M. on 6/5/15.
//  Copyright (c) 2015 myjeeva.com. All rights reserved.
//

@import ServiceManagement;
@import AppKit;

@interface Disk : NSObject {
	CFTypeRef _diskRef;
}

@property (readonly, copy) NSString *BSDName;
@property (readonly, copy) NSImage *icon;
@property CFDictionaryRef desc;
@property (readonly, copy) NSString *volumeUUID;
@property (readonly, copy) NSString *diskUUID;
@property (readonly, copy) NSString *volumeName;
@property (nonatomic, copy) NSString *volumePath;
@property (readonly, copy) NSString *mediaName;
@property (nonatomic) BOOL isNTFSWritable;
//@property CFTypeRef favoriteItem;
@property (readonly, copy) NSDictionary *description;

@property Disk *parent;
@property (nonatomic, retain) NSMutableArray *children;

@property BOOL isExpanded;
@property BOOL isMounting;

+ (Disk *)getDiskForDARef:(DADiskRef)diskRef;
+ (Disk *)getDiskForUserInfo:(NSDictionary *)userInfo;
- (id)initWithDADiskRef:(DADiskRef)diskRef;
- (void)disappeared;

- (NSString *)volumeName;
- (NSString *)mediaName;
- (NSNumber *)mediaSize;
- (NSString *)volumeKind;
- (NSString *)deviceProtocol;
- (NSString *)mediaContent;
- (NSString *)volumeFS;
- (NSNumber *)freeSpace;
- (NSNumber *)usedSpace;
- (NSString *)formattedFreeSpace;
- (NSString *)formattedUsedSpace;
- (NSString *)formattedSize;
- (BOOL)isWholeDisk;
- (BOOL)isMounted;
- (BOOL)isMountable;
- (BOOL)isEjectable;
- (BOOL)isRemovable;
- (BOOL)isLeaf;
- (BOOL)isInternal;
- (void)mount;
- (void)mountWhole;
- (void)mountAtPath:(NSString *)path withArguments:(NSArray *)args;
- (void)mountWholeDiskAtPath:(NSString *)path withArguments:(NSArray *)args;
- (void)unmountWithOptions:(NSUInteger)options;
- (void)eject;
//- (void)unmount;

@end

