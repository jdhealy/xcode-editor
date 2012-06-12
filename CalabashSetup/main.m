//
//  main.m
//  CalabashSetup
//
//  Created by Karl Krukow on 05/04/12.
//  Copyright (c) 2012 Trifork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBCalabashSetup.h"

int main (int argc, const char * argv[])
{

    @autoreleasepool {
        NSString *defaultProjectName = [NSString stringWithUTF8String:argv[2]];
        NSString *path = [NSString stringWithUTF8String:argv[1]];
        [CBCalabashSetup setupProject:defaultProjectName withPath:path];

    }
    return 0;
}

