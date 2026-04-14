require_relative './name_utils'
require_relative './name_sources'
require 'titleize'
require 'set'

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

    # Honorifics for minor rural nobles, by culture.  Sample uniformly — frequency
    # is controlled by repetition.  Add entries to extend the range of titles.
    MINOR_NOBLE_TITLES = {
      desert:      %w[Sheikh Sheikh Bey Emir Wali Malik],
      arid:        %w[Don Don Sir Señor Alcaide Adelantado],
      mountainous: %w[Thane Thane Sir Jarl Herse Hövding],
      forested:    %w[Sir Sir Sir Maer Lord Arglwydd],
      lowland:     %w[Ritter Ritter Sir Herr Junker Freiherr],
      maritime:    %w[Messer Messer Sir Signore Don Podestà],
      fantasy:     %w[Sir Sir Dame Lord Lady Baron Baroness],
    }

    # Culture-appropriate particles for family names. nil = no particle.
    PARTICLES = {
      desert:      ["al-", "ibn ", "abu ", "umm "],
      arid:        ["de ", "ibn ", "bel ", "al-"],
      mountainous: ["af ", "av ", nil],
      forested:    ["ap ", "ferch ", "ab ", nil],
      lowland:     ["von ", "zu ", nil],
      maritime:    ["di ", "da ", "de "],
      fantasy:     ["de ", "von ", "ap ", nil]
    }

    # Suffixes appended to a place name when deriving a family name from it (~10% chance).
    PLACE_SUFFIXES = {
      desert:      ["i", "ani"],
      arid:        ["i", "ano"],
      mountainous: ["son", "dottir"],
      forested:    ["wyn", "wen"],
      lowland:     ["er"],
      maritime:    ["ano", "i"],
      fantasy:     ["er", "wyn", "i"]
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
        m = @data[:middles].sample
        main.push m unless m.nil?
      end

      # add end syllable
      main.push @data[:ends].sample

      name.push main.join('')

      # add suffix according to frequency
      if rand <= @data[:suffix_frequency]
        name.push @data[:suffixes].sample
      end

      n = name.join(' ').titleize
      return get_name if @data[:source].include?(n.downcase) || @generated_places.include?(n.downcase) || repetitive?(n)
      @generated_places << n.downcase
      n
    end

    # Generate a noble family name appropriate to this culture.
    #
    # Lowland culture uses Germanic compound nouns (Falkenrath, Silberburg).
    # All others use a particle prefix + a short syllabic root.
    # ~10% of the time every culture instead derives the name from a place name
    # with a culture-appropriate suffix (e.g. "Ravenmerewyn", "Adlersteineri").
    def get_family_name
      if rand < 0.1
        return get_name + PLACE_SUFFIXES[@culture].sample
      end

      if @culture == :lowland
        get_lowland_family_name
      else
        get_particle_family_name
      end
    end

    # Generate a minor noble name appropriate to this culture, e.g. "Ritter Wolfram"
    # or "Freiherr Rudolf".  Picks an honorific uniformly from MINOR_NOBLE_TITLES
    # (frequency controlled by repetition) and combines it with a given name from
    # KNIGHT_NAMES.  Each given name is used at most once per instance; falls back
    # to duplicates if the pool is exhausted.
    def get_knight_name
      honorific = MINOR_NOBLE_TITLES[@culture].sample
      names     = Emissary::NameSources::KNIGHT_NAMES[@culture]
      available = names.reject { |n| @generated_knights.include?(n.downcase) }
      name      = (available.empty? ? names : available).sample
      @generated_knights << name.downcase
      "#{honorific} #{name}"
    end

    private

    def initialize(culture)
      @culture = culture.to_sym
      @utils = Emissary::NameUtils.new
      @names = Emissary::NameSources.new
      @generated_places   = Set.new
      @generated_families = Set.new
      @generated_knights  = Set.new

      if @culture == :fantasy
        @data = Emissary::NameSources.data_for_fantasy
      else
        @data = @utils.get_data_for_words(@names.for_culture(@culture))
      end
    end

    def get_lowland_family_name
      first  = Emissary::NameSources::LOWLAND_FAMILY_FIRSTS.sample
      second = Emissary::NameSources::LOWLAND_FAMILY_SECONDS.sample
      name   = (first + second).titleize
      return get_lowland_family_name if @generated_families.include?(name.downcase)
      @generated_families << name.downcase
      name
    end

    def get_particle_family_name
      root = (@data[:starts].sample + @data[:ends].sample).titleize
      return get_particle_family_name if @data[:source].include?(root.downcase) || @generated_families.include?(root.downcase)
      @generated_families << root.downcase
      particle = PARTICLES[@culture].sample
      particle ? "#{particle}#{root}" : root
    end

    # Returns true if any substring of length 3-5 appears more than once in the name.
    # Rejects names like "Elmsbenbenstadt" or "Turmherheiersbach".
    def repetitive?(name)
      n = name.downcase.gsub(/[^a-z]/, '')
      (3..5).any? do |len|
        (0..n.length - len).any? { |i| n.index(n[i, len]) != n.rindex(n[i, len]) }
      end
    end

    def self.passing_rules(terrain_hash, rules)

      # work out percentage of non-ocean only and then ocean
      # (so won't add up to 100% but much more useful)
      total_rating = terrain_hash.values.sum.to_f
      total_rating_excluding_ocean = terrain_hash.reject { |k, _| k == 'ocean' }.values.sum.to_f
      percentages = terrain_hash.reject { |k, _| k == 'ocean' }.transform_values { |rating| ((rating / total_rating_excluding_ocean) * 100).to_i }
      percentages["ocean"] = ((terrain_hash['ocean'] / total_rating) * 100).to_i

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

