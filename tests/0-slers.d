/++ dub.sdl:
	name "tests.slers"
	dependency "dslu" path=".."
+/

module tests.slers;

import dslu;
import test.utils;

import std.datetime;
import std.meta;
import std.stdio;

/// Number of iterations
enum ulong C = 1_000_000;

/// Compile time generated set of strings to be used for testing
enum string[] SS = generateStrings();

int main()
{
	ulong[SS.length] ar;
	TickDuration[SS.length] ad;
	foreach(I, S; aliasSeqOf!SS)
	{
		string s = S.dup;
		ad[I] = benchmark!(() => ar[I] += slers!(S, false, true)(s) ? 1 : 0)(C)[0];
	}

	int tr;
	TickDuration td;
	auto o = File("tests/tests.slers.txt", "w+");
	foreach(i, _; ad)
	{
		td += ad[i];
		tr += ar[i];
		o.writeln("Iteration:\t", i + 1, "\tduration:\t", ad[i].usecs, "\tresult\t", ar[i]);
	}
	o.writeln("Total:\t", tr, "\tduration:\t", dur!("hnsecs")(td.hnsecs));

	return tr;
}