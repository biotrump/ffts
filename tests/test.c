/*

 This file is part of SFFT.

 Copyright (c) 2012, Anthony M. Blake
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 	* Redistributions of source code must retain the above copyright
 		notice, this list of conditions and the following disclaimer.
 	* Redistributions in binary form must reproduce the above copyright
 		notice, this list of conditions and the following disclaimer in the
 		documentation and/or other materials provided with the distribution.
 	* Neither the name of the organization nor the
	  names of its contributors may be used to endorse or promote products
 		derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL ANTHONY M. BLAKE BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#include <stdio.h>
#include <math.h>

#ifdef __ARM_NEON__
#endif
#ifdef HAVE_SSE
	#include <xmmintrin.h>
#endif

#include "../include/ffts.h"


#define PI 3.1415926535897932384626433832795028841971693993751058209

float impulse_error(int N, int sign, float *data) {
#ifdef __ANDROID__
	double delta_sum = 0.0f;
	double sum = 0.0f;
#else
	long double delta_sum = 0.0f;
	long double sum = 0.0f;
#endif

	int i;
	for(i=0;i<N;i++) {
#ifdef __ANDROID__
		double re, im;
		if(sign < 0) {
			re = cos(2 * PI * (double)i / (double)N);
			im = -sin(2 * PI * (double)i / (double)N);
		}else{
			re = cos(2 * PI * (double)i / (double)N);
			im = sin(2 * PI * (double)i / (double)N);
		}
#else
		long double re, im;
		if(sign < 0) {
			re = cosl(2 * PI * (long double)i / (long double)N);
			im = -sinl(2 * PI * (long double)i / (long double)N);
		}else{
			re = cosl(2 * PI * (long double)i / (long double)N);
			im = sinl(2 * PI * (long double)i / (long double)N);
		}
#endif
		sum += re * re + im * im;

		re = re - data[2*i];
		im = im - data[2*i+1];

		delta_sum += re * re + im * im;

	}
#ifdef __ANDROID__
	return sqrt(delta_sum) / sqrt(sum);
#else
	return sqrtl(delta_sum) / sqrtl(sum);
#endif
}

int
test_transform(int n, int sign) {

#ifdef HAVE_SSE
	float __attribute__ ((aligned(32))) *input = _mm_malloc(2 * n * sizeof(float), 32);
  float __attribute__ ((aligned(32))) *output = _mm_malloc(2 * n * sizeof(float), 32);
#else
	float __attribute__ ((aligned(32))) *input = valloc(2 * n * sizeof(float));
  float __attribute__ ((aligned(32))) *output = valloc(2 * n * sizeof(float));
#endif
	int i;
	for(i=0;i<n;i++) {
		input[2*i]   = 0.0f;
		input[2*i+1] = 0.0f;
	}

	input[2] = 1.0f;//impulse in time domain

	ffts_plan_t *p = ffts_init_1d(i, sign);
	if(p) {
		ffts_execute(p, input, output);
		printf(" %3d  | %9d | %10E\n", sign, n, impulse_error(n, sign, output));
  	ffts_free(p);
	}else{
		printf("Plan unsupported\n");
		return 0;
	}

	return 1;
}

/* http://www.sccon.ca/sccon/fft/fft3.htm
* A shifted impulse, [0,1,0....], alters only the phase of the transform components.
* The magnitude remains constant since "sin2x + cos2x = 1".
* In discrete form, the shifted impulse is a non-zero sample at REAL[1].
*
* n : 2^a
* sign : +1 forward FFT, -1 INV FFT
* shift : offset
*/
int impulse_test(int n, int sign, int shift)
{
	printf("%s : n = %d, sign=%d, shift=%d\n", __func__, n, sign, shift);
#ifdef HAVE_SSE
		float __attribute__ ((aligned(32))) *input = _mm_malloc(2 * n * sizeof(float), 32);
		float __attribute__ ((aligned(32))) *output = _mm_malloc(2 * n * sizeof(float), 32);
		float __attribute__ ((aligned(32))) *pow_mag = _mm_malloc(n * sizeof(float), 32);
#else
		float __attribute__ ((aligned(32))) *input = valloc(2 * n * sizeof(float));
		float __attribute__ ((aligned(32))) *output = valloc(2 * n * sizeof(float));
		float __attribute__ ((aligned(32))) *pow_mag = valloc( n * sizeof(float));
#endif
		memset(input,0, 2*n*sizeof(float));
		memset(output,0, 2*n*sizeof(float));
		shift = shift > (n-1) ? n-1 : shift;
		//printf("new shift %d\n",shift);
		input[shift<<1] = 1.0f;	//impulse is at real position
		ffts_plan_t *p = ffts_init_1d(n, sign);
		printf("idx|sign|real     imag     pow_mag\n");
		printf("---+--+--------+---------+---------+\n");

		if(p) {
			int i;
			ffts_execute(p, input, output);
			ffts_pow_mag(n, output, pow_mag);
			for(i=0;i<n;i++) printf("%3d %2d %8.4f %8.4f %8.4f\n", i, sign, output[2*i], output[2*i+1], pow_mag[i]);
			ffts_free(p);
			//INV FFT
			p = ffts_init_1d(i, -sign);
			if(p){
				ffts_execute(p, output, input);
				ffts_pow_mag(n, input, pow_mag);
				for(i=0;i<n;i++) printf("%3d %2d %8.4f %8.4f %8.4f\n", i, sign, input[2*i]/n, input[2*i+1]/n, pow_mag[i]/(n*n));
				ffts_free(p);
			}
		}else{
			printf("Plan unsupported\n");
			return 0;
		}

#ifdef HAVE_NEON
		_mm_free(input);
		_mm_free(output);
#else
		free(input);
		free(output);
#endif

}

