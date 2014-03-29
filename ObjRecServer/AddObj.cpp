// Michael MacDougall
// AddObj

#include <stdio.h>
#include <opencv2/opencv.hpp>

using namespace cv;

#define KEY_POINT_SENSITIVITY 30


int main(int argc, char** argv)
{
	// Get Image
	Mat image;
	image = imread(argv[1],1);
	
	// Convert to grayscale
	Mat tempGray;
	cvtColor(image,tempGray, COLOR_RGB2GRAY);
	
	// Get keypoints
	vector<KeyPoint> keyPointVector;
	FAST(tempGray,keyPointVector,KEY_POINT_SENSITIVITY);
	
	// Get descriptors
	Mat tempDescriptor;
	FREAK freak;
	freak.compute(tempGray,keyPointVector,tempDescriptor);
	
	// Write descriptors to file
	string filename = argv[1];
	string filenameString = "Descriptor_Database/" + filename + ".yml";
	FileStorage fs(filenameString,FileStorage::WRITE);
	write(fs,"descriptors",tempDescriptor);
	
	fs.release();
	
}