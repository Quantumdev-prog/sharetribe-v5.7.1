Feature: User creates a new listing
  In order to perform a certain task using an item, a skill, or a transport, or to help others
  As a person who does not have the required item, skill, or transport, or has them and wants offer them to others
  I want to be able to offer and request an item, a favor, a transport or housing
  
  @javascript
  Scenario: Creating a new item request successfully
    Given I am logged in
    And I am on the home page
    When I follow "Post a new listing!"
    And I follow "I need something"
    And I follow "An item"
    And I should see "How do you want to get it?"
    And I follow "buy it"
    And I fill in "listing_title" with "Sledgehammer"
    And I fill in "listing_description" with "My description"
    #And I fill in "listing_tag_list" with "Tools, hammers"
    And I attach a valid image file to "listing_listing_images_attributes_0_image"
    And I press "Save request"
    Then I should see "Buying: Sledgehammer" within ".item-description"
    And I should see "Request created successfully" within ".flash-notifications"
    And I should see the image I just uploaded
  
  @javascript
  Scenario: Creating a new item offer successfully
    Given I am logged in
    And I am on the home page
    When I follow "Post a new listing!"
    And I follow "offer to others"
    And I follow "An item"
    And I should see "How do you want to share it?"
    And I follow "lend"
    And I fill in "listing_title" with "My offer"
    And I fill in "listing_description" with "My description"
    And I attach a valid image file to "listing_listing_images_attributes_0_image"
    And I press "Save offer"
    Then I should see "Lending: My offer" within ".item-description"
    And I should see "Offer created successfully" within ".flash-notifications"
    And I should see the image I just uploaded
  
  @javascript
  Scenario: Creating a new service request successfully
    Given I am logged in
    And I am on the home page
    When I follow "Post a new listing!"
    And I follow "I need something"
    And I follow "a service"
    And I fill in "listing_title" with "Massage"
    And I fill in "listing_description" with "My description"
    And I attach a valid image file to "listing_listing_images_attributes_0_image"
    And I press "Save request"
    Then I should see "Service request: Massage" within ".item-description"
    And I should see "Request created successfully" within ".flash-notifications"
    And I should see the image I just uploaded
  
  @javascript  
  Scenario: Creating a new rideshare request successfully
    Given I am logged in
    And I am on the home page
    When I follow "Post a new listing!"
    And I follow "I need something"
    And I follow "shared ride"
    And I fill in "listing_origin" with "Otaniemi"
    And I fill in "listing_destination" with "Turku"
    And wait for 2 seconds
    And I press "Save request"
    Then I should see "Rideshare request: Otaniemi - Turku" within ".item-description"
    And I should see "Request created successfully" within ".flash-notifications" 
  
  @javascript  
  Scenario: Trying to create a new request without being logged in
    Given I am not logged in
    And I am on the home page
    When I follow "Post a new listing!"
    Then I should see "You must log in to Sharetribe to create a new listing" within ".flash-notifications"
    And I should see "Log in to Sharetribe" within "h2"

  @javascript
  Scenario: Trying to create a new item request with insufficient information
    Given I am logged in
    And I am on the home page
    When I follow "Post a new listing!"
    And I follow "I need something"
    And I follow "An item"
    And I follow "borrow it"
    And I attach an image with invalid extension to "listing_listing_images_attributes_0_image"
    And I select "31" from "listing_valid_until_3i"
    And I select "December" from "listing_valid_until_2i"
    And I select "2014" from "listing_valid_until_1i"
    And I press "Save request"
    Then I should see "This field is required." 
    And I should see "This date must be between current time and one year from now." 
    And I should see "The image file must be either in GIF, JPG or PNG format." 
    
  @javascript  
  Scenario: Trying to create a new rideshare request with insufficient information
    Given I am logged in
    And I am on the home page
    When I follow "Post a new listing!"
    And I follow "I need something"
    And I follow "shared ride"
    And I fill in "Origin" with "Test"
    And I choose "valid_until_select_date"
    And I select "31" from "listing_valid_until_3i"
    And I select "December" from "listing_valid_until_2i"
    And I select "2014" from "listing_valid_until_1i"
    And I press "Save request"
    Then I should see "This field is required."
    And I should see "Departure time must be between current time and one year from now." 

  @javascript
  Scenario: User creates a listing and sees it in another community
    Given there are following users:
      | person | 
      | kassi_testperson3 |
    And there is item request with title "Hammer" from "kassi_testperson3" and with share type "buy"
    And visibility of that listing is "all_communities"
    And I am on the homepage
    Then I should see "Hammer"
    When I move to community "test2"
    And I am on the homepage
    Then I should not see "Hammer"
    And I log in as "kassi_testperson3"
    And I check "community_membership_consent"
    And I press "Join community"
    And the system processes jobs
    And I am on the homepage
    Then I should see "Hammer"

  @javascript
  Scenario: Create a new listing successfully after going back and forth in the listing form
    Given I am logged in
    And I am on the home page
    When I follow "Post a new listing!"
    And I follow "I need something"
    And I should see "What do you need?"
    And I should see "Listing type: Request"
    And I follow "An item"
    And I should see "Listing type: Request"
    And I should see "Category: Item"
    And I should see "What kind of item do you need?"
    And I follow "Tools"
    And I should see "Listing type: Request"
    And I should see "Category: Item"
    And I should see "Subcategory: Tools"
    And I should see "How do you want to get it?"
    And I follow "buy it"
    And I should see "Share type: Buying"
    And I should see "Item you need*"
    And I follow "Listing type: Request"
    And I should not see "Listing type: Request"
    And I should not see "Category: Item"
    And I should not see "Item you need*"
    And I should not see "Subcategory: Tools"
    And I should not see "Share type: Buying"
    And I follow "I have something to offer to others"
    And I follow "A shared ride"
    And I should see "Origin*"
    And I follow "Category: Rideshare"
    And I follow "A space"
    And I follow "Garden"
    And I follow "I'm sharing it for free"
    And I follow "Share type: Sharing for free"
    And I follow "I'm selling it"
    And I should see "Space you offer*"
    