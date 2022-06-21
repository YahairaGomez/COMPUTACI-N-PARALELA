#include <cstdio>
#include <cuda_runtime.h>
#include <stdlib.h>

using namespace std;

#if defined(NDEBUG)
#define CUDA_CHECK (x) (x)
#else
#define CUDA_CHECK(X) do{\
	(X);\
	cudaError_t e = cudaGetLastError(); \
	if(cudaSuccess != e){\
		printf("cuda failure %s at %s : %d", cudaGetErrorString(e), __FILE__, __LINE__);\
		exit(1);\
	}\
}while (0)
#endif

__global__ void addKernel(int* c, const int* a, const int* b)
{
	int x = threadIdx.x;
	int y = threadIdx.y;
	int i = y * (blockDim.x) + x;	//[y][x] = y * width + x
	c[i] = a[i] + b[i];
}

int main()
{
	const int WIDTH = 5;
	int a[WIDTH][WIDTH];
	int b[WIDTH][WIDTH];
	int c[WIDTH][WIDTH] = { 0 };

	//make a,b matrix
	for (int y = 0; y < WIDTH; y++)
	{
		for (int x = 0; x < WIDTH; x++)
		{
			a[y][x] = rand() % 20;
			b[y][x] = rand() % 20;
		}
	}

    //imprimiendo matriz A
    printf("VALORES DE MATRIZ A \n");
	for (int y = 0; y < WIDTH; y++)
	{
		for (int x = 0; x < WIDTH; x++)
		{
			printf("%5d", a[y][x]);
		}
		printf("\n");
	}
	
	printf("\n\n VALORES DE MATRIZ A \n");
	for (int y = 0; y < WIDTH; y++)
	{
		for (int x = 0; x < WIDTH; x++)
		{
			printf("%5d", b[y][x]);
		}
		printf("\n\n");
	}
	
	// device-side data
	int* dev_a = 0;
	int* dev_b = 0;
	int* dev_c = 0;

	//allocate device memory
	CUDA_CHECK(cudaMalloc((void**)&dev_a, WIDTH * WIDTH * sizeof(int)));
	CUDA_CHECK(cudaMalloc((void**)&dev_b, WIDTH * WIDTH * sizeof(int)));
	CUDA_CHECK(cudaMalloc((void**)&dev_c, WIDTH * WIDTH * sizeof(int)));

	//copy from host to device
	CUDA_CHECK(cudaMemcpy(dev_a, a, WIDTH * WIDTH * sizeof(int), cudaMemcpyHostToDevice));
	CUDA_CHECK(cudaMemcpy(dev_b, b, WIDTH * WIDTH * sizeof(int), cudaMemcpyHostToDevice));

	//launch a kernel on the GPU with one thread for each element
	dim3 dimBlock(WIDTH, WIDTH, 1);
	addKernel <<<1, dimBlock >>> (dev_c, dev_a, dev_b);
	CUDA_CHECK(cudaPeekAtLastError());
	
	//copy from device to host
	CUDA_CHECK(cudaMemcpy(c, dev_c, WIDTH * WIDTH * sizeof(int), cudaMemcpyDeviceToHost));

	//free device memory
	CUDA_CHECK(cudaFree(dev_c));
	CUDA_CHECK(cudaFree(dev_a));
	CUDA_CHECK(cudaFree(dev_b));

	//print the result
	printf("RESULTADO DE SUMA \n");
	for (int y = 0; y < WIDTH; y++)
	{
		for (int x = 0; x < WIDTH; x++)
		{
			printf("%5d", c[y][x]);
		}
		printf("\n");
	}
	return 0;
}