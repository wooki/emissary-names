module Emissary
    class NameUtils 

        def index_of_longest_word(words)
            return nil if words.empty?
          
            longest_word_index = 0
          
            words.each_with_index do |word, index|
              if word.length > words[longest_word_index].length
                longest_word_index = index
              end
            end
          
            longest_word_index
        end          
          
        def extract_prefix_suffix(words)
          
            prefixes = []
            suffixes = []
            base_words = []
          
            words.each do |word|
              if word.include?(' ')
                parts = word.split(' ')

                # longest word is the base word
                base_word_index = index_of_longest_word(parts)
                base_words << parts[base_word_index]

                if base_word_index > 0
                  prefixes << parts[0..base_word_index - 1].join(' ')
                end
                if base_word_index < parts.length - 1
                  suffixes << parts[base_word_index + 1..-1].join(' ')
                end

              else
                base_words << word
              end
            end
          
            { prefixes: prefixes, suffixes: suffixes, base_words: base_words }
          end                  
          
          # Vowels including common diacritics found in source word lists.
          VOWELS = "aeiouyàáâãäåæèéêëìíîïòóôõöøùúûüý"

          def split_into_syllables(word)
            return [word] if word.length <= 1
            # Each syllable: (optional leading consonants)(one or more vowels)(optional trailing consonants)
            # This onset-maximisation approach correctly places consonants with the following vowel,
            # e.g. "Valhalla" -> ["Val", "hal", "la"], "Silberburg" -> ["Sil", "ber", "burg"]
            chunks = word.scan(/[^#{VOWELS}]*[#{VOWELS}]+[^#{VOWELS}]*/i)
            chunks.empty? ? [word] : chunks
          end

          def extract_syllables(words)
            starts = []
            middles = []
            ends = []
            lengths = Hash.new(0)

            words.each do |word|
              syllables = split_into_syllables(word.downcase)
              word_middles = syllables[1..-2] || []

              starts << (syllables[0] || "")
              middles.concat word_middles
              ends << (syllables[-1] || "")
              lengths[word_middles.length] += 1
            end

            { starts: starts.uniq, middles: middles.uniq, ends: ends.uniq, lengths: lengths }
        end
        
        def get_data_for_words(words)             
            data = extract_prefix_suffix(words)
            syllables = extract_syllables(data[:base_words])

            {
              prefixes: data[:prefixes],
              suffixes: data[:suffixes],
              base_words: data[:base_words],
              starts: syllables[:starts],
              middles: syllables[:middles],
              ends: syllables[:ends],
              prefix_frequency: data[:prefixes].length.to_f / data[:base_words].length.to_f,
              suffix_frequency: data[:suffixes].length.to_f / data[:base_words].length.to_f,
              syllable_lengths: syllables[:lengths],
              source: words.map(&:downcase)
            } 
        end

        def random_key_with_frequency(frequencies)
          total_frequency = frequencies.values.sum
          random_number = rand(1..total_frequency)
        
          cumulative_frequency = 0
          frequencies.each do |key, frequency|
            cumulative_frequency += frequency
            return key if random_number <= cumulative_frequency
          end
        end                      
          
    end
end
