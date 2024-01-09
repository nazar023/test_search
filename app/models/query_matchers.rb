# frozen_string_literal: true

module QueryMatchers # :nodoc:
  # returns bool, checks if input word is present in list of all types
  def type?(query_word)
    List.all_types.each do |types_arr|
      return true if types_arr.include?(query_word)
    end
    false
  end

  # Check if it's two word named type
  def two_word_named_type?(index)
    type?("#{@query[index]} #{@query[index + 1]}")
  end

  # returns bool, checks if input word is present in list of all authors
  def author?(query_word)
    List.all_authors.each do |bunch_of_authors|
      return true if bunch_of_authors.include?(query_word)
    end
    false
  end

  # bool check if input word is present in all author names
  def name?(query_word)
    List.authors_names.each do |bunch_of_names|
      return true if bunch_of_names.include?(query_word)
    end
    false
  end

  # returns arr of arrys, inside arrs surnames(ONLY surnames) authors of object splited by comma
  def surname?(query_word)
    List.authors_surnames.each do |bunch_of_surnames|
      return true if bunch_of_surnames.include?(query_word)
    end
    false
  end

  # returns bool in input index is the last in query
  def last_index?(index)
    index == @query.length - 1
  end

  # checks array of authors whether it has at least on simmilar author in list
  def check_arr_has_author?(arr)
    return false if arr.blank?

    arr.each do |arr_el|
      List.all_authors.each do |bunch_of_authors|
        return true if bunch_of_authors.include?(arr_el)
      end
    end
    false
  end

  # Check if it has references to atuhors
  def references_to_authors?(word)
    true if name?(word) || surname?(word)
  end

  # return bool, check if word has any references to language list
  def references_to_language?(word, index)
    languege?(word) || two_word_named_language?(index)
  end

  # return bool ,check whether input word mathces any particular language in language list
  def languege?(query_word)
    List.all_languages.include?(query_word)
  end

  # return bool, check if next query word combined with current creates any particular language in language list
  def two_word_named_language?(index)
    languege?("#{@query[index]} #{@query[index + 1]}") || languege?("#{@query[index + 1]} #{@query[index]}")
  end

end
