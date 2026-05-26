module Backstage
  class ResourceConfig
    attr_accessor :model_class, :index_fields, :edit_fields, :associations
    attr_writer :display_column

    def initialize(model_class)
      @model_class = model_class
      @index_fields = []
      @edit_fields = []
      @associations = []
    end

    def display_column(value = nil)
      value ? @display_column = value.to_sym : @display_column
    end

    def model_name_param
      model_class.model_name.plural
    end

    def sidebar(&block)
      @sidebar_config ||= SidebarConfig.new
      block&.call(@sidebar_config)
      @sidebar_config
    end

    attr_reader :sidebar_config

    def fields(*names)
      @index_fields_explicit = true
      @index_fields = names.map { |n| find_or_build_field(n) }
    end

    def exclude(*names)
      names.map!(&:to_sym)
      @index_fields = @index_fields.reject { |f| names.include?(f.name) }
      @edit_fields = @edit_fields.reject { |f| names.include?(f.name) }
    end

    def has_many(name, **opts)
      display_as = opts.delete(:as) || :has_many
      assoc = AssociationConfig.new(name, :has_many, opts)
      @associations << assoc
      if display_as == :thumbnails
        field_obj = Field.new(name.to_sym, :thumbnails, association: assoc, readonly: true)
        @edit_fields.reject! { |f| f.name == field_obj.name }
        @edit_fields << field_obj
      else
        ids_field = Field.new(:"#{name.to_s.singularize}_ids", :has_many, association: assoc)
        @edit_fields.reject! { |f| f.name == ids_field.name }
        @edit_fields << ids_field
      end
    end

    def nested(name, fields:, readonly_fields: [])
      field_obj = Field.new(name.to_sym, :nested,
        nested_fields: Array(fields).map(&:to_sym),
        nested_readonly_fields: Array(readonly_fields).map(&:to_sym))
      @edit_fields.reject! { |f| f.name == field_obj.name }
      (@current_target || @edit_fields) << field_obj
    end

    def belongs_to(name, **opts)
      assoc = AssociationConfig.new(name, :belongs_to, opts)
      @associations << assoc
      fk_field = Field.new(assoc.foreign_key, :belongs_to, association: assoc)
      index_field = Field.new(name.to_sym, :belongs_to, association: assoc)
      @edit_fields.reject! { |f| f.name == fk_field.name }
      @index_fields.reject! { |f| f.name == fk_field.name || f.name == index_field.name }
      @edit_fields << fk_field
      @index_fields << index_field unless @index_fields_explicit
    end

    def field(name, **opts)
      type = opts.delete(:as) || opts.delete(:type)
      sym = name.to_sym
      existing = find_field(sym)
      if existing
        existing.options.merge!(opts)
        existing.instance_variable_set(:@type, type.to_sym) if type
        if @current_target
          @edit_fields.reject! { |f| f.name == sym }
          @current_target << existing
        end
      else
        new_field = Field.new(sym, type || :string, opts)
        (@current_target || @edit_fields) << new_field
        @index_fields << new_field unless @index_fields_explicit || @current_target
      end
    end

    def row(*names)
      syms = names.map(&:to_sym)
      sub = syms.map { |n| find_field(n) || Field.new(n, :string) }
      @edit_fields.reject! { |f| syms.include?(f.name) }
      row_field = Field.new(:"row_#{names.first}", :row, sub_fields: sub)
      (@current_target || @edit_fields) << row_field
    end

    def section(heading, **opts)
      section_field = Field.new(:"section_#{heading.parameterize}", :section,
        heading: heading, sub_fields: [], **opts)
      @current_target = section_field.sub_fields
      yield if block_given?
      @edit_fields << section_field
    ensure
      @current_target = nil
    end

    private

    def find_field(name)
      all_fields = @index_fields + @edit_fields
      all_fields.uniq.each do |f|
        return f if f.name == name
        if f.container?
          found = f.sub_fields.find { |sf| sf.name == name }
          return found if found
        end
      end
      nil
    end

    def find_or_build_field(name)
      find_field(name.to_sym) || Field.new(name.to_sym, :string)
    end
  end
end
