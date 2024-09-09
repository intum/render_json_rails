module RenderJsonRails
  module Concern
    extend ActiveSupport::Concern

    # http://marcin.xxx.test/api/organize/questions/2.json?formatted=yes&include=last_answers,last_answers.user&fields[question]=id&fields[user]=email,login,get_name
    # http://marcin.xxx.test/api/organize/questions/2.json?formatted=yes&include=last_answers,team,team.questions

    # http://marcin.yyy.test/xx/55200174.json?formatted=yes&mass_fiscal_print=yes
    # http://marcin.yyy.test/xx/55200174.json?formatted=yes&fields[invoice_position]=id,fiscal_short_name
    # http://marcin.yyy.test/yy/uu.json?formatted=yes&fields[payment]=id
    # http://marcin.yyy.test/yy/uu.json?formatted=yes&fields[payment]=id&include=invoices,payment_connections

    class_methods do
      # Metoda przygotowuje parametry `options` do generowania json-a
      # `methods` to dodatkowe metody które domyślnie będą wyświetlane w jsonie
      # `allowed_methods` definiuje metody, które możemy wymienić w `fields` i wtedy
      #  zostaną one wyświelone w json-ie
      # TODO:
      # [ ] spradzanie czy parametry "fields" i "include" sa ok i jesli nie to error
      def default_json_options(name:, fields: nil, only: nil, except: nil, methods: nil, allowed_methods: nil, additional_fields: nil)
        # name ||= self.name.underscore.gsub('/', '_')
        # raise self.name.underscore.gsub('/', '_')
        # except ||= [:account_id, :agent, :ip]

        options = {}
        if fields && fields[name].present?
          if additional_fields && additional_fields[name].present?
            fields[name] += ",#{additional_fields[name]}"
          end
          options[:only] = fields[name].split(',').map{ |e| e.to_s.strip.to_sym }.find_all { |el| !except&.include?(el) }
          if only.present?
            options[:only] = options[:only].find_all do |el|
              only.include?(el) || allowed_methods&.include?(el) || methods&.include?(el)
            end
          end
          options[:methods] = methods&.find_all { |el| options[:only].include?(el) }
          if allowed_methods
            options[:methods] = (options[:methods] || []) | allowed_methods.find_all { |el| options[:only].include?(el) }
          end
          if options[:methods].present? && options[:only].present?
            options[:methods].each { |method| options[:only].delete(method) }
          end
        else
          options[:except] = except
          options[:only] = only if only.present?
          options[:methods] = methods
          if additional_fields && additional_fields[name].present? && allowed_methods
            additional_methods = additional_fields[name].split(',').map{ |e| e.to_s.strip.to_sym }.find_all { |el| allowed_methods.include?(el) }
            options[:methods] = (options[:methods] || []) | additional_methods
          end
        end
        options
      end

      def render_json_config(config)
        @render_json_config = config
      end

      def render_json_options(includes: nil, fields: nil, override_render_json_config: nil, additional_config: nil, additional_fields: nil)
        raise "należy skonfigurowac render_json metodą: render_json_config" if !defined?(@render_json_config)

        if override_render_json_config
          current_json_config = override_render_json_config # @render_json_config.merge(override_render_json_config)
          current_json_config[:name] ||= @render_json_config[:name]
          current_json_config[:default_fields] ||= @render_json_config[:default_fields]
        else
          current_json_config = @render_json_config
        end

        name = current_json_config[:name].to_s

        if (fields.blank? || fields[name].blank?) && current_json_config[:default_fields].present?
          fields ||= {}
          fields[name] = current_json_config[:default_fields].join(',')
        end

        options = default_json_options(
          name: name,
          fields: fields,
          only: current_json_config[:only],
          except: current_json_config[:except],
          methods: current_json_config[:methods],
          allowed_methods: current_json_config[:allowed_methods],
          additional_fields: additional_fields
        )

        if includes
          include_options = []
          current_json_config[:includes]&.each do |model_name, klass|
            if includes.include?(model_name.to_s)
              includes2 = RenderJsonRails::Concern.includes_for_model(includes: includes, model: model_name.to_s)
              include_options << { model_name => klass.render_json_options(includes: includes2, fields: fields,
                additional_fields: additional_fields) }
            end
          end

          options[:include] = include_options if include_options.present?
        end

        options = RenderJsonRails::Concern.deep_meld(options, additional_config) if additional_config

        if options[:except].present?
          options[:methods] = options[:methods]&.find_all { |el| !options[:except].include?(el) }
        end

        options.delete(:methods) if options[:methods].blank?

        options
      end # render_json_options
    end # class_methods

    def self.includes_for_model(includes:, model:)
      includes = includes.map { |el| el.gsub(/^#{model}\./, '') if el.start_with?(model + '.') }
      includes.find_all { |el| el.present? }
    end

    def self.deep_meld(hh1, hh2)
      hh1.deep_merge(hh2) do |_key, this_val, other_val|
        if !this_val.nil? && other_val == nil
          this_val
        elsif this_val == nil && !other_val.nil?
          other_val
        elsif this_val.is_a?(Array) && other_val.is_a?(Array)
          this_val | other_val
        elsif this_val.is_a?(Hash) && other_val.is_a?(Hash)
          deep_meld(this_val, other_val)
        else
          [this_val, other_val]
        end
      end
    end
  end
end
