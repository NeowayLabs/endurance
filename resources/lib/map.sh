# This package implements a naive map implementation using
# a list of (key, value) tuples.
# nash does not have a map implementation, yet :-)

fn resources_lib_map_new() {
	map = ()

	return $map
}

fn resources_lib_map_get(map, key) {
	for entry in $map {
		if $entry[0] == $key {
			return $entry[1]
		}
	}

	return ()
}

fn resources_lib_map_add(map, key, val) {
	for entry in $map {
		if $entry[0] == $key {
			entry[1] = $val
			
			return $map
		}
	}

	tuple = ($key $val)

	map <= append($map, $tuple)

	return $map
}
