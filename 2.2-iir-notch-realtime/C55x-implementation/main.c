/*****************************************************************************/
/*                                                                           */
/* FILENAME                                                                  */
/* 	 main.c                                                                  */
/*                                                                           */
/* DESCRIPTION                                                               */
/*   This code implements E4DSA case 2: 2nd order IIR notch filter           */
/*   Take line/mic input, filter and send to line out (headphones)           */
/*                                                                           */
/* REVISION                                                                  */
/*   Revision: 2.00	                                                         */
/*   Author  : Janus Bo Andersen                                             */
/*---------------------------------------------------------------------------*/
/*                                                                           */
/* HISTORY                                                                   */
/*   Revision: 1.00                                                          */
/*   5th March 2010. Created by Richard Sikora from TMS320C5510 DSK code.    */
/*                                                                           */
/*   Revision: 2.00                                                          */
/*   March 2020. Implement the IIR filter and use rev. 1 for audio loop.     */
/*                                                                           */
/*****************************************************************************/
/*
 * Copyright (C) 2010 Texas Instruments Incorporated - http://www.ti.com/ 
 * 
 * 
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions 
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright 
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the 
 *    documentation and/or other materials provided with the   
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/

#include "stdio.h"
#include "usbstk5505.h"
#include "aic3204.h"
#include "PLL.h"
#include "stereo.h"
#include "iir_notch.h"

Int16 left_input;
Int16 right_input;
Int16 left_output;
Int16 right_output;
Int16 mono_input;

#define SAMPLES_PER_SECOND 48000

unsigned long int i = 0;


/* ------------------------------------------------------------------------ *
 *                                                                          *
 *  main( )                                                                 *
 *                                                                          *
 * ------------------------------------------------------------------------ */
void main( void ) 
{
    /* Initialize BSL */
    USBSTK5505_init( );
	
	/* Initialize PLL */
	pll_frequency_setup(100);

    /* Initialise hardware interface and I2C for code */
    aic3204_hardware_init();
    
    /* Initialise the AIC3204 codec */
	aic3204_init(); 

    printf("E4DSA Case 2 (Janus) - IIR notch filter DSP: ");
	
	/* Setup sampling frequency and 0 dB gain for microphone */
    set_sampling_frequency_and_gain(SAMPLES_PER_SECOND, 0);
  
    asm(" bclr XF");
   
    printf("Starting IIR notch filter");

 	while (1) // run for infty //for ( i = 0  ; i < SAMPLES_PER_SECOND * 600L  ;i++  )
 	{

     aic3204_codec_read(&left_input, &right_input); // Configured for one interrupt per two channels.
   
     //mono_input = stereo_to_mono(left_input, right_input);
   
     left_output =  right_input; //left_input;
     right_output = filter_iir_notch(iir_b, iir_a, right_input); //right_input;
    
     aic3204_codec_write(left_output, right_output);
 	}

   /* Disable I2S and put codec into reset */ 
    aic3204_disable();

    printf( "\n***Program has Terminated***\n" );
    SW_BREAKPOINT;
}
