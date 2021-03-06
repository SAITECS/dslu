module dslu.slers;

private:

import std.algorithm;
import std.conv;
import std.meta;
import std.range;
import std.stdio;
import std.string;
import std.typecons;

enum SIZE(TYPE) = TYPE.sizeof;
enum bool SIZE_FILTER(TYPE) = SIZE!TYPE <= SIZE!size_t;
enum bool SIZE_COMPARE(LEFT, RIGHT) = SIZE!LEFT > SIZE!RIGHT;
alias ALL_INTEGRAL_TYPES = AliasSeq!(ulong, uint, ushort, ubyte);
alias ORDERED_AVAILABLE_INTEGRAL_TYPES =
	staticSort!(SIZE_COMPARE, Filter!(SIZE_FILTER, ALL_INTEGRAL_TYPES));


template SizeToTypeOffsetTuple(
	size_t TOTAL_SIZE,
	INTEGRAL_TYPES_LIST = ORDERED_AVAILABLE_INTEGRAL_TYPES)
{
	template GenerateTypeOffsetTuple(size_t START_OFFSET, CURRENT_TYPES_LIST...)
	{
		static if (CURRENT_TYPES_LIST.length > 0)
		{
			alias TYPE = CURRENT_TYPES_LIST[0];
			enum size_t TYPE_SIZE = SIZE!TYPE;
			enum size_t TYPE_COUNT = ((TOTAL_SIZE - START_OFFSET) / TYPE_SIZE);

			static if (TYPE_COUNT > 0)
			{
				enum size_t END_OFFSET = START_OFFSET + TYPE_COUNT * TYPE_SIZE;
				alias GenerateTypeOffsetTuple =
					AliasSeq!(
						AliasSeq!(TYPE, TYPE_COUNT, START_OFFSET),
						GenerateTypeOffsetTuple!
							(END_OFFSET, CURRENT_TYPES_LIST[1..$]));
			}
			else
			{
				alias GenerateTypeOffsetTuple =
					GenerateTypeOffsetTuple!
						(START_OFFSET, CURRENT_TYPES_LIST[1..$]);
			}
		}
		else
		{
			alias GenerateTypeOffsetTuple = AliasSeq!();
		}
	}

	alias SizeToTypeOffsetTuple =
		GenerateTypeOffsetTuple!(0, ORDERED_AVAILABLE_INTEGRAL_TYPES);

	debug pragma(msg, SizeToTypeOffsetTuple);
}

@safe
unittest
{
	alias SOT = AliasSeq!(SizeToTypeOffsetTuple!(15));
	alias ESOT = AliasSeq!(ulong, 1, 0, 8, uint, 1, 8, 12, ushort, 1, 12, 14, ubyte, 1, 14, 15);
//	static assert(is(SOT : ESOT));
}


@trusted
string toHexString(TYPE)(in string s, in size_t ubo = 0)
{
	import std.system: Endian, endian;
	import std.digest.digest: toHexString, Order;
	enum o = endian == Endian.littleEndian ? Order.decreasing: Order.increasing;
	return toHexString!(o)((cast(ubyte[]) s)[ubo..ubo + SIZE!TYPE]);
}

@safe
unittest
{
	static assert(toHexString!(ulong)("ABCDEFGH12345678", 8) == "3837363534333231");
}


/**
 *	Checks if a string literal is equal to a runtime provided string.
 *
 *  The performance of the comparison is the same or faster than memcmp. This is
 *	achieved by employing the x86/AMD64 CPU instruction cache for the string
 *	literal data which itself is achieved by representing the string literal in
 *	the form of one or more integer literal(s) which correspond to the runtime
 *	string representation in memory.
 *
 *	Params:
 *		SL = String Literal: Template string parameter containing the value for
 *			 which comparison code is generated.
 *		CL = Check Length: Template boolean parameter controling if a length
 *			 check code should be generated. True by default i.e. length check
 *			 code is generated if parameter value is not provided.
 *		NI = No Inline: Template boolean parameter which can be used to prevent
 *			 inlining the generated function. False by default i.e. generated
 *			 function is inlineable if parameter value is not provided.
 *		rs = Runtime String: String parameter containing the value which is
 *			 compared against the template provided string value.
 *
 *	Examples:
 *	---
 *	import dslu;
 * 
 *	int main(string[] args)
 *	{
 *		if (args.length > 0)
 *		{
 *			return slers!("--option")(args[1]);
 *		}
 *
 *		return 0;
 *	}
 *	---
 *
 *	Copyright: © 2017 SAITECS
 *	License: Subject to the terms of the BSL-1.0 license, as written in the
 *			 included LICENSE.txt file.
 *	Authors: Dentcho Bankov
 */

public
@trusted
bool slers(string SL, bool CL = true, bool NI = false)(string rs)
{
	static if (NI)
	{
		pragma(inline, false);
	}

	static if(CL)
	{
		if (SL.length != rs.length) return false;
	}

	alias TOT = SizeToTypeOffsetTuple!(SL.length);

	alias TYPE_COUNT(alias TYPE_INDEX) = TOT[TYPE_INDEX + 1];
	alias START_OFFSET(alias TYPE_INDEX) = TOT[TYPE_INDEX + 2];

	foreach(INDEX, TYPE; TOT)
	{
		static if (INDEX % 3 == 0)
		{
			foreach(CURRENT_COUNT; aliasSeqOf!(iota(TYPE_COUNT!INDEX)))
			{
				enum CURRENT_OFFSET = START_OFFSET!INDEX + CURRENT_COUNT * SIZE!TYPE;
				enum INTEGER_LITERAL = mixin("0x" ~ toHexString!TYPE(SL, CURRENT_OFFSET));
				debug pragma(msg, "Offset:\t", CURRENT_OFFSET, "\tValue:\t", INTEGER_LITERAL);
				if (INTEGER_LITERAL != *(cast(TYPE*) &(cast(void*) rs)[CURRENT_OFFSET])) return false;
			}
		}
	}

	return true;
}

/*
@trusted
public
bool slers(string SL, bool CL = true, bool NI = false)(string rs)
{
	static if (NI)
	{
		pragma(inline, false);
	}

	ulong r;

	static if (CL)
	{
		r = SL.length - rs.length;
		if (r != 0) goto exit;
	}

	alias TOT = SizeToTypeOffsetTuple!(SL.length);

	alias C(alias I) = TOT[I + 1];
	alias B(alias I) = TOT[I + 2];

	foreach(I, T; TOT)
	{
		static if (I % 3 == 0)
		{
			foreach(J; aliasSeqOf!(iota(C!I)))
			{
				enum bo = B!I + J * SIZE!T;
				enum il = mixin("0x" ~ toHexString!T(SL, bo));
				r = il - *(cast(T*) &rs[bo]);
				if (r != 0) goto exit;
			}
		}
	}

exit:
	return r == 0;
}
*/

@safe
unittest
{
	enum SS = "00000000111111112222334";
	assert(slers!(SS)(SS.dup), "slers!" ~ SS ~ "(" ~ SS ~ ") returned false!");

	string[] ars = [SS[1..$]];
	ars ~= SS.dup.replace(0, 1, ['!']);
	ars ~= SS.dup.replace(8, 9, ['!']);
	ars ~= SS.dup.replace(16, 17, ['!']);
	ars ~= SS.dup.replace(20, 21, ['!']);
	ars ~= SS.dup.replace(22, 23, ['!']);

	foreach(rs; ars)
	{
		assert(!slers!(SS)(rs), "slers!" ~ SS ~ "(" ~ rs ~ ") returned true!");
	}
}
