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

    def association
      options[:association]
    end
  end
end
