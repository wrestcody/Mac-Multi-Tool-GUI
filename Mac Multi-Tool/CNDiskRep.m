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
@synthesize name=_name;
@synthesize type=_type;
@synthesize isChild=_isChild;
@synthesize size=_size;
@synthesize identifier=_identifier;


- (id)init {
    if (self = [super init]) {
        //Set up anything that needs to happen at init.
    }
    return self;
}

- (void) dealloc {
    // Shouldn't ever be called, but here for clarity.
}

- (id)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
        return self;
    } else {
        return nil;
    }
}
- (id)initWithName:(NSString *)name child:(id)child {
    if (self = [super init]) {
        [self setName:name];
        [self addChild:child];
        return self;
    } else {
        return nil;
    }
}
- (id)initWithName:(NSString *)name children:(NSMutableArray *)children {
    if (self = [super init]) {
        [self setName:name];
        [self setChildren:children];
        return self;
    } else {
        return nil;
    }
}

- (NSString *)getName {
    return _name;
}

- (BOOL)isChild; {
    return _isChild;
}

- (NSString *)getSize {
    return _size;
}

- (NSString *)getType {
    return _type;
}

- (NSString *)getIdentifier {
    return _identifier;
}

- (NSMutableArray *)getChildren {
    return _children;
}

- (BOOL)hasChildren {
    if (_children != nil && [_children count] > 0) {
        return YES;
    } else {
        return NO;
    }
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

- (void)addChild:(id)child {
    if (_children == nil) {
        _children = [[NSMutableArray alloc] init];
    }
    [_children addObject:child];
}

@end
