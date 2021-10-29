# reads the output of the testbench from it file and compares it on a plot

import numpy as np
import matplotlib.pyplot as plt
import os.path

# parameters of wave
Fs = 44100
Fc = 2000
A  = 5

# input wave and coeff in float
t = np.linspace(0, 2 * 1 / Fc, 2 * Fs / Fc + 1)
input_float = A * np.sin(2 * np.pi * Fc * t)

coeff_float = []
with open(os.path.dirname(__file__) + "/../filter_info/coeff_tap11Fc10800Fs44100.fcf", "r") as file:
    lines = [line.strip() for line in file if line.strip()]
    lines = [line for line in lines if line[0] != '%']
    coeff_float = [0] * len(lines)
    for i in range(0, len(lines)):
        coeff_float[i] = float(lines[i])

# input wave and coeff in fixed point
Scaler_input = 2**12
input_fixed = [int(i * Scaler_input) for i in input_float]
Scaler_coeff = 2**15
coeff_fixed = [int(i * Scaler_coeff) for i in coeff_float]

#print(input_fixed)
#print(coeff_fixed)

# convolution float
conv_float = np.convolve(input_float, coeff_float)
x_axis_conv = [1/Fs*i for i in range(0, len(coeff_float) + len(input_float) - 1)]

# convolution fixed
conv_fixed = np.convolve(input_fixed, coeff_fixed)
# the conv output is in 36 bits, we truncate leaving with only the top 19 bits
conv_fixed = conv_fixed >> 17
new_Scaler = 2**10
conv_fixed = conv_fixed * 1 / new_Scaler

# read result from testbench
conv_testbench = []
with open(os.path.dirname(__file__) + "/../input_output_signals/outputSignal.txt", "r") as file:
    lines = [line.strip() for line in file if line.strip()]
    conv_testbench = [0] * len(lines)
    for i in range(0, len(lines)):
        conv_testbench[i] = int(lines[i])

new_Scaler = 2**10 # 9,10 format (19 bits)
conv_testbench = [i * 1 / new_Scaler for i in conv_testbench]

# compare on plot
plt.plot(t, input_float, label='input')

plt.plot(x_axis_conv, conv_float, label='float convolution')

plt.plot(x_axis_conv, conv_fixed, label='fixed point convolution')

plt.plot(x_axis_conv, conv_testbench, label='fpga convolution')

plt.legend()
plt.show()

diff_conv_float_fixed = conv_float - conv_fixed
print("Av error convolution float vs fixed")
print(np.average(diff_conv_float_fixed))

diff_conv_float_fixedFpga = conv_float - conv_testbench
print("Av error convolution float vs fixedFpga")
print(np.average(diff_conv_float_fixedFpga))

diff_conv_fixed_fixedFpga = conv_fixed - conv_testbench
print("Av error convolution fixed vs fixedFpga")
print(np.average(diff_conv_fixed_fixedFpga))