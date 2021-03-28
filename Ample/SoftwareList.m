//
//  SoftwareList.m
//  Ample
//
//  Created by Kelvin Sherlock on 1/30/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Ample.h"

#import "SoftwareList.h"

@implementation  Software
@end

@implementation  SoftwareList
@end



@interface SoftwareListDelegate : NSObject<NSXMLParserDelegate> {
    unsigned _state;
    NSString *_name;
    NSString *_description;
    NSMutableArray *_array;
    SoftwareList *_list;
}

-(SoftwareList *)list;
@end


@implementation SoftwareListDelegate

-(SoftwareList *)list;{
    return _list;
}

-(void)parserDidStartDocument:(NSXMLParser *)parser {
    _array = [NSMutableArray new];
    _list = [SoftwareList new];

    _state = 0;
    
}

/*
 The parts we care about:
 
 <softwarelist name="" description="">
    <software name="">
        <description>...</description>
    </software>
    ...
 </softwarelist>
 */

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    if ([@"softwarelist" isEqualToString: elementName]) {
        if (_state == 0b0000) {
            _state = 0b0001;
            
            NSString *name = [attributeDict objectForKey: @"name"];
            NSString *description = [attributeDict objectForKey: @"description"];
            if (!description) description = name;
            [_list setTitle: description];
            [_list setName: name];
        }
        return;
    }
    if ([@"software" isEqualToString: elementName]) {
        if (_state == 0b0001) {
            _name = [attributeDict objectForKey: @"name"];
            _state |= 0b0010;
        }
        return;
    }
    if ([@"description" isEqualToString: elementName]) {
        if (_state == 0b0011) {
            _state |= 0b0100;
        }
        return;
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

    if ([@"softwarelist" isEqualToString: elementName]) {
        if (_state == 0b0001) {
            _state = 0b0000;
        }

        [_array sortUsingComparator: ^NSComparisonResult(id a, id b){
            NSString *aa = [(Software *)a title];
            NSString *bb = [(Software *)b title];
            return [aa compare: bb];
        }];
        
        [_list setItems: _array];
        _array = nil;
        return;
    }
    if ([@"software" isEqualToString: elementName]) {
        if (_state == 0b0011) {
            _state &= ~0b0010;
            
            if (_name) {
                if (!_description) _description = _name;
                Software *s = [Software new];
                [s setTitle: _description];
                [s setName: _name];
                [_array addObject: s];
            }
            _name = nil;
            _description = nil;
        }
        return;
    }
    if ([@"description" isEqualToString: elementName]) {
        if (_state == 0b0111) {
            _state &= ~0b0100;
        }
        return;
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_state == 0b0111) {
        if (_description) _description = [_description stringByAppendingString: string];
        else _description = string;
    }
}


@end


static SoftwareList *LoadSoftwareList(NSURL *url, NSError **error) {
    
    NSXMLParser *p = [[NSXMLParser alloc] initWithContentsOfURL: url];
    SoftwareListDelegate *d = [SoftwareListDelegate new];
    
    [p setDelegate: d];
    
    BOOL ok = [p parse];
    if (!ok) {
        if (error) *error = [p parserError];
        return nil;
    }
    return [d list];
    
}


NSArray<SoftwareList *> *SoftwareListForMachine(NSString *machine) {
    
    static NSCache *cache;
    
    if (!cache)
        cache = [NSCache new];
    
    machine = InternString(machine);
    NSArray *a = [cache objectForKey: machine];
    if (a) return a;

    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url= [bundle URLForResource: machine withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];
    if (!d) return nil;
    NSArray *list = [d objectForKey: @"software"];

    NSMutableArray *tmp = [NSMutableArray new];
    for (NSString *xml in list) {
        SoftwareList *sw;
        NSURL *url = SupportDirectory();
        url = [url URLByAppendingPathComponent: @"hash"];
        url = [url URLByAppendingPathComponent: xml];

        
        NSError *error = nil;
        sw = LoadSoftwareList(url, &error);
        if (error) {
            NSLog(@"SoftwareListForMachine: %@ %@: %@", machine, xml, error);
            continue;
        }
        
        [tmp addObject: sw];
    }

#if 0
    [tmp sortUsingComparator: ^NSComparisonResult(id a, id b){
        NSString *aa = [(Software *)a title];
        NSString *bb = [(Software *)b title];
        return [aa compare: bb];

    }];
#endif

    [cache setObject: tmp forKey: machine];
    return tmp;
    
}
