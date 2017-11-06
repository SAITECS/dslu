module dslu.sleqs;

package:

import std.algorithm;
import std.conv;
import std.meta;
import std.range;
import std.stdio;
import std.string;
import std.typecons;

enum S(T) = T.sizeof;
enum STS = S!size_t;
enum bool SFILTER(T) = S!T <= STS;
enum bool SCOMPARE(L, R) = S!L > S!R;
alias ITL = AliasSeq!(ulong, uint, ushort, ubyte);
alias SFITL = staticSort!(SCOMPARE, Filter!(SFILTER, ITL));

template SizeToTypeOffsetTuple(size_t Size, TypeList = SFITL)
{
	template GenerateTypeOffsetTuple(size_t BO, TL...)
	{
		static if (TL.length > 0)
		{
			alias T = TL[0];
			enum size_t TS = T.sizeof;
			enum size_t TC = ((Size - BO) / TS);

			static if (TC > 0)
			{
				enum size_t EO = BO + TC * TS;
				alias GenerateTypeOffsetTuple = AliasSeq!(AliasSeq!(T, TC, BO), GenerateTypeOffsetTuple!(EO, TL[1..$]));
			}
			else
			{
				alias GenerateTypeOffsetTuple = GenerateTypeOffsetTuple!(BO, TL[1..$]);
			}
		}
		else
		{
			alias GenerateTypeOffsetTuple = AliasSeq!();
		}
	}

	alias SizeToTypeOffsetTuple = GenerateTypeOffsetTuple!(0, TypeList);

//	debug pragma(msg, SizeToTypeOffsetTuple);
}

@safe
unittest
{
	alias SOT = AliasSeq!(SizeToTypeOffsetTuple!(15));
	alias ESOT = AliasSeq!(ulong, 1, 0, 8, uint, 1, 8, 12, ushort, 1, 12, 14, ubyte, 1, 14, 15);
//	static assert(is(SOT : ESOT));
}

string toHexString(T)(string s, size_t ubo = 0)
{
	ubyte[T.sizeof] uba = (cast(ubyte[]) s)[ubo..ubo + S!T];
	version(LittleEndian) { reverse(uba[]); }
	return chain(only("0x"), uba[].map!(ub => to!string(ub, 16))).join;
}

@safe
unittest
{
	static assert(toHexString!(ulong)("ABCDEFGH12345678", 8) == "0x3837363534333231");
}

/**
	Checks if a string literal is equal to a runtime provided string but faster
	than memcmp. The latter is achieved by employing the CPU instruction cache
	for the string literal data which is done by representing the string literal
	in the form of one or more integer literal(s) which correspond to the
	runtime string representation in memory.

	Copyright: © 2017 SAITECS Ltd.
	License: Subject to the terms of the BSD-1.0 license, as written in the
			 included LICENSE.txt file.
	Authors: Dentcho Bankov
*/
public
@system
bool sleqs(string ss, bool cl = true, bool inl = true)(string ds)
{
	static if (!inl)
	{
		pragma(inline, false);
	}

	static if(cl)
	{
		if (ss.length != ds.length) return false;
	}

	alias C(alias I) = TOT[I + 1];
	alias B(alias I) = TOT[I + 2];

	alias TOT = SizeToTypeOffsetTuple!(ss.length);

	foreach(I, T; TOT)
	{
		static if (I % 3 == 0)
		{
			foreach(i; aliasSeqOf!(iota(C!I)))
			{
				enum bo = B!I + i * S!T;
				enum sv = mixin(toHexString!T(ss, bo));
				if (sv != *(cast(T*) &ds[bo])) return false;
			}
		}
	}

	return true;
}

/*
@system
public
ulong sleqs(string ss, bool cl = true)(string ds)
{
	ulong r;

	static if (cl)
	{
		r = ss.length - ds.length;
		if (r != 0) goto exit;
	}

	alias C(alias I) = TOT[I + 1];
	alias B(alias I) = TOT[I + 2];

	alias TOT = SizeToTypeOffsetTuple!(staticString.length);

	foreach(I, T; TOT)
	{
		static if (I % 4 == 0)
		{
			foreach(i; aliasSeqOf!(iota(C!I)))
			{
				enum bo = B!I + i * S!T;
				enum sv = mixin(toHexString!T(ss, bo));
				r = sv - *(cast(T*) &ds[bo];
				if (r != 0) goto exit;
			}
		}
	}

exit:
	return r;
}
*/

@system
unittest
{
	enum SS = "00000000111111112222334";
	assert(sleqs!(SS)(SS.dup), "sleqs!" ~ SS ~ "(" ~ SS.dup ~ ") returned false!");

	string[] ads = [SS.dup.replace(0, 1, ['!'])];
	ads ~= SS.dup.replace(8, 9, ['!']);
	ads ~= SS.dup.replace(16, 17, ['!']);
	ads ~= SS.dup.replace(20, 21, ['!']);
	ads ~= SS.dup.replace(22, 23, ['!']);

	foreach(ds; ads)
	{
		assert(!sleqs!(SS)(ds), "sleqs!" ~ SS ~ "(" ~ ds ~ ") returned true!");
	}
}

///
public
bool memcmp(string ss, bool cl = true, bool inl = true)(string ds)
{
	static if (!inl)
	{
		pragma(inline, false);
	}

	static if (cl)
	{
		if (ss.length != ds.length) return false;
	}

	import core.stdc.string: memcmp;
	return memcmp(cast(void*) cast(string) ss, cast(void*) ds, ss.length) == 0;
}

@system
unittest
{
	enum SS = "00000000111111112222334";
	assert(memcmp!(SS)(SS.dup), "sleqs!" ~ SS ~ "(" ~ SS.dup ~ ") returned false!");

	string[] ads = [SS.dup.replace(0, 1, ['!'])];
	ads ~= SS.dup.replace(8, 9, ['!']);
	ads ~= SS.dup.replace(16, 17, ['!']);
	ads ~= SS.dup.replace(20, 21, ['!']);
	ads ~= SS.dup.replace(22, 23, ['!']);

	foreach(ds; ads)
	{
		assert(!memcmp!(SS)(ds), "sleqs!" ~ SS ~ "(" ~ ds ~ ") returned true!");
	}
}
