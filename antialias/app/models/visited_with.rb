class VisitedWith
  include Neo4j::ActiveRel

  from_class :any
  to_class :any

  validate :unique_rel

  def unique_rel
    rel_exists = to_node.visited_withs.include?(from_node)
    errors.add("#{from_node.inspect} already linked to #{to_node.inspect}") if rel_exists
  end

  def nodes
    [from_node, to_node]
  end

  def matches?(other)
    other.class == self.class
    other.nodes.map(&:neo_id).sort == self.nodes.map(&:neo_id).sort
  end

  def self.completely_connect(nodes)
    existing_rels = nodes.map(&:rels).flatten.uniq

    proposed_rels = nodes.combination(2).map do |l, r|
      self.new(from_node: l, to_node: r)
    end

    to_relate = proposed_rels.reject do |rel|
      existing_rels.any? { |r| r.matches?(rel) }
    end

    to_relate.each(&:save!)
  end
end
