# frozen_string_literal: true

module HomeSearchHelper # :nodoc:
  def search_elements_from_list
    # Format query string
    @query = params[:query].split(' ').map(&:downcase)

    # Get ids of elements with negative prompts
    negative_prompts = find_negative_prompts_in_query

    # Get sorted list without negative prompts elements
    list = sort_founded_indexes(loop_query_search.compact) - negative_prompts

    # If list is blank and in query wasn't any other queries
    # That means in queary was only prompt eg. "-Iterative" or "-Compiled -Iterative"
    # Initialize original list of indexes to @updated list
    list = (0..@list.length).to_a if list.blank? && query_without_negative_prompts.blank?

    # Deleting all unpropriate indexes, which include @negative_prompts
    # If no prompt was entered @negative_prompts = []
    # list -= negative_prompts
    # Get from original list elements by index
    list = list.map { |index| @list[index] }

    # If query is fully blank assign full list
    list = @list if @query.blank?

    # return list
    list
  end

  private

  def sort_founded_indexes(indexes)
    # If list didn't find anything intialize empty array
    return [] if indexes.blank?

    # Get key ids from array of arrays of indexes
    indexes = combine_all_atributes_to_find(indexes.compact) if indexes.count > 1

    # Counting the most common indexes which we got from filtrating
    # And sort them by descending
    hash_with_count = indexes.uniq.flatten.map do |uniq_num|
      # counts all same indexes and creating hash with index => amount in array
      amount_of_num = indexes.flatten.count(uniq_num)
      { uniq_num => amount_of_num }
    end
    # sorting hash by previosly counted indexes in array
    sorted = hash_with_count.sort_by {|hash| hash.values}.reverse

    # mapping keys,get original indexes, already sorted
    indexes = sorted.map(&:keys).uniq.compact.flatten
  end

  def loop_query_search
    @skip_index = nil

    @query.map.with_index do |word, index|
      # Skip if it's negative prompt or already processed index
      next if index == @skip_index || negative_prompt?(word)

      # Classify each element using word and index
      classify_elements(word, index)
    end
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

  # Handle language classifyed word
  def handle_language(word, index)
    if two_word_named_language?(index)
      handle_two_word_named_language(index)
    elsif languege?(word)
      find_particular_language_by_word(word)
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

  # Check if it has references to atuhors
  def references_to_authors?(word)
    true if name?(word) || surname?(word)
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

  # Handle two word named language
  def handle_two_word_named_language(index)
    # Skip next iteration if it's successful
    @skip_index = index + 1
    find_similar_language_by_word(get_correct_two_word_named_language(index))
  end

  # Handle two word named type
  def handle_two_word_named_type(index)
    # Skip next iteration if it's successful
    @skip_index = index + 1
    # If it type word, try to find and return all indexes with that particular type
    find_particular_type_by_word("#{@query[index]} #{@query[index + 1]}")
  end

  # return arr of strings, query without negative prompts
  def query_without_negative_prompts
    temp = @query.dup
    find_negative_prompt_words.map do |word|
      temp.delete(word)
    end
    temp
  end

  # return arr of strings, negative prompts with '-'
  def find_negative_prompt_words
    @query.map do |word|
      word if negative_prompt?(word)
    end
  end

  # return arr of strings, negative prompts without '-'
  def find_negative_prompts_in_query
    find_particular_type_by_arr(@query.map do |word|
      negative_prompt_word(word) if negative_prompt?(word)
    end)
  end

  # return bool ,check whether input word mathces any particular language in language list
  def languege?(query_word)
    all_languages.include?(query_word)
  end

  # Check if input is negative prompt
  def negative_prompt?(word)
    word.first == '-' && type?(word[1..word.length])
  end

  # return string, transform negative prompt word to common type
  def negative_prompt_word(word)
    word[1..word.length]
  end

  def references_to_language?(word, index)
    languege?(word) || two_word_named_language?(index)
  end

  # return bool, check if next query word combined with current creates any particular language in language list
  def two_word_named_language?(index)
    languege?("#{@query[index]} #{@query[index + 1]}") || languege?("#{@query[index + 1]} #{@query[index]}")
  end

  # Check if it's two word named type
  def two_word_named_type?(index)
    type?("#{@query[index]} #{@query[index + 1]}")
  end

  # returns word(String) which matches some language in language list
  def get_correct_two_word_named_language(index)
    current_with_next_query_word = "#{@query[index]} #{@query[index + 1]}"
    next_query_word_with_current = "#{@query[index + 1]} #{@query[index]}"

    languege?(current_with_next_query_word) ? current_with_next_query_word : next_query_word_with_current
  end

  # returns arr of particulary matching language with word
  def find_particular_language_by_word(word)
    all_languages.map.with_index do |one, i|
      i if one == word
    end.compact
  end

  # returns arr of similary matching language with word
  def find_similar_language_by_word(word)
    all_languages.map.with_index do |one, i|
      i if one.include?(word)
    end.compact
  end

  # returns bool, check if input word similary mathching with language
  def similar_language_exist?(word)
    all_languages.map do |one|
      return true if one.include?(word)
    end.compact
    false
  end

  # returns arr of indexes, compares input array elements to author list
  # find only exactly matching authors
  # used only with find_simillar_authors_by_word (line 171)
  def find_authors_in_arr(arr)
    return [] if arr.blank?

    arr.map do |arr_el|
      all_authors.map.with_index do |bunch_authors, i|
        bunch_authors.map do |author|
          i if author == arr_el
        end.compact
      end.compact.flatten
    end.flatten
  end

  #  return ids of all similar authors compared with input word
  def find_similar_author_by_word(word)
    all_authors.map.with_index do |bunch_authors, i|
      bunch_authors.map do |author|
        i if author.include?(word)
      end.compact
    end.flatten
  end

  # returns id of all similar names founded by comparison of each name with input
  def find_similar_name_by_word(word)
    authors_names.map.with_index do |bunch_authors, i|
      bunch_authors.map do |author|
        i if author.include?(word)
      end.compact
    end.flatten
  end

  # returns array of full names by comparison  each author with input by include?
  def find_simillar_authors_by_word(word)
    similar_dev_full_name_ids = find_similar_author_by_word(word)
    return if similar_dev_full_name_ids.empty?

    similar_dev_full_name_ids.map do |index|
      all_authors[index].map do |author|
        author if author.include?(word)
      end.compact
    end.compact.flatten.uniq
  end

  # checks array of authors whether it has at least on simmilar author in list
  def check_arr_has_author?(arr)
    return false if arr.blank?

    arr.each do |arr_el|
      all_authors.each do |bunch_of_authors|
        return true if bunch_of_authors.include?(arr_el)
      end
    end
    false
  end

  # returns id of all similar surnames founded by comparison of each surname with input
  def find_similar_surname_by_word(word)
    authors_surnames.map.with_index do |bunch_surnames, i|
      bunch_surnames.map do |author|
        i if author.include?(word)
      end.compact
    end.flatten
  end

  # checks if input string(query_word) mathces any
  def find_particular_type_by_word(query_word)
    all_types.map.with_index do |types_arr, i|
      i if types_arr.include?(query_word)
    end.compact
  end

  # returns ids of particular types by comparing it with input arr elements
  def find_particular_type_by_arr(arr)
    all_types.map.with_index do |types_arr, i|
      arr.map do |el|
        i if types_arr.include?(el)
      end.compact
    end.compact.reject(&:blank?).flatten.uniq
  end

  # returns bool, checks if input word is present in list of all types
  def type?(query_word)
    all_types.each do |types_arr|
      return true if types_arr.include?(query_word)
    end
    false
  end

  # returns bool, checks if input word is present in list of all authors
  def author?(query_word)
    all_authors.each do |bunch_of_authors|
      return true if bunch_of_authors.include?(query_word)
    end
    false
  end

  # returns all names of objects(languages)
  def all_languages
    languages = []
    @list.each do |hash|
      language = hash['Name']
      languages << language.downcase unless languages.include?(language)
    end
    languages
  end

  # returns all types of object
  def all_types
    uniq = []
    @list.each do |hash|
      types_of_el = hash['Type']
      uniq << types_of_el.downcase.split(', ')
    end
    uniq
  end

  # returns arr of arrys, inside arrs authors(full names) of object splited by comma
  def all_authors
    authors = []
    @list.each do |hash|
      authors_of_el = hash['Designed by']
      authors << authors_of_el.downcase.split(', ')
    end
    authors
  end

  # bool check if input word is present in all author names
  def name?(query_word)
    authors_names.each do |bunch_of_names|
      return true if bunch_of_names.include?(query_word)
    end
    false
  end

  # returns arr of arrys, inside arrs names(ONLY NAMES) authors of object splited by comma
  def authors_names
    all_authors.map do |bunch_authors|
      bunch_authors.map do |author|
        author.split(' ')[0]
      end
    end
  end

  # returns arr of arrys, inside arrs surnames(ONLY surnames) authors of object splited by comma
  def surname?(query_word)
    authors_surnames.each do |bunch_of_surnames|
      return true if bunch_of_surnames.include?(query_word)
    end
    false
  end

  # returns arr of arrys inside each of them are only surnames of developers
  def authors_surnames
    all_authors.map do |bunch_authors|
      bunch_authors.map do |author|
        author.split(' ').drop(1)
      end.flatten
    end
  end

  # returns bool in input index is the last in query
  def last_index?(index)
    index == @query.length - 1
  end

  # return bool if next word is name
  def next_word_name?(index)
    name?(@query[index + 1])
  end

  # return bool if next word is surname
  def next_word_surname?(index)
    surname?(@query[index + 1])
  end

  # If in query has a lot of words we need to leave
  # requests which mathced all querys
  def combine_all_atributes_to_find(big_arr)
    temp_arr = big_arr[0]
    (1...big_arr.length).each do |index|
      temp_arr = (temp_arr & big_arr[index])
    end
    temp_arr
  end
end
