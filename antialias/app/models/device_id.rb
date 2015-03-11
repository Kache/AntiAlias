class DeviceId
  include Neo4j::ActiveNode

  property :value
  property :created_at
  property :updated_at

  index :value
  index :created_at
  index :updated_at

  validates :value, presence: true
  has_many :shares_visit_with, :phone_numbers
  has_many :shares_visit_with, :device_ids
  has_many :shares_visit_with, :emails
end
