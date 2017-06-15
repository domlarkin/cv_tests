#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/imgcodecs.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <sstream>

using namespace cv;

int threshold_value = 240;
int threshold_type = 3;
int erosion_size = 1;
int bkSize =5;
int ekSize =3;
int h_rho = 1; // Distance resolution of the accumulator in pixels (hough transform)
int h_theta = 180; // Angle resolution of the accumulator in radians (hough transform)
int h_thresh = 5; // Accumulator threshold parameter. Only those lines are returned that get enough votes (hough transform)
int h_minLineLen = 10; // Line segments shorter than that are rejected (hough transform)
int h_maxLineGap = 7; // Maximum allowed gap between points on the same line to link them (hough transform)

std::vector<cv::Vec4i> lines;

int const max_value = 255;
int const max_type = 4;
int const max_BINARY_value = 255;
Mat src, src_gray, src_blur, src_erode, src_canny, dst;
const char* window_name = "Threshold Demo";
const char* trackbar_type = "Type: \n 0: Binary \n 1: Binary Inverted \n 2: Truncate \n 3: To Zero \n 4: To Zero Inverted";
const char* trackbar_value = "Value";
void Threshold_Demo( int, void* );

void log2file( const std::string &text )
{
    std::ofstream log_file(
        "log_fileth.csv", std::ios_base::out | std::ios_base::app );
    log_file << text;
}
bool isLogging=true;

int main( int, char** argv )
{
    namedWindow( window_name, WINDOW_AUTOSIZE );
    createTrackbar( trackbar_type, window_name, &threshold_type, max_type);
    createTrackbar( trackbar_value, window_name, &threshold_value, max_value);
    createTrackbar( "Blur kSize", window_name, &bkSize, 9);
    createTrackbar( "Erode kSize", window_name, &ekSize, 9);

    VideoCapture capture("leftcam_15.avi");
    if(!capture.isOpened()){
        std::cout<<"cannot read video!\n";
        return -1;
    }
    std::ostringstream colHeaders;
    colHeaders << "top,aftblur,aftgray,aftthresh,afterode,aftcanny,afthough,aftdrawing,"<<CLOCKS_PER_SEC<<"\n" ;
    if (isLogging) log2file(colHeaders.str());
    while(true)
    {
        if(!capture.read(src)){
            break;
        }

        Threshold_Demo(0,0);

        int c = waitKey(20);
        if((char)c == 27) { 
            break;
        }


    }
}

void Threshold_Demo( int, void* )
{ 
  /* 0: Binary
     1: Binary Inverted
     2: Threshold Truncated
     3: Threshold to Zero
     4: Threshold to Zero Inverted
   */
   
   /*
     *  It Uses the following algorithm to find white lines:
     *     1. blur the image
     *     2. turn image into grayscale
     *     3. run it through a threshold filter using THRESH_TO_ZERO mode
     *     4. run it through an erosion filter
     *     5. run it through a Canny edge detector
     *     6. finally, take this processed image and find the lines using   
   */
   // Blur the image
    std::ostringstream outStream; 
    if (isLogging) outStream << clock() << ","; // TIMER: top
    GaussianBlur(src, src_blur, cv::Size((bkSize*2)+1, (bkSize*2)+1), 0.0, 0.0, cv::BORDER_DEFAULT);  
    if (isLogging) outStream << clock() << ","; // TIMER: aftblur 
   // GrayScale the image     
    cvtColor( src_blur, src_gray, COLOR_RGB2GRAY );
    if (isLogging) outStream << clock() << ","; // TIMER: aftgray 
   // Threshhold the image
    threshold( src_gray, src_erode, threshold_value, max_BINARY_value,threshold_type );
    if (isLogging) outStream << clock() << ","; // TIMER: aftthresh 
    // Erode the image
    cv::Mat element = getStructuringElement(cv::MORPH_ELLIPSE, cv::Size((ekSize*2)+1, (ekSize*2)+1),
                                            cv::Point(-1, -1));
    cv::erode(src_erode, src_canny, element); 
    if (isLogging) outStream << clock() << ","; // TIMER: afterode    
    // Canny edge detection
    cv::Canny(src_canny, dst, 50, 250, 3);
    if (isLogging) outStream << clock() << ","; // TIMER: aftcanny 
    
    // Find the Hough lines
    cv::HoughLinesP(src_canny, lines, h_rho, (CV_PI / h_theta), h_thresh, h_minLineLen, h_maxLineGap);
    if (isLogging) outStream << clock() << ","; // TIMER: afthough
    //Mat hough_image = cv::Mat::zeros(src_canny.size(), src_canny.type());
        // Draw the Hough lines on the image
    for (int i = 0; i < lines.size(); i++) {
        line(src, cv::Point(lines[i][0], lines[i][1]),
            cv::Point(lines[i][2], lines[i][3]), cv::Scalar(0, 0, 255), 3, 8);
    }
    if (isLogging) outStream << clock() << "\n"; // TIMER: aftdrawing
    if (isLogging) log2file(outStream.str());
    //imshow("HoughLines", src);
    imshow( window_name, src );
}
