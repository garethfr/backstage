module Backstage
  class Field
    attr_reader :name, :type, :options

    def initialize(name, type, options = {})
      @name = name.to_sym
      @type = type.to_sym
      @options = options
    end

    def partial_path
      options[:partial] || "backstage/fields/#{type}"
    end

    def readonly?
      options.fetch(:readonly, false)
    end

    def enum?
      type == :enum
    end

    def enum_values
      options[:enum_values] || []
    end

    def belongs_to?
      type == :belongs_to
    end

    def has_many?
      type == :has_many
    end

    def nested?
      type == :nested
    end

    def image_url?
      type == :image_url
    end

    def nested_fields
      options[:nested_fields] || []
    end

    def nested_readonly_fields
      options[:nested_readonly_fields] || []
    end

    def row?
      type == :row
    end

    def section?
      type == :section
    end

    def container?
      row? || section?
    end

    def sub_fields
      options[:sub_fields] || []
    end

    def heading
      options[:heading]
    end

    def collapsed?
      options.fetch(:collapsed, false)
    end

    def association
      options[:association]
    end
  end
end
