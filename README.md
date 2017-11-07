# DSLU aka DLang String Literal Utils

# Overview

DSLU is a D Programming Language library containing several simple but efficient utilities targeted at better utilization of string literals:

```D
slers(string SL, bool CL = true, bool NI = false)(string rs)
```

The first and foremost facility included in the DSLU library is the _slers_ (String Literal Equals Runtime String) function which is a simple comparison utility that can be used to check if a runtime string is equal to a string literal provided as a template parameter. On average the comparison is done about twice faster than the compiler provided runtime string _opEquals_/_memcmp_ implementations for strings ranging from 1 to 128 bytes. Note that for some strings from 1 to 16 bytes LDC2's/CLANG's _opEquals_/_memcmp_ generates exactly the same code as _slers_ thus in these cases performance of _slers_ is equal to _opEquals_/_memcmp_. Still for larger strings _slers_ is significantly faster which results in the observed result mentioned above. The improved performance is achieved at the cost of additional code being generated. Precisely a separate function is generated for each string literal and the actual comparison is done by converting the string literal to a set of integer literals at compile time and then at runtime comparing the passed runtime string against these integer literals by casting the corresponding parts of the runtime string to the appropriate integral type and comparing the resulting values. The reason for this approach to provide better performance than _opEquals_/_memcmp_ is because the integer literals in the generated code are compiled to immediate instructions for the x86_64 CPUs thus becoming part of the code itself (which however also increases the generated code size). The latter means that effectively the string literal is loaded through the instruction cache while the runtime string is loaded through the data cache.

To ilustrate what _slers_ does at compile time below is an example of the function generated when the "00000000111111112222334" string literal is passed to it:

```D
bool slers!("00000000111111112222334")(string rs)
{
    if (23 != rs.length) return false;
    if (3472328296227680304L != *(cast(ulong*) &(cast(void*) rs)[0])) return false;
    if (3544668469065756977L != *(cast(ulong*) &(cast(void*) rs)[8])) return false;
    if (842150450 != *(cast(uint*) &(cast(void*) rs)[16])) return false;
    if (13107 != *(cast(ushort*) &(cast(void*) rs)[20])) return false;
    if (52 != *(cast(ubyte*) &(cast(void*) rs)[22])) return false;

    return true;
}
```

and here is the generated assembly code (by LDC2):

```Assembly
100009A90: 48 83 FF 17                cmpq   $0x17, %rdi
100009A94: 75 3B                      jne    0x100009ad1  ; <+65>
100009A96: 48 B8 30 30 30 30 30 30 >  movabsq $0x3030303030303030, %rax  ; imm = 0x3030303030303030 
100009AA0: 48 39 06                   cmpq   %rax, (%rsi)
100009AA3: 75 2C                      jne    0x100009ad1  ; <+65>
100009AA5: 48 B8 31 31 31 31 31 31 >  movabsq $0x3131313131313131, %rax  ; imm = 0x3131313131313131 
100009AAF: 48 39 46 08                cmpq   %rax, 0x8(%rsi)
100009AB3: 75 1C                      jne    0x100009ad1  ; <+65>
100009AB5: 81 7E 10 32 32 32 32       cmpl   $0x32323232, 0x10(%rsi)  ; imm = 0x32323232 
100009ABC: 75 13                      jne    0x100009ad1  ; <+65>
100009ABE: 0F B7 46 14                movzwl 0x14(%rsi), %eax
100009AC2: 3D 33 33 00 00             cmpl   $0x3333, %eax  ; imm = 0x3333 
100009AC7: 75 08                      jne    0x100009ad1  ; <+65>
100009AC9: 80 7E 16 34                cmpb   $0x34, 0x16(%rsi)
100009ACD: 0F 94 C0                   sete   %al
100009AD0: C3                         retq   
100009AD1: 31 C0                      xorl   %eax, %eax
100009AD3: C3                         retq   
100009AD4: 66 66 66 2E 0F 1F 84 00 >  nopw   %cs:(%rax,%rax) 
```

# Testing

To build and run the DSLU library unit tests execute:

```bash
dub test
```

To run the slers (string literal equals runtime string) performance test exectue:

```bash
dub run --build=release-nobounds --compiler=ldc2 --single tests/0-slers.d
```

To run the rsers (runtime string equals runtime string) performance test (for comparison) execute:

```bash
dub run --build=release-nobounds --compiler=ldc2 --single tests/0-rsers.d
```

To run the memcmp performance test (for comparison) execute:

```bash
dub run --build=release-nobounds --compiler=ldc2 --single tests/0-memcmp.d
```
