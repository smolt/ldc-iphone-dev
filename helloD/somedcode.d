// Just some D code that has a C API so can be called by other languages

import std.conv;
import std.stdio;

extern (C) double someDCode(const char* question)
{
    class Universe
    {
        // the universe may or may not end
        ~this() {puts("the end of the universe");}
    }

    auto oneOfMany = new Universe;

    writefln("The question: \"%s\"\n", to!string(question));
    return to!double("42");
}
