/+
 Unittest runner for iOS.

 Only use druntime imports that are musts.  Don't want this test runner to
 rely too much on the modules it is testing.
+/
module unittester;

import core.runtime;
import core.stdc.stdio;
import xyzzy = ldc.xyzzy: cvstr;

// Only compile in main if running stand alone.  If called from an iOS app,
// don't need main.
version (UnittestMain)
{
    shared static this()
    {
        // disable builtin unit test runner that runs before main.
        Runtime.moduleUnitTester = ()=>true;
    }
    
    int main()
    {
        setupEnvAndRunTests();

        // for iOS, exit(0) for some reason causes a delay when app exits but only
        // if threading was used.  Don't know why, but happens with the simplest
        // of C code too, so not D related.  Not really an issue because real iOS
        // apps should never return anyway.
        // Return non-zero to avoid the delay.
        return 1;
    }
}
else
{
    // Start here when calling from a non D main (i.e. C).
    extern (C) int runUnitTests()
    {
        int r = 0;
        rt_init();

        try
        {
            r = setupEnvAndRunTests();
        }
        catch (Throwable any)
        {
            auto msg = any.toString();
            printf("Caught unexpect %.*s\n", msg.cvstr);
        }
    
        rt_term();
        return r;
    }
}


// A test TLS var
int varInitWorking = 42;

// This will be defined in libunittest-(release|debug).a with appropriate name
extern extern(C) const char* unittest_configname;

bool setupEnvAndRunTests() 
{
    import core.stdc.stdlib;
    import core.sys.posix.fcntl;
    import core.sys.posix.unistd;

    printf("=-=-= Testing druntime/phobos %s build =-=-=\n",
           unittest_configname);

    // Sanity check to make sure variables and underlying TLS (or no TLS) is
    // being initialized properly.
    assert(varInitWorking == 42, "Make sure TLS are initialized");

    // Move to tmpdir so unittests that write files can do so.
    const char* tmpdir = getenv("TMPDIR");
    if (!tmpdir)
    {
        puts("Hmmm, TMPDIR not in env, file write tests may fail");
        return false;
    }

    // first save current dir so can restore
    int cdfd = syschk!open(".".ptr, O_RDONLY);
    scope (exit) syschk!fchdir(cdfd);
   
    printf("Setting dir to TMPDIR so unittests can write files if needed.\n"
           "cd %s\n", tmpdir);
    syschk!chdir(tmpdir);


    /* iOS has ARM FPU in run fast mode, so need to disable these things to
       help math tests to pass all their cases.  In a real iOS app, probably
       would not depend on such behavior that math unittests expect.

       FPSCR(ARM)/ FPCR(AArch64) mode bits of interest.  ARM has both bits
       24,25 set by default, AArch64 has just bit 25 set by default.

       [25] DN Default NaN mode enable bit:
       0 = default NaN mode disabled 1 = default NaN mode enabled.
       [24] FZ Flush-to-zero mode enable bit:
       0 = flush-to-zero mode disabled 1 = flush-to-zero mode enabled. */
    version (D_HardFloat)
    {
        import ldc.llvmasm;
        version (ARM)
        {
            puts("FPU Flush to Zero and Default NaN disabled for tests");
            cast(void)__asm!uint("vmrs $0, fpscr\n"
                                 "bic $0, #(3 << 24)\n"
                                 "vmsr fpscr, $0", "=r");
            scope (exit)
            {
                puts("Restoring FPU mode");
                // restore flush to zero and default nan mode
                cast(void)__asm!uint("vmrs $0, fpscr\n"
                                     "orr $0, #(3 << 24)\n"
                                     "vmsr fpscr, $0", "=r");
            }
        }
        else version (AArch64)
        {
            puts("Default NaN disabled for tests");
            cast(void)__asm!uint("mrs $0, fpcr\n"
                                 "and $0, $0, #~(1 << 25)\n"
                                 "msr fpcr, $0", "=r");
            scope (exit)
            {
                puts("Restoring FPU mode");
                // restore default nan mode
                cast(void)__asm!uint("mrs $0, fpcr\n"
                                     "orr $0, $0, #(1 << 25)\n"
                                     "msr fpcr, $0", "=r");
            }
        }
    }

    return runModuleTests(findModuleTests());
}


ModuleInfo*[] findModuleTests()
{
    // collect all modules and sort with with simple insertion sort
    // (remember, don't use phobos!)
    ModuleInfo*[] modules;

    foreach (m; ModuleInfo)
    {
        // test specific module
        //if (m.name != "std.math") continue;
        
        size_t i = (modules.length += 1);
        while (--i > 0 && m.name < modules[i-1].name)
            modules[i] = modules[i-1];
        modules[i] = m;
    }

    return modules;
}

bool runModuleTests(ModuleInfo*[] modules)
{
    bool ok = true;
    int i;
    int pass;
    int partial;

    foreach (m; modules)
    {
        if (m.unitTest)
        {
            printf("Testing %d %.*s: ", ++i, m.name.cvstr);
            fflush(stdout);

            if (runTest(m.unitTest, partial))
                ++pass;
            else
                ok = false;
        }
        else
        {
            //printf("  no unittest in %.*s\n", m.name.cvstr);
        }
    }

    printf("Passed %d of %d (%d have tailored tests), "
           "%d other modules did not have tests\n",
           pass,
           i,
           partial,
           modules.length - i);

    return ok;
}

bool runTest(void function() testfunc, ref int partial)
{
    import core.time: TickDuration;

    bool ok = true;
    string msg;
    immutable beforeSkipped = xyzzy.skippedTests;
    immutable beforeFailed = xyzzy.failedTests;
    immutable t0 = TickDuration.currSystemTick;

    try
    {
        testfunc();
    }
    catch (Throwable e)
    {
        xyzzy.skippedTests = beforeSkipped;
        ok = false;
        msg = e.toString();
    }
    
    immutable t1 = TickDuration.currSystemTick;
    if (xyzzy.failedTests > beforeFailed)
    {
        ok = false;
        msg = "";
    }

    printf("%s (took %dms)", ok ? "OK".ptr : "FAIL".ptr, (t1 - t0).msecs);

    if (xyzzy.skippedTests > beforeSkipped)
    {
        printf(" note: some tests where skipped for this target");
        ++partial;
    }
    putchar('\n');

    if (msg.length > 0) printf("%.*s\n", msg.cvstr);

    return ok;
}

auto syschk(alias syscall, Args...)(auto ref Args args)
{
    // Call POSIX style syscall and check for error, throwing exception
    auto r = syscall(args);
    if (r == -1)
    {
        // avoid std imports :-(
        //import std.traits;
        //enum errmsg = fullyQualifiedName!syscall ~ " failed";
        enum errmsg = __traits(identifier, syscall) ~ " failed";
        perror(errmsg.ptr);
        throw new Exception(errmsg);
    }
    return r;
}
