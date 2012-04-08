////////////////////////////////////////////////////////////////////////////////
//
//  EXPANZ
//  Copyright 2008-2011 EXPANZ
//  All Rights Reserved.
//
//  NOTICE: Expanz permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////


#import "xcode_Project.h"
#import "XcodeSourceFileType.h"
#import "xcode_Group.h"
#import "xcode_FileWriteQueue.h"
#import "xcode_Target.h"
#import "xcode_SourceFile.h"
#import "xcode_KeyBuilder.h"


@interface xcode_Project (private)

- (NSArray*) projectFilesOfType:(XcodeSourceFileType)fileReferenceType;

@end


@implementation xcode_Project


@synthesize fileWriteQueue = _fileWriteQueue;

/* ================================================== Initializers ================================================== */
- (id) initWithFilePath:(NSString*)filePath {
    if (self) {
        _filePath = [filePath copy];
        _project = [[NSMutableDictionary alloc]
                initWithContentsOfFile:[_filePath stringByAppendingPathComponent:@"project.pbxproj"]];
        if (!_project) {
            [NSException raise:NSInvalidArgumentException format:@"Project file not found at file path %@", _filePath];
        }
        _fileWriteQueue = [[FileWriteQueue alloc] initWithBaseDirectory:[_filePath stringByDeletingLastPathComponent]];
    }
    return self;
}


/* ================================================ Interface Methods =============================================== */
#pragma mark Files

- (NSArray*) files {
    NSMutableArray* results = [[NSMutableArray alloc] init];
    [[self objects] enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSDictionary* obj, BOOL* stop) {
        if ([[obj valueForKey:@"isa"] asMemberType] == PBXFileReference) {
            XcodeSourceFileType fileType = [[obj valueForKey:@"lastKnownFileType"] asSourceFileType];
            NSString* path = [obj valueForKey:@"path"];
            [results addObject:[[SourceFile alloc] initWithProject:self key:key type:fileType name:path]];
        }
    }];
    NSSortDescriptor* sorter = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    return [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
}

- (xcode_SourceFile*) fileWithKey:(NSString*)key {
    NSDictionary* obj = [[self objects] valueForKey:key];
    if (obj && [[obj valueForKey:@"isa"] asMemberType] == PBXFileReference) {
        XcodeSourceFileType fileType = [[obj valueForKey:@"lastKnownFileType"] asSourceFileType];

        NSString* name = [obj valueForKey:@"name"];
        if (name == nil) {
            name = [obj valueForKey:@"path"];
        }
        return [[SourceFile alloc] initWithProject:self key:key type:fileType name:name];
    }
    return nil;
}

- (xcode_SourceFile*) fileWithName:(NSString*)name {
    for (SourceFile* projectFile in [self files]) {
        if ([[projectFile name] isEqualToString:name]) {
            return projectFile;
        }
    }
    return nil;
}


- (NSArray*) headerFiles {
    return [self projectFilesOfType:SourceCodeHeader];
}

- (NSArray*) objectiveCFiles {
    return [self projectFilesOfType:SourceCodeObjC];
}

- (NSArray*) objectiveCPlusPlusFiles {
    return [self projectFilesOfType:SourceCodeObjCPlusPlus];
}


- (NSArray*) xibFiles {
    return [self projectFilesOfType:XibFile];

}


/* ================================================================================================================== */
#pragma mark Groups

- (NSArray*) groups {

    NSMutableArray* results = [[NSMutableArray alloc] init];
    [[self objects] enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSDictionary* obj, BOOL* stop) {

        if ([[obj valueForKey:@"isa"] asMemberType] == PBXGroup) {
            [results addObject:[self groupWithKey:key]];
        }
    }];

    return results;
}

- (Group*) groupWithKey:(NSString*)key {
    NSDictionary* obj = [[self objects] valueForKey:key];
    if (obj && [[obj valueForKey:@"isa"] asMemberType] == PBXGroup) {

        NSString* name = [obj valueForKey:@"name"];
        NSString* path = [obj valueForKey:@"path"];
        NSArray* children = [obj valueForKey:@"children"];

        return [[Group alloc] initWithProject:self key:key alias:name path:path children:children];
    }
    return nil;
}

