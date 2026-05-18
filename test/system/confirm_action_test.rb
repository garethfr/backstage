require_relative "application_system_test_case"

class ConfirmActionTest < ApplicationSystemTestCase
  setup do
    Article.delete_all
    @article = Article.create!(title: "To Delete")
  end

  test "delete button shows confirm dialog and cancelling keeps the record" do
    visit "/admin/articles/#{@article.id}/edit"

    dismiss_confirm { click_button "Delete" }

    assert_equal 1, Article.count
  end

  test "delete button shows confirm dialog and accepting deletes the record" do
    visit "/admin/articles/#{@article.id}/edit"

    accept_confirm { click_button "Delete" }

    assert_current_path "/admin/articles"
    assert_equal 0, Article.count
  end
end
