require_relative "application_system_test_case"

class MobileNavTest < ApplicationSystemTestCase
  test "nav is hidden by default on mobile and opens via the menu toggle" do
    Capybara.current_window.resize_to(375, 812)
    visit "/admin/articles"

    assert_no_selector "nav.backstage-nav", visible: true

    find("[data-nav-toggle]").click

    assert_selector "nav.backstage-nav", visible: true

    find("[data-nav-toggle]").click

    assert_no_selector "nav.backstage-nav", visible: true
  end

  test "nav is visible without a toggle on desktop widths" do
    Capybara.current_window.resize_to(1400, 900)
    visit "/admin/articles"

    assert_selector "nav.backstage-nav", visible: true
    assert_no_selector "[data-nav-toggle]", visible: true
  end
end
