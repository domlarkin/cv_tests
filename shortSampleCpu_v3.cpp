/* OpenCV3: Thresholding using CPU */
#include <iostream>
#include <string.h>
#include <time.h>
#include <ctime>
#include <chrono>
#include "opencv2/opencv.hpp"
#include "opencv2/imgcodecs.hpp"
#include <fstream>
#include <sstream>

void log2file( const std::string &text )
{
    std::ofstream log_file(
        "log_filec3.csv", std::ios_base::out | std::ios_base::app );
    log_file << text;
}

bool isLogging=true;

using namespace cv;

int main (int argc, char* argv[])
{
    try
    {
        for(int i = 0; i < 1000; i++){
            std::ostringstream outStream; 
            cv::Mat src_host = cv::imread("file.png", IMREAD_GRAYSCALE);
            if (isLogging) outStream << clock() << ","; // TIMER: top
            cv::Mat dst;

            cv::threshold(src_host, dst, 128.0, 255.0, THRESH_BINARY);
            if (isLogging) outStream << clock() << "\n"; // TIMER: bottom
            if (isLogging) log2file(outStream.str());
            //cv::imshow("Result", result_host);
            //cv::waitKey();
        }
    }
    catch(const cv::Exception& ex)
    {
        std::cout << "Error: " << ex.what() << std::endl;
    }
    return 0;
}
