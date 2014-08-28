include(`capitalize.m4')
include(`types.m4')
divert(`-1')
# Common hash map macros
# key_type - Key type
define(`key_type', _type1)
# val_type - Value type
define(`val_type', _type2)
# hash_map - Hash map structure name
define(`hash_map', format(`hash_map%s%s', _type1_abv, _type2_abv))
# hash_map_func - Add prefix to hash map function
#	$1 - name
define(`hash_map_func', format(`%s_%s', hash_map, $1))
# hash_map_cvar - Add prefix to hash map constant
#	$1 - name
define(`hash_map_cvar', format(`%s_%s', upcase(hash_map), $1))
# keyval_ptr - 1 if key or value type is pointer type, 0 otherwise
define(`keyval_ptr', ifelse_ptr(key_type, 1, ifelse_ptr(val_type, 1, 0)))
# key_ptr - 1 if key is pointer type (not char *)
define(`key_ptr', ifelse_str(key_type, 0, ifelse_ptr(key_type, 1, 0)))
# val_ptr - 1 if value is pointer type (not char *)
define(`val_ptr', ifelse_str(val_type, 0, ifelse_ptr(val_type, 1, 0)))
divert`'dnl
