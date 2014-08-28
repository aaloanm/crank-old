divert(`-1')
# ifelse_ptr - Determine if a type is a pointer type
#	$1 - Type to check
#	$2 - Execute if $1 is ptr
#	$3 - Execute if $1 is not ptr
#
define(`ifelse_ptr', `ifelse(index(`$1', `*'), -1, $3, $2)')
# ifelse_str - Determine if a type is a string pointer type
#	$1 - Type to check
#	$2 - Execute if $1 is string pointer
#	$3 - Execute if $1 is not string pointer
#
define(`ifelse_str', `ifelse(index($1, `char'), -1,
	$3, ifelse_ptr($1, $2, $3))')
# const_arg - Add const keyword to type if pointer
#	$1 - Type to check
#
define(`const_arg', `ifelse_ptr($1, const $1, $1)')
# const_str_arg - Add const keyword to type if char pointer
#	$1 - Type to check
#
define(`const_str_arg', `ifelse_str($1, const $1, $1)')
divert`'dnl
