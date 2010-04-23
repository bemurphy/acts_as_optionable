module ActiveRecord
  module Acts
    module Optionable
      module SpecifyOption
        module ClassMethods
          # Setup a default value at the class level.
          def specify_option(option_name, opts = {})
            optionable_specified_options[option_name.to_s] = Option.new_readonly(:name => option_name.to_s, :default => opts[:default])
          end
          
          # Returns a hash of options specified at the class level
          def optionable_specified_options
            @optionable_specified_options ||= {}
          end

          # Get an option specified at the class level.
          def get_specified_option(option_name)
            optionable_specified_options[option_name.to_s]
          end          
        end

        module InstanceMethods
          attr_reader :instance_specified_options

          # Return an option specified for this instance
          def instance_specified_option(option_name)
            instance_specified_options[option_name.to_s] if instance_specified_options
          end

          # Setup instance options.  Pass in a hash of options as such:
          #   instance_options = {
          #     :foo => { :default => "FOO" },
          #     :bar => { :default => "BAR" }
          #   }
          #   foo.instance_specified_options = instance_options
          #
          # These options only persist in the instance, and aren't stored to database.
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