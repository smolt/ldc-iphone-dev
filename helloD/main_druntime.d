// Demo various parts of druntime, including threads and TLS.
import core.stdc.stdio;
import core.thread;

int tls = 42;

int main()
{
    auto x = new Hello;

    printf("main is running on");
    printThread();
    tls = 2001;
    
    auto th = new Thread
        ({
            printf("Running, tls is %d", tls);
            assert(tls == 42);
            printThread();
        });
    th.start();
    th.join();

    assert(tls == 2001);

    puts("All done, main exiting");
    return 0;
}


class Hello
{
    this()  {puts("Hello D runtime");}
    ~this() {puts("Goodbye D runtime (thank you for freeing me)");}
}

void printThread()
{
    printf(" [thread %p]\n", Thread.getThis());
}

static this()
{
    printf("Hello module ctors");
    printThread();
}

static ~this()
{
    printf("Goodbye module ctors");
    printThread();
}

shared static this()
{
    puts("Hello shared module ctors");
}

shared static ~this()
{
    puts("Goodbye shared module ctors");
}

