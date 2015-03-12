# a "Person" is a strongly connected group of data nodes
class Person
  include Neo4j::ActiveNode

  property :created_at

  index :created_at

  has_many :out, :data_nodes, model_class: false, rel_class: DataPoint
  has_many :in, :merged, model_class: 'Person'

  # merges multiple people into the one oldest person
  def self.merge(people)
    sorted_ppl = people.sort_by(&:created_at)

    oldest, *younger_people = sorted_ppl
    data_nodes_to_merge = younger_people.flat_map { |person| person.data_nodes.map { |x| x } }

    if oldest.present? && younger_people.present?
      query = <<-neo4j
        match (oldest_person:Person)
        where id(oldest_person) = #{oldest.neo_id}
        match (young_person:Person)-[rels_to_delete:DATA_POINT]->(nodes)
        where id(nodes) in #{data_nodes_to_merge.map(&:neo_id)} and id(young_person) <> id(oldest_person)
        create (oldest_person)-[:DATA_POINT]->(nodes)
        create (young_person)-[:MERGED]->(oldest_person)
        delete rels_to_delete
      neo4j
      Neo4j::Session.query(query)
    end
  end
end
