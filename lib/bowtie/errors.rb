module Bowtie
  class ProjectSecretKeyMissing < RuntimeError
    def initialize(msg='You need "project": { "environments": { "development": { "secret_key": "XYZ" } } } defined in `settings.json`')
      super
    end
  end
end
