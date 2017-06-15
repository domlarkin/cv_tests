/* OpenCV3: Thresholding using GPU */
#include <iostream>
#include <string.h>
#include <time.h>
#include <ctime>
#include <chrono>

//#include "opencv2/opencv.hpp"
//#include "opencv2/imgcodecs.hpp"
//#include "opencv2/core/cuda.hpp"
//#include "opencv2/cudaarithm.hpp"

#include "opencv2/core.hpp"
#include <opencv2/core/utility.hpp>
#include "opencv2/highgui.hpp"
#include "opencv2/imgproc.hpp"
#include "opencv2/cudaimgproc.hpp"
#include "opencv2/cudafilters.hpp" // used for gaussian
#include "opencv2/cudaarithm.hpp" // Used for threshold
#include "opencv2/core/matx.hpp" // Used for vec4i

#include <fstream>
#include <sstream>

using namespace cv;

int threshold_value = 225;
int threshold_type = 3;
int erosion_size = 1;
int bkSize =5;
int ekSize =3;
int h_rho = 1; // Distance resolution of the accumulator in pixels (hough transform)
int h_theta = 180; // Angle resolution of the accumulator in radians (hough transform)
int h_minLineLen = 150; // Line segments shorter than that are rejected (hough transform)
int h_maxLineGap = 25; // Maximum allowed gap between points on the same line to link them (hough transform)

//std::vector<cv::Vec4i> lines;
cv::cuda::GpuMat d_lines;

int const max_value = 255;
int const max_type = 4;
int const max_BINARY_value = 255;
cv::cuda::GpuMat src, src_gray, src_blur, src_erode, src_canny, dst;
cv::Mat src_host; 
const char* window_name = "Threshold Demo";
const char* trackbar_type = "Type: \n 0: Binary \n 1: Binary Inverted \n 2: Truncate \n 3: To Zero \n 4: To Zero Inverted";
const char* trackbar_value = "Value";
void Threshold_Demo( int, void* );

void log2file( const std::string &text )
{
    std::ofstream log_file(
        "log_file_cuda.csv", std::ios_base::out | std::ios_base::app );
    log_file << text;
}
bool isLogging=false;

int main( int, char** argv )
{
    namedWindow( window_name, WINDOW_AUTOSIZE );
    createTrackbar( trackbar_type, window_name, &threshold_type, max_type);
    createTrackbar( trackbar_value, window_name, &threshold_value, max_value);
    createTrackbar( "Blur kSize", window_name, &bkSize, 9);
    createTrackbar( "Erode kSize", window_name, &ekSize, 9);
    createTrackbar( "h_rho", window_name, &h_rho, 10);
    createTrackbar( "h_theta", window_name, &h_theta, 180);
    createTrackbar( "h_minLineLen", window_name, &h_minLineLen, 400);
    createTrackbar( "h_maxLineGap", window_name, &h_maxLineGap, 100);


    VideoCapture capture("leftcam_15.avi");
    if(!capture.isOpened()){
        std::cout<<"cannot read video!\n";
        return -1;
    }
    std::ostringstream colHeaders;
    colHeaders << "top,aftblur,aftgray,aftthresh,afterode,aftcanny,afthough,aftdrawing,"<<CLOCKS_PER_SEC<<"\n" ;
    if (isLogging) log2file(colHeaders.str());
    bool pause = false;
    while(true)
    {
        if(!pause){
            if(!capture.read(src_host)){
                break;
            }
        }
        Threshold_Demo(0,0);
        int c = waitKey(20);
        if((char)c == 27) { 
            break;
        }
        else if(c == 'p'){
            pause = !pause;
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
    src.upload(src_host); 
    if (isLogging) outStream << clock() << ","; // TIMER: top
    
    // ===== Blur the image CUDA
    cv::Ptr<cv::cuda::Filter> filter = cv::cuda::createGaussianFilter(src.type(), src_blur.type(), cv::Size((bkSize*2)+1, (bkSize*2)+1), 0.0);
    filter->apply(src, src_blur);
    if (isLogging) outStream << clock() << ","; // TIMER: aftblur 
   
    // ===== GrayScale the image CUDA    
    cv::cuda::cvtColor( src_blur, src_gray, COLOR_RGB2GRAY );
    if (isLogging) outStream << clock() << ","; // TIMER: aftgray 
    
    // ===== Threshhold the image CUDA
    cv::cuda::threshold( src_gray, src_erode, threshold_value, max_BINARY_value,threshold_type );
    if (isLogging) outStream << clock() << ","; // TIMER: aftthresh 

    // ===== Erode the image CUDA
    cv::Mat element = getStructuringElement(cv::MORPH_ELLIPSE, cv::Size((ekSize*2)+1, (ekSize*2)+1),
                                            cv::Point(-1, -1));
    Ptr<cuda::Filter> erodeFilter = cv::cuda::createMorphologyFilter(MORPH_ERODE, src_erode.type(), element);
    erodeFilter->apply(src_erode, src_canny);
    if (isLogging) outStream << clock() << ","; // TIMER: afterode   

    // ===== Canny edge detection CUDA
    cv::Ptr<cv::cuda::CannyEdgeDetector> canny = cv::cuda::createCannyEdgeDetector(50, 250, 3);
    canny->detect(src_canny, dst);
    if (isLogging) outStream << clock() << ","; // TIMER: aftcanny 

    // ===== Find the Hough lines CUDA
    //cv::Ptr<cv::cuda::HoughSegmentDetector> hough = cv::cuda::createHoughSegmentDetector(1.0f, (float) (CV_PI / 180.0f), 50, 5);
    cv::Ptr<cv::cuda::HoughSegmentDetector> hough = cv::cuda::createHoughSegmentDetector(h_rho, (CV_PI / h_theta), h_minLineLen, h_maxLineGap);
    hough->detect(src_canny, d_lines);
    if (isLogging) outStream << clock() << ","; // TIMER: afthough
    std::vector<cv::Vec4i> lines_gpu;
    if (!d_lines.empty())
    {
        lines_gpu.resize(d_lines.cols);
        Mat h_lines(1, d_lines.cols, CV_32SC4, &lines_gpu[0]);
        d_lines.download(h_lines);
    }
    Mat dst_host;
    src.download(dst_host);
    for (size_t i = 0; i < lines_gpu.size(); ++i)
    {
        Vec4i l = lines_gpu[i];
        line(dst_host, Point(l[0], l[1]), Point(l[2], l[3]), Scalar(0, 0, 255), 3, LINE_AA);
    }
    
    if (isLogging) outStream << clock() << "\n"; // TIMER: aftdrawing
    if (isLogging) log2file(outStream.str());
    imshow( window_name, dst_host );
}
