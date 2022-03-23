#include <iostream>
#include <ctime> 
#include <vector>
#define MAX 1000
using namespace std;

unsigned t0, t1, t2, t3;
double C[MAX][MAX], A[MAX][MAX], B[MAX][MAX];
vector<double> v1;

//Lleno matrices A y B
void init(){
    for (int i = 0; i < MAX; i++)
        for (int j = 0; j < MAX; j++){
            A[i][j] = rand() % 100;
            B[i][j] = rand() % 100;
        }
}

//MULTIPLICACION NORMAL (3 BUCLES)
void mulNormal(){
    for (int i = 0; i < MAX; i++) {
        for (int j = 0; j < MAX; j++) {
            for (int k = 0; k < MAX; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
            
    }
}

int main() {

    //MULTIPLICACION NORMAL
    init();
    t0=clock();
    mulNormal();
    t1=clock();
    double time = (double(t1-t0)/CLOCKS_PER_SEC);
    cout << "Tiempo de ejecucion Multiplicacion normal: " << time << endl;

    
}
