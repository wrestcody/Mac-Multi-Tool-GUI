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
//  Arbitration.m
//  NTFS-OSX
//
//  Created by Jeevanandam M. on 6/5/15.
//  Copyright (c) 2015 myjeeva.com. All rights reserved.
//

#import "Arbitration.h"
#import "Disk.h"
#import "DiskUtilityController.h"

DASessionRef session;
DASessionRef approvalSession;
NSMutableArray *allDisks;
NSMutableArray *diskArray;


void RegisterDA(void) {

	// Disk Arbitration Session
	session = DASessionCreate(kCFAllocatorDefault);
	if (!session) {
		[NSException raise:NSGenericException format:@"Unable to create Disk Arbitration session."];
		return;
	}

	NSLog(@"Disk Arbitration Session created");
    
    NSString *AppName = @"Mac Multi-Tool";

	allDisks =  [NSMutableArray new];
    diskArray = [NSMutableArray new];

	// Matching Conditions - Let's get EVERYTHING
	CFMutableDictionaryRef match = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

	// Device matching criteria
	// 1. Of-course it shouldn't be internal device since
	//CFDictionaryAddValue(match, kDADiskDescriptionDeviceInternalKey, kCFBooleanFalse);

	// Volume matching criteria
	// It should statisfy following
	//CFDictionaryAddValue(match, kDADiskDescriptionVolumeKindKey, (__bridge CFStringRef)DADiskDescriptionVolumeKindValue);
	//CFDictionaryAddValue(match, kDADiskDescriptionVolumeMountableKey, kCFBooleanTrue);
	//CFDictionaryAddValue(match, kDADiskDescriptionVolumeNetworkKey, kCFBooleanFalse);

	//CFDictionaryAddValue(match, kDADiskDescriptionDeviceProtocolKey, CFSTR(kIOPropertyPhysicalInterconnectTypeUSB));

	DASessionScheduleWithRunLoop(session, CFRunLoopGetMain(), kCFRunLoopCommonModes);

	// Registring callbacks
	DARegisterDiskAppearedCallback(session, match, DiskAppearedCallback, (__bridge void *)AppName);
	DARegisterDiskDisappearedCallback(session, match, DiskDisappearedCallback, (__bridge void *)AppName);
	DARegisterDiskDescriptionChangedCallback(session, match, NULL, DiskDescriptionChangedCallback, (__bridge void *)AppName);

	// Disk Arbitration Approval Session
	approvalSession = DAApprovalSessionCreate(kCFAllocatorDefault);
	if (!approvalSession) {
		NSLog(@"Unable to create Disk Arbitration approval session.");
		return;
	}

	NSLog(@"Disk Arbitration Approval Session created");
	DAApprovalSessionScheduleWithRunLoop(approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);

	// Same match condition for Approval session too
	DARegisterDiskMountApprovalCallback(approvalSession, match, DiskMountApprovalCallback, (__bridge void *)AppName);

	if (match != NULL) CFRelease(match);
}

