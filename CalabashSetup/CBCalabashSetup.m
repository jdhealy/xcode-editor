//
//  CBCalabashSetup.m
//  xcode-editor
//
//  Created by Karl Krukow on 05/04/12.
//  Copyright (c) 2012 EXPANZ. All rights reserved.
//

#import "CBCalabashSetup.h"
#import "xcode_Project.h"
#import "xcode_Group.h"
#import "xcode_FrameworkDefinition.h"
#import "xcode_Target.h"
#import "Helpers.h"

static NSString *PATH_TO_CALABASH  = @"/Users/krukow/github/calabash-ios-example/calabash.framework";


@implementation CBCalabashSetup

+(Target *)findTarget:(NSString *)defaultProjectName path:(NSString *)path inProject:(Project *)project
{
    __block Target *defaultTarget = nil;
    
    
    NSArray *targets = [project targets];
    NSInteger targetCount = [targets count];
    if (targetCount == 0)
    {
        info(app(@"No targets found in %@. Aborting.", path),^{ exit(EXIT_FAILURE);});
    }
    if (targetCount == 1)
    {
        defaultTarget = [targets objectAtIndex:0];
    }
    else
    {
        for (Target *t in targets)
        {
            if ([t.name isEqualToString:defaultProjectName])
            {
                defaultTarget = t;
            }
        }     
        info(@"Found several targets. Please enter name of target to duplicate.",^{
            if (defaultTarget)
            {
                OUT(@"Default target: %@. Just hit <Enter> to select default.",defaultTarget.name);
            }
            for (Target *t in targets)
            {
                OUT(@"%@",t.name);
            }   
            
            NSString *inputString = inputline();
            OUT(@"input: %@",inputString);
            if (defaultTarget && [inputString length] == 0)
            {
                OUT(@"Selecting default target (%@)", defaultTarget);
            }
            else 
            {
                defaultTarget = nil;
                for (Target *t in targets)
                {
                    if ([t.name isEqualToString:inputString])
                    {
                        defaultTarget = t;
                        break;
                    }    
                }
            }                        
        });
    }
    
    if (defaultTarget==nil) 
    {
        OUT(@"No target was selected. Aborting.");exit(EXIT_FAILURE);
    }
    
    Target *target = [project duplicateTarget:defaultTarget withName:[NSString stringWithFormat:@"%@-cal",defaultTarget.name]];
    
    return target;
}

+(void)setupProject:(NSString *)defaultProjectName withPath:(NSString *)path
{
    Project* project = [[Project alloc] initWithFilePath:path];
    Target *target = [self findTarget:defaultProjectName path:path inProject:project];        
    if (target==nil) 
    {
        OUT(@"No target was selected. Aborting.");exit(EXIT_FAILURE);
    }

    Group *group =nil;
    NSArray *filteredGroups = [[project groups] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"displayName == 'Frameworks'"]];
    if ([filteredGroups count]==0) 
    {
        OUT(@"No frameworks Group found. Aborting.");exit(EXIT_FAILURE);
    }
    else
    {
        group = [filteredGroups objectAtIndex:0];
    }
    NSArray *targets = [NSArray arrayWithObject:target];
    NSArray *targetMembers = [[target members] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"displayName == 'CFNetwork.framework'"]];
    if ([targetMembers count] == 0)
    {
        OUT(@"Adding CFNetwork.framework to target %@",target.name);
        FrameworkDefinition* frameworkDefinition = 
        [[FrameworkDefinition alloc] initWithFilePath:@"System/Library/Frameworks/CFNetwork.framework" copyToDestination:NO isSDK:YES];
        [group addFramework:frameworkDefinition toTargets:targets];
    }
        
    
    FrameworkDefinition* frameworkDefinition = 
    [[FrameworkDefinition alloc] initWithFilePath:PATH_TO_CALABASH copyToDestination:YES];
    [group addFramework:frameworkDefinition toTargets:targets];
    
        [project save];
    OUT(@"%@", group);
}
@end
