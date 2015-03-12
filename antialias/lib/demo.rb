module Demo

  NOTABLE = {
    Person.find_by_neo_id(2778) => "largest",
    Person.find_by_neo_id(5137) => "one phone number",
    Person.find_by_neo_id(2778) => "largest",
  }


  def self.show_person_query(node)
    query = <<-neo4j
      match (n:Person)-[]-(m)
      where id(n) = #{node.neo_id}
      return n, m
      limit 50
    neo4j
    puts query
  end

  def self.show_group(node)
    query = <<-neo4j
      match (n:#{node.class})-[*1..20]-(m)
      where id(n) = #{node.neo_id}
      return n, m
      limit 50
    neo4j
    puts query
  end

  # Demo.show_group(AntiAlias.chokepoint(PhoneNumber, 10).first)

  # Demo.show_person_query(AntiAlias.largest_person_group(10).map(&:first)[0])
  # Demo.show_person_query(AntiAlias.largest_person_group(10).map(&:first)[3]) => "cliquey",

  # Demo.show_person_query(AntiAlias.associated([PhoneNumber.find_by(value: "5622213232")], Person).first)
end
