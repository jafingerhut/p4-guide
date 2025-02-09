/*
 * Copyright 2024 Andy Fingerhut
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

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
