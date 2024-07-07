#include <stdio.h>

int main (int argc, char *argv[]) {
    printf("Common code for all preprocessor symbol settings here.\n");
#ifdef LANG_ENGLISH
    printf("Hello, world!\n");
#endif
#ifdef LANG_ESPERANTO
    printf("Saluton mondo!\n");
#endif
#ifdef LANG_FRENCH
    printf("Bonjour le monde!\n");
#endif
}
