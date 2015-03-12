class CreateDriversLicenses < ActiveRecord::Migration
  def change
    create_table :drivers_licenses do |t|
      t.string :credit_card

      t.timestamps null: false
    end
  end
end
