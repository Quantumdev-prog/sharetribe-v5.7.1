class AddDefaultCategories < ActiveRecord::Migration
  def up
    CategoriesHelper.load_default_categories_to_db
  end

  def down
    puts "THIS MIGRATION ADDS DEFAULT CATEGORIES IF NOT ALREADY IN DB. SO ROLLBACK WON'T DELETE THOSE."
  end
end
