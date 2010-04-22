class OptionGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => 'create_options'
      m.template 'model.rb', 'app/models/option.rb'
    end
  end
end
