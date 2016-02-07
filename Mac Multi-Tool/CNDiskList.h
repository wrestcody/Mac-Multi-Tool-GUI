//
//  CNDiskList.h
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/5/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CNDiskRep.h"

@interface CNDiskList : NSObject

@property (nonatomic, retain) NSMutableArray *diskList;

+ (id)sharedList;

- (NSMutableDictionary *)getAllDisksPlist;
- (NSMutableDictionary *)getPlistForDisk:(NSString *)disk;
- (NSMutableDictionary *)diskUtilWithArguments:(NSArray *)args;

- (NSString *)getStringForDisk:(CNDiskRep *)disk;

- (NSMutableArray *)getAllDiskIdentifiers;
- (NSMutableArray *)getWholeDiskIdentifiers;
- (NSMutableArray *)getVolumesFromDisks;
- (NSMutableArray *)getOutlineViewList;
- (NSMutableArray *)getVolumesViewList;
- (NSMutableArray *)getAllDisksAndPartitionsList;
- (NSMutableArray *)getDiskViewList:(id)disk;
- (NSString *)getBootDeviceNode;

- (NSString *)getReadableSizeFromString:(NSString *)string;

@end