/* real1d FFT
 * input size : FORWARD FFT, size = N = 2^a for real part only
 * 				no imaginary part is needed!
 * 				Inverse FFT, size = (N / 2 + 1) * 2
 * 				The frequency domain has real and imaginary parts and
 * 				only the first half of real and imaginary parts are used for inverse 1d FFT.
 * 				The second half parts are mirror of the first half, because it's real FFT.
 * output size : FORWARD FFT (N / 2 + 1) * 2
 * 				 The frequency domain has real and imaginary parts and
 * 				 only the first half of real and imaginary parts are used.
 *				 inverse FFT N : this is the real part in time domain
 * n : 2^a
 * sign : +1 forward FFT, -1 INV FFT
 * shift : offset
 *
 * TODO : real1d has a bug in INV FFT if impulse shift to 1, but shift 0, 2,3,... n-1 are all correct!
*/
int impulse_test_real1d(int n, int sign, int shift)
{
	printf("%s : n = %d, sign=%d, shift=%d\n", __func__, n, sign, shift);
#ifdef HAVE_SSE
		float __attribute__ ((aligned(32))) *input = _mm_malloc( n * sizeof(float), 32);
		float __attribute__ ((aligned(32))) *output = _mm_malloc((n/2+1) * 2 * sizeof(float), 32);
		float __attribute__ ((aligned(32))) *pow_mag = _mm_malloc(n * sizeof(float), 32);
#else
		float __attribute__ ((aligned(32))) *input = valloc( n * sizeof(float));
		float __attribute__ ((aligned(32))) *output = valloc((n/2+1) * 2 * sizeof(float));
		float __attribute__ ((aligned(32))) *pow_mag = valloc( n * sizeof(float));
#endif
		memset(input,0, n*sizeof(float));
		memset(output,0, (n/2+1) * 2 *sizeof(float));
		shift = shift < 0 ? 0: shift;
		shift = shift > (n-1) ? n-1 : shift;
		printf("new shift %d\n",shift);
		input[shift] = 1.0f;	//impulse is at real position
		ffts_plan_t *p = ffts_init_1d_real(n, sign);
		printf("idx|sign|time real     imag     pow_mag\n");
		printf("---+--+----+--------+---------+---------+\n");

		if(p) {
			int i;
			ffts_execute(p, input, output);
			ffts_pow_mag(n, output, pow_mag);
			for(i=0;i <= n/2;i++) printf("%3d %2d %4.1f %8.4f %8.4f %8.4f\n", i, sign,
				input[i], output[2*i], output[2*i+1], pow_mag[i]);
			ffts_free(p);
			//INV FFT
			p = ffts_init_1d_real(n, -sign);
			if(p){
				ffts_execute(p, output, input);
				for(i=0;i<n;i++) printf("%3d %2d %8.4f\n", i, -sign, input[i]/n);
				ffts_free(p);
			}
		}else{
			printf("Plan unsupported\n");
			return 0;
		}

#ifdef HAVE_NEON
		_mm_free(input);
		_mm_free(output);
#else
		free(input);
		free(output);
#endif

}

