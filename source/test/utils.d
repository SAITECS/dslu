/// String Literal Generation
module test.utils;

package:

import std.algorithm;
import std.array;
import std.ascii;
import std.meta;
import std.range;

/**
    Utility function used to generate the set of strings containing strings of
    sizes from 1 to 128 chars
*/
string[] generateStrings()
{
	string[] result;

	foreach(i; 0..127)
	{
		result ~= uppercase.cycle.drop(i).take(i + 1).map!(c => cast(char) c).array;
	}

	return result;
}
