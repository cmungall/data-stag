
char* stag_name(stag_node *node) {
  return node->name;
}

char* stag_kids(stag_node *node) {
  return node->data;
}

GSList* stag_findnode(stag_node *node, 
		      char *name, 
		      stag_node *replacement_node) {

  GSList* matchlist = g_slist_alloc();

  if (stag_testeq(node->name, name)) {
    g_slist_append(matchlist, node);
  }
  else if (node->is_terminal) {
    return;
  }
  else {
    for (i=0; i < g_slist_length_foreach(node->data); i++) {
      stag_node *subnode = g_slist_nth(node->data, i);
      GSList* sublist = stag_findnode(subnode, name, replacement_node);
      g_slist_concat(matchlist, sublist);
    }
  }
  return matchlist;
}
