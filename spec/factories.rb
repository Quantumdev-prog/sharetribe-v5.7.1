FactoryGirl.define do
  sequence :username do |n|
    "kassi_tester#{n}"
  end

  sequence :email_address do |n|
    "kassi_tester#{n}@example.com"
  end

  sequence :domain do |n|
    "sharetribe_testcommunity_#{n}" 
  end

  sequence :category_name do |n|
    "item_#{n}" 
  end


  factory :person, aliases: [:author, :receiver, :recipient, :payer, :sender] do
    is_admin 0
    locale "en"
    test_group_number 4
    given_name "Proto"
    family_name "Testro"
    phone_number "0000-123456"
    username
    password "testi"
    is_organization false

    after(:create) do |person|
      FactoryGirl.create_list(:email, 1, person: person)
    end
  end  

  factory :listing do
    title "Sledgehammer"
    description("test")
    author
    category {find_or_create_category("item")}
    transaction_type { FactoryGirl.create(:transaction_type_sell) }
    tag_list("tools, hammers")
    valid_until 3.months.from_now
    times_viewed 0
    visibility "this_community"
    privacy "public"
    communities { [ FactoryGirl.create(:community) ] }
  end

  factory :conversation do
    title "Item offer: Sledgehammer"
    listing
    status "pending"
  end

  factory :message do
    content "Test"
    association :conversation
    sender
  end

  factory :participation do
    association :conversation
    association :person
    is_read false
    last_sent_at DateTime.now
  end

  factory :testimonial do
    author
    association :participation
    grade 0.5
    text "Test text"
  end

  factory :comment do
    author { |author| author.association(:person) }
    association :listing
    content "Test text"
  end

  factory :feedback do
    author
    content "Test feedback"
    url "/requests"
    email "kassi_testperson1@example.com"
    is_handled 0
  end

  factory :badge do
    person
    name "rookie"
  end

  factory :notification do
    receiver
    is_read 0
    notifiable_type "Listing"
    notifiable_id "1"
    description "to_own_listing"
  end

  factory :community do
    name { generate(:domain) }
    domain
    slogan "Test slogan"
    description "Test description"
    category "other"

    factory :community_with_multiple_members do
      after_create do |community, evaluator|
        create_list(:person, 5, communities: [community])
      end
    end
  end

  factory :community_membership do
    association :community
    association :person
    admin false
    consent "test_consent0.1"
    status "accepted"
  end

  factory :contact_request do
    email "test@example.com"
  end

  factory :invitation do
    community_id 1
  end

  factory :news_item do
    title "A new event in our community"
    content "More information about this amazing event."
    author { |author| author.association(:person) }
  end  

  factory :device do
    device_type "iPhone"
    device_token "LSIDFSLDJIOGSSCSBEUS52349583"
    person { |person| person.association(:person, :id => get_test_person_and_session("kassi_testperson1")[0].id) }
  end

  factory :location do
    association :listing
    association :person
    association :community
    latitude 62.2426
    longitude 25.7475
    address "helsinki"
    google_address "Helsinki, Finland"
  end
  
  factory :email do
    person
    address { generate(:email_address) }
    confirmed_at Time.now
    send_notifications true
  end
  
  factory :category do
    icon "item"
    association :community
    before(:create) do |category|
      category.translations << FactoryGirl.create(:category_translation)
      category.transaction_types << FactoryGirl.create(:transaction_type_sell)
    end
  end

  factory :category_translation do
    name "test category"
    locale "en"
  end

  factory :transaction_type_translation do
    name "Selling"
    locale "en"
  end

  factory :transaction_type do
    association :community
    
    ['Sell', 'Give', 'Lend', 'Request', 'Service'].each do |type|
      factory_name = "transaction_type_#{type.downcase}"
      factory factory_name.to_sym, class: type do
        type type
        after(:create) do |transaction_type|
          transaction_type.translations << FactoryGirl.create(:transaction_type_translation, :name => type, :transaction_type_id => transaction_type.id)
        end
      end
    end
  end

  factory :custom_field, aliases: [:question] do
    community

    before(:create) do |custom_field|
      category = FactoryGirl.create(:category)
      custom_field.category_custom_fields << FactoryGirl.create(:category_custom_field, :category => category, :custom_field => custom_field)
      custom_field.names << FactoryGirl.create(:custom_field_name)
    end

    factory :custom_dropdown_field, class: 'Dropdown' do
      before(:create) do |custom_field|
        custom_field.options << FactoryGirl.create(:custom_field_option)
        custom_field.options << FactoryGirl.create(:custom_field_option)
      end
    end

    factory :custom_text_field, class: 'TextField' do
    end
    
  end

  factory :category_custom_field do
    category
    custom_field :custom_dropdown_field
  end

  factory :custom_field_option do
    titles { [ FactoryGirl.create(:custom_field_option_title) ] }
  end
  
  factory :custom_field_option_title do
    value "Test option"
    locale "en"
  end
  
  factory :custom_field_name do
    value "Test field"
    locale "en"
  end

  factory :custom_field_value do
    question
    listing
  end
  
  factory :payment do
    payer
    recipient
    status "pending"
    type "Checkout"
  end

  factory :braintree_account do
    person
    first_name "Joe"
    last_name "Bloggs"
    email "joe@14ladders.com"
    phone "5551112222"
    address_street_address "123 Credibility St."
    address_postal_code "60606"
    address_locality "Chicago"
    address_region "IL"
    date_of_birth "1980-10-09"
    routing_number "1234567890"
    hidden_account_number "*********98"
    status "active"
    community
  end

  factory :payment_gateway do
    type "Checkout"
    braintree_merchant_id { APP_CONFIG.braintree_test_merchant_id }
    braintree_master_merchant_id { APP_CONFIG.braintree_test_master_merchant_id }
    braintree_public_key { APP_CONFIG.braintree_test_public_key }
    braintree_private_key { APP_CONFIG.braintree_test_private_key }
    braintree_client_side_encryption_key { APP_CONFIG.braintree_client_side_encryption_key }
    braintree_environment { APP_CONFIG.braintree_environment }
  end
end
