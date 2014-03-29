Feature: Admin edits community look-and-feel
  In order to give my marketplace distinct look
  As an admin
  I want to be able to modify look-and-feel

  Background:
     Given there are following users:
      | person            | given_name | family_name | email               | membership_created_at     |
      | manager           | matti      | manager     | manager@example.com | 2014-03-01 00:12:35 +0200 |
      | kassi_testperson1 | john       | doe         | test2@example.com   | 2013-03-01 00:12:35 +0200 |
      | kassi_testperson2 | jane       | doe         | test1@example.com   | 2012-03-01 00:00:00 +0200 |
    And I am logged in as "manager"
    And "manager" has admin rights in community "test"
    And "kassi_testperson1" has admin rights in community "test"
    And I am on the edit look-and-feel page

  @javascript
  Scenario: Admin can change the default listing view to list
    Given community "test" has default browse view "grid"
    When I change the default browse view to "List"
    And I go to the homepage
    Then I should see the browse view selected as "List"

  @javascript
  Scenario: Admin can change the default listing view to map
    Given community "test" has default browse view "grid"
    When I change the default browse view to "Map"
    And I go to the homepage
    Then I should see the browse view selected as "Map"

  @javascript
  Scenario: Admin can change the default listing view to grid
    Given community "test" has default browse view "map"
    When I change the default browse view to "Grid"
    And I go to the homepage
    Then I should see the browse view selected as "Grid"
