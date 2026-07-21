module Backstage
  class AssociationConfig
    attr_reader :name, :kind, :options

    def initialize(name, kind, options = {})
      @name = name.to_sym
      @kind = kind.to_sym
      @options = options
    end

    def display_column
      options[:display_column] || :id
    end

    def foreign_key
      options[:foreign_key] || :"#{name}_id"
    end

    def class_name
      options[:class_name] || name.to_s.classify
    end

    def associated_class
      class_name.constantize
    end

    def order
      options[:order] || display_column
    end

    def image_col
      options[:image_col] || :url
    end
  end
end
