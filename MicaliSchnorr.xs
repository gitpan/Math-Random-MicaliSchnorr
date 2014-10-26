#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gmp.h>

void ms_seedgen(mpz_t * seed, SV * exp, mpz_t * p, mpz_t * q) {
     mpz_t phi, pless1, qless1;
     unsigned long bign, ret, k;
     double kdoub;
     gmp_randstate_t state;

     if(mpz_cmp_ui(*seed, 0) < 0)croak("Negative seed in ms_seedgen");
     
     mpz_init(phi);
     mpz_init(pless1);
     mpz_init(qless1);

     mpz_sub_ui(qless1, *q, 1);
     mpz_sub_ui(pless1, *p, 1);

     mpz_mul(phi, *p, *q);

     bign = mpz_sizeinbase(phi, 2);
     ret = bign / 80;
     if(!(ret & 1)) --ret;

     if(ret < 3) croak("You need to choose different primes P and Q. The product of P and Q needs to be at least a 240-bit number");

     mpz_mul(phi, pless1, qless1);
     mpz_clear(pless1);
     mpz_clear(qless1);

     while(1) {
       if(mpz_gcd_ui(NULL, phi, ret) == 1) break;
       ret -= 2;
       if(ret < 3) croak("The chosen primes are unsuitable in ms_seedgen() function");
     }

     mpz_clear(phi);

     sv_setsv(exp, newSVuv(ret));

     kdoub = (double) 2 / (double) SvUV(exp);
     kdoub = (double) 1 - kdoub;
     kdoub *= (double) bign;
     k = kdoub;
     //r = bign - k;
     bign -= k;

     gmp_randinit_default(state);
     gmp_randseed(state, *seed);
     mpz_urandomb(*seed, state, bign);
     gmp_randclear(state);
}

void ms(mpz_t * outref, mpz_t * p, mpz_t * q, mpz_t * seed, SV * exp, int bits_required) {
     mpz_t n, phi, pless1, qless1, mod, keep;
     unsigned long k, bign, r, its, i, r_shift, check;
     double kdoub;

     if(SvUV(exp) <= 2) croak("Unsuitable exponent supplied to ms function - needs to be greater than 2");

     if(mpz_cmp_ui(*seed, 0) < 0)croak("Negative seed in ms function");

     mpz_init(n);
     mpz_init(phi);
     mpz_init(pless1);
     mpz_init(qless1);

     mpz_sub_ui(qless1, *q, 1);
     mpz_sub_ui(pless1, *p, 1);

     mpz_mul(n, *p, *q);

     bign = mpz_sizeinbase(n, 2);
     if(SvUV(exp) > bign / 80) croak("Unsuitable exponent supplied to ms function - needs to be less than or equal to %u", bign / 80);

     mpz_mul(phi, pless1, qless1);
     mpz_clear(pless1);
     mpz_clear(qless1);

     if(mpz_gcd_ui(NULL, phi, SvUV(exp)) != 1) croak("Unsuitable exponent supplied to ms function - gcd(exp, phi) != 1");

     mpz_clear(phi);

     kdoub = (double) 2 / (double)SvUV(exp);
     kdoub = (double) 1 - kdoub;
     kdoub *= (double) bign;
     k = kdoub;
     r = bign - k;

     if(mpz_sizeinbase(*seed, 2) > r) croak("The seed supplied to the ms function is too big");

     r_shift = bits_required % k;

     if(r_shift) its = (bits_required / k) + 1;
     else its = bits_required / k;

     mpz_init(mod);
     mpz_init(keep);
     mpz_set_ui(*outref, 0);
     mpz_ui_pow_ui(mod, 2, k);

     for(i = 0; i < its; ++i) {
         mpz_powm_ui(*seed, *seed, SvUV(exp), n);
         mpz_mod(keep, *seed, mod);
         mpz_mul_2exp(*outref, *outref, k);
         mpz_add(*outref, *outref, keep);
         mpz_fdiv_q_2exp(*seed, *seed, k);
         if(!i) check = k - mpz_sizeinbase(keep, 2);    
         }
     mpz_clear(n); 
     mpz_clear(keep);
     mpz_clear(mod);

     if(r_shift) mpz_fdiv_q_2exp(*outref, *outref, k - r_shift);

     if(check + mpz_sizeinbase(*outref, 2) != bits_required)
        croak("Bug in ms() function");

}

int monobit(mpz_t * bitstream) {
    unsigned long len, i, count = 0;

    len = mpz_sizeinbase(*bitstream, 2);

    if(len > 20000) croak("Wrong size random sequence for monobit test");
    if(len < 19967) {
       warn("More than 33 leading zeroes in monobit test\n");
       return 0;
       }

    count = mpz_popcount(*bitstream);

    if(count > 9654 && count < 10346) return 1;
    return 0;

}

