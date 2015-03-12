module AntiAlias
  # biggest collection of associated nodes
  def self.largest_group
  end

  # how cliquey is a group
  def self.group_connectedness
  end

  # single email using lots of cc's/lots of dl's
  def self.chokepoint(node_type, limit=1, rel_type=VisitedWith)
    query_rel_name = rel_type.name.underscore.upcase
    query = <<-neo4j
      MATCH (chokepoint:#{node_type})-[r:#{query_rel_name}]-()
      RETURN chokepoint, COUNT(r)
      ORDER BY COUNT(r) DESC
      LIMIT #{limit};
    neo4j
    Neo4j::Session.query(query).map(&:chokepoint)
  end

  # given set of emails, get all related cc's
  def self.associated(data_nodes, assoc_type)
    query = <<-neo4j
      MATCH (n)-[r]-(associated:#{assoc_type})
      WHERE ID(n) IN #{data_nodes.map(&:neo_id)}
      RETURN associated;
    neo4j
    Neo4j::Session.query(query).map(&:associated)
  end

  # returns all nodes connected to data_node
  def self.strongly_connected(data_node)
    query = <<-neo4j
      MATCH person = node-[*]-()
      WHERE ID(node) = #{data_node.neo_id}
      RETURN person
    neo4j
    Neo4j::Session.query(query).map(&:person)
  end
end
