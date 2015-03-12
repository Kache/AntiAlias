module AntiAlias
  # biggest collection of associated nodes
  def self.largest_group
  end

  # how cliquey is a group
  def self.group_connectedness
  end

  # single email using lots of cc's/lots of dl's
  def self.chokepoint
    <<-neo4j
      MATCH (n)-[r]-(x) RETURN n, COUNT(r) ORDER BY COUNT(r) DESC LIMIT 1;
    neo4j
  end

  # given set of emails, get all related cc's
  def self.associated(target_type)
  end
end