int longrun(mpz_t * bitstream) {
    unsigned long i, el, init = 0, count = 0, len, t;

    len = mpz_sizeinbase(*bitstream, 2);

    if(len > 20000) croak("Wrong size random sequence for longrun test");
    if(len < 19967) {
       warn("More than 33 leading zeroes in longrun test\n");
       return 0;
       }

    el = mpz_tstbit(*bitstream, 0);

    for(i = 0; i < len; ++i) {
        t = mpz_tstbit(*bitstream, i);
        if(t == el) ++count;
        else {
           el = t;
           if(count > init) init = count;
           count = 1;
           }
        }

    if(init < 34 && count < 34) return 1;
    return 0;

}

int runs(mpz_t * bitstream) {
    int b[6] = {0,0,0,0,0,0}, g[6] = {0,0,0,0,0,0},
    len, count = 1, i, t, diff;

    len = mpz_sizeinbase(*bitstream, 2);
    diff = 20000 - len;

    if(len > 20000) croak("Wrong size random sequence for runs test");
    if(len < 19967) {
       warn("More than 33 leading zeroes in runs test\n");
       return 0;
       }

    --len;

    for(i = 0; i < len; ++i) {
        t = mpz_tstbit(*bitstream, i);
        if(t == mpz_tstbit(*bitstream, i + 1)) ++ count;
        else {
           if(t) {
              if(count >= 6) ++b[5];
              else ++b[count - 1];
              }
            else {
              if(count >= 6) ++g[5];
              else ++g[count - 1];
              }
            count = 1;
            }
         }

     if(count >= 6) {
        if(mpz_tstbit(*bitstream, len)) {
           ++b[5];
           if(diff) ++g[diff - 1];
           }
        else ++g[5];
        }
     else {
        if(mpz_tstbit(*bitstream, len)) {
           ++b[count - 1];
           if(diff) ++g[diff - 1];
           }
        else {
          count += diff;
          if(count >= 6) ++g[5];
          else ++g[count - 1];
          }
        }

             
        if (
            b[0] <= 2267 || g[0] <= 2267 ||
            b[0] >= 2733 || g[0] >= 2733 ||
            b[1] <= 1079 || g[1] <= 1079 ||
            b[1] >= 1421 || g[1] >= 1421 ||
            b[2] <= 502  || g[2] <= 502  ||
            b[2] >= 748  || g[2] >= 748  ||
            b[3] <= 223  || g[3] <= 223  ||
            b[3] >= 402  || g[3] >= 402  ||
            b[4] <= 90   || g[4] <= 90   ||
            b[4] >= 223  || g[4] >= 223  ||
            b[5] <= 90   || g[5] <= 90   ||
            b[5] >= 223  || g[5] >= 223
           ) return 0;

    return 1;

}

int poker (mpz_t * bitstream) {
    int counts[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
       len, i, st, diff;
    double n = 0;

    len = mpz_sizeinbase(*bitstream, 2);

    if(len > 20000) croak("Wrong size random sequence for poker test");
    if(len < 19967) {
       warn("More than 33 leading zeroes in poker test\n");
       return 0;
       }

/* pad with trailing zeroes (if necessary) to achieve length of 20000 bits. */
    diff = 20000 - len;
    if(diff) mpz_mul_2exp(*bitstream, *bitstream, diff);
    if(mpz_sizeinbase(*bitstream, 2) != 20000) croak("Bug in bit sequence manipulation in poker() function");

    for(i = 0; i < 20000; i += 4) {
        st = mpz_tstbit(*bitstream, i) +
             (mpz_tstbit(*bitstream, i + 1) * 2) +
             (mpz_tstbit(*bitstream, i + 2) * 4) +
             (mpz_tstbit(*bitstream, i + 3) * 8);
        ++counts[st];
        } 


    for(i = 0; i < 16; ++i) n += counts[i] * counts[i];

    n /= 5000;
    n *= 16;
    n -= 5000;

    if(n > 1.03 && n < 57.4) return 1;
    
    return 0;        
}

MODULE = Math::Random::MicaliSchnorr	PACKAGE = Math::Random::MicaliSchnorr	

PROTOTYPES: DISABLE


void
ms_seedgen (seed, exp, p, q)
	mpz_t *	seed
	SV *	exp
	mpz_t *	p
	mpz_t *	q
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	ms_seedgen(seed, exp, p, q);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
ms (outref, p, q, seed, exp, bits_required)
	mpz_t *	outref
	mpz_t *	p
	mpz_t *	q
	mpz_t *	seed
	SV *	exp
	int	bits_required
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	ms(outref, p, q, seed, exp, bits_required);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

int
monobit (bitstream)
	mpz_t *	bitstream

int
longrun (bitstream)
	mpz_t *	bitstream

int
runs (bitstream)
	mpz_t *	bitstream

int
poker (bitstream)
	mpz_t *	bitstream

