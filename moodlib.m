//
//  MathFunctions.m
//  ICodeMathUtils
//
//  Created by Brandon Trebitowski on 4/7/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "moodlib.h"
#import "SmileDetector.h"

@implementation moodlib

// Name of face cascade resource file without xml extension
NSString * const kFaceCascadeFilename = @"haarcascade_frontalface_alt2";
NSString * const kMouthCascadeFilename = @"Mouth";
NSString * const kMouthCascadeFilename2 = @"smiled_05";
cv::VideoCapture *_videoCapture;
cv::Mat _lastFrame;
cv::CascadeClassifier _faceCascade;
cv::CascadeClassifier _mouthCascade;
cv::CascadeClassifier _mouthCascade2;
// Options for cv::CascadeClassifier::detectMultiScale
const int kHaarOptions =  CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH;

-(void)dealloc
{
    if (_videoCapture->isOpened())
        _videoCapture->release();
    delete _videoCapture;
    [super dealloc];
}


- (void)closeCamera
{
    if (_videoCapture->isOpened())
        _videoCapture->release();
    
}

- (BOOL)openCamera
{
    if (!_videoCapture->isOpened())
    {
        if (!_videoCapture->open(CV_CAP_AVFOUNDATION+1))
        {
            NSLog(@"Failed to open video camera");
            return NO;
        }
    }
    return YES;
}


- (void) getMood:(void(^)(int))handler;
{
    int mood = -1;
    int cadresToProcess = 5;
    int failCpunt = 0;
/*    map<int, int> max_array;
    max_array.insert(pair<-1,0>);
    max_array.insert(pair<0,0>);
    max_array.insert(pair<1,0>);
    max_array.insert(pair<2,0>);
*/
    try{
    //NSLog(@"cadresToProcess%d",cadresToProcess);
        while (mood == -1 && cadresToProcess > 0 && failCpunt < 3){
            if (![self openCamera])
            {
                [NSThread exit];
            }
            if (_videoCapture && _videoCapture->grab())
            {
                (*_videoCapture) >> _lastFrame;
                if (_lastFrame.empty())
                {
                    failCpunt++;
                    continue;
                }
                

                mood =[self processFrame];
                mood = rand()%3;
/*                max_array[mood]++;*/
            }
            else
            {
                NSLog(@"Failed to grab frame");
            }
            //NSLog(@"cadresToProcess%d",cadresToProcess);
            cadresToProcess--;
            [self closeCamera];
        }
    }
    catch(...)
    {
       NSLog(@"UUU");
    }
    [self closeCamera];

    //NSLog(@"Handler%d",mood);
   // mood = max(max_array[]);
    handler(mood);
}

void onUncaughtException(NSException* exception)
{
    NSLog(@"UUU");
    [NSThread exit];
}

void SignalHandler(int s)
{
    NSLog(@"UUU");
    [NSThread exit];
}


- (id)init;
{
    self=[super init];

    NSSetUncaughtExceptionHandler(&onUncaughtException);
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
    signal(0x91, SignalHandler);

    
    _videoCapture = new cv::VideoCapture;
    if (!_videoCapture->open(CV_CAP_AVFOUNDATION+1))
    {
        NSLog(@"Failed to open video camera");
    }
    
    // Load the face Haar cascade from resources
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeFilename ofType:@"xml"];
    
    if (!_faceCascade.load([faceCascadePath UTF8String])) {
        NSLog(@"Could not load face cascade: %@", faceCascadePath);
    }
    // Load the face Haar cascade from resources
    NSString *mouthCascadePath = [[NSBundle mainBundle] pathForResource:kMouthCascadeFilename ofType:@"xml"];
    
    if (!_mouthCascade.load([mouthCascadePath UTF8String])) {
        NSLog(@"Could not load mouth cascade: %@", mouthCascadePath);
    }
    
    // Load the face Haar cascade from resources
    NSString *mouthCascadePath2 = [[NSBundle mainBundle] pathForResource:kMouthCascadeFilename2 ofType:@"xml"];
    
    if (!_mouthCascade2.load([mouthCascadePath2 UTF8String])) {
        NSLog(@"Could not load mouth cascade: %@", mouthCascadePath2);
    }
    

   return self; 
}


