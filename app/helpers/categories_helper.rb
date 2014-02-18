# encoding: UTF-8

module CategoriesHelper

  require File.expand_path('../../../test/helper_modules', __FILE__)
  include TestHelpers

  DEFAULT_TRANSACTION_TYPES_FOR_TESTS = {
    Sell: {
      en: {
        name: "Selling", action_button_label: "Buy this item"
      }
    },
    Lend: {
      en: {
        name: "Lending", action_button_label: "Borrow this item"
      }
    },
    Request: {
      en: {
        name: "Requesting", action_button_label: "Offer"
      }
    },
    Service: {
      en: {
        name: "Selling services", action_button_label: ""
      }
    }
  }

  DEFAULT_CATEGORIES_FOR_TESTS = [
    {
    "item" => [
      "tools",
      "books"
      ]
    },
    "favor",
    "housing" 
  ]

  def self.load_test_categories_and_transaction_types_to_db(community)
    CategoriesHelper.load_categories_and_transaction_types_to_db(community, DEFAULT_TRANSACTION_TYPES_FOR_TESTS, DEFAULT_CATEGORIES_FOR_TESTS)
  end

  def self.load_categories_and_transaction_types_to_db(community, transaction_types, categories)
    # Load transaction types
    transaction_types.each do |type, translations|

      transaction_type = Object.const_get(type.to_s).create!(:type => type, :community_id => community.id)
      community.locales.each do |locale|
        translation = translations[locale.to_sym]

        if translation then
          tt_name = translation[:name]
          tt_action = translation[:action_button_label]
          transaction_type.translations.create!(:locale => locale, :name => tt_name, :action_button_label => tt_action)
        end
      end
    end

    # Load categories
    categories.each do |c|

      # Categories that do not have subcategories
      if c.is_a?(String)
        category = Category.create!(:community_id => community.id)
        CategoriesHelper.add_transaction_types_and_translations_to_category(category, c)

      # Categories that have subcategories
      elsif c.is_a?(Hash)
        top_level_category = Category.create!(:community_id => community.id)
        CategoriesHelper.add_transaction_types_and_translations_to_category(top_level_category, c.keys.first)
        c.values.first.each do |sg|
          subcategory = Category.create!(:community_id => community.id, :parent_id => top_level_category.id)
          CategoriesHelper.add_transaction_types_and_translations_to_category(subcategory, sg)
        end
      end

    end
  end

  def self.add_transaction_types_and_translations_to_category(category, category_name)
    category.community.transaction_types.each { |tt| category.transaction_types << tt }
    category.community.locales.each do |locale|
      cat_name = I18n.t!(category_name, :locale => locale, :scope => ["common", "categories"], :raise => true)
      category.translations.create!(:locale => locale, :name => cat_name)
    end
  end

  def self.add_custom_price_quantity_placeholders
    throw "Uses share_type"
    sell = ShareType.find_by_name("sell")
    rent_out = ShareType.find_by_name("rent_out")
    item = Category.find_by_name("item")
    housing = Category.find_by_name("housing")
    buy =ShareType.find_by_name("buy")
    rent = ShareType.find_by_name("rent")
    
    sell_item = CommunityCategory.where("category_id = ? AND share_type_id = ? AND community_id IS NULL", item.id.to_s, sell.id.to_s).first
    sell_item.update_attributes(:price => true, :payment => true)
    
    rent_out_item = CommunityCategory.where("category_id = ? AND share_type_id = ? AND community_id IS NULL", item.id.to_s, rent_out.id.to_s).first
    rent_out_item.update_attributes(:price => true, :price_quantity_placeholder => "time", :payment => true)
    
    buy_item = CommunityCategory.where("category_id = ? AND share_type_id = ? AND community_id IS NULL", item.id.to_s, buy.id.to_s).first
    buy_item.update_attributes(:payment => true)
    
    rent_item = CommunityCategory.where("category_id = ? AND share_type_id = ? AND community_id IS NULL", item.id.to_s, rent.id.to_s).first
    rent_item.update_attributes(:payment => true)
    
    sell_housing = CommunityCategory.where("category_id = ? AND share_type_id = ? AND community_id IS NULL", housing.id.to_s, sell.id.to_s).first
    sell_housing.update_attributes(:price => true, :payment => true)
    
    rent_out_housing = CommunityCategory.where("category_id = ? AND share_type_id = ? AND community_id IS NULL", housing.id.to_s, rent_out.id.to_s).first
    rent_out_housing.update_attributes(:price => true, :price_quantity_placeholder => "long_time", :payment => true)
    
    buy_housing = CommunityCategory.where("category_id = ? AND share_type_id = ? AND community_id IS NULL", housing.id.to_s, buy.id.to_s).first
    buy_housing.update_attributes(:payment => true)
    
    rent_housing = CommunityCategory.where("category_id = ? AND share_type_id = ? AND community_id IS NULL", housing.id.to_s, rent.id.to_s).first
    rent_housing.update_attributes(:payment => true)
    
  end
  
  def self.update_default_rent_out_quantity_placeholder
    # This custom line sets the default housing rent_out offer to 
    # have price_quantity_placeholder "long_time" instead of the normal time :)
    CommunityCategory.find_by_category_id_and_share_type_id_and_community_id(Category.find_by_name("housing").id, ShareType.find_by_name("rent_out").id, nil).update_attribute(:price_quantity_placeholder, "long_time")
  end
  
  def self.remove_all_categories_from_db
    throw "Uses share type"
    Category.delete_all
    CategoryTranslation.delete_all
    ShareType.delete_all
    ShareTypeTranslation.delete_all
    CommunityCategory.delete_all
  end
  
end