#include <stddef.h>

#include "primes.h"

static int is_prime(size_t x)
{
	size_t o = 4;
	size_t i = 5;
	do {
		size_t q = x / i;
		if (q < i)
			return 1;
		if (x == q * i)
			return 0;
		o ^= 6;
		i += o;
	} while (1);
	return 1;
}

size_t next_prime(size_t x)
{
	switch (x) {
	case 0:
	case 1:
	case 2:
		return 2;
	case 3:
		return 3;
	case 4:
	case 5:
		return 5;
	}
	size_t k = x / 6;
	size_t i = x - 6 * k;
	size_t o = i < 2 ? 1 : 5;
	x = 6 * k + o;
	for (i = (3 + o) / 2; !is_prime(x); x += i)
		i ^= 6;
	return x;
}
