//mpirun -np 6 ./matrix_vec 1000 8
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>
int cols; // Nro columnas
int rows; // Nro filas y size vector
int main(int argc, char** argv) {

   
  
   int p_count; // Nro procesos
   int p_id; 

   int i, j; //iteradores
   int *vector; 
   int *matrix; // matriz principal
   int *my_matrix; // Matriz dividida por procesadores (para poder operarla)
   int *result_vector; 
   int debug = 0; // debug flag

   MPI_Init(&argc, &argv); 
   MPI_Comm_size(MPI_COMM_WORLD, &p_count);  
   MPI_Comm_rank(MPI_COMM_WORLD, &p_id);  

  
   if(argc == 3)
   {
      rows = atoi(argv[1]);
      cols = atoi(argv[2]);
      if(!p_id) printf("Filas = %d, Colum = %d\n\n", rows, cols);
   }
  
    //Reservo espacio para vector
    srand(time(NULL));
   vector = malloc(rows*sizeof(int));
   if(!p_id)
   {
      // Reservo espacio para matriz y vector resultante en proceso 0
      matrix = malloc(rows*cols*sizeof(int));
      result_vector = malloc(rows*sizeof(int));
      //Lleno vector random
      for(i = 0; i < rows; i++)
         vector[i] = rand()%20;
      // Lleno matriz random
      for(i=0; i < rows; i++){
         for(j=0; j < cols; j++){
            matrix[i*cols+j] = rand()%20;
         }
      }

   }

   MPI_Barrier(MPI_COMM_WORLD);
   clock_t start =clock();

   
   // Organizo trabajo para cada proc
   int block_rows[p_count];
   int block_cols[p_count];
   int row_remain = rows%p_count;
   for(i=0; i<p_count; i++)
   {
      block_rows[i] = rows/p_count;
      if(i < row_remain) block_rows[i]++;
      block_cols[i] = cols;
   }
   int my_rows = block_rows[p_id];
   int my_cols = block_cols[p_id];

   // Asigno todas las listas para hacer scatter y gather
   my_matrix = malloc(my_rows*my_cols*sizeof(int)); // Matrices parciales
   int *scount = malloc(p_count*sizeof(int)); 
   int *displ = malloc(p_count*sizeof(int)); 
   int *r_displ = malloc(p_count*sizeof(int)); 
   int *rcount = malloc(p_count*sizeof(int)); 
   int tail = 0; 
   int r_tail = 0; 
   for(i=0; i<p_count; i++)
   {
      displ[i] = tail;
      r_displ[i] = r_tail;
      scount[i] = block_cols[i]*block_rows[i];
      rcount[i] = block_rows[i];
      r_tail = r_tail + rcount[i];
      tail = tail + scount[i];
   }
   MPI_Scatterv(matrix, scount, displ, MPI_INT, my_matrix, (my_rows*my_cols), MPI_INT, 0, MPI_COMM_WORLD);
   MPI_Bcast(vector, rows, MPI_INT, 0, MPI_COMM_WORLD);

   int *partial_vector = calloc(block_rows[p_id], sizeof(int));
   int sum;

   // Hago operacion de matrix c vector
   for(i=0; i<block_rows[p_id];i++)
   {
      sum = 0;
      for(j=0; j<block_cols[p_id]; j++)
      {
         sum += my_matrix[i*block_cols[p_id]+j]*vector[j];
      }
      partial_vector[i] = sum;
   }

   MPI_Gatherv(partial_vector, block_rows[p_id], MPI_INT, result_vector, rcount, r_displ, MPI_INT, 0, MPI_COMM_WORLD);

    MPI_Barrier(MPI_COMM_WORLD);
    clock_t end =clock();
    float elapsed = (double)(end - start) / CLOCKS_PER_SEC;
    if(!p_id)
    {
        printf("Time execution: %f\n", elapsed);
        free(matrix);
        free(vector);
        free(result_vector);
    }
    
    free(my_matrix);
    free(scount);
    free(rcount);
    free(r_displ);
    free(displ);

    MPI_Finalize();
}
