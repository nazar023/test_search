# frozen_string_literal: true

class Query # :nodoc:
  attr_reader :query, :negative_prompts, :search_result

  include QueryMatchers
  include QueryHandlers
  include QueryFinders

  def initialize(query_params)
    # Format query string
    @query = query_params.split(' ').map(&:downcase)
    @negative_prompts = negative_prompts_in_query
    @search_result = loop_query_search
    @skip_index = nil
  end

  # Get ids of elements with negative prompts
  def negative_prompts_in_query
    negative_prompt_words = @query.map do |word|
      negative_prompt_word(word) if negative_prompt?(word)
    end

    find_particular_type_by_arr(negative_prompt_words)
  end

  # return arr of strings, query without negative prompts
  def without_negative_prompts
    temp = @query.dup
    find_negative_prompt_words.map do |word|
      temp.delete(word)
    end
    temp
  end

  private

  def loop_query_search
    @skip_index = nil

    @query.map.with_index do |word, index|
      # Skip if it's negative prompt or already processed index
      next if index == @skip_index || negative_prompt?(word)

      # Classify each element using word and index
      classify_elements(word, index)
    end.compact
  end

  def classify_elements(word, index)
    # Check if next word in query by combining creates a full language name
    # Check if it has language refernces
    if references_to_language?(word, index)
      # If it has, find ids of
      handle_language(word, index)
    # Check if it's one word language name
    elsif references_to_authors?(word)
      # Find word is author, find simmilar words to it
      handle_author(word, index)
    # Check if it's one word type
    elsif type?(word) || two_word_named_type?(index)
      handle_type(word, index)
    # If we don't find any particular object which we were searching
    # We enter to else and try to find at least something which matches that query
    else
      # Try to find anything with that particular word
      handle_else(word)
    end
  end

  def negative_prompt?(word)
    word.first == '-' && type?(word[1..word.length])
  end

  def negative_prompt_word(word)
    word[1..word.length]
  end
end
