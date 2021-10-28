# writes the input wave that will go through the vhdl testbench in a file
# the testbench reads it and passes it through the filter and then writes
# the output to another file

import numpy as np

Fs = 44100
Fc = 1000
A  = 5

# the input wave will be A*sin(2pi*1000t) which means the output will be A/2*sin(2pi*1000t)

t = np.linspace(0, 2 * 1 / Fc, 2 * Fs / Fc + 1)
input = A * np.sin(2 * np.pi * Fc * t)

# Scaler
Numbits = 16
IWidth = 3
Scaler = 2 ** (Numbits - IWidth - 1) # 1 bit for the sign so 3+1 bits for -5 to 5
FormatStr = '{:04X}'

def float_to_binary(float_):

    temp = float_ * Scaler  # Scale the number up.
    temp = int(temp)     # Turn it into an integer.

    if temp < 0:
        temp += 2**Numbits

    return FormatStr.format(temp)

with open("inputWave.txt", "w") as file:
    for i in input:
        temp = float_to_binary(i)
        #print(temp," ", i) #seems about right
        file.write(temp + '\n')