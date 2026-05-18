require "test_helper"

class FieldTest < ActiveSupport::TestCase
  test "name is a symbol" do
    field = Backstage::Field.new("title", :string)
    assert_equal :title, field.name
  end

  test "type is a symbol" do
    field = Backstage::Field.new(:title, "string")
    assert_equal :string, field.type
  end

  test "partial_path defaults to backstage/fields/TYPE" do
    field = Backstage::Field.new(:title, :string)
    assert_equal "backstage/fields/string", field.partial_path
  end

  test "partial_path uses custom partial from options" do
    field = Backstage::Field.new(:url, :string, partial: "my_app/fields/image")
    assert_equal "my_app/fields/image", field.partial_path
  end

  test "readonly? defaults to false" do
    field = Backstage::Field.new(:title, :string)
    assert_equal false, field.readonly?
  end

  test "readonly? returns true when set in options" do
    field = Backstage::Field.new(:created_at, :datetime, readonly: true)
    assert_equal true, field.readonly?
  end

  test "enum? returns true for :enum type" do
    field = Backstage::Field.new(:status, :enum)
    assert field.enum?
  end

  test "enum? returns false for non-enum type" do
    field = Backstage::Field.new(:title, :string)
    assert_not field.enum?
  end

  test "enum_values returns values from options" do
    values = [["Draft", "draft"], ["Published", "published"]]
    field = Backstage::Field.new(:status, :enum, enum_values: values)
    assert_equal values, field.enum_values
  end

  test "enum_values returns empty array when not set" do
    field = Backstage::Field.new(:title, :string)
    assert_equal [], field.enum_values
  end
end
