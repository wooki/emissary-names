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
          
          def split_into_syllables(word)
            return [word] if word.length <= 1
          
            vowels = "aeiouy"
            syllables = []
            current_syllable = ""
            switch_on = :none
            last_char = nil

            word.each_char do |char|
                                
                if !last_char.nil? and last_char == char and !vowels.include?(char) # always break on double consonants
                    current_syllable += char
                    syllables << current_syllable
                    current_syllable = ""
                    switch_on = :none 

                elsif !last_char.nil? and vowels.include?(char) and vowels.include?(last_char) # never break on double vowels

                    current_syllable += char
                    switch_on = :consonant

                elsif (switch_on == :vowel and vowels.include?(char)) or (switch_on == :consonant and !vowels.include?(char))                    
                    syllables << current_syllable unless current_syllable.empty?
                    switch_on = :none                    
                    current_syllable = char
                else
                    current_syllable += char

                    if switch_on == :none
                        if vowels.include?(char)
                            switch_on = :vowel
                        else
                            switch_on = :none
                        end
                    end
                end   
                
                last_char = char
            end
          
            syllables << current_syllable unless current_syllable.empty?
            syllables
          end

          def extract_syllables(words)
            starts = []
            middles = []
            ends = []
            lengths = Hash.new
          
            words.each do |word|
              # Split the word into syllables
              syllables = split_into_syllables(word.downcase)

              # Extract start, middle, and end syllables
              start_syllable = syllables[0] || ""
              end_syllable = syllables[-1] || ""
              middle_syllables = Array.new if middle_syllables.nil?
              middle_syllables = middle_syllables.concat(syllables[1..-2])

              # Add syllables to respective arrays
              starts << start_syllable
              middles.concat middle_syllables
              ends << end_syllable

              if lengths[middle_syllables.length]
                lengths[middle_syllables.length] += 1
              else
                lengths[middle_syllables.length] = 1
              end
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
