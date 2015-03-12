# shared functionality for AntiAlias Nodes
module AntiAliasNodeMethods
  def name
    "#{self.class} node #{self.neo_id}"
  end

  def validate_has_unique_rels
    if !self.persisted? then return end

    node_pairs = self.rels.map { |r| r.nodes.map(&:neo_id).sort }
    rels_are_unique = node_pairs.uniq == node_pairs

    errors.add("#{self.name} has duplicate rels") if !rels_are_unique
  end

  module ClassMethods
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
