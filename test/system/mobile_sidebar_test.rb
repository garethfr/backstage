require_relative "application_system_test_case"

class MobileSidebarTest < ApplicationSystemTestCase
  setup do
    Article.delete_all
    @article = Article.create!(title: "Sidebar test")
  end

  test "sidebar stacks below content on narrow viewports" do
    Capybara.current_window.resize_to(375, 812)
    visit "/admin/articles/#{@article.id}/edit"

    columns = page.evaluate_script(
      "getComputedStyle(document.querySelector('.edit-layout')).gridTemplateColumns"
    ).split(" ")

    assert_equal 1, columns.length
  end

  test "sidebar stays beside content on wide viewports" do
    Capybara.current_window.resize_to(1400, 900)
    visit "/admin/articles/#{@article.id}/edit"

    columns = page.evaluate_script(
      "getComputedStyle(document.querySelector('.edit-layout')).gridTemplateColumns"
    ).split(" ")

    assert_equal 2, columns.length
  end
end
