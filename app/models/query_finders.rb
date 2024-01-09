# frozen_string_literal: true

module QueryFinders # :nodoc:
  # returns arr of similary matching language with word
  def find_similar_language_by_word(word)
    List.all_languages.map.with_index do |one, i|
      i if one.include?(word)
    end.compact
  end

  # returns word(String) which matches some language in language list
  def find_correct_two_word_named_language(index)
    current_with_next_query_word = "#{@query[index]} #{@query[index + 1]}"
    next_query_word_with_current = "#{@query[index + 1]} #{@query[index]}"

    languege?(current_with_next_query_word) ? current_with_next_query_word : next_query_word_with_current
  end

  # returns arr of particulary matching language with word
  def find_particular_language_by_word(word)
    List.all_languages.map.with_index do |one, i|
      i if one == word
    end.compact
  end

  # returns array of full names by comparison  each author with input by include?
  def find_simillar_authors_by_word(word)
    similar_dev_full_name_ids = find_similar_author_by_word(word)
    return if similar_dev_full_name_ids.empty?

    similar_dev_full_name_ids.map do |index|
      List.all_authors[index].map do |author|
        author if author.include?(word)
      end.compact
    end.compact.flatten.uniq
  end

  # returns ids of particular types by comparing it with input arr elements
  def find_particular_type_by_arr(arr)
    List.all_types.map.with_index do |types_arr, i|
      arr.map do |el|
        i if types_arr.include?(el)
      end.compact
    end.compact.reject(&:blank?).flatten.uniq
  end

  # returns arr of indexes, compares input array elements to author list
  # find only exactly matching authors
  # used only with find_simillar_authors_by_word (line 171)
  def find_authors_in_arr(arr)
    return [] if arr.blank?

    arr.map do |arr_el|
      List.all_authors.map.with_index do |bunch_authors, i|
        bunch_authors.map do |author|
          i if author == arr_el
        end.compact
      end.compact.flatten
    end.flatten
  end

  #  return ids of all similar authors compared with input word
  def find_similar_author_by_word(word)
    List.all_authors.map.with_index do |bunch_authors, i|
      bunch_authors.map do |author|
        i if author.include?(word)
      end.compact
    end.flatten
  end

  # returns id of all similar names founded by comparison of each name with input
  def find_similar_name_by_word(word)
    List.authors_names.map.with_index do |bunch_authors, i|
      bunch_authors.map do |author|
        i if author.include?(word)
      end.compact
    end.flatten
  end

  # returns id of all similar surnames founded by comparison of each surname with input
  def find_similar_surname_by_word(word)
    List.authors_surnames.map.with_index do |bunch_surnames, i|
      bunch_surnames.map do |author|
        i if author.include?(word)
      end.compact
    end.flatten
  end

  # checks if input string(query_word) mathces any
  def find_particular_type_by_word(query_word)
    List.all_types.map.with_index do |types_arr, i|
      i if types_arr.include?(query_word)
    end.compact
  end

  # return arr of strings, negative prompts with '-'
  def find_negative_prompt_words
    @query.map do |word|
      word if negative_prompt?(word)
    end
  end
end
