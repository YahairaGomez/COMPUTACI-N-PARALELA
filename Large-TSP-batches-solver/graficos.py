import  numpy as np
import pandas as pd
import matplotlib.pyplot as plt 


  
a = [8, 16, 32, 64, 128]

plt.title("Comparación de tiempo de ejecución en Modelo Serial y Paralelo")

plt.xlabel("Tiempo de ejecución (segundos)")
plt.ylabel("Nro. de batches")

serial = [8, 16, 37, 72, 144]
paralelo = [5, 8, 21, 43, 88]

plt.plot(serial, a, marker='o', linestyle='-', color='b', label = "Serial")
plt.plot(paralelo, a,  marker='o', linestyle='-', color='g', label = "Paralelo")

plt.legend(loc="upper left")

plt.show()


