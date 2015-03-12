class CreateUserIds < ActiveRecord::Migration
  def change
    create_table :user_ids do |t|

      t.timestamps null: false
    end
  end
end
