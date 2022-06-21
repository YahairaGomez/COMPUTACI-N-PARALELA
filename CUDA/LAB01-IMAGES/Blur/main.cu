/**
* Developed By Karan Bhagat
* February 2017
**/

#include <stdio.h>
#include <string>
#include <math.h>
#include <iostream>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

//number of channels i.e. R G B
#define CHANNELS 3
#define BLUR_SIZE 6

//Cuda kernel for blurring an RGB image
__global__
void add_blur(unsigned char *rgb, unsigned char *blur_rgb, int rows, int cols)
{
	int col = threadIdx.x + blockIdx.x * blockDim.x;
	int row = threadIdx.y + blockIdx.y * blockDim.y;

	//Compute for only those threads which map directly to 
	//image grid
	if (col < cols && row < rows)
	{
        int r_pixel_val = 0;
        int g_pixel_val = 0;
        int b_pixel_val = 0;
        int pixels = 0;
        int blur_row = 0;
        int blur_col = 0;
        for (blur_row = -BLUR_SIZE; blur_row < BLUR_SIZE + 1; ++blur_row)
        {
            for (blur_col = -BLUR_SIZE; blur_col < BLUR_SIZE + 1; ++blur_col)
            {
                int cur_row = row + blur_row;
                int cur_col = col + blur_col;

                if (cur_row > -1 && cur_row < rows && cur_col > -1 && cur_col < cols)
                {
					
                    int offset = (cur_row * cols + cur_col) * CHANNELS;
					//weight sum for all 3 channels separately 
                    r_pixel_val += rgb[offset + 0];
                    g_pixel_val += rgb[offset + 1];
                    b_pixel_val += rgb[offset + 2];
                    pixels++;
                }
            }
        }

        int blur_offset = (row * cols + col) * CHANNELS;
	
        blur_rgb[blur_offset + 0] = (unsigned char) (r_pixel_val / pixels);
        blur_rgb[blur_offset + 1] = (unsigned char) (g_pixel_val / pixels);
        blur_rgb[blur_offset + 2] = (unsigned char) (b_pixel_val / pixels);
    }
}

size_t loadImageFile(unsigned char *blur_image, const std::string &input_file, int *rows, int *cols );

void outputImage(const std::string &output_file, unsigned char *blur_image, int rows, int cols);

unsigned char *h_rgb_image; //store image's rbg data

int main(int argc, char **argv) 
{
	std::string input_file;
	std::string output_file;

	//Check for the input file and output file names
	switch(argc) {
		case 3:
			input_file = std::string(argv[1]);
			output_file = std::string(argv[2]);
            break;
		default:
			std::cerr << "Usage: <executable> input_file output_file";
			exit(1);
	}
	
	unsigned char *d_rgb_image; //array for storing rgb data on device
	unsigned char *h_blur_image, *d_blur_image; //host and device's blur image data array pointers
	int rows; //number of rows of pixels
	int cols; //number of columns of pixels
	
	//load image into an array and retrieve number of pixels
	const size_t total_pixels = loadImageFile(h_blur_image, input_file, &rows, &cols);

	//allocate memory of host's blur image data array
	h_blur_image = (unsigned char *)malloc(sizeof(unsigned char*) * total_pixels * CHANNELS);

	//allocate and initialize memory on device
	cudaMalloc(&d_rgb_image, sizeof(unsigned char) * total_pixels * CHANNELS);
	cudaMalloc(&d_blur_image, sizeof(unsigned char) * total_pixels * CHANNELS);
	cudaMemset(d_blur_image, 0, sizeof(unsigned char) * total_pixels * CHANNELS);
	
	//copy host rgb data array to device rgb data array
	cudaMemcpy(d_rgb_image, h_rgb_image, sizeof(unsigned char) * total_pixels * CHANNELS, cudaMemcpyHostToDevice);

	//define block and grid dimensions
	const dim3 dimGrid((int)ceil((cols)/16), (int)ceil((rows)/16));
	const dim3 dimBlock(16, 16);
	
	//execute cuda kernel
	add_blur<<<dimGrid, dimBlock>>>(d_rgb_image, d_blur_image, rows, cols);

	//copy computed gray data array from device to host
	cudaMemcpy(h_blur_image, d_blur_image, sizeof(unsigned char) * total_pixels * CHANNELS, cudaMemcpyDeviceToHost);

	//output the blurred image
	outputImage(output_file, h_blur_image, rows, cols);
	cudaFree(d_rgb_image);
	cudaFree(d_blur_image);
	return 0;
}

//function for loading an image into rgb format unsigned char array
size_t loadImageFile(unsigned char *blur_image, const std::string &input_file, int *rows, int *cols) 
{
	cv::Mat img_data; //opencv Mat object

	//read image data into img_data Mat object
	img_data = cv::imread(input_file.c_str(), CV_LOAD_IMAGE_COLOR);
	if (img_data.empty()) 
	{
		std::cerr << "Unable to laod image file: " << input_file << std::endl;
	}
		
	*rows = img_data.rows;
	*cols = img_data.cols;

	//allocate memory for host rgb data array
	h_rgb_image = (unsigned char*) malloc(*rows * *cols * sizeof(unsigned char) * CHANNELS);
	unsigned char* rgb_image = (unsigned char*)img_data.data;

	//populate host's rgb data array
	int x = 0;
	for (x = 0; x < *rows * *cols * CHANNELS; x++)
	{
		h_rgb_image[x] = rgb_image[x];
	}
	
	size_t num_of_pixels = img_data.rows * img_data.cols;
	
	return num_of_pixels;
}

//function for writing blurred image data array to the image file
void outputImage(const std::string& output_file, unsigned char* blur_image, int rows, int cols)
{
	//serialize gray data array into opencv's Mat object
	cv::Mat blurData(rows, cols, CV_8UC3,(void *) blur_image);
	//write Mat object to file
	cv::imwrite(output_file.c_str(), blurData);
}