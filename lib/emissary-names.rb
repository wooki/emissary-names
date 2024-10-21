require_relative './name_utils'
require_relative './name_sources'
require 'titleize'

module Emissary

class Names

    attr_accessor :culture, :data

    @@rules = {
      desert: { desert: 50..100 },
      arid: { desert: 5..50 },
      mountainous: { mountain: 30..100 },
      forested: { forest: 45..100 },
      lowland: { lowland: 50..100 },
      maritime: { ocean: 80..100 },
      fantasy: {} # Fallback generator
    }

    def self.get_culture_for_terrain(terrain_hash)
      passed = passing_rules(terrain_hash, @@rules)
      passed.first
    end

    def self.for_culture(culture)
      Names.new(culture)
    end

    def get_name

      name = Array.new

      # add a prefix according to frequency
      if rand <= @data[:prefix_frequency]
        name.push @data[:prefixes].sample
      end

      main = Array.new

      # add start syllable
      main.push @data[:starts].sample

      # add middle syllable
      middle_length = @utils.random_key_with_frequency(@data[:syllable_lengths]).to_i
      middle_length.times do
        main.push @data[:middles].sample
      end

      # add end syllable
      main.push @data[:ends].sample

      name.push main.join('')

      # add suffix according to frequency
      if rand <= @data[:suffix_frequency]
        name.push @data[:suffixes].sample
      end

      n = name.join(' ').titleize
      return get_name if @data[:source].include? n.downcase
      n
    end

    private

    def initialize(culture)
      @culture = culture.to_sym
      @utils = Emissary::NameUtils.new
      @names = Emissary::NameSources.new

      if @culture == :fantasy
        @data = Emissary::NameSources.data_for_fantasy
      else
        @data = @utils.get_data_for_words(@names.for_culture(@culture))
      end
    end

    def self.passing_rules(terrain_hash, rules)

      # work out percentrage of non-ocean only and then ocean
      # (so won't add up to 100% but much more useful)
      total_rating = terrain_hash.values.sum.to_f
      total_rating_excluding_ocean = terrain_hash.reject { |k, _| k == 'ocean' }.values.sum.to_f
      percentages = terrain_hash.reject { |k, _| k == 'ocean' }.transform_values { |rating| ((rating / total_rating_excluding_ocean) * 100).to_i }
      percentages[:ocean] = ((terrain_hash['ocean'] / total_rating) * 100).to_i
      
      passed_rules = []

      rules.each do |group, terrain_rules|
        all_terrains_passed = terrain_rules.all? do |terrain, range|
          percentage = percentages[terrain.to_s]

          if range.nil?
            true # Not required, so it passes
          else
            range.include?(percentage)
          end
        end

        passed_rules << group if all_terrains_passed
      end

      passed_rules
    end

end

end