// Perform image processing on the last captured frame and display the results
- (int)processFrame
{
    cv::Mat grayFrame, output;
    std::vector<cv::Rect> faces;
    std::vector<cv::Rect> mouths;
    std::vector<cv::Rect> mouths2;
    
    // Convert captured frame to grayscale
    cv::cvtColor(_lastFrame, grayFrame, cv::COLOR_RGB2GRAY);
    cv::equalizeHist(grayFrame, grayFrame);    
    _faceCascade.detectMultiScale(grayFrame, faces, 1.1, 1, kHaarOptions, cv::Size(60, 60));
    int smile = 2;
    bool enteredSmile = false;
    
    if (faces.size() == 0)
#ifdef DRAW
        return;
#else
    return -1;
#endif
    
    if (faces.size())
    {
        
        // Adding + 20 pixels as some faces are detected too close for mouth
        if (faces[0].y + faces[0].height + 20 <_lastFrame.rows)
        {
            faces[0].height += 20; 
        }
        
        
        
#ifdef DRAW
        cv::rectangle(_lastFrame, faces[0], cv::Scalar(255,255,255));
        NSLog(@"ROI3  %d, %d, %d, %d ", faces[0].x, faces[0].y, faces[0].width, faces[0].height );
#endif
        grayFrame = grayFrame(faces[0]);
        int faceX = faces[0].x;
        int faceY = faces[0].y;
        cv::Rect face = faces[0];
        int face_3rd = face.height/3;
        //NSLog(@"ROI  %d, %d, %d",  2*face_3rd, face.width, face.height/3);
        
        cv::Rect mouthROI(0, 2*face_3rd,face.width,
                          face.height/3);
        grayFrame = grayFrame(mouthROI);
        
        
#ifdef DRAW
        cv::Rect mt;
        mt.x = mouthROI.x + faceX;
        mt.y = mouthROI.y + faceY;
        
        // show mouth search place
        cv::rectangle(_lastFrame, mt, cv::Scalar(0,0,0));
#endif        
        cv::equalizeHist(grayFrame, grayFrame);  
        _mouthCascade2.detectMultiScale(grayFrame, mouths2, 1.1, 1, 0, cv::Size(30, 30));
        if (mouths2.size()) 
        {   
            enteredSmile = true;
            smile = 1;
#ifdef DRAW
            int best_mouth = getClosedMouth(mouths2, mouthROI);
            
            for (int j=0; j< mouths2.size(); ++j)
            {
                mouths2[j].x = mouths2[j].x + mouthROI.x + faceX;
                mouths2[j].y = mouths2[j].y + mouthROI.y + faceY;
                if (j == best_mouth )
                    cv::rectangle(_lastFrame, mouths2[j], cv::Scalar(0,255,0));
                else
                    cv::rectangle(_lastFrame, mouths2[j], cv::Scalar(0,0,0));
            }
#endif
        }
        
        if (smile == 2) 
        {
            _mouthCascade.detectMultiScale(grayFrame, mouths, 1.1, 1, 0, cv::Size(30, 30));        
            if (mouths.size()) 
            {
                enteredSmile = true;
                
                int best_mouth = getClosedMouth(mouths, mouthROI);
                
                //NSLog(@"Mouth rect aaaa");
                for (int j=0; j< mouths.size(); ++j)
                {
                    
                    if (j == best_mouth )
                    {
                        
                        //NSLog(@"ROI2  %d, %d, %d, %d ",  mouths[j].x, mouths[j].y, mouths[j].width,mouths[j].height );
                        output = grayFrame(mouths[j]);
                        mouths[j].x = mouths[j].x + mouthROI.x + faceX;
                        mouths[j].y = mouths[j].y + mouthROI.y + faceY;
                        
                        if (featureExtractor(output, _lastFrame, mouths[j].x, mouths[j].y))
                        {
                            smile = 1;
                        }
                        
#ifdef DRAW
                        cv::rectangle(_lastFrame, mouths[j], cv::Scalar(255,0,0));
#endif
                        
                    }
                    else
                    {
#ifdef DRAW
                        mouths[j].x = mouths[j].x + mouthROI.x + faceX;
                        mouths[j].y = mouths[j].y + mouthROI.y + faceY;
                        cv::rectangle(_lastFrame, mouths[j], cv::Scalar(0,0,255));
#endif
                    }
                }
            }
        }
        
        
    }
    
    if (!enteredSmile)
    {
        
#ifdef DRAW
        return;
#else
        return -1;
#endif
    }
    
    if (smile == 1)
        NSLog(@"SMILE!");
    else
        NSLog(@"NOSMILE!");
    
#ifdef DRAW
    self.imageView.image = [UIImage imageWithCVMat:_lastFrame];
#else
    return smile;
#endif
}
@end
