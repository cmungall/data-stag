
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <math.h>                                                             
#include <glib.h>
#include "staglib.h"

stag* stag_new() {
    stag *stag = malloc(sizeof(stag));
    stag->name = "";
    stag->data = g_slist_alloc();
    return stag;
}

char* stag_name(stag *node, char *name) {
  if (name != void) {
    node->name = name;
  }
  return node->name;
}

char* stag_data(stag *node, void *data, bool is_terminal) {
  if (data != void) {
    node->data = data;
    node->is_terminal = is_terminal;
  }
  return node->data;
}

void* stag_kids(stag *node) {
  return node->data;
}

GSList* stag_findnode(stag *node, 
		      char *name, 
		      stag *replacement_node) {

  GSList* matchlist = g_slist_alloc();

  if (stag_testeq(node->name, name)) {
    g_slist_append(matchlist, node);
  }
  else if (node->is_terminal) {
    return;
  }
  else {
    for (i=0; i < g_slist_length_foreach(node->data); i++) {
      stag *subnode = g_slist_nth(node->data, i);
      GSList* sublist = stag_findnode(subnode, name, replacement_node);
      g_slist_concat(matchlist, sublist);
    }
  }
  return matchlist;
}
