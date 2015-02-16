// Basic breath of life for D compiled code that gets by without any runtime
// support.

extern (C):

int puts(const(char)* str);                  // normally from stdio

int main()
{
    puts("Hello (using no D runtime libs)");
    return 0;
}

// Our D module init code isn't used but it needs to link to this
__gshared void* _Dmodule_ref;

