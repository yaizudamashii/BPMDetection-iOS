//
//  ViewController.m
//  BPMDetect
//
//  Created by Yuki Konda on 1/29/16.
//  Copyright © 2016 Yuki Konda. All rights reserved.
//

#import "ViewController.h"
#import "BPMDetector.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *BPMResultLabel;
@end

@implementation ViewController

- (NSURL *)audioFileURL {
    NSString *trackPath = [[NSBundle mainBundle] pathForResource:@"track_Who_Do_You_Think_You_Are_Spice_Girls" ofType:@"m4a"];
    NSURL *trackURL;
    if ([[NSFileManager defaultManager] fileExistsAtPath:trackPath]) {
        trackURL = [NSURL fileURLWithPath:trackPath];
    }
    return trackURL;
}

- (void)viewDidAppear:(BOOL)animated {
    NSURL *url = [self audioFileURL];
    if (url) {
        [self performSelectorInBackground:@selector(displayBPM:) withObject:url];
    }
}

- (void)displayBPM:(NSURL *)url {
    BPMDetector *detector = [[BPMDetector alloc] init];
    float bpm = [detector getBPM:url];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.BPMResultLabel.text = [NSString stringWithFormat:@"%.2f", bpm];
    });
}

@end
