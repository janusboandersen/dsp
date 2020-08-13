/*
 * iir_notch.c
 *
 *  Created on: 10 Mar 2020
 *      Author: Janus Bo Andersen (JA67494)
 *      Implementation of the IIR filter function
 *      Implemented as direct form I filter
 *      Relies on the 50% scaling of b1 and a1 coefficients
 *
 */
#include "stdio.h"

# define NATIVE_MAX 32767  /* 2^15-1*/
# define NATIVE_MIN -32768  /* -2^15*/

/* The filter function takes b and a coefficients, and the input from line in */
signed int filter_iir_notch(const signed int * b, const signed int * a, signed int input) {

    /* Delay line managed as static variables with persistence between calls */
    static signed int dx[2] = {0, 0};    /* x(n-1), x(n-2) */
    static signed int dy[2] = {0, 0};    /* y(n-1), y(n-2) */

    /* Accumulator 32-bit (8 guard bits for overflow) */
    long acc = 0;

    /* difference equation, coerce all data into
     * sign extended 32-bit words during calculation */
    acc =  ( (long) b[0] * input );     /* b0 x(n)*/
    acc += ( (long) b[1] * dx[0] );     /* b1 x(n-1) */
    acc += ( (long) b[1] * dx[0] );     /* added twice due to coeff. scaling */
    acc += ( (long) b[2] * dx[1] );     /* b2 x(n-2) */
    acc += ( (long) a[1] * dy[0] );     /* a1 y(n-1) */
    acc += ( (long) a[1] * dy[0] );     /* added twice due to coeff. scaling */
    acc += ( (long) a[2] * dy[1] );     /* a2 y(n-2) */

    /* coerce back into 16-bit word size */
    acc >>= 15;

    /* check for overflow and use saturation logic */
    if (acc > NATIVE_MAX) {
        acc = NATIVE_MAX;   /* Saturate instead of overflow */
    } else if (acc < NATIVE_MIN) {
        acc = NATIVE_MIN;   /* Saturate instead of underflow */
    }

    /* Update delay line */
    dx[1] = dx[0]; /* x(n-2) = x(n-1) */
    dx[0] = input; /* x(n-1) = x(n) */
    dy[1] = dy[0]; /* y(n-2) = y(n-1) */
    dy[0] = (short) acc; /* y(n-1) = y(n) */

    /* Return value */
    return (short) acc;
}






