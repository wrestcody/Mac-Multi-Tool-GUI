//
//  CNDiskRep.h
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/5/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CNDiskRep : NSObject

@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, retain) NSString *name;
@property (nonatomic)         BOOL isChild;
@property (nonatomic)         BOOL isBoot;
@property (nonatomic, retain) NSString *size;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *type;

- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name child:(id)child;
- (id)initWithName:(NSString *)name children:(NSMutableArray *)children;

- (void)addChild:(id)child;

- (NSString *)getName;
- (BOOL)isChild;
- (BOOL)isBoot;
- (NSString *)getSize;
- (NSString *)getIdentifier;
- (NSString *)getType;
- (NSMutableArray *)getChildren;
- (unsigned long)numberOfChildren;
- (id)childAtIndex:(unsigned long)index;

- (BOOL)hasChildren;

@end
