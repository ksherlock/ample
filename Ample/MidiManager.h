//
//  MidiManager.h
//  Ample
//
//  Created by Kelvin Sherlock on 8/6/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#ifndef MidiManager_h
#define MidiManager_h


extern NSString *kMidiSourcesChangedNotification;
extern NSString *kMidiDestinationsChangedNotification;

@interface MidiManager : NSObject

@property NSArray *sources;
@property NSArray *destinations;

+(instancetype)sharedManager;

@end

#endif /* MidiManager_h */
