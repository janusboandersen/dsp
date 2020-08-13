# Case 2
Design and implementation of an IIR notch filter to remove narrow-band noise from a signal. Implementation on a realtime system (Texas DSP C55).
See the pdf for the report.

The `.tex` file can be created by publishing the `.m` file using the `.xsl` template.
The pdf was created using LuaLaTeX.

The C55x- folder contains the implementation. Key files are `iir_notch.h` and `iir_notch.c` containing the filter implementation, as well as of course `main.c` which sets up the board and handles signal routing.
