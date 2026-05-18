require "test_helper"

Capybara.app = Rails.application

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]

  setup { visit "/test_login" }
  teardown {}
end
