#  reads file of float coefficientes
#  converts the coefficients to fixed point of chosen format
#  writes file with these cofficients

# Scaler
Numbits = 16
IWidth = 0
Scaler = 2 ** (Numbits - IWidth - 1) # 1 bit for the sign
FormatStr = '{:04X}'

#https://stackoverflow.com/questions/17582657/how-to-convert-between-floats-and-decimal-twos-complement-numbers-in-python
def float_to_binary(float_):
    # Turns the provided floating-point number into a fixed-point
    # binary representation with IWIDTH bits for the integer component and
    # (Numbits - IWidth) bits for the fractional component.

    temp = float_ * Scaler  # Scale the number up.
    temp = int(temp)     # Turn it into an integer.

    if temp < 0:
        temp += 2**Numbits

    return FormatStr.format(temp)

# test
#num = -0.003277228269042432515223417510696890531
#print(float_to_binary(num))

import os.path

if __name__ == "__main__":
    new_coeff = []
    with open(os.path.dirname(__file__) + "/../filter_info/coeff_tap11Fc10800Fs44100.fcf", "r") as file:
        lines = [line.strip() for line in file if line.strip()]
        lines = [line for line in lines if line[0] != '%']
        #for line in lines:
        #    print(line)
        new_coeff = [0] * len(lines)
        for i in range(0, len(lines)):
            new_coeff[i] = float_to_binary(float(lines[i]))
            print(new_coeff[i])

    with open(os.path.dirname(__file__) + "/../filter_info/coeff_tap11Fc10800Fs44100_FIXED.fcf", "w") as file:
        for i in range(len(new_coeff)):
            file.write('x"' + new_coeff[i] + '"')
            if(i != len(new_coeff) - 1):
                file.write(", ")
            if(i%5 == 0 and i != 0):
                file.write("\n")