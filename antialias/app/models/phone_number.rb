class PhoneNumber
  include Neo4j::ActiveNode
  include AntiAliasNodeMethods

  property :value
  property :created_at
  property :updated_at

  index :value
  index :created_at
  index :updated_at

  validates :value, presence: true
  validate :validate_has_unique_rels

  has_many :both, :visited_withs, model_class: false, rel_class: VisitedWith
end
