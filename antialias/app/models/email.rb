class Email
  include Neo4j::ActiveNode

  property :value
  property :created_at
  property :updated_at

  index :value
  index :created_at
  index :updated_at

  validates :value, presence: true
  has_many :both, :visited_withs, model_class: false, rel_class: VisitedWith
end
