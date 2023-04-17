# Large-TSP-batches-solver
Solving large batches of traveling salesman problems with parallel and distributed computing

## Serial part
g++ -o solver.exe serial_solver.cpp

.\solver  

## Parallel part
g++ --o solver.exe parallel_solver.cpp -pthread

.\solver
