module ActiveRecord
  module Acts
    module Optionable
      module SpecifyOption
        module ClassMethods
          def specify_option(option_name, opts = {})
            optionable_specified_options[option_name.to_s] = Option.new_readonly(:name => option_name.to_s, :default => opts[:default])
          end
          
          def optionable_specified_options
            @optionable_specified_options ||= {}
          end

          def get_specified_option(option_name)
            optionable_specified_options[option_name.to_s]
          end          
        end

        module InstanceMethods
          attr_reader :instance_specified_options

          def instance_specified_option(option_name)
            instance_specified_options[option_name.to_s] if instance_specified_options
          end

          def instance_specified_options=(opts)
            @instance_specified_options = {}
            opts.each do |option_name, attributes|
              attributes.symbolize_keys!
              @instance_specified_options[option_name.to_s] = Option.new_readonly(:name => option_name, :default => attributes[:default])
            end
          end
        end
      end
    end
  end
end