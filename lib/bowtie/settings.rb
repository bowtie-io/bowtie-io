module Bowtie
  class Settings
    class << self
      def [](key)
        @settings ||= JSON.parse(File.read('./settings.json'))
        @settings[key]
      end
    end
  end
end
