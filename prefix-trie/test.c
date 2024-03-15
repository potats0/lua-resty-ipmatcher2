#include "bindings.h"
#include <stdio.h>

int main(){
    void *tree = new_prefix_trie();
    insert(tree, 3232235776, 24, 1);
    int action = get(tree, 3232235777, 32);
    printf("aa %d\n", action);
}