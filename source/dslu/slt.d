module dslu.slt;

private:

import std.meta;
import std.range;
import std.traits;
import std.typecons;

///
static struct StaticLookupTable(alias RD)
{
    static if (is(typeof(RD) == string[]))
    {
        debug enum Msg = "string[]: ";

        alias KeyType = string;
        alias ValueType = size_t;

        alias KeyData = aliasSeqOf!(RD);
        alias ValueData = aliasSeqOf!(iota(RD.length));
    }
    else static if (is (typeof(RD): DVT[DKT], DKT, DVT))
    {
        debug enum Msg = "AA: ";

        alias KeyType = DKT;
        alias ValueType = typeof(ValueData[0]);

        alias KeyData = aliasSeqOf!(RD.keys);
        alias ValueData = aliasSeqOf!(RD.values);
    }
    else static if (is (RD == enum))
    {
        debug enum Msg = "Enum: ";

        alias KeyType = string;
        alias ValueType = typeof(ValueData[0]);

        alias KeyData = AliasSeq!(__traits(allMembers, RD));
        alias ValueData = EnumMembers!RD;
    }
    else static if (is (typeof(RD) == Tuple!DVT, DVT...))
    {
        debug enum Msg = "Tuple: ";
        import std.variant: Algebraic;

        alias KeyType = string;
        alias ValueType = Algebraic!(NoDuplicates!(RD.Types));

        alias KeyData = AliasSeq!(RD.fieldNames);
        alias ValueData = RD;
    }
    else
    {
        debug enum Msg = "Error: ";
        static assert(false, "Unsupported initialization data type!");
    }

    debug pragma(msg, Msg, ValueType, "[", KeyType, "], ", KeyData, ", ", ValueData, ")");

    static ValueType opIndex(KeyType key)
    {
        import std.range;

        enum Size(alias V) = V.length;
        enum SizeComp(alias LHS, alias RHS) = Size!LHS < Size!RHS;
        alias SSKeyData = staticSort!(SizeComp, KeyData);
        alias S = NoDuplicates!(staticMap!(Size, SSKeyData));

        pragma(msg, S);
        pragma(msg, SSKeyData);
        
        final switch(key.length)
        {
            foreach(s; S)
            {
                case s:
                {
                    final switch(key)
                    {
                        foreach(i, _; KeyData)
                        {
                            static if (Size!(KeyData[i]) == s)
                            {
                                case KeyData[i]: return ValueType(ValueData[i]);
                            }
                        }
                    }
                }
            }
        }
/*
        final switch(key)
        {
            static foreach(i, _; KeyData)
            {
                case KeyData[i]: return ValueType(ValueData[i]);
            }
        }
*/
    }
}

@safe
unittest
{
    enum string[] TEST = ["k0", "ke1", "key1"];
    alias LookupTable = StaticLookupTable!TEST;
    assert(LookupTable["ke1"] == 1);
}

@safe
unittest
{
    enum int[string] TEST = ["k0": 0, "ke1": 1, "key2": 2];
    alias LookupTable = StaticLookupTable!TEST;
    assert(LookupTable["ke1"] == 1);
}

@safe
unittest
{
    enum TEST { k0 = 0, ke1 = 1, key2 = 2 }
    alias LookupTable = StaticLookupTable!TEST;
    assert(LookupTable["ke1"] == TEST.ke1);
}

@system
unittest
{
    enum TEST = tuple!("k0", "ke1", "key2")(0, '1', "2");
    alias LookupTable = StaticLookupTable!TEST;
    assert(LookupTable["ke1"] == '1');
}