include(`hash_map.m4')
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

`#include '"blaCk/hash_map.h"
#include "blaCk/compiler.h"
#include "primes.h"
#include "config.h"

enum {
	ST_FREE,
	ST_FULL,
	ST_REMOVED
};

/**
 * choose_hiwm() - Calculate a high water mark threshold for a map.
 * @map:	Pointer to hash map.
 *
 * Returns calculated high water mark threshold for @map.
 */
static size_t choose_hiwm(const struct hash_map *map);

/**
 * choose_lowm() - Calculate a low water mark threshold for a map.
 * @map:	Pointer to hash map.
 *
 * Returns calculated low water mark threshold for @map.
 */
static size_t choose_lowm(const struct hash_map *map);

/**
 * choose_grow_cap() - Calculate a new expanded capacity for a map.
 * @map:	Pointer to hash map.
 *
 * Returns calculated expanded capacity for @map.
 */
static size_t choose_grow_cap(const struct hash_map *map);

/**
 * choose_shrink_cap() - Calculate a minimum capacity for a map.
 * @map:	Pointer to hash map.
 *
 * Returns calculated minimum capacity for @map.
 */
static size_t choose_shrink_cap(const struct hash_map *map);

/**
 * hash_key() - Calculate hash value for key.
 * @map:	Pointer to hash map.
 * @key:	Key to calculate hash value for.
 */
static ALWAYS_INLINE size_t hash_key(const struct hash_map *map,
	const_arg(key_type) key);
/**
 * equal_keys() - Determine if two keys are equal.
 * @map:	Pointer to hash map.
 * @k2idx:	Index of key in @map to compare.
 * @k1:		Key to compare against key in map.
 *
 * Returns 1 if the key at @k2idx in @map is equal to @k1, otherwise 0.
 */
static ALWAYS_INLINE int equal_keys(const struct hash_map *map,
	size_t k2idx, const_arg(key_type) k1);

/**
 * equal_vals() - Determine if two values are equal.
 * @map:	Pointer to hash map.
 * @v2idx:	Index of value in @map to compare.
 * @v1:		Value to compare against value in map.
 *
 * Returns 1 if the value at @v2idx in @map is equal to @v1, otherwise 0.
 */
static ALWAYS_INLINE int equal_vals(const struct hash_map *map,
	size_t v2idx, const_arg(val_type) v1);

/**
 * get_val() - Retrieve value from map.
 * @map:	Pointer to hash map.
 * @idx:	Index of value.
 * @valp:	Pointer to area where value will be stored.
 */
static ALWAYS_INLINE void get_val(const struct hash_map *map,
	size_t idx, val_type *valp);

/**
 * set_val() - Set value at index in map.
 * @map:	Pointer to hash map.
 * @idx:	Index to set value at.
 * @val:	Value to set to.
 *
 * ifelse_ptr(val_type, `If hash_map_cvar(CLONE_VAL) is specified in @map``,''
 * @val will be cloned.')
 */
static ALWAYS_INLINE void set_val(struct hash_map *map,
	size_t idx, val_type val);

/**
 * get_key() - Retrieve key at index in map.
 * @map:	Pointer to hash map.
 * @idx:	Index of key.
 * @keyp:	Pointer to location where key will be stored.
 */
static ALWAYS_INLINE void get_key(const struct hash_map *map,
	size_t idx, key_type *keyp);

/**
 * set_key() - Set key at index in map.
 * @map:	Pointer to hash map.
 * @idx:	Index in map to set key at.
 * @key:	Key to set to.
 *
 * ifelse_ptr(key_type, `If hash_map_cvar(CLONE_KEY) is specified in @map``,'' @key
 * will be cloned.')
 */
static ALWAYS_INLINE void set_key(struct hash_map *map,
	size_t idx, key_type key);

/**
 * indexof_insert() - Determine index to insert key at in map.
 * @map:	Pointer to hash map.
 * @k:		Key to insert into map.
 *
 * If @key already exists in @map, '-index - 1' is returned, otherwise a
 * positive value denoting the suggested insertion index is returned.
 */
static ssize_t indexof_insert(const struct hash_map *map,
	const_arg(key_type) k);

/**
 * indexof() - Determine index of a key in map.
 * @map:	Pointer to hash map.
 * @k:		Key to search for.
 *
 * If @key is found in @map, a positive value denoting the index of @key is
 * returned, otherwise -1 is returned.n
 */
static ssize_t indexof(const struct hash_map *map,
	const_arg(key_type) k);

/**
 * alloc_keytable() - Allocate key table for map.
 * @map:	Pointer to hash map.
 * @cap:	Capacity of the table.
 *
 * Returns a pointer to the key table.
 */
static key_type *alloc_keytable(const struct hash_map *map, size_t cap);

/**
 * alloc_valtable() - Allocate value table for map.
 * @map:	Pointer to hash map.
 * @cap:	Capacity of the table.
 *
 * Returns a pointer to the value table.
 */
static val_type *alloc_valtable(const struct hash_map *map, size_t cap);

/**
 * resize_hash_map() - Resize hash map.
 * @map:	Pointer to hash map.
 * @cap:	New capacity.
 */
static void resize_hash_map(struct hash_map *map, size_t cap);

void hash_map_func(init)(struct hash_map *map, size_t inicap)
{
	float max_lf = map->max_lf;
	if (max_lf <= 0.0f || max_lf >= 1.0f)
		map->max_lf = max_lf = hash_map_cvar(`DEFAULT_MAX_LF');
	float min_lf = map->min_lf;
	if (min_lf < 0.0f || min_lf >= 1.0f)
		map->min_lf = min_lf = hash_map_cvar(`DEFAULT_MIN_LF');
	size_t cap = next_prime(inicap);
	if (cap == 0)
		cap = 1;
	map->size = 0;
	map->capacity = cap;
	map->nr_free = cap;
	map->lo_wm = 0;
	map->hi_wm = choose_hiwm(map);
	map->keys = alloc_keytable(map, cap);
	map->vals = alloc_valtable(map, cap);
	map->state = malloc(cap);
	memset(map->state, ST_FREE, cap);
}

void hash_map_func(destroy)(struct hash_map *map)
{
	ifelse_str(key_type, `
	if (map->flags & hash_map_cvar(CLONE_KEY)) {
		size_t size = map->size;
		size_t i```,''' j;
		for (i = 0```,''' j = 0; j != size; i++) {
			if (map->state[i] != ST_FULL)
				continue;
			free(map->keys[i]);
			++j;
		}
	}')
	ifelse_str(val_type, `
	if (map->flags & hash_map_cvar(CLONE_VAL)) {
		size_t size = map->size;
		size_t i```,''' j;
		for (i = 0```,''' j = 0; j != size; i++) {
			if (map->state[i] != ST_FULL)
				continue;
			free(map->vals[i]);
			++j;
		}
	}')
	free(map->vals);
	free(map->keys);
	free(map->state);
	map->size = 0;
}

