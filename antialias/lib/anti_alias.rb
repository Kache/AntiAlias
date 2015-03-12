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
    Neo4j::Session.query(<<-neo4j).map(&:n)
      MATCH (n:#{node_type})-[r:#{query_rel_name}]-(x)
      RETURN n, COUNT(r)
      ORDER BY COUNT(r) DESC
      LIMIT #{limit};
    neo4j
  end

  # given set of emails, get all related cc's
  def self.associated(target_type)
  end
end
