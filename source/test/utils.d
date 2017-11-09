/// String Literal Generation
module test.utils;

private:

import std.algorithm;
import std.array;
import std.ascii;
import std.meta;
import std.range;

/**
 *	Utility function used to generate a string array containing strings of size
 *	varying from 1 to 128 chars based on the 'letters' array from std.ascii.
 */
@safe
public
string[] generateStrings()
{
	string[] result;

	foreach(i; 0..127)
	{
		result ~= letters.cycle.drop(i).take(i + 1).map!((c) @trusted => cast(char) c).array;
	}

	return result;
}

@safe
unittest
{
	const as = generateStrings();
	assert(as[5] == "FGHIJK", "Expected: \"FGHIJK\" but received: " ~ as[5]);
}

///
public
bool rsers(string SL, bool CL = true, bool NI = false)(string rs)
{
	static if (NI)
	{
		pragma(inline, false);
	}

	return SL == rs;
}

@system
unittest
{
	enum SS = "00000000111111112222334";
	assert(rsers!(SS)(SS.dup), "rsers!" ~ SS ~ "(" ~ SS ~ ") returned false!");

	string[] ars = [SS[1..$]];
	ars ~= SS.dup.replace(0, 1, ['!']);
	ars ~= SS.dup.replace(8, 9, ['!']);
	ars ~= SS.dup.replace(16, 17, ['!']);
	ars ~= SS.dup.replace(20, 21, ['!']);
	ars ~= SS.dup.replace(22, 23, ['!']);

	foreach(rs; ars)
	{
		assert(!rsers!(SS)(rs), "rsers!" ~ SS ~ "(" ~ rs ~ ") returned true!");
	}
}

///
public
bool memcmp(string SL, bool CL = true, bool NI = false)(string rs)
{
	static if (NI)
	{
		pragma(inline, false);
	}

	static if (CL)
	{
		if (SL.length != rs.length) return false;
	}

	import core.stdc.string: memcmp;
	return memcmp(cast(void*) cast(string) SL, cast(void*) rs, SL.length) == 0;
}

@system
unittest
{
	enum SS = "00000000111111112222334";
	assert(memcmp!(SS)(SS.dup), "memcmp!" ~ SS ~ "(" ~ SS ~ ") returned false!");

	string[] ars = [SS[1..$]];
	ars ~= SS.dup.replace(0, 1, ['!']);
	ars ~= SS.dup.replace(8, 9, ['!']);
	ars ~= SS.dup.replace(16, 17, ['!']);
	ars ~= SS.dup.replace(20, 21, ['!']);
	ars ~= SS.dup.replace(22, 23, ['!']);

	foreach(rs; ars)
	{
		assert(!memcmp!(SS)(rs), "memcmp!" ~ SS ~ "(" ~ rs ~ ") returned true!");
	}
}
