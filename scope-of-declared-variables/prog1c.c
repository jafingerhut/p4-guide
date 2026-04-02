#include <stdlib.h>
#include <stdio.h>

int i;                            // line 1

int main(int argc, char *argv[])
{
    int in1, in2, out1, out2, out3;

    if (argc != 3) {
        fprintf(stderr, "usage: %s <in1> <in2>\n", argv[0]);
        exit(1);
    }
    in1 = atoi(argv[1]);
    in2 = atoi(argv[2]);

    i = in1;                      // line 2
    {
        int j = i + 1;            // line 3
        int i = in2;              // line 4
        out2 = i;                 // line 5
        out3 = j;                 // line 6
    }
    out1 = i;                     // line 7
    printf("out1=%d out2=%d out3=%d\n", out1, out2, out3);
}
