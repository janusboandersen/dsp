/*
 * iir_notch.h
 *
 *  Created on: 10 Mar 2020
 *      Author: Janus Bo Andersen (JA67494)
 *      Interface for the IIR filter function
 *      Defines the filter coefficients for a 876 Hz notch filter
 */

#ifndef IIR_NOTCH_H_
#define IIR_NOTCH_H_

    /*                           b0     b1 / 2   b2 */
 /* const signed int iir_b[3] = {32738, -32523, 32738}; */
    const signed int iir_b[3] = {32690, -32475, 32690};

    /*                           a0     a1 / 2   a2 */
 /* const signed int iir_a[3] = {32767,  32520, -32702}; */
    const signed int iir_a[3] = {32767,  32227, -32116};

    /* The filter takes b and a coefficients, and input from line-in */
    signed int filter_iir_notch(const signed int * b,
                                const signed int * a, signed int input);

#endif /* IIR_NOTCH_H_ */
