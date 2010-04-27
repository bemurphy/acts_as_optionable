class OptionGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory 'app/models'
      m.file 'option.rb', 'app/models/option.rb'
      m.migration_template "create_options.rb", "db/migrate"
    end
  end

  def file_name
    "create_options"
  end
end
