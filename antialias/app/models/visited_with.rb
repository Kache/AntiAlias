class VisitedWith < ActiveRecord::Base
  include Neo4j::ActiveRel

  from_class :any
  to_class :any
end
