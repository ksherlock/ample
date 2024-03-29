//
//  SoftwareList.m
//  Ample
//
//  Created by Kelvin Sherlock on 1/30/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <wctype.h>

#include "Ample.h"
#import "SoftwareList.h"

@implementation  Software

-(BOOL)filter: (NSString *)filter {
    
    if (!_compatibility || ![_compatibility length]) return YES;
    
    unichar *needle;
    unichar *haystack;
    NSUInteger needle_length;
    NSUInteger haystack_length;
    BOOL ok = NO;
    
    haystack_length = [_compatibility length];
    if (!haystack_length) return YES;
    needle_length = [filter length];
    if (!needle_length) return NO;

    if (needle_length > haystack_length) return NO;

    haystack = malloc((haystack_length + 1) * sizeof(unichar));
    [_compatibility getCharacters: haystack range: NSMakeRange(0, haystack_length)];

    needle = malloc((needle_length + 1) * sizeof(unichar));
    [filter getCharacters: needle range: NSMakeRange(0, needle_length)];

    haystack[haystack_length] = 0;
    needle[needle_length] = 0;
    
    NSUInteger i = 0;
    unichar c;
    do {
        if (!memcmp(needle, haystack + i, sizeof(unichar) * needle_length)) {
            i += needle_length;
            c = haystack[i];
            if (c == ',' || c == 0) { ok = YES; break; }
        }
        do {
            c = haystack[i++];
        } while ( c && c != ',');
    } while (c);
    
    free(needle);
    free(haystack);
    
    return ok;
}

- (nonnull NSAttributedString *)menuAttributedTitle {
    return nil;
}

- (BOOL)menuEnabled {
    return YES;
}

- (BOOL)menuIsHeader {
    return NO;
}

- (nonnull NSString *)menuTitle {
    return _title;
}

-(NSString *)fullName {
    if (![_list length]) return _name;
    return [NSString stringWithFormat: @"%@:%@", _list, _name];
}

@end

@implementation  SoftwareList

-(SoftwareList *)filter: (NSString *)filter {
    
    unichar *needle = NULL;
    __block unichar *haystack = NULL;
    NSUInteger needle_length = 0;
    __block NSUInteger  max_haystack_length = 0;
    
    
    needle_length = [filter length];
    if (!needle_length) return self;

    needle = malloc(needle_length * sizeof(unichar) + sizeof(unichar));
    [filter getCharacters: needle range: NSMakeRange(0, needle_length)];
    needle[needle_length] = 0;

    max_haystack_length = 127;
    haystack = malloc(max_haystack_length * sizeof(unichar) + sizeof(unichar));


    NSPredicate *p = [NSPredicate predicateWithBlock: ^BOOL(Software *o, NSDictionary *bindings){
        
        NSString *s = [o compatibility];
        NSUInteger length = [s length];
        if (length == 0) return YES;
        if (length < needle_length) return NO;

        if (length > max_haystack_length) {
            max_haystack_length = length;
            haystack = realloc(haystack, sizeof(unichar ) * length + sizeof(unichar));
        }
        
        [s getCharacters: haystack range: NSMakeRange(0, length)];
        haystack[length] = 0;
   
        
        NSUInteger i = 0;
        unichar c;
        do {
            if (!memcmp(needle, haystack + i, sizeof(unichar) * needle_length)) {
                i += needle_length;
                c = haystack[i];
                if (c == ',' || c == 0) return YES;
            }
            do {
                c = haystack[i++];
            } while ( c && c != ',');
        } while (c);
        return NO;
    }];
    
    NSArray *items = [_items filteredArrayUsingPredicate: p];
    free(needle);
    free(haystack);

    if ([items count] == [_items count]) return self;
    
    SoftwareList *rv = [SoftwareList new];
    [rv setItems: items];
    [rv setName: _name];
    [rv setTitle: _title];
    
    return rv;

}

- (nonnull NSAttributedString *)menuAttributedTitle {
    return nil;
}

- (BOOL)menuEnabled {
    return NO;
}

- (BOOL)menuIsHeader {
    return YES;
}

- (nonnull NSString *)menuTitle {
    return _title;
}

