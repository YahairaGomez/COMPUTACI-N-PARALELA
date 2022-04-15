#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <time.h>
// Nros random
int rand_range(int min, int max)
{
    return rand() % (max - min + 1) + min;
}
//Defino la clase linked_list
pthread_mutex_t mutex;
struct list_node_s
{
    int data;
    struct list_node_s *next;
};
struct list_node_s *head_p = NULL;
int Member(int value)
{
    struct list_node_s *curr_p = head_p;
    while (curr_p != NULL && curr_p->data < value)
        curr_p = curr_p->next;
    if (curr_p == NULL || curr_p->data > value)
        return 0;
    else
        return 1;
}
int Insert(int value)
{
    struct list_node_s *curr_p = head_p;
    struct list_node_s *pred_p = NULL;
    struct list_node_s *temp_p;
    while (curr_p != NULL && curr_p->data < value)
    {
        pred_p = curr_p;
        curr_p = curr_p->next;
    }
    if (curr_p == NULL || curr_p->data > value)
    {
        temp_p = malloc(sizeof(struct list_node_s));
        temp_p->data = value;
        temp_p->next = curr_p;
        if (pred_p == NULL)
            head_p = temp_p;
        else
            pred_p->next = temp_p;
        return 1;
    }
    else
        return 0;
}
int Delete(int value)
{
    struct list_node_s *curr_p = head_p;
    struct list_node_s *pred_p = NULL;
    while (curr_p != NULL && curr_p->data < value)
    {
        pred_p = curr_p;
        curr_p = curr_p->next;
    }
    if (curr_p == NULL || curr_p->data > value)
    {
        return 0;
    }
    else
    {
        if (pred_p == NULL)
            head_p = curr_p->next;
        else
            pred_p->next = curr_p->next;
        free(curr_p);
        return 1;
    }
}
int Print()
{
    struct list_node_s *curr_p = head_p;
    while (curr_p != NULL)
    {
        printf("%d ", curr_p->data);
        curr_p = curr_p->next;
    }
    printf("\n");
    return 1;
}
void OpHelper()
{
    int i;
    for (i = 0; i < 100000; i++)
    {
        int op = rand_range(0, 9);
        int value=rand_range(0, 10000);
        if (op == 0)
        {
            pthread_mutex_lock(&mutex);
            Delete(value);
            pthread_mutex_unlock(&mutex);
        }
        else if (op == 1)
        {
            pthread_mutex_lock(&mutex);
            Insert(value);
            pthread_mutex_unlock(&mutex);
        }
        else
        {
            pthread_mutex_lock(&mutex);
            Member(value);
            pthread_mutex_unlock(&mutex);
        }
    }
}
void mainHelper(int numThreads)
{
    head_p = NULL;
    //Inicializar la lista con 1000 elementos
    int i;
    for (i = 0; i < 1000; i++)
    {
        int value=rand_range(0, 10000);
        Insert(value);
    }
    printf("--------------------------");
    printf("\n");
    printf("Tiempo para ");
    printf("%d", numThreads);
    printf(" hilos\n");
    clock_t start, end;
    pthread_t threads[numThreads];
    start = clock();
    for (i = 0; i < numThreads; i++)
    {
        pthread_create(&threads[i], NULL,(void *)OpHelper, NULL);
    }
    for(i=0;i<numThreads;i++){
        pthread_join(threads[i],NULL);
    }
    end = clock();
    printf("\n");
    printf("Para 100,000 operaciones 80%% de inserción, 10%% de búsqueda y 10%% de eliminación aprox: \n");
    printf("%f\n", (double)(end - start) / CLOCKS_PER_SEC);
}
int main()
{
    srand(time(NULL));
    mainHelper(1);
    mainHelper(2);
    mainHelper(4);
    mainHelper(8);
    //Print();
    return 0;
}