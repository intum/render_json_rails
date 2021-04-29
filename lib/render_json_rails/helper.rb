module RenderJsonRails
  module Helper
    # https://jsonapi.org/format/#fetching-sparse-fieldsets
    # https://jsonapi.org/examples/
    # https://jsonapi-resources.com/v0.10/guide/serializer.html#include
    # http://xxx.yyyy.test/banking/object1/758449.json?formatted=1&fields[payment]=id,price&fields[invoice]=price_gross&fields[payment_connection]=amount&include=payment_connections,connectable
    # parametry:
    # formatted=1
    # fields[payment]=id,price
    # fields[invoice]=price_gross
    # fields[payment_connection]=amount&
    # include=payment_connections,connectable

    # http://xxx.yyyy.test/object.json?formatted=yes&fields[invoice]=number,sales_code&fields[invoice_position]=price_gross&include=positions
    # parametry:
    # formatted=yes&
    # fields[invoice]=number,sales_code
    # fields[invoice_position]=price_gross
    # include=positions
    def render_json(object, override_render_json_config: nil, additional_config: nil, status: nil, location: nil)

      if (class_object = RenderJsonRails::Helper.find_render_json_options_class!(object))
        includes = params[:include].to_s.split(',').map { |el| el.to_s.strip } if params[:include]
        options = class_object.render_json_options(
          includes: includes,
          fields: params[:fields],
          override_render_json_config: override_render_json_config,
          additional_config: additional_config,
          additional_fields: params[:additional_fields]
        )
      else
        options = {}
      end

      if params[:formatted] && !Rails.env.development? || params[:formatted] != 'no' && Rails.env.development?
        json = JSON.pretty_generate(object.as_json(options))
        render json: json, status: status, location: location
      else
        options[:json] = object
        options[:status] = status
        options[:location] = location
        render options
      end
    end

    def self.find_render_json_options_class!(object)
      return nil if object == nil

      if object.class.respond_to?(:render_json_options)
        object.class
      # elsif object.is_a?(ActiveRecord::Base)
      #   raise "klasa: #{object.class} nie ma konfiguracji 'render_json_config'"
      elsif object.respond_to?(:first)
        RenderJsonRails::Helper.find_render_json_options_class!(object[0])
      else
        nil
      end

    end

  end
end
