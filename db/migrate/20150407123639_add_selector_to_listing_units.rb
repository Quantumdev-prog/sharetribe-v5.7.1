class AddSelectorToListingUnits < ActiveRecord::Migration
  def change
    add_column :listing_units, :selector, :string, limit: 32, after: :unit_type, null: false
  end
end
