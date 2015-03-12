# shared functionality for AntiAlias Nodes
module AntiAliasNodeMethods
  def name
    "#{self.class.name} node #{self.neo_id}"
  end

  def validate_has_unique_rels
    node_pairs = self.rels.map { |r| r.nodes.map(&:neo_id).sort }
    rels_are_unique = node_pairs.uniq == node_pairs

    errors.add("#{self.name} has duplicate rels") if !rels_are_unique
  end
end
