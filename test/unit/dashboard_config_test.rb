require "test_helper"

class DashboardConfigTest < ActiveSupport::TestCase
  test "raises ArgumentError when name is missing" do
    assert_raises(ArgumentError) do
      Backstage::DashboardConfig.new("model" => "Article")
    end
  end

  test "raises ArgumentError when model is missing" do
    assert_raises(ArgumentError) do
      Backstage::DashboardConfig.new("name" => "drafts")
    end
  end

  test "initialises successfully with name and model" do
    config = Backstage::DashboardConfig.new("name" => "drafts", "model" => "Article")
    assert_equal "drafts", config.name
    assert_equal "Article", config.model_name
  end
end
