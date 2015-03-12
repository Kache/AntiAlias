module Dev

  module Neo4j
    mattr_accessor :safety
    @@safety = true

    def self.destroy_all_nodes_and_rels!
      carefully do
        Neo4j::Session.query(<<-cypher)
          MATCH (n)
          OPTIONAL MATCH (n)-[r]-()
          DELETE n,r;
        cypher
      end
    end

    def self.start
      puts `neo4j start`
    end

    def self.stop
      puts `neo4j stop`
    end

    def self.reset_database!
      carefully do
        puts `neo4j stop`
        puts `rm -rf /usr/local/Cellar/neo4j/2.1.7/libexec/data/graph.db`
        puts `neo4j start`
      end
    end

    def self.carefully(&block)
      if @@safety then raise "safety's on" end
      ret = nil
      ::Neo4j::Transaction.run do |tx|
        begin
          ret = yield
        rescue
          tx.fail
        end
      end
      @@safety = true
      return ret
    end
  end
end