void UnregisterDA(void) {
	NSString *AppName = @"Mac Multi-Tool";
    // DA Session
	if (session) {
		DAUnregisterCallback(session, DiskAppearedCallback, (__bridge void *)AppName);
		DAUnregisterCallback(session, DiskDisappearedCallback, (__bridge void *)AppName);

		DASessionUnscheduleFromRunLoop(session, CFRunLoopGetMain(), kCFRunLoopCommonModes);
		if (session != NULL) CFRelease(session);

		NSLog(@"Disk Arbitration Session destoryed");
	}

	// DA Approval Session
	if (approvalSession) {
		DAUnregisterApprovalCallback(approvalSession, DiskMountApprovalCallback, (__bridge void *)AppName);

		DAApprovalSessionUnscheduleFromRunLoop(approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
		if (approvalSession != NULL) CFRelease(approvalSession);

		NSLog(@"Disk Arbitration Approval Session destoryed");
	}

	[allDisks removeAllObjects];
	allDisks = nil;
    
    [diskArray removeAllObjects];
    diskArray = nil;
}

BOOL Validate(DADiskRef diskRef) {

	if (DADiskGetBSDName(diskRef) == NULL) {
        NSLog(@"No BSD Name");
        return FALSE;
	}

	return TRUE;
}

void DiskAppearedCallback(DADiskRef diskRef, void *context) {
	NSLog(@"DiskAppearedCallback called: %s", DADiskGetBSDName(diskRef));

	if (Validate(diskRef)) {
		Disk *disk = [[Disk alloc] initWithDADiskRef:diskRef];
		NSLog(@"Name: %@ \tUUID: %@", disk.volumeName, disk.volumeUUID);
        
        
        // Get dictionary - bridge it, and display it.
        //CFDictionaryRef dDict = DADiskCopyDescription(diskRef);
        //NSDictionary *diskDict = (NSDictionary *)CFBridgingRelease(dDict);
        //NSLog(@"Disk Dict: %@", diskDict);

        
		[[NSNotificationCenter defaultCenter] postNotificationName:@"diskAppearedNotification" object:disk];
	}
}

void DiskDisappearedCallback(DADiskRef diskRef, void *context) {
	NSLog(@"DiskDisappearedCallback called: %s", DADiskGetBSDName(diskRef));

	if (Validate(diskRef)) {
		Disk *disk = [Disk getDiskForDARef:diskRef];
		NSLog(@"Name: %@ \tUUID: %@", disk.volumeName, disk.volumeUUID);

		[[NSNotificationCenter defaultCenter] postNotificationName:@"diskDisappearedNotification" object:disk];
	}
}

void DiskDescriptionChangedCallback(DADiskRef diskRef, CFArrayRef keys, void *context) {
	NSLog(@"DiskDescriptionChangedCallback called: %s", DADiskGetBSDName(diskRef));

	Disk *disk = [Disk getDiskForDARef:diskRef];

	if (disk) {
		CFDictionaryRef newDesc = DADiskCopyDescription(diskRef);
		disk.desc = newDesc;

		//NSLog(@"Updated Disk Description: %@", disk.desc);

		if (newDesc != NULL) CFRelease(newDesc);
	}
}

DADissenterRef DiskMountApprovalCallback(DADiskRef diskRef, void *context) {
	NSLog(@"DiskMountApprovalCallback called: %s", DADiskGetBSDName(diskRef));

	if (Validate(diskRef)) {
		Disk *disk = [[Disk alloc] initWithDADiskRef:diskRef];
		NSLog(@"Name: %@ \tUUID: %@", disk.volumeName, disk.volumeUUID);
	}

	return NULL;
}

void DiskMountCallback(DADiskRef diskRef, DADissenterRef dissenter, void *context)
{
    //	Disk *disk = (Disk *)context;
    NSMutableDictionary *info = nil;
    
    //Log(LOG_DEBUG, @"%s %@ dissenter: %p", __func__, context, dissenter);
    
    if (dissenter) {
        DAReturn status = DADissenterGetStatus(dissenter);
        
        NSString *statusString = (NSString *) DADissenterGetStatusString(dissenter);
        if (!statusString)
            statusString = [NSString stringWithFormat:@"%@: %#x", NSLocalizedString(@"Dissenter status code", nil), status];
        
       // Log(LOG_INFO, @"%s %@ dissenter: (%#x) %@", __func__, context, status, statusString);
        
        info = [NSMutableDictionary dictionary];
        [info setObject:statusString forKey:NSLocalizedFailureReasonErrorKey];
        [info setObject:[NSNumber numberWithInt:status] forKey:@"DAStatusErrorKey"];
    }
    else {
       // Log(LOG_DEBUG, @"%s disk %@ mounted", __func__, context);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DADiskDidAttemptMountNotification" object:(__bridge id _Nullable)(context) userInfo:info];
}

void DiskUnmountCallback(DADiskRef diskRef, DADissenterRef dissenter, void *context)
{
    NSDictionary *info = nil;
    
    if (dissenter) {
        DAReturn status = DADissenterGetStatus(dissenter);
        
        NSString *statusString = (NSString *) DADissenterGetStatusString(dissenter);
        if (!statusString)
            statusString = [NSString stringWithFormat:@"Error code: %d", status];
        
        //Log(LOG_DEBUG, @"%s disk %@ dissenter: (%d) %@", __func__, context, status, statusString);
        
        info = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:status], @"DAStatusErrorKey",
                statusString, NSLocalizedFailureReasonErrorKey,
                statusString, NSLocalizedRecoverySuggestionErrorKey,
                nil];
    }
    else {
        //Log(LOG_DEBUG, @"%s disk %@ unmounted", __func__, context);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DADiskDidAttemptUnmountNotification" object:(__bridge id _Nullable)(context) userInfo:info];
}

void DiskEjectCallback(DADiskRef diskRef, DADissenterRef dissenter, void *context)
{
    NSDictionary *info = nil;
    
    if (dissenter) {
        DAReturn status = DADissenterGetStatus(dissenter);
        
        NSString *statusString = (NSString *) DADissenterGetStatusString(dissenter);
        if (!statusString)
            statusString = [NSString stringWithFormat:@"Error code: %d", status];
        
       // Log(LOG_INFO, @"%s disk: %@ dissenter: (%d) %@", __func__, context, status, statusString);
        
        info = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:status], @"DAStatusErrorKey",
                statusString, NSLocalizedFailureReasonErrorKey,
                statusString, NSLocalizedRecoverySuggestionErrorKey,
                nil];
    }
    else {
       // Log(LOG_DEBUG, @"%s disk ejected: %@ ", __func__, context);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DADiskDidAttemptEjectNotification" object:(__bridge id _Nullable)(context) userInfo:info];
}
