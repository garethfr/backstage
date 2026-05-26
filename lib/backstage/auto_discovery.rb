module Backstage
  class AutoDiscovery
    SYSTEM_COLUMNS = %i[id created_at updated_at].freeze

    COLUMN_TYPE_MAP = {
      string: :string,
      text: :text,
      integer: :integer,
      decimal: :decimal,
      float: :decimal,
      boolean: :boolean,
      date: :date,
      datetime: :datetime
    }.freeze

    def self.build(model_class)
      new(model_class).build
    end

    def initialize(model_class)
      @model_class = model_class
    end

    def build
      config = ResourceConfig.new(@model_class)
      config.display_column = detect_display_column
      fields = column_fields + enum_fields
      config.index_fields = fields
      config.edit_fields = fields.dup
      config
    end

    private

    def column_fields
      @model_class.columns
        .reject { |col| SYSTEM_COLUMNS.include?(col.name.to_sym) }
        .reject { |col| enum_column_names.include?(col.name.to_sym) }
        .map { |col| Field.new(col.name, COLUMN_TYPE_MAP.fetch(col.type, :string)) }
    end

    def enum_fields
      @model_class.defined_enums.map do |name, values|
        enum_values = values.keys.map { |k| [k.humanize, k] }
        Field.new(name, :enum, enum_values: enum_values)
      end
    end

    def enum_column_names
      @enum_column_names ||= @model_class.defined_enums.keys.map(&:to_sym)
    end

    def detect_display_column
      column_names = @model_class.column_names.map(&:to_sym)
      %i[name title email id].find { |col| column_names.include?(col) }
    end
  end
end
