require "render_json_rails/version"

module RenderJsonRails
  class Error < StandardError; end
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
    def render_json(object, additional_config: nil, status: nil, location: nil)
      raise "objekt nie moze byc null" if object == nil

      if object.class.to_s.include?('ActiveRecord_Relation')
        return render json: [] if !object[0]

        class_object = object[0].class
      else
        class_object = object.class
      end
      includes = params[:include].to_s.split(',').map{ |el| el.to_s.strip } if params[:include]
      options = class_object.render_json_options(
        includes: includes,
        fields: params[:fields],
        additional_config: additional_config
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

  ######

  module ModelConcern
    extend ActiveSupport::Concern

    # http://marcin.xxx.test/api/organize/questions/2.json?formatted=yes&include=last_answers,last_answers.user&fields[question]=id&fields[user]=email,login,get_name
    # http://marcin.xxx.test/api/organize/questions/2.json?formatted=yes&include=last_answers,team,team.questions

    # http://marcin.yyy.test/xx/55200174.json?formatted=yes&mass_fiscal_print=yes
    # http://marcin.yyy.test/xx/55200174.json?formatted=yes&fields[invoice_position]=id,fiscal_short_name
    # http://marcin.yyy.test/banking/uu.json?formatted=yes&fields[payment]=id
    # http://marcin.yyy.test/banking/uu.json?formatted=yes&fields[payment]=id&include=invoices,payment_connections

    class_methods do
      # Metoda przygotowuje parametry `options` do generowania json-a
      # `methods` to dodatkowe metody które domyślnie będą wyświetlane w jsonie
      # `allowed_methods` definiuje metody, które możemy wymienić w `fields` i wtedy
      #  zostaną one wyświelone w json-ie
      # TODO:
      # [ ] spradzanie czy parametry "fields" i "include" sa ok i jesli nie to error
      def default_json_options(name:, fields: nil, except: nil, methods: nil, allowed_methods: nil)
        # name ||= self.name.underscore.gsub('/', '_')
        # raise self.name.underscore.gsub('/', '_')
        except ||= [:account_id, :agent, :ip]

        options = {}
        if fields && fields[name].present?
          options[:only] = fields[name].split(',').find_all{ |el| !except.include?(el.to_sym) }
          options[:methods] = methods&.find_all{ |el| options[:only].include?(el.to_s) }
          if allowed_methods
            options[:methods] = (options[:methods] || []) | allowed_methods.find_all{ |el| options[:only].include?(el.to_s) }
          end
        else
          options[:except] = except
          options[:methods] = methods
        end
        options
      end

      def render_json_config(config)
        @render_json_config = config
        # @render_json_config[:methods] = [:image]
      end

      # rubocop:disable Lint/UnusedMethodArgument
      def render_json_options(includes: nil, fields: nil, additional_config: nil)
        raise "należy skonfigurowac render_json metodą: render_json_config" if !defined?(@render_json_config)

        options = default_json_options(
          name: @render_json_config[:name].to_s,
          fields: fields,
          except: @render_json_config[:except],
          methods: @render_json_config[:methods],
          allowed_methods: @render_json_config[:allowed_methods]
        )

        if includes
          include_options = []
          @render_json_config[:includes].each do |name, klass|
            if includes.include?(name.to_s)
              includes2 = RenderJsonOptions.includes_for_model(includes: includes, model: name.to_s)
              # raise includes2.inspect + ' ' + includes.inspect
              include_options << { name => klass.render_json_options(includes: includes2, fields: fields) }
            end
          end if @render_json_config[:includes]

          # if includes.include?('questions')
          #   includes2 = RenderJsonOptions.includes_for_model(includes: includes, model: 'questions')
          #   # raise includes2.inspect + ' ' + includes.inspect
          #   include_options << { questions: Organize::Question.render_json_options(includes: includes2, fields: fields) }
          # end
          options[:include] = include_options
        end

        options
      end # render_json_options
      # rubocop:enable Lint/UnusedMethodArgument


    end # class_methods

    def self.includes_for_model(includes:, model:)
      # include.split(',')
      # includes.delete(to_remove)
      includes = includes.map do |el|
        if el.start_with?(model + '.')
          el = el.gsub(/^#{model}\./, '')
        else
          el = nil
        end
      end
      includes.find_all{ |el| el.present? }
      # raise includes.to_json
    end

  end

end


