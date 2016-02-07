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
@property (nonatomic, retain) NSMutableDictionary *objects;
@property (nonatomic)         BOOL isChild;
@property (nonatomic)         BOOL isBoot;

- (void)addChild:(id)child;
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)setObjects:(NSMutableDictionary *)objects;
- (void)removeObjectWithKey:(NSString *)key;

- (BOOL)isChild;
- (BOOL)isBoot;

- (id)objectForKey:(NSString *)key;
- (NSMutableDictionary *)getObjects;

- (NSMutableArray *)getChildren;
- (unsigned long)numberOfChildren;
- (id)childAtIndex:(unsigned long)index;

- (BOOL)hasChildren;

@end
