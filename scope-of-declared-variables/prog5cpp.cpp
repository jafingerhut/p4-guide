#include <stdlib.h>
#include <stdio.h>

void foo(int i, int *o1, int *o2, int *o3) {
    int i = i + 1;
    *o1 = i;
    {
        int i = i + 1;
        *o2 = i;
    }
    *o3 = i;
}

int main(int argc, char *argv[])
{
    int in1, in2, o1, o2, o3;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <in1>\n", argv[0]);
        exit(1);
    }
    in1 = atoi(argv[1]);

    int i = in1;
    foo(i, &o1, &o2, &o3);
    printf("o1=%d o2=%d o3=%d\n", o1, o2, o3);
}
