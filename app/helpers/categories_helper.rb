module CategoriesHelper
  
  def self.load_default_categories_to_db
    
    default_categories = [
      {
      "item" => [
        "tools",
        "sports",
        "music",
        "books",
        "games",
        "furniture",
        "outdoors",
        "food",
        "electronics",
        "pets",
        "film",
        "clothes",
        "garden",
        "travel",
        "other"
        ]
      },
      "favor",
      "rideshare",
      "housing" 
    ]

    default_share_types = {
      "offer" => {:categories => ["item", "favor", "rideshare", "housing"]},
        "sell" => {:parent => "offer", :categories => ["item", "housing"]},
        "rent_out" => {:parent => "offer", :categories => ["item", "housing"]},
        "lend" => {:parent => "offer", :categories => ["item"]}, 
        "offer_to_swap" => {:parent => "offer", :categories => ["item"]}, 
        "give_away" => {:parent => "offer", :categories => ["item"]},
        "share_for_free" => {:parent => "offer", :categories => ["housing"]},

      "request" => {:categories => ["item", "favor", "rideshare", "housing"]}, 
        "buy" => {:parent => "request", :categories => ["item", "housing"]},
        "rent" => {:parent => "request", :categories => ["item", "housing"]},
        "borrow" => {:parent => "request", :categories => ["item"]},
        "request_to_swap" => {:parent => "request", :categories => ["item"]}, 
        "receive" => {:parent => "request", :categories => ["item"]}, 
        "accept_for_free" => {:parent => "request", :categories => ["housing"]}
    }


    default_categories.each do |category| 
      if category.class == String
        Category.create([{:name => category, :icon => category}]) unless Category.find_by_name(category)
      elsif category.class == Hash
        parent = Category.find_by_name(category.keys.first) || Category.create(:name => category.keys.first) 
        category.values.first.each do |subcategory|
          c = Category.find_by_name(subcategory) || Category.create({:name => subcategory, :icon => subcategory, :parent_id => parent.id}) 
          # As subcategories won't get their own link to share_types (as they inherit that from parent category)
          # We create a CommunityCategory entry here to mark that these subcategories exist in the default tribe
          CommunityCategory.create(:category => c) unless CommunityCategory.find_by_category_id(c.id)
        end
      else
        puts "Invalid data for default_categories. It must be array of Strings and Hashes."
        return
      end
    end

    default_share_types.each do |share_type, details|
      parent = ShareType.find_by_name(details[:parent]) if details[:parent]
      s =  ShareType.find_by_name(share_type) || ShareType.create(:name => share_type, :icon => share_type, :parent => parent)
      details[:categories].each do |category_name|
        c = Category.find_by_name(category_name)
        CommunityCategory.create(:category => c, :share_type => s) if c && ! CommunityCategory.find_by_category_id_and_share_type_id(c.id, s.id)
      end
    end
    
    # Store translations for all that can be found from translation files
    Kassi::Application.config.AVAILABLE_LOCALES.each do |loc|
      locale = loc[1]
      Category.find_each do |category|
        begin 
          translated_string = I18n.t!(category.name, :locale => locale, :scope => ["common", "categories"], :raise => true)
          CategoryTranslation.create(:category => category, :locale => locale, :name => translated_string) unless CategoryTranslation.find_by_category_id_and_locale(category.id, locale)
        rescue I18n::MissingTranslationData
          # just skip storing translation for this one
        end
      end
      
      ShareType.find_each do |share_type|
        begin
          translated_string = I18n.t!(share_type.name, :locale => locale, :scope => ["common", "share_types"], :raise => true)
          ShareTypeTranslation.create(:share_type => share_type, :locale => locale, :name => translated_string) unless ShareTypeTranslation.find_by_share_type_id_and_locale(share_type.id, locale)
        rescue I18n::MissingTranslationData
          # just skip storing translation for this one
        end
      end
      
    end
    
  end
  
end