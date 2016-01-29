//
//  BPMDetector.h
//  BPMDetect
//
//  Created by Yuki Konda on 1/29/16.
//  Copyright © 2016 Yuki Konda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPMDetector : NSObject
- (float)getBPM:(NSURL *)fileURL;
@end
