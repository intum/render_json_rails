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
      raise "objekt nie moze byc null" if object == nil

      if object.class.to_s.include?('ActiveRecord_Relation')
        return render json: [] if !object[0]

        class_object = object[0].class
      else
        class_object = object.class
      end
      includes = params[:include].to_s.split(',').map { |el| el.to_s.strip } if params[:include]
      options = class_object.render_json_options(
        includes: includes,
        fields: params[:fields],
        override_render_json_config: override_render_json_config,
        additional_config: additional_config,
        additional_fields: params[:additional_fields]
      )
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
  end
end
