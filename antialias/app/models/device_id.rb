class DeviceId
  include Neo4j::ActiveNode

  property :value
  property :created_at
  property :updated_at

  index :value
  index :created_at
  index :updated_at

  validates :value, presence: true
  has_many :both, :phone_numbers
  has_many :both, :device_ids
  has_many :both, :emails
end