- (xcode_Group*) groupForGroupMemberWithKey:(NSString*)key {
    for (Group* group in [self groups]) {
        if ([group memberWithKey:key]) {
            return group;
        }
    }
    return nil;
}


/* ================================================================================================================== */
#pragma mark Targets

- (NSArray*) targets {
    if (_targets == nil) {
        _targets = [[NSMutableArray alloc] init];
        [[self objects] enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSDictionary* obj, BOOL* stop) {
            if ([[obj valueForKey:@"isa"] asMemberType] == PBXNativeTarget) {
                Target* target = [[Target alloc] initWithProject:self key:key name:[obj valueForKey:@"name"]];
                [_targets addObject:target];
            }
        }];
    }
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    return [_targets sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (Target*) targetWithName:(NSString*)name {
    for (Target* target in [self targets]) {
        if ([[target name] isEqualToString:name]) {
            return target;
        }
    }
    return nil;
}


- (xcode_Group*) groupWithPathRelativeToParent:(NSString*)path {
    for (Group* group in [self groups]) {
        if ([group.pathRelativeToParent isEqualToString:path]) {
            return group;
        }
    }
    return nil;
}
-(NSString*)duplicateBuildConfWithKey:(NSString *)key
{
    NSDictionary *bcl = [[self objects] objectForKey:key];
    NSMutableDictionary *dupBuildConf = [bcl mutableCopy];
    NSMutableDictionary *buildSettings = [[dupBuildConf objectForKey:@"buildSettings"] mutableCopy];
    NSMutableArray *searchPaths = [[buildSettings objectForKey:@"FRAMEWORK_SEARCH_PATHS"] mutableCopy];
    if (searchPaths == nil)
    {
        searchPaths = [NSMutableArray arrayWithCapacity:2];
    }
    if (![searchPaths containsObject:@"$(inherited)"])
    {
        [searchPaths addObject:@"$(inherited)"];
    }
    if (![searchPaths containsObject:@"$(SRCROOT)"])
    {
        [searchPaths addObject:@"$(SRCROOT)"];
    }
    [buildSettings setObject:searchPaths forKey:@"FRAMEWORK_SEARCH_PATHS"];    
    
    NSMutableArray *lflags = [[buildSettings objectForKey:@"OTHER_LDFLAGS"] mutableCopy];
    if (lflags == nil)
    {
        lflags = [NSMutableArray arrayWithCapacity:3];
    }
    if (![lflags containsObject:@"-force_load"])
    {
        [lflags addObject:@"-force_load"];
    }
    if (![lflags containsObject:@"$(SRCROOT)/calabash.framework/calabash"])
    {
        [lflags addObject:@"$(SRCROOT)/calabash.framework/calabash"];
    }
    if (![lflags containsObject:@"-lstdc++"])
    {
        [lflags addObject:@"-lstdc++"];
    }
    
    [buildSettings setObject:lflags forKey:@"OTHER_LDFLAGS"];    
             
    
    [dupBuildConf setObject:buildSettings forKey:@"buildSettings"];
    KeyBuilder* builtKey = [KeyBuilder forDictionary:dupBuildConf];
    NSString* dupKey = [builtKey build];
    [[self objects] setObject:dupBuildConf forKey:dupKey];
    return dupKey;    
}
- (NSString*) duplicateBuildConfListWithKey:(NSString*)key
{
    NSDictionary *bcl = [[self objects] objectForKey:key];
    NSMutableDictionary *dupBuildConfList = [bcl mutableCopy];
    NSMutableArray *buildConfs = [NSMutableArray array];
    for (NSString *buildConf in [dupBuildConfList objectForKey:@"buildConfigurations"])
    {
        [buildConfs addObject:[self duplicateBuildConfWithKey:buildConf]];
    }
    [dupBuildConfList setObject:buildConfs forKey:@"buildConfigurations"];
    KeyBuilder* builtKey = [KeyBuilder forDictionary:dupBuildConfList];
    NSString* dupKey = [builtKey build];
    [[self objects] setObject:dupBuildConfList forKey:dupKey];
    return dupKey;    
}
- (xcode_Target*) duplicateTarget:(xcode_Target *)target withName:(NSString*)dupName
{
    NSDictionary *dictTarget = [[self objects] objectForKey:target.key];
        
    NSMutableDictionary *dupedDict = [dictTarget mutableCopy];
    [dupedDict setObject:dupName forKey:@"name"];
    
    NSString *buildConfListKey = [dupedDict objectForKey:@"buildConfigurationList"];
    NSString *dupBuildConfListKey = [self duplicateBuildConfListWithKey:buildConfListKey];
    
    [dupedDict setObject:dupBuildConfListKey forKey:@"buildConfigurationList"];
    
    NSString *name = [NSString stringWithFormat:@"%@-cal",[dupedDict valueForKey:@"productName"]];
    [dupedDict setObject:name forKey:@"productName"];
    
    NSString *productFileRefKey = [dupedDict objectForKey:@"productReference"];
    NSMutableDictionary *productFileRef = [[[self objects] objectForKey:productFileRefKey] mutableCopy];
    NSString *path = [productFileRef objectForKey:@"path"];
    NSString *namePrefix = [[path componentsSeparatedByString:@".app"] objectAtIndex:0];
    NSString *calpath = [NSString stringWithFormat:@"%@-cal.app",namePrefix];
    [productFileRef setObject:calpath forKey:@"path"];
        
    NSString* dupProductFileRefKey = [[KeyBuilder forItemNamed:calpath] build];
    [[self objects] setObject:productFileRef forKey:dupProductFileRefKey];
        
    [dupedDict setObject:dupProductFileRefKey forKey:@"productReference"];
    
    
    NSMutableArray *buildPhases = [NSMutableArray arrayWithCapacity:3];
    for (NSString *bf in [dupedDict objectForKey:@"buildPhases"])
    {
        NSMutableDictionary *bfDup = [[[self objects] objectForKey:bf] mutableCopy];
        NSMutableArray *dupedFiles = [[bfDup objectForKey:@"files"] mutableCopy];
        [bfDup setObject:dupedFiles forKey:@"files"];
        KeyBuilder* builtKey = [KeyBuilder forDictionary:bfDup];
        NSString *buildPhaseKey = [builtKey build];
        [[self objects] setObject:bfDup forKey:buildPhaseKey];
        [buildPhases addObject:buildPhaseKey];
    }

    [dupedDict setObject:buildPhases forKey:@"buildPhases"];
    
    
    Group *group =nil;
    NSArray *filteredGroups = [[self groups] filteredArrayUsingPredicate:
                               [NSPredicate predicateWithFormat:@"displayName == 'Products'"]];
    if ([filteredGroups count] > 0)
    {
        group = [filteredGroups objectAtIndex:0];
        [group performSelector:@selector(addMemberWithKey:) withObject:dupProductFileRefKey];
    }
    
    
    KeyBuilder* builtKey = [KeyBuilder forItemNamed:dupName];
    NSString* key = [builtKey build];
    [[self objects] setObject:dupedDict forKey:key];
    xcode_Target* dupTarget = [[xcode_Target alloc] initWithProject:self key:key name:dupName];
    [_targets addObject:dupTarget];
    
    NSString *rootKey = [_project objectForKey:@"rootObject"];
    NSMutableDictionary *rootObj = [[[self objects] objectForKey:rootKey] mutableCopy];
    NSMutableArray *rootObjTargets = [[rootObj objectForKey:@"targets"] mutableCopy];
    [rootObjTargets addObject:dupTarget.key];
    [rootObj setObject:rootObjTargets forKey:@"targets"];
    
    [[self objects] setObject:rootObj forKey:rootKey];
    
    
    
    
    
    
//    [[self objects] setObject:[dupTarget asDictionar] forKey:dupTarget.key]
    
    return dupTarget;
    
}


- (void) save {
    [_fileWriteQueue writePendingFilesToDisk];
    [_project writeToFile:[_filePath stringByAppendingPathComponent:@"project.pbxproj"] atomically:NO];
}

- (NSMutableDictionary*) objects {
    return [_project objectForKey:@"objects"];
}

/* ================================================== Private Methods =============================================== */
#pragma mark Private

- (NSArray*) projectFilesOfType:(XcodeSourceFileType)projectFileType {
    NSMutableArray* results = [[NSMutableArray alloc] init];
    for (SourceFile* file in [self files]) {
        if ([file type] == projectFileType) {
            [results addObject:file];
        }
    }
    NSSortDescriptor* sorter = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    return [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
}


@end