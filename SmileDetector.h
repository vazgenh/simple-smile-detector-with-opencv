//
//  SmileDetector.h
//  MoodTest
//
//  Created by Vazgen Hakobjanyan on 5/5/12.
//

#ifndef MoodTest_SmileDetector_h
#define MoodTest_SmileDetector_h

//#define DRAW


int featureExtractor(cv::Mat& grayFrame, cv::Mat& _lastFrame, int offsetX, int offsetY)
{
    std::vector<cv::Point2f> points[2];
    
    cv::goodFeaturesToTrack(grayFrame, points[1], 500, 0.1, 10, cv::Mat(), 3, 0, 0.04);
    int px =0, py =0;
    cv::Point2f pt;
#ifdef DRAW
    
    for( int i =  0; i < points[1].size(); i++ )
    {
        pt.x = points[1][i].x + offsetX;
        pt.y = points[1][i].y + offsetY;
        cv::circle( _lastFrame,  pt, 3, cv::Scalar(0,255,0), -1, 8);    // Display result 
    }
#endif
    
    int third_cols = grayFrame.cols/3;
    int two_third_cols = third_cols * 2;
    
    int third_rows = grayFrame.rows/3;
    int two_third_rows = third_rows * 2;
    
    int  count_den[3][3]={0}; 
    
    
    for (int i =  0; i < points[1].size(); i++)
    {
        px = points[1][i].x; 
        py = points[1][i].y; 
        
        if (px > two_third_cols) // upper 3th
        {
            if (py > two_third_rows) // 02
                count_den[0][2]++;
            else if (py <= two_third_rows && py > third_rows) // 01
                count_den[0][1]++;
            else
                count_den[0][0]++;
        }
        else if (px <= two_third_cols && px > third_cols)
        {
            if (py > two_third_rows) // 02
                count_den[1][2]++;
            else if (py <= two_third_rows && py > third_rows) // 01
                count_den[1][1]++;
            else
                count_den[1][0]++;
            
        }
        else
        {
            if (py > two_third_rows) // 02
                count_den[2][2]++;
            else if (py <= two_third_rows && py > third_rows) // 01
                count_den[2][1]++;
            else
                count_den[2][0]++;
            
        }
    }
    
    int smile = 0;        
    
    NSLog(@"Mouth rect %d, %d, %d", count_den[0][0], count_den[0][1], count_den[0][2]);
    if (count_den[0][0] > count_den[0][1] && count_den[0][2] > count_den[0][1])
        smile = 1;
    
    return smile;
    
}





// Select most close to face boundrary mouth
int getClosedMouth(std::vector<cv::Rect>& mouths, cv::Rect& mouthROI)
{
    int thrd = mouthROI.height/3;
    int mouthUpperROIY =  mouthROI.y + thrd;
    int mouthBottomROIY = mouthUpperROIY + thrd;
    int closest_to_middle_upper = -1, closest_to_middle_lower =-1;
    int closest_to_middle_upper_id = -1, closest_to_middle_lower_id =-1, middle_id = -1;
    
    
    for (int i=0; i<mouths.size(); ++i) {
        int centerY = mouths[i].y + mouths[i].height/2;
        
        // if too upper
        if ( centerY < mouthUpperROIY )
        {
            if  (centerY > closest_to_middle_upper)
            {
                closest_to_middle_upper = centerY;
                closest_to_middle_upper_id = i;   
            }
        }
        else if ( centerY > mouthBottomROIY ) // if too lower
        {
            if  (centerY > closest_to_middle_upper)
            {
                closest_to_middle_lower = centerY;
                closest_to_middle_lower_id = i;
            }
        } else //middle!
        {
            if (middle_id == -1)
            {
                middle_id = i;
            }
            // if already one in the middle than select mouth with more big area 
            else if (mouths[i].area() > mouths[middle_id].area())
            {
                middle_id = i;
            }
            
        }
        
    }
    
    if (middle_id == -1) // this means we need to select closest mouth from others
    {
        if (closest_to_middle_upper == -1)
            return closest_to_middle_lower_id;
        
        if (closest_to_middle_lower == -1)
            return closest_to_middle_upper_id;
        
        int dist_mid_upper = (closest_to_middle_lower - mouthBottomROIY);
        int dist_mid_lower = ( mouthUpperROIY - closest_to_middle_upper);
        
        if (dist_mid_upper > dist_mid_lower)
        {
            return closest_to_middle_lower_id;
        }
        else if (dist_mid_upper == dist_mid_lower)
        {
            if (mouths[closest_to_middle_lower_id].area() > mouths[closest_to_middle_upper_id].area())
                return closest_to_middle_lower_id;
            else
                return closest_to_middle_upper_id;
        }
        else
        {
            return closest_to_middle_upper_id;
        }
    }
    else
    {
        return middle_id;
    }
}

#endif
