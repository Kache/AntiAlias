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

  def strongly_connected
    <<-neo4j
      MATCH person = self-[*]-n
      WHERE ID(self) = #{self.neo_id}
      RETURN person
    neo4j
  end

  module ClassMethods
    def biggest_chokepoints(limit=1)
      Neo4j::Session.query("MATCH (n:#{self})-[r]-(x) RETURN n, COUNT(r) ORDER BY COUNT(r) DESC LIMIT #{limit};").map(&:n)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
