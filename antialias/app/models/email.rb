class Email
  include Neo4j::ActiveNode

  property :value
  property :created_at
  property :updated_at

  index :value
  index :created_at
  index :updated_at

  validates :value, presence: true
  has_n :shares_visit_with, :phone_numbers
  has_n :shares_visit_with, :device_ids
  has_n :shares_visit_with, :emails
end
