//
//  Midi.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/6/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

#import "MidiManager.h"

static NSArray *MidiSources(void) {
    
    ItemCount count = MIDIGetNumberOfSources();
    if (count <= 0) return @[];
    
    NSMutableArray *rv = [NSMutableArray arrayWithCapacity: count + 1];
    
    MIDIEndpointRef ep;
    for(int i = 0; i < count; ++i) {
        ep = MIDIGetSource(i);
        if (!ep) continue;

        // https://developer.apple.com/library/archive/qa/qa1374/_index.html
        CFStringRef str = NULL;
        MIDIObjectGetStringProperty(ep, kMIDIPropertyDisplayName, &str);

        if (str) {
            [rv addObject: (__bridge id _Nonnull)(str)];
            CFRelease(str);
        }
    }
    return rv;
}


static NSArray *MidiDestinations(void) {
    
    ItemCount count = MIDIGetNumberOfDestinations();
    if (count <= 0) return @[];
    
    NSMutableArray *rv = [NSMutableArray arrayWithCapacity: count + 1];
    
    MIDIEndpointRef ep;
    for(int i = 0; i < count; ++i) {
        ep = MIDIGetDestination(i);
        if (!ep) continue;

        // https://developer.apple.com/library/archive/qa/qa1374/_index.html
        CFStringRef str = NULL;
        MIDIObjectGetStringProperty(ep, kMIDIPropertyDisplayName, &str);

        if (str) {
            [rv addObject: (__bridge id _Nonnull)(str)];
            CFRelease(str);
        }
    }
    return rv;
}

NSString *kMidiSourcesChangedNotification = @"Midi Sources Changed";
NSString *kMidiDestinationsChangedNotification = @"Midi Destinations Changed";


@interface MidiManager () {
    MIDIClientRef _client;
}

-(void)objectAddRemove: (const MIDIObjectAddRemoveNotification *)message;
-(void)objectPropertyChanged: (const MIDIObjectPropertyChangeNotification *)message;
@end


static MidiManager *singleton = nil;
@implementation MidiManager

-(void)awakeFromNib {
    if (!singleton) singleton = self;
}

+(instancetype)sharedManager {
    if (!singleton) singleton = [MidiManager new];
    return singleton;
}

-(instancetype)init {
    
    if (singleton) return singleton;

    OSStatus status;
    

    status = MIDIClientCreateWithBlock(
        CFSTR("serial_midi"),
        &_client,
        ^(const MIDINotification *message){
        switch(message->messageID) {
            case kMIDIMsgObjectAdded:
            case kMIDIMsgObjectRemoved:
                [self objectAddRemove: (const MIDIObjectAddRemoveNotification *)message];
                break;
            case kMIDIMsgPropertyChanged:
                [self objectPropertyChanged: (const MIDIObjectPropertyChangeNotification *)message];
            default:
                break;
        }
    });
   
    _sources = MidiSources();
    _destinations = MidiDestinations();
    return self;
}

-(void)objectAddRemove: (const MIDIObjectAddRemoveNotification *)message {

    const MIDIObjectAddRemoveNotification *m = (const MIDIObjectAddRemoveNotification *)message;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    if (m->childType == kMIDIObjectType_Source) {
        [self setSources: MidiSources()];
        [nc postNotificationName: kMidiSourcesChangedNotification object: self];
    }
    
    if (m->childType == kMIDIObjectType_Destination) {
        [self setDestinations: MidiDestinations()];
        [nc postNotificationName: kMidiDestinationsChangedNotification object: self];
    }
   
}
-(void)objectPropertyChanged: (const MIDIObjectPropertyChangeNotification *)message {

    const MIDIObjectPropertyChangeNotification *m = (const MIDIObjectPropertyChangeNotification *)message;
    if (m->propertyName == kMIDIPropertyDisplayName) {
        [self setSources: MidiSources()];
        [self setDestinations: MidiDestinations()];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName: kMidiSourcesChangedNotification object: self];
        [nc postNotificationName: kMidiDestinationsChangedNotification object: self];
    }
}


-(void)dealloc {
    
    if (_client)
        MIDIClientDispose(_client);
}
@end

