module Backstage
  class ActionsController < ApplicationController
    def create
      begin
        Backstage.registry.resource_for(params[:resource].classify)
      rescue KeyError
        return render plain: "Not Found", status: :not_found
      end

      resource_name = params[:resource].classify.pluralize
      controller_class = "Backstage::#{resource_name}Controller".safe_constantize
      action_name = params[:action_name]

      if controller_class.nil? || controller_class == Backstage::ResourcesController
        raise NotImplementedError,
          "Backstage: no custom controller found for #{resource_name}. " \
          "Define Backstage::#{resource_name}Controller."
      end

      unless controller_class.method_defined?(action_name.to_sym, false)
        raise NotImplementedError,
          "Backstage: no action '#{action_name}' on #{controller_class}. " \
          "Define it in Backstage::#{resource_name}Controller."
      end

      status, headers, body = controller_class.action(action_name).call(request.env)
      self.status = status
      self.headers.merge!(headers)
      self.response_body = body
    end
  end
end
