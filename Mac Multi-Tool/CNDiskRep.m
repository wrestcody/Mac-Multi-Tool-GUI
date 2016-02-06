//
//  CNDiskRep.m
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/5/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import "CNDiskRep.h"

@implementation CNDiskRep

@synthesize children=_children;
@synthesize objects=_objects;
@synthesize isChild=_isChild;
@synthesize isBoot=_isBoot;


- (id)init {
    if (self = [super init]) {
        //Set up anything that needs to happen at init.
        return self;
    } else {
        return nil;
    }
}

- (void) dealloc {
    // Shouldn't ever be called, but here for clarity.
}

- (void)addChild:(id)child {
    if (_children == nil) {
        _children = [[NSMutableArray alloc] init];
    }
    if ([child isKindOfClass:[CNDiskRep class]]) {
        [child setIsChild:YES];
    }
    [_children addObject:child];
}

- (void)setObject:(id)object forKey:(NSString *)key {
    if (_objects == nil) {
        _objects = [[NSMutableDictionary alloc] init];
    }
    [_objects setObject:object forKey:key];
}

- (void)setObjects:(NSMutableDictionary *)objects {
    _objects = [objects mutableCopy];
}

- (BOOL)isChild; {
    return _isChild;
}

- (BOOL)isBoot; {
    return _isBoot;
}

- (id)objectForKey:(NSString *)key {
    if (_objects == nil) {
        return nil;
    } else {
        return [_objects objectForKey:key];
    }
}

- (NSMutableDictionary *)getObjects {
    return _objects;
}

- (NSMutableArray *)getChildren {
    return _children;
}

- (unsigned long)numberOfChildren {
    if ([self hasChildren]) {
        return [_children count];
    } else {
        return 0;
    }
}

- (id)childAtIndex:(unsigned long)index {
    if ([self hasChildren] && index < [self numberOfChildren]) {
        return [_children objectAtIndex:index];
    } else {
        return nil;
    }
}

- (BOOL)hasChildren {
    if (_children != nil && [_children count] > 0) {
        return YES;
    } else {
        return NO;
    }
}

@end
