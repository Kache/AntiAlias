class DataPoint
  include Neo4j::ActiveRel

  from_class Person
  to_class :any
end