int specific_patter(int n, int sign)
{
#ifdef HAVE_SSE
		float __attribute__ ((aligned(32))) *input = _mm_malloc(2 * n * sizeof(float), 32);
		float __attribute__ ((aligned(32))) *output = _mm_malloc(2 * n * sizeof(float), 32);
#else
		float __attribute__ ((aligned(32))) *input = valloc(2 * n * sizeof(float));
		float __attribute__ ((aligned(32))) *output = valloc(2 * n * sizeof(float));
#endif
		int i;
		for(i=0;i<n;i++) {
			input[2*i]   = i;
			input[2*i+1] = 0.0f;
		}

		ffts_plan_t *p = ffts_init_1d(i, sign);
		if(p) {
			ffts_execute(p, input, output);
			for(i=0;i<n;i++) printf("%d %d %f %f\n", i, sign, output[2*i], output[2*i+1]);
			ffts_free(p);
			//INV FFT
			p = ffts_init_1d(i, -sign);
			if(p){
				ffts_execute(p, output, input);
				for(i=0;i<n;i++) printf("%d %d %f %f\n", i, -sign, input[2*i], input[2*i+1]);
				ffts_free(p);
			}
		}else{
			printf("Plan unsupported\n");
			return 0;
		}

#ifdef HAVE_NEON
		_mm_free(input);
		_mm_free(output);
#else
		free(input);
		free(output);
#endif
}
/* input data format : real, img, real, img.......
 * 						real component is stored in the even index,0,2,4,6,8...
 * 						imaginary component is stored in the odd index,1,3,5,7,9...
 * output data format has the same interleaving format
 * sign :
 * FORWARD FFT			(-1)
 * BACKWARD FFT			(1)
 */
int
main(int argc, char *argv[]) {
#ifdef STATIC_TRIGONO_TABLE
	if(!static_trigono_tab_init(TRIG_TABLE_SIZE)){	//this is a must to init COS, SINE table
		printf("static_trigono_tab_init init error!\n");
		return -1;
	}
#endif
	find_best_N_pow2((unsigned)(10*8));
	find_best_N_pow2((unsigned)(20*60));

	if(argc >= 3) {//n sign shift
		impulse_test(atoi(argv[1]), atoi(argv[2]), atoi(argv[3]));
		impulse_test_real1d(atoi(argv[1]), atoi(argv[2]), atoi(argv[3]));
	}else{
		// test various sizes and display error
		printf(" Sign |      Size |     L2 Error\n");
		printf("------+-----------+-------------\n");
		int n;
		for(n=1;n<=18;n++) {
			test_transform(pow(2,n), -1);
		}
		for(n=1;n<=18;n++) {
			test_transform(pow(2,n), 1);
		}
	}
#ifdef STATIC_TRIGONO_TABLE
	static_trigono_tab_free();
#endif
	return 0;
}
// vim: set autoindent noexpandtab tabstop=3 shiftwidth=3:
