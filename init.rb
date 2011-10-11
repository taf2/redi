require 'redi'

Redi.config = YAML.load_file(File.join(RAILS_ROOT,'config/redi.yml'))[RAILS_ENV]
