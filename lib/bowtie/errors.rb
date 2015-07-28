module Bowtie
  class ProjectSecretKeyMissing < RuntimeError
    def initialize(msg='You need "project": { "secret_key": "XYZ" } defined in `settings.json`')
      super
    end
  end
end
