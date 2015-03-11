class CreateVisitedWiths < ActiveRecord::Migration
  def change
    create_table :visited_withs do |t|

      t.timestamps null: false
    end
  end
end
