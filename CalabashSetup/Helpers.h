//
//  Helpers.h
//  xcode-editor
//
//  Created by Karl Krukow on 05/04/12.
//  Copyright (c) 2012 EXPANZ. All rights reserved.
//

#ifndef xcode_editor_Helpers_h
#define xcode_editor_Helpers_h

static void OUT(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    
    static NSData *NL = nil;
    if (!NL)
    {
        NL = [@"\n"  dataUsingEncoding: NSUTF8StringEncoding];
    }
    NSString *formattedString = [[NSString alloc] initWithFormat: format
                                                       arguments: args];
    va_end(args);
    NSFileHandle * so = [NSFileHandle fileHandleWithStandardOutput];
    [so writeData:[formattedString dataUsingEncoding: NSUTF8StringEncoding]];
    [so writeData:NL];
}


static NSString* app(NSString *fmt, NSString *arg)
{
    return [NSString stringWithFormat:fmt, arg];
}
static void dashes(NSString *msg)
{
    OUT(@"---------- %@ ----------",msg);    
}
static void dashesEnd()
{
    dashes(@"-");
}

static void info(NSString *msg, void (^block)(void))
{
    dashes([NSString stringWithFormat:@"Info",msg]);
    OUT(@"%@",msg);
    block();
    dashesEnd();
}

static NSString * inputline(void) {
    char * line = malloc(100), * linep = line;
    size_t lenmax = 100, len = lenmax;
    int c;
    
    if(line == NULL)
        return NULL;
    
    for(;;) {
        c = fgetc(stdin);
        if(c == EOF)
            break;
        
        if(--len == 0) {
            char * linen = realloc(linep, lenmax *= 2);
            len = lenmax;
            
            if(linen == NULL) {
                free(linep);
                return NULL;
            }
            line = linen + (line - linep);
            linep = linen;
        }
        
        *line = c;
        if (c == '\n')
        {
            *line = '\0';
            break;            
        }
        line++;
    }

    return [NSString stringWithCString:linep encoding:NSUTF8StringEncoding];
}

#endif
