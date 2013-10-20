//
//  MathFunctions.h
//  ICodeMathUtils
//
//  Created by Brandon Trebitowski on 4/7/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoCaptureViewController;

@interface moodlib : NSObject {

}

- (void) getMood:(void(^)(int))handler;
- (int)processFrame;
- (void)closeCamera;
- (BOOL)openCamera;

@end
