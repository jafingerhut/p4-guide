#include <stdlib.h>
#include <stdio.h>

void foo(int i, int *out1, int *out2, int *out3) {
    int i = i + 1;
    *out1 = i;
    {
        int i = i + 1;
        *out2 = i;
    }
    *out3 = i;
}

int main(int argc, char *argv[])
{
    int in1, in2, out1, out2, out3;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <in1>\n", argv[0]);
        exit(1);
    }
    in1 = atoi(argv[1]);

    int i = in1;
    foo(i, &out1, &out2, &out3);
    printf("out1=%d out2=%d out3=%d\n", out1, out2, out3);
}
