#include "bindings.h"
#include <assert.h>
#include <stdio.h>

int main(){
    void *tree = new_prefix_trie();
    insert(tree, 3232235776, 24, 1);
    char action = get(tree, 3232235777, 32);
    assert(action == 1);
}