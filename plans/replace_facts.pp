plan puppetdb::replace_facts (
  TargetSpec $nodes,
) {
  # This collects facts on nodes and update the inventory
  $nodes.apply_prep

  get_targets($nodes).each |$node| {
    replace_facts($node)
  }
}
