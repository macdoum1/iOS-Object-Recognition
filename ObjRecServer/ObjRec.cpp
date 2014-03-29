// Michael MacDougall
// ObjRec

#include <stdio.h>
#include <opencv2/opencv.hpp>
#include <dirent.h>
#include <vector>
#include <ctime>

using namespace cv;

#define KEY_POINT_SENSITIVITY 30
#define GOOD_MATCH_THRESHOLD 110

vector<string> listFiles( const char* path )
{
   DIR* dirFile = opendir( path );
   vector<string> returnVector;
   if ( dirFile ) 
   {
      struct dirent* hFile;
      errno = 0;
      while (( hFile = readdir( dirFile )) != NULL ) 
      {
         if ( !strcmp( hFile->d_name, "."  )) continue;
         if ( !strcmp( hFile->d_name, ".." )) continue;
         if ( hFile->d_name[0] == '.' ) continue;
		 returnVector.push_back(hFile->d_name);
      } 
      closedir( dirFile );
   }
   return returnVector;
}


int main(int argc, char** argv)
{
	clock_t startTime = clock();
	double secondsPassed;
	// Get Image
	Mat image;
	image = imread(argv[1],1);

	if(image.empty())
	{
	}
	// Convert to grayscale
	Mat tempGray;

	cvtColor(image,tempGray, COLOR_RGB2GRAY);
	// Get keypoints
	vector<KeyPoint> keyPointVector;
	FAST(tempGray,keyPointVector,KEY_POINT_SENSITIVITY);
	

	// Get descriptors
	Mat testDescriptor;
	FREAK freak;
	freak.compute(tempGray,keyPointVector,testDescriptor);

	// Get all descriptor filenames from database directory

	vector<string> fileVector = listFiles("Descriptor_Database");

	// Set up matcher
		//std::cout << "after" << std::endl;

	BFMatcher matcher(NORM_HAMMING);
	vector<DMatch> matches;
	int maxMatch = -1;
	double maxMatchPercent = 0.0;
	double percent = 0.0;
			//std::cout << "before" << std::endl;

	// Loop through all files
	Mat databaseDescriptor;
	for(int i = 0; i < fileVector.size(); i++)
	{
		// Set up path
		string filename = fileVector[i];
		filename = "Descriptor_Database/" + filename;
		//std::cout << filename << std::endl;
		// Open file
		FileStorage fs(filename.c_str(), FileStorage::READ);
			if(fs.isOpened())
			{
				// Get descriptors
				read(fs["descriptors"],databaseDescriptor);
				percent = 0.0;
				
				// Perform match
				matcher.match(testDescriptor,databaseDescriptor, matches);
				
				// Check for good matches
				int goodMatches = 0;
				for(int j=0;j<matches.size() -1;j++)
				{
					if(matches[j].distance < GOOD_MATCH_THRESHOLD)
					{
						goodMatches++;
					}
				}
			
				// Calculate percent and store if better than all previous
				percent = (goodMatches / (double) matches.size()) * 100;
				if(percent > maxMatchPercent)
				{
					maxMatchPercent = percent;
					maxMatch = i;
				}
			}
		fs.release();
	}
	// Print result
	if(maxMatch != -1)
	{
		// Remove extensions from filename
		string objWith2Ext = fileVector[maxMatch];
		int lastIndex = objWith2Ext.find_last_of(".");
		string objWith1Ext = objWith2Ext.substr(0, lastIndex);
		lastIndex = objWith1Ext.find_last_of(".");
		string matchedObj = objWith1Ext.substr(0,lastIndex);
		
		std::cout << "M|" << matchedObj << "|" << maxMatchPercent;
	}
	else
	{
		std::cout << "NM|" << std::endl;
	}	
	secondsPassed = (clock() - startTime);
	//std::cout << "Time Taken: " << secondsPassed << std::endl;
}