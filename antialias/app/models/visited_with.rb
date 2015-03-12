class VisitedWith
  include Neo4j::ActiveRel

  from_class :any
  to_class :any

  validate :unique_rel

  def unique_rel
    to_from_rel = to_node.visited_withs.include?(from_node)
    from_to_rel = from_node.visited_withs.include?(to_node)
    rel_already_exists = to_from_rel || from_to_rel

    errors.add("#{from_node.name} already linked to #{to_node.name}") if rel_already_exists
  end

  def nodes
    [from_node, to_node]
  end

  def matches?(other)
    other.class == self.class
    other.nodes.map(&:neo_id).sort == self.nodes.map(&:neo_id).sort
  end

  # ensures all nodes are completely related via VisitedWith once and only once
  def self.completely_connect(nodes)
    existing_rels = nodes.map(&:rels).flatten.uniq

    proposed_rels = nodes.combination(2).map do |l, r|
      self.new(from_node: l, to_node: r)
    end

    to_relate = proposed_rels.reject do |rel|
      existing_rels.any? { |r| r.matches?(rel) }
    end

    to_relate.each(&:save!)

    query = <<-neo4j
      MATCH (n)
      WHERE NOT (:Person)-[:DATA_POINT]->(n) AND NOT n:Person AND ID(n) IN #{nodes.map(&:neo_id)}
      RETURN n
    neo4j
    ungrouped_nodes = Neo4j::Session.query(query).map(&:n)

    if ungrouped_nodes.present?
      p = Person.create
      ungrouped_nodes.each do |n|
        DataPoint.create(from_node: p, to_node: n)
      end
    end

    people = AntiAlias.associated(nodes, Person)
    Person.merge(people)
  end
end
