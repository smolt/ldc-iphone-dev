// Example of calling D from other language
#import <Foundation/Foundation.h>

// D runtime lifecycle
int rt_init(void);
int rt_term(void);

double someDCode(const char *msg);

int main()
{
    rt_init();

    double answer = someDCode("What is the Answer to the Ultimate Question "
                              "of Life, The Universe, and Everything?");
    NSLog(@"someDCode says it is %g", answer);

    rt_term();                               // will the universe end?
}
