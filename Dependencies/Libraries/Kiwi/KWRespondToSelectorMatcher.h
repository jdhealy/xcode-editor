//
// Licensed under the terms in License.txt
//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KiwiConfiguration.h"
#import "KWMatcher.h"

@interface KWRespondToSelectorMatcher : KWMatcher {
@private
    SEL selector;
}

#pragma mark -
#pragma mark Configuring Matchers

- (void) respondToSelector:(SEL)aSelector;

@end
