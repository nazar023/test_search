# frozen_string_literal: true

module QueryHandlers # :nodoc:
  # Handle language classifyed word
  def handle_language(word, index)
    if two_word_named_language?(index)
      handle_two_word_named_language(index)
    elsif languege?(word)
      find_particular_language_by_word(word)
    end
  end

  # Handle two word named language
  def handle_two_word_named_language(index)
    # Skip next iteration if it's successful
    @skip_index = index + 1
    find_similar_language_by_word(find_correct_two_word_named_language(index))
  end

  # Handle author classifyed word
  def handle_author(word, index)
    # Handle name
    if name?(word)
      handle_founded_name(word, index)
      # Handle surname
    else
      handle_founded_surname(word, index)
    end
  end

  # Handle name query
  def handle_founded_name(word, index)
    name_with_next_query_word = "#{@query[index]} #{@query[index + 1]}"
    # If it'name, check weather it last element in arr
    # Also check if combination of current word and next word creates existing author
    if !last_index?(index) && check_arr_has_author?(find_simillar_authors_by_word(name_with_next_query_word))
      # Skip next iteration if it's successful
      @skip_index = index + 1
      # If any simmilar author was found
      # Find all similar authors in origin list and return arr of indexes
      find_authors_in_arr(find_simillar_authors_by_word(name_with_next_query_word))
    else
      # If it isn't full name, try to find all simmilar names
      # Find all similar names in origin list and return arr of indexes
      find_similar_name_by_word(word)
    end
  end

  # Handle surname query
  def handle_founded_surname(word, index)
    surname_with_previous_query_word = "#{@query[index + 1]} #{@query[index]}"
    # If it's surname, check weather it's last element in arr
    # Also check if combination of current word and next word creates existing author
    if !last_index?(index) && check_arr_has_author?(find_simillar_authors_by_word(surname_with_previous_query_word))
      # Skip next iteration if it's successful
      @skip_index = index + 1
      # If any simmilar author was found
      # Find all similar authors in origin list and return arr of indexes
      find_authors_in_arr(find_simillar_authors_by_word(surname_with_previous_query_word))
    else
      # If it's just a surname, try to find any similar surnames and return arr of it's indexes
      find_similar_surname_by_word(word)
    end
  end

  # Handle type classifyed word
  def handle_type(word, index)
    # Defining what exactly query we found
    if type?(word)
      # If it type one word, try to find and return all indexes with that particular type
      find_particular_type_by_word(word)
      # Else combine word by using string interpolation and find two worded type
    else
      handle_two_word_named_type(index)
    end
  end

  # Handle two word named type
  def handle_two_word_named_type(index)
    # Skip next iteration if it's successful
    @skip_index = index + 1
    # If it type word, try to find and return all indexes with that particular type
    find_particular_type_by_word("#{@query[index]} #{@query[index + 1]}")
  end

  # Handle else classifyed word
  def handle_else(word)
    # Try to find any similar languages and authors with that query
    simmilar_languages = find_similar_language_by_word(word)
    simmilar_authors = find_authors_in_arr(find_simillar_authors_by_word(word))

    # If we found anything store to mapping and continue
    if simmilar_languages.present? && simmilar_authors.present?
      simmilar_authors + simmilar_languages
    elsif simmilar_languages.present?
      simmilar_languages
    elsif simmilar_authors.present?
      simmilar_authors
    end
  end
end
