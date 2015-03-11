class Email < ActiveRecord::Base
  include Neo4j::ActiveNode

  property :value
  property :created_at
  property :updated_at

  index :value
  index :created_at
  index :updated_at
end
