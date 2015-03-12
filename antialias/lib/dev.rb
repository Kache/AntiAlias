module Dev
  def self.destroy_all_nodes_and_rels!
    Neo4j::Session.query(<<-cypher)
      MATCH (n)
      OPTIONAL MATCH (n)-[r]-()
      DELETE n,r;
    cypher
  end
end
