#ifndef _BLACK_COMPILER_H_
#define _BLACK_COMPILER_H_ 1

#ifdef __GNUC__
# define ALWAYS_INLINE	inline __attribute__((__always_inline__))
# define LIKELY(x)	__builtin_expect(!!(x), 1)
# define UNLIKELY(x)	__builtin_expect(!!(x), 0)
#else
# define ALWAYS_INLINE	inline
# define LIKELY(x)	(x)
# define UNLIKELY(x)	(x)
#endif /* __GNUC__ */

#define UNUSED(x)	((void) (x))

#endif /* _BLACK_COMPILER_H_ */
