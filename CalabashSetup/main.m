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
        NSString *defaultProjectName = [[NSString alloc] initWithCString:argv[2] encoding:NSASCIIStringEncoding];
        NSString *path = [[NSString alloc] initWithCString:argv[1] encoding:NSASCIIStringEncoding];
        [CBCalabashSetup setupProject:defaultProjectName withPath:path];

    }
    return 0;
}

