component output="false" {
	include template="relation/cache.cfm";
	include template="relation/execution.cfm";
	include template="relation/initialization.cfm";
	include template="relation/looping.cfm";
	include template="relation/mapping.cfm";
	include template="relation/objects.cfm";
	include template="relation/onMissingMethod.cfm";
	include template="relation/pagination.cfm";
	include template="relation/query.cfm";
	include template="parser/parse.cfm";
	include template="parser/grammar.cfm";
	include template="caching/caching.cfm";
	include template="caching/caching-control.cfm";
	include template="caching/signatures.cfm";
	include template="functions.cfm";

	function query() {
		return $query(argumentCollection = arguments);
	}

	function struct() {
		return $struct(argumentCollection = arguments);
	}

	function arrayLast() {
		return $arrayLast(argumentCollection = arguments);
	}

	function sizeOf() {
		return $sizeOf(argumentCollection = arguments);
	}
}
