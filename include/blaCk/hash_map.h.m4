include(`hash_map.m4')
divert(`-1')
define(`hash_map_header_def', format(`_BLACK_%s_H_', upcase(hash_map)))
divert`'dnl
`#ifndef 'hash_map_header_def
`#define 'hash_map_header_def 1
ifelse(keyval_ptr, 0, `divert(`-1')')dnl

enum {
	ifelse_ptr(val_type, hash_map_cvar(`CLONE_VAL') = 1`'dnl
ifelse_ptr(key_type, ````,''''))
	ifelse_ptr(key_type, hash_map_cvar(`CLONE_KEY') = 4)
};
ifelse_ptr(keyval_ptr, 0, `divert`'')dnl

`#define 'hash_map_cvar(`DEFAULT_MIN_LF')	0.05f
`#define 'hash_map_cvar(`DEFAULT_MAX_LF')	0.75f

/**
 * struct hash_map - Hash map structure.
 *ifelse(keyval_ptr, 1, ` @flags:	Flags for hash map.')
 * @min_lf:	Minimum load factor before shrinking map.
 * @max_lf:	Maximum load factor before expanding map.
 *ifelse_ptr(key_type, ifelse_str(key_type,,`@klen:	Length of keys.'))
 *ifelse_ptr(val_type, ifelse_str(val_type,,`@vlen:	Length of values.'))
 * @size:	Number of keys mapped to values.
 * @capacity:	Actual capacity of hash map.
 * @keys:	Pointer to key table.
 * @vals:	Pointer to value table.
 * @state:	Mapping state.
 */
struct hash_map {
	ifelse(keyval_ptr, 1, `int flags;')
	float min_lf;
	float max_lf;
	/* private: internal use only */
	size_t lo_wm;
	/* private: internal use only */
	size_t hi_wm;
	ifelse_ptr(key_type, ifelse_str(key_type,,`size_t klen;'))
	ifelse_ptr(val_type, ifelse_str(val_type,,`size_t vlen;'))
	/* private: internal use only */
	size_t nr_free;
	size_t size;
	size_t capacity;
	ifelse_ptr(key_type, `key_type*keys', `key_type *keys');
	ifelse_ptr(val_type, `val_type*vals', `val_type *vals');
	char *state;
};

/**
 * hash_map_func(init)() - Initialize hash map.
 * @map:	Pointer to hash map.
 * @inicap:	Initial capacity of map.
 *
 * Expected fields to be set in @map:
 *	minimum load factor
 *	maximum load factor
 *	ifelse(keyval_ptr, 1, `flags')
 *	ifelse_ptr(key_type, ifelse_str(key_type,,`key length'))
 *	ifelse_ptr(val_type, ifelse_str(val_type,, `value length'))
 */
extern void hash_map_func(init)(struct hash_map *map, size_t inicap);

/**
 * hash_map_func(destroy)() - Destroy hash map.
 * @map:	Pointer to hash map.
 *
 * Data allocated for @map is released and the size of @map is set to zero.
 */
extern void hash_map_func(destroy)(struct hash_map *map);

/**
 * hash_map_func(put)() - Map value to key.
 * @map:	Pointer to hash map.
 * @key:	Key to map value to.
 * @val:	Value to map to key.
 * @oldval:	Pointer to location where old value
 *		will be stored (may be NULL).
 *
 * If @key already has a mapping in @map, the value is stored in @oldval, if
 * @oldval is not NULL, and @val is mapped to @key. If @val equals the previous
 * value mapped to @key, nothing is done.
 *
 * ifelse_str(val_type, `If hash_map_cvar(CLONE_VAL) is set in @map and
 * @oldval is not NULL, the value placed in @oldval must be freed using
 * free().')
 * ifelse(val_ptr, 1, `If hash_map_cvar(CLONE_VAL) is set in @map and
 * @oldval is not NULL, the memory pointed to by @oldval must be at least
 * the length of the value set in @map.')
 *
 * Returns 0 if @val was mapped to @key in @map, otherwise 1 is returned.
 */
extern int hash_map_func(put)(struct hash_map *map,
	key_type key, val_type val, val_type *oldval);

/**
 * hash_map_func(remove)() - Remove mapping for key.
 * @map:	Pointer to hash map.
 * @key:	Key to remove mapping for.
 * @valp:	Pointer to value.
 *
 * Removes mapping for @key from @map. If @key has mapping in @map and @valp
 * is not NULL, the value is stored in @valp.
 *
 * ifelse_str(val_type, `If hash_map_cvar(CLONE_VAL) is set in @map and
 * @oldval is not NULL, the value placed in @oldval must be freed using
 * free().')
 * ifelse(val_ptr, 1, `If hash_map_cvar(CLONE_VAL) is set in @map and
 * @oldval is not NULL, the memory pointed to by @oldval must be at least
 * the length of the value set in @map.')
 *
 * Returns 0 if @key had a mapping, otherwise 1.
 */
extern int hash_map_func(remove)(struct hash_map *map,
	const_arg(key_type) key, val_type *valp);

/**
 * hash_map_func(get)() - Retrieve value mapped to key.
 * @map:	Pointer to hash map.
 * @key:	Key to retrieve value for.
 * @valp:	Pointer to value.
 *
 * If @key has a value mapped to it in @map, that value will be stored in
 * @valp.
 * ifelse(val_ptr, 1, `If hash_map_cvar(CLONE_VAL) is specified in @map and
 * @key has a value mapped, a pointer to the value will be placed in @valp.')
 *
 * Returns 0 if @key had a mapping, otherwise 1.
 */
extern int hash_map_func(get)(const struct hash_map *map,
	const_arg(key_type) key, val_type *valp);

/**
 * hash_map_func(contains)() - Determine if key has mapping.
 * @map:	Pointer to hash map.
 * @key:	Key to search for.
 *
 * Returns 0 if @key has a mapping, otherwise 1.
 */
extern int hash_map_func(contains)(const struct hash_map *map,
	const_arg(key_type) key);

`#endif '/* hash_map_header_def */
