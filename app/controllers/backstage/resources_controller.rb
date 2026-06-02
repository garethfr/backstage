module Backstage
  class ResourcesController < ApplicationController
    before_action :find_resource_config
    before_action :find_record, only: %i[edit update destroy]

    def index
      @page = (params[:page] || 1).to_i
      per_page = Backstage.configuration.per_page
      scope = @resource_config.model_class.all

      if params[:q].present?
        col = @resource_config.display_column
        scope = scope.where("#{col} LIKE ?", "%#{params[:q]}%")
      end

      @resource_config.index_fields.select(&:enum?).each do |field|
        next unless params[field.name].present?
        scope = scope.where(field.name => params[field.name])
      end

      valid_columns = @resource_config.index_fields.map { |f| f.name.to_s }
      if params[:sort].present? && valid_columns.include?(params[:sort])
        @sort = params[:sort]
        @dir = (params[:dir] == "desc") ? "desc" : "asc"
        arel_col = @resource_config.model_class.arel_table[@sort]
        scope = scope.order((@dir == "desc") ? arel_col.desc : arel_col.asc)
      end

      @total_pages = [(scope.count.to_f / per_page).ceil, 1].max
      @records = scope.offset((@page - 1) * per_page).limit(per_page)
    end

    def new
      @record = @resource_config.model_class.new
    end

    def edit
    end

    def create
      @record = @resource_config.model_class.new(record_params)
      if @record.save
        redirect_to edit_resource_path(resource: params[:resource], id: @record.id)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @record.update(record_params)
        redirect_to resources_path(resource: params[:resource])
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @record.destroy
      redirect_to resources_path(resource: params[:resource])
    end

    private

    def find_resource_config
      @resource_config = Backstage.registry.resource_for(params[:resource].classify)
    rescue KeyError
      render plain: "Not Found", status: :not_found
    end

    def find_record
      @record = @resource_config.model_class.find_by(id: params[:id])
      render plain: "Not Found", status: :not_found unless @record
    end

    def respond_with_row_removed
      row_id = "#{@resource_config.model_name_param}_#{@record.id}_row"
      render html: %(<turbo-stream action="remove" target="#{row_id}"></turbo-stream>).html_safe,
        content_type: "text/vnd.turbo-stream.html"
    end

    def respond_with_success(message)
      safe_message = ERB::Util.html_escape(message)
      render html: %(<turbo-stream action="prepend" target="flash">
        <template><p class="notice">#{safe_message}</p></template>
      </turbo-stream>).html_safe,
        content_type: "text/vnd.turbo-stream.html"
    end

    def record_params
      params
        .require(@resource_config.model_class.model_name.param_key)
        .permit(permitted_field_names(@resource_config.edit_fields))
    end

    def permitted_field_names(fields)
      fields.reject(&:readonly?).flat_map do |field|
        if field.container?
          permitted_field_names(field.sub_fields)
        elsif field.has_many?
          [{field.name => []}]
        elsif field.nested?
          [{"#{field.name}_attributes": [:id, :_destroy, *field.nested_fields]}]
        else
          [field.name]
        end
      end
    end
  end
end