@end




@interface SoftwareListDelegate : NSObject<NSXMLParserDelegate> {
    unsigned _state;

    NSString *_name;
    NSString *_description;
    NSString *_compatibility;
    NSString *_notes;
    
    NSString *_scratch;

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
    <notes>...</notes>
    <software name="">
        <description>...</description>
        <notes>...</notes>
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
    if ([@"sharedfeat" isEqualToString: elementName]) {
        if ([@"compatibility" isEqualToString: [attributeDict objectForKey: @"name"]]) {
            _compatibility = [attributeDict objectForKey: @"value"];
        }
    }
    if ([@"notes" isEqualToString: elementName]) {
        /* notes is a child of software list and software. */
        if (_state == 0b0001 || _state == 0b0011) {
            _state |= 0b1000;
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
                [s setCompatibility: _compatibility];
                [s setNotes: _notes];
                [s setList: [_list name]];
                [_array addObject: s];
            }
            _name = nil;
            _description = nil;
            _compatibility = nil;
            _notes = nil;
        }
        return;
    }
    if ([@"description" isEqualToString: elementName]) {
        if (_state == 0b0111) {
            _state &= ~0b0100;
            _description = _scratch;
            _scratch = nil;
        }
        return;
    }
    if ([@"notes" isEqualToString: elementName]) {
        if (_state == 0b1001) {
            _state &= ~0b1000;

            [_list setNotes: _scratch];
            _scratch = nil;
        }
        if (_state == 0b1011) {
            _state &= ~0b1000;
            _notes = _scratch;
            _scratch = nil;
        }
        return;
    }

}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_state == 0b0111 || _state == 0b1011 || _state == 0b1001) {
        if (_scratch) _scratch = [_scratch stringByAppendingString: string];
        else _scratch = string;
    }
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
    // ?
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    
    if (_state & 0b1000) {
        // notes
        NSString *string = [[NSString alloc] initWithData: CDATABlock encoding: NSUTF8StringEncoding];

        string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (_scratch) {
            _scratch = [_scratch stringByAppendingString: @"\n"];
            _scratch = [_scratch stringByAppendingString: string];
        }
        else _scratch = string;
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
    
    if (!machine) return nil;
    machine = InternString(machine);
    NSArray *a = [cache objectForKey: machine];
    if (a) return a;

    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url= [bundle URLForResource: machine withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];
    if (!d) return nil;
    NSArray *list = [d objectForKey: @"software"];

    NSMutableArray *tmp = [NSMutableArray new];
    for (NSObject *o in list) {
        SoftwareList *sw;
        NSURL *url = SupportDirectory();
        
        NSString *xml = nil;
        NSString *filter = nil;
        if ([o isKindOfClass: [NSString class]]) {
            xml = (NSString *)o;
        } else if ([o isKindOfClass: [NSDictionary class]]) {
            xml = [(NSDictionary *)o objectForKey: @"name"];
            filter = [(NSDictionary *)o objectForKey: @"filter"];
        } else if ([o isKindOfClass: [NSArray class]]) {
            // [ xml, filter ]
            xml = [(NSArray *)o objectAtIndex: 0];
            filter = [(NSArray *)o objectAtIndex: 1];
        }
        else {
            continue;
        }
        if (!xml) continue;

        xml = InternString(xml);
        sw = [cache objectForKey: xml];
        if (!sw) {
            url = [url URLByAppendingPathComponent: @"hash"];
            url = [url URLByAppendingPathComponent: xml];

            
            NSError *error = nil;
            sw = LoadSoftwareList(url, &error);
            if (error) {
                NSLog(@"SoftwareListForMachine: %@ %@: %@", machine, xml, error);
                continue;
            }
            if (sw) [cache setObject: sw forKey: xml];
        }
        if (filter) {
            sw = [sw filter: filter];
        }
        if (!sw) continue;
        
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


@interface SoftwareSet () {
    
    NSArray<SoftwareList *> *_items;
    NSCountedSet *_set;
    NSCache *_cache;
}

@end

@implementation SoftwareSet

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nullable [])buffer count:(NSUInteger)len {
    return [_items countByEnumeratingWithState: state objects: buffer count: len];
}

-(void)buildSet {
    if (_set) return;
    _set = [NSCountedSet new];

    for (SoftwareList *list in _items) {
        for (Software *s in [list items]) {
            [_set addObject: [s name]];
        }
    }
}

-(BOOL)nameIsUnique:(NSString *)name {
    if (![name length]) return YES;
    
    if (!_set) [self buildSet];
    return [_set countForObject: name] <= 1;
}

-(NSString *)nameForSoftware: (Software *)software {
    
    if (!software) return nil;
    if (!_set) [self buildSet];
    
    NSString *name = [software name];
    if ([_set countForObject: name] > 1) {
        return [software fullName];
    }
    return name;
}

-(Software *)softwareForName: (NSString *)name {
    /* name will be name or set:name */
    NSString *set = nil;
    NSArray *tmp = [name componentsSeparatedByString: @":"];
    switch([tmp count]) {
        case 1: break;
        case 2:
            set = [tmp objectAtIndex: 0];
            name = [tmp objectAtIndex: 1];
            break;
        default: return nil;
    }
    
    if (_set && ![_set containsObject: name]) return nil;

    for (SoftwareList *list in _items) {
        if (set && ![set isEqualToString: [list name]]) continue;
        
        for (Software *s in [list items]) {
            if ([name isEqualToString: [s name]]) return s;
        }
    }
    return nil;
    
}


static NSCache *cache;
+(void)invalidate {
// called after mame components are updated.  clears the cache.
    cache = nil;
}

+(instancetype)softwareSetForMachine:(NSString *)machine {
    
    
    if (!cache)
        cache = [NSCache new];
    
    if (!machine) return nil;
    machine = InternString(machine);
    SoftwareSet *s= [cache objectForKey: machine];
    if (s) return s;

    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url= [bundle URLForResource: machine withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];
    if (!d) return nil;
    NSArray *list = [d objectForKey: @"software"];

    NSMutableArray *tmp = [NSMutableArray new];
    for (NSObject *o in list) {
        SoftwareList *sw;
        NSURL *url = SupportDirectory();
        
        NSString *xml = nil;
        NSString *filter = nil;
        if ([o isKindOfClass: [NSString class]]) {
            xml = (NSString *)o;
        } else if ([o isKindOfClass: [NSDictionary class]]) {
            xml = [(NSDictionary *)o objectForKey: @"name"];
            filter = [(NSDictionary *)o objectForKey: @"filter"];
        } else if ([o isKindOfClass: [NSArray class]]) {
            // [ xml, filter ]
            xml = [(NSArray *)o objectAtIndex: 0];
            filter = [(NSArray *)o objectAtIndex: 1];
        }
        else {
            continue;
        }
        if (!xml) continue;

        xml = InternString(xml);
        sw = [cache objectForKey: xml];
        if (!sw) {
            url = [url URLByAppendingPathComponent: @"hash"];
            url = [url URLByAppendingPathComponent: xml];

            
            NSError *error = nil;
            sw = LoadSoftwareList(url, &error);
            if (error) {
                NSLog(@"SoftwareListForMachine: %@ %@: %@", machine, xml, error);
                continue;
            }
            if (sw) [cache setObject: sw forKey: xml];
        }
        if (filter) {
            sw = [sw filter: filter];
        }
        if (!sw) continue;
        
        [tmp addObject: sw];
    }

    if (![tmp count]) return nil;
    
    s = [SoftwareSet new];
    s->_items = tmp;
    [cache setObject: s forKey: machine];
    return s;
}


-(BOOL)hasSoftware: (Software *)software {
    
    if (_set) {
        NSString *name = [software name];
        if (![_set containsObject: name]) return NO;
    }
    
    NSString *slist = [software list];
    for (SoftwareList *list in _items) {
        if (![slist isEqualToString: [list name]]) continue;
        
        return [[list items] containsObject: software];        
    }
    return NO;
}


- (nonnull NSArray<id<AutocompleteItem>> *)autocomplete:(AutocompleteControl *)control completionsForItem:(id<AutocompleteItem>)item {

    for (SoftwareList *list in _items) {
        NSArray *items = [list items];
        if ([items containsObject: item]) {
            return @[ list, item ];
        }
    }
    return nil;
}



static NSString *SearchString(NSString *s) {
    
    s = [s stringByFoldingWithOptions: NSCaseInsensitiveSearch|NSWidthInsensitiveSearch|NSDiacriticInsensitiveSearch locale: nil];
    
    // strip leading "the " ???
    NSUInteger l = [s length];
    if (l > 4) {
        unichar buffer[4];
        static unichar the_l[4] = { 't', 'h', 'e', ' '};
        static unichar the_u[4] = { 'T', 'H', 'E', ' '};

        [s getCharacters: buffer range: NSMakeRange(0, 4)];
        if (!memcmp(buffer, the_l, sizeof(buffer))) return [s substringFromIndex: 4];
        if (!memcmp(buffer, the_u, sizeof(buffer))) return [s substringFromIndex: 4];
    }
    if (l > 256) return [s substringToIndex: 256];
    return s;
}

- (nonnull NSArray<id<AutocompleteItem>> *)autocomplete:(nonnull AutocompleteControl *)control completionsForString:(nonnull NSString *)string {

    if (!_cache) {
        _cache = [NSCache new];
        [_cache setCountLimit: 10];
    }
    

    
    // diacritic normalization.
    // déjá vu -> deja vu
    string = SearchString(string);

    enum { max_haystack_length = 256, max_needle_length = 256 };

    unichar needle_data[max_needle_length];
    
    if (!_items) return @[];
    
    NSUInteger needle_length = [string length];
    needle_length = MIN(needle_length, max_needle_length);

    [string getCharacters: needle_data range: NSMakeRange(0, needle_length)];
    
    // based on testing, NSCaseInsensitiveSearch uses lowercase but it's not guaranteed.
    for (NSUInteger i = 0; i < needle_length; ++i)
        needle_data[i] = towlower(needle_data[i]);
    string = InternString([NSString stringWithCharacters: needle_data length: needle_length]);


    NSArray *a = [_cache objectForKey: string];
    if (a) return a;

    
    NSMutableArray *rv = [NSMutableArray new];

    if (needle_length == 0) {
        for(SoftwareList *list in _items) {
            [rv addObject: list];
            [rv addObjectsFromArray: [list items]];
        }
        [_cache setObject: rv forKey: string];
        return rv;
    }
    
    //if (needle_length < 2) return nil;
    

    
    const unichar *needle_data_ptr = needle_data;
    NSPredicate *p = [NSPredicate predicateWithBlock: ^BOOL(Software *o, NSDictionary *bindings){
        // prefix match.

        unichar haystack_data[max_haystack_length];
        NSString *haystack;
        NSUInteger length;
        
        haystack = [o name];

        length = [haystack length];
        length = MIN(length, max_haystack_length);
        if (length >= needle_length) {
            [haystack getCharacters: haystack_data range: NSMakeRange(0, length)];
            for (NSUInteger i = 0; i < length; ++i)
                haystack_data[i] = towlower(haystack_data[i]);
            if (!memcmp(haystack_data, needle_data_ptr, needle_length * sizeof(unichar))) return YES;
        }

        haystack = [o searchTitle];
        if (!haystack) {
            haystack = SearchString([o title]);
            [o setSearchTitle: haystack];
        }

        length = [haystack length];
        length = MIN(length, max_haystack_length);
        if (length >= needle_length) {
            [haystack getCharacters: haystack_data range: NSMakeRange(0, length)];
            for (NSUInteger i = 0; i < length; ++i)
                haystack_data[i] = towlower(haystack_data[i]);
            if (!memcmp(haystack_data, needle_data_ptr, needle_length * sizeof(unichar))) return YES;
        }

        return NO;
    }];
    
    for (SoftwareList *list in _items) {

        NSArray *items = [list items];
        
        NSArray *tmp = [items filteredArrayUsingPredicate: p];
        // add header ... ?
        if (![tmp count]) continue;
        [rv addObject: list]; // header
        [rv addObjectsFromArray: tmp];
        
    }

    [_cache setObject: rv forKey: string];
    return rv;
    
}

@end