int hash_map_func(put)(struct hash_map *map,
	key_type key, val_type val, val_type *oldval)
{
	ssize_t idx = indexof_insert(map, key);
	if (idx < 0) {
		idx = -idx - 1;
		if (equal_vals(map, idx, val))
			return 1;
		if (oldval) {
			ifelse(val_ptr, 1, `
			if (map->flags & hash_map_cvar(CLONE_VAL)) {
				val_type ov;
				get_val(map, idx, &ov);
				memcpy(oldval, ov, map->vlen);
			} else {
				get_val(map, idx, oldval);
			}
			', `
			get_val(map, idx, oldval);
			')
		} ifelse_str(val_type, `
		else if (map->flags & hash_map_cvar(CLONE_VAL)) {
			val_type ov;
			get_val(map, idx, &ov);
			free(ov);
		}')
		set_val(map, idx, val);
		return 0;
	}
	if (map->size > map->hi_wm) {
		size_t new_cap = choose_grow_cap(map);
		resize_hash_map(map, new_cap);
		return hash_map_func(put)(map, key, val, oldval);
	}
	set_key(map, idx, key);
	set_val(map, idx, val);
	if (map->state[idx] == ST_FREE)
		map->nr_free--;
	map->state[idx] = ST_FULL;
	map->size++;
	if (map->nr_free < 1) {
		size_t new_cap = choose_grow_cap(map);
		resize_hash_map(map, new_cap);
	}
	return 0;
}

int hash_map_func(remove)(struct hash_map *map,
	const_arg(key_type) key, val_type *valp)
{
	ssize_t idx = indexof(map, key);
	if (idx < 0)
		return 1;
	if (valp) {
		ifelse(val_ptr, 1, `
		if (map->flags & hash_map_cvar(CLONE_VAL)) {
			val_type ov;
			get_val(map, idx, &ov);
			memcpy(valp, ov, map->vlen);
		} else {
			get_val(map, idx, valp);
		}
		', `
		get_val(map, idx, valp);
		')
	} ifelse_str(val_type, `
	else if (map->flags & hash_map_cvar(CLONE_VAL)) {
		val_type ov;
		get_val(map, idx, &ov);
		free(ov);
	}')
	ifelse_str(key_type, `
	if (map->flags & hash_map_cvar(CLONE_KEY)) {
		key_type ok;
		get_key(map, idx, &ok);
		free(ok);
	}')
	map->state[idx] = ST_REMOVED;
	map->size--;
	if (map->size < map->lo_wm) {
		size_t new_cap = choose_shrink_cap(map);
		resize_hash_map(map, new_cap);
	}
	return 0;
}

int hash_map_func(get)(const struct hash_map *map,
	const_arg(key_type) key, val_type *valp)
{
	ssize_t idx = indexof(map, key);
	if (idx < 0)
		return 1;
	get_val(map, idx, valp);
	return 0;
}

int hash_map_func(contains)(const struct hash_map *map,
	const_arg(key_type) key)
{
	ssize_t idx = indexof(map, key);
	return idx >= 0;
}

static size_t choose_hiwm(const struct hash_map *map)
{
	size_t cap = map->capacity;
	size_t x = cap - 2;
	size_t y = (size_t) (cap * map->max_lf);
	return x < y ? x : y;
}

static size_t choose_lowm(const struct hash_map *map)
{
	return (size_t) (map->capacity * map->min_lf);
}

static size_t choose_grow_cap(const struct hash_map *map)
{
	size_t sz = map->size + 1;
	size_t x = sz + 1;
	size_t y = (size_t) ((4 * sz) / (3 * map->min_lf + map->max_lf));
	return next_prime(x > y ? x : y);
}

static size_t choose_shrink_cap(const struct hash_map *map)
{
	size_t sz = map->size;
	size_t x = sz + 1;
	size_t y = (size_t) ((4 * sz) / (map->min_lf + 3 * map->max_lf));
	return next_prime(x > y ? x : y);
}

static ALWAYS_INLINE size_t hash_key(const struct hash_map *map,
	const_arg(key_type) key)
{
	ifelse_ptr(key_type, `
	const char *cur = key;
	size_t hash = 5381;
	ifelse_str(key_type, `
	int c;
	while ((c = *cur++))
		hash = ((hash << 5) + hash) ^ c;
	', `
	size_t len = map->klen;
	while (len-- != 0)
		hash = ((hash << 5) + hash) ^ (*cur++);
	')
	return hash;
	', `
	return (size_t) key;
	')
}

static ALWAYS_INLINE int equal_keys(const struct hash_map *map,
	size_t k2idx, const_arg(key_type) k1)
{
	ifelse_str(key_type, `
	return strcmp(k1, map->keys[k2idx]) == 0;
	', ifelse_ptr(key_type, `
	size_t klen = map->klen;
	const void *k2 = (map->flags & hash_map_cvar(CLONE_KEY)) ?
		&((const char *) map->keys)[k2idx * klen] : map->keys[k2idx];
	return memcmp(k1, k2, klen) == 0;
	', `
	return map->keys[k2idx] == k1;
	'))
}

static ALWAYS_INLINE int equal_vals(const struct hash_map *map,
	size_t v2idx, const_arg(val_type) v1)
{
	ifelse_str(val_type, `
	return strcmp(v1, map->vals[v2idx]) == 0;
	', ifelse_ptr(val_type, `
	size_t vlen = map->vlen;
	const void *v2 = (map->flags & hash_map_cvar(CLONE_VAL)) ?
		&((const char *) map->vals)[vlen * v2idx] : map->vals[v2idx];
	return memcmp(v1, v2, vlen) == 0;
	', `
	return map->vals[v2idx] == v1;
	'))
}

static ALWAYS_INLINE void get_val(const struct hash_map *map,
	size_t idx, val_type *valp)
{
	ifelse(val_ptr, 1, `
	if (map->flags & hash_map_cvar(CLONE_VAL)) {
		*valp = &((char *) map->vals)[map->vlen * idx];
		return;
	}')
	*valp = map->vals[idx];
}

static ALWAYS_INLINE void set_val(struct hash_map *map,
	size_t idx, val_type val)
{
	ifelse_ptr(val_type, `
	if (map->flags & hash_map_cvar(CLONE_VAL)) {
		ifelse_str(val_type, `
		map->vals[idx] = strdup(val);
		', `
		size_t vlen = map->vlen;
		void *clone = &((char *) map->vals)[idx * vlen];
		memcpy(clone, val, vlen);
		')
		return;
	}')
	map->vals[idx] = val;
}

static ALWAYS_INLINE void get_key(const struct hash_map *map,
	size_t idx, key_type *keyp)
{
	ifelse(key_ptr, 1, `
	if (map->flags & hash_map_cvar(CLONE_KEY)) {
		*keyp = &((char *) map->keys)[idx * map->klen];
		return;
	}')
	*keyp = map->keys[idx];
}

static ALWAYS_INLINE void set_key(struct hash_map *map,
	size_t idx, key_type key)
{
	ifelse_ptr(key_type, `
	if (map->flags & hash_map_cvar(CLONE_KEY)) {
		ifelse_str(key_type, `
		map->keys[idx] = strdup(key);
		', `
		size_t klen = map->klen;
		key_type clone = &((char *) map->keys)[idx * klen];
		memcpy(clone, key, klen);
		')
		return;
	}')
	map->keys[idx] = key;
}

static ssize_t indexof_insert(const struct hash_map *map,
	const_arg(key_type) k)
{
	const char *state = map->state;
	size_t cap = map->capacity;
	uint32_t hash = hash_key(map, k);
	ssize_t idx = hash % cap;
	uint32_t dec = (uint32_t) (hash % (cap - 2));
	if (UNLIKELY(dec == 0))
		dec = 1;
	char s;
	while ((s = state[idx]) == ST_FULL && !equal_keys(map, idx, k)) {
		idx -= dec;
		if (idx < 0)
			idx += cap;
	}
	if (s == ST_REMOVED) {
		size_t j = idx;
		while ((s = state[idx]) != ST_FREE && (s == ST_REMOVED ||
			!equal_keys(map, idx, k))) {
			idx -= dec;
			if (idx < 0)
				idx += cap;
		}
		if (s == ST_FREE)
			idx = j;
	}
	return s == ST_FULL ? (-idx - 1) : idx;
}

static ssize_t indexof(const struct hash_map *map,
	const_arg(key_type) k)
{
	const char *state = map->state;
	size_t cap = map->capacity;
	uint32_t hash = hash_key(map, k);
	ssize_t idx = hash % cap;
	uint32_t dec = hash % (cap - 2);
	if (UNLIKELY(dec == 0))
		dec = 1;
	char s;
	while ((s = state[idx]) != ST_FREE && (s == ST_REMOVED ||
		!equal_keys(map, idx, k))) {
		idx -= dec;
		if (idx < 0)
			idx += cap;
	}
	return s == ST_FREE ? -1 : idx;
}

static key_type *alloc_keytable(const struct hash_map *map, size_t cap)
{
	ifelse(key_ptr, 1, `
	if (map->flags & hash_map_cvar(CLONE_KEY))
		return malloc(cap * map->klen);
	')
	return malloc(cap * sizeof(key_type));
}

static val_type *alloc_valtable(const struct hash_map *map, size_t cap)
{
	ifelse(val_ptr, 1, `
	if (map->flags & hash_map_cvar(CLONE_VAL))
		return malloc(cap * map->vlen);
	')
	return malloc(cap * sizeof(val_type));
}

static void resize_hash_map(struct hash_map *map, size_t cap)
{
	struct hash_map old_map = *map;
	map->capacity = cap;
	map->nr_free = cap - map->size;
	map->lo_wm = choose_lowm(map);
	map->hi_wm = choose_hiwm(map);
	map->state = malloc(cap);
	map->keys = alloc_keytable(map, cap);
	map->vals = alloc_valtable(map, cap);
	memset(map->state, ST_FREE, cap);
	size_t size = map->size;
	size_t i, j;
	ifelse_str(key_type, `
	int flags = map->flags;
	map->flags = 0;
	', ifelse_str(val_type, `
	int flags = map->flags;
	map->flags = 0;
	'))
	for (i = 0, j = 0; j != size; i++) {
		if (old_map.state[i] != ST_FULL)
			continue;
		key_type key;
		val_type val;
		get_key(&old_map, i, &key);
		get_val(&old_map, i, &val);
		ssize_t idx = indexof_insert(map, key);
		set_key(map, idx, key);
		set_val(map, idx, val);
		map->state[idx] = ST_FULL;
		++j;
	}
	ifelse_str(key_type, `
	map->flags = flags;
	', ifelse_str(val_type, `
	map->flags = flags;
	'))
	free(old_map.state);
	free(old_map.keys);
	free(old_map.vals);
}
