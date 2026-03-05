Feature: App Shell Routine
  As a user
  I want a stable app shell and navigation structure
  So I can seamlessly switch between maps, archives, and settings without losing my context

  Background:
    Given the application is installed and has not completed first-launch onboarding

  Scenario: First launch onboarding flow routing
    When the user launches the application for the first time
    Then the language selection screen is presented
    When the user selects a language and continues
    Then the push permission prompt screen is presented
    When the user resolves permissions and continues
    Then the application completes onboarding
    And the Map screen is displayed as the core default view
    And the bottom TabBar becomes visible

  Scenario: Tab navigation preserves nested state
    Given the user is on the Map tab
    When the user switches to the Settings tab
    And navigates to the nested "About" subpage
    When the user switches back to the Map tab
    Then the Map screen is displayed exactly as previously left
    When the user switches back to the Settings tab
    Then the "About" subpage is still actively visible

  Scenario: Point preview expands via content-aware preview sheet
    Given the user is on the Map default view
    When the user taps a specific map pin
    Then a preview sheet is presented at a content-aware compact height
    And the primary CTA button is fully hittable with a minimum touch target of 44×44
    And no action element overlaps with or is visually pressed against the Tab Bar
    And the map dynamically recenters to the selected pin

  Scenario: Map search basic behavior flow
    Given the user is on the Map default view
    When the user activates the search bar
    Then search recommendations and recents are displayed
    When the user selects a search recommendation
    Then the map centers on the selected location coordinate
    And a location preview card is successfully displayed

  Scenario: Instant language switch mechanism
    Given the user is currently in the Settings tab
    When the user changes the language preference to "简体中文"
    Then the application interface immediately updates to the new locale
    And no manual app restart is required
