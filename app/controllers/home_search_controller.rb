# frozen_string_literal: true

class HomeSearchController < ApplicationController # :nodoc:
  def start
    @list = JSON.parse(File.read('storage/data.json'))
  end

  def search
    # Initialize JSON data list and query from user
    @list = JSON.parse(File.read('storage/data.json'))
    # Split query with ' ' and downcase to make work with it easier
    @query = params[:query].split(' ').map(&:downcase)

    # Search in list and search negarive prompts
    @updated_list = sort_founded_indexes(get_searched_elements_from_list)
    @negative_prompts = find_particular_type_by_arr(find_negative_prompts_in_query)

    # If @updated list didn't find anything intialize empty array
    @updated_list ||= []

    # If list is blank and in query wasn't any other queries
    # That means in queary was only prompt eg. "-Iterative" or "-Compiled -Iterative"
    # Initialize original list of indexes to @updated list
    @updated_list = (0..@list.length).to_a if @update_list.blank? && get_query_without_negative_prompts.blank?
    # Deleting all unpropriate indexes, which include @negative_prompts
    # If no prompt was entered @negative_prompts = []
    @updated_list -= @negative_prompts.uniq
    # Get from original list elements by index
    @updated_list = @updated_list&.uniq&.compact&.flatten&.map { |index| @list[index] }

    # render view with turbo, no reload page
    @updated_list = @list if params[:query].blank?
    render turbo_stream:
    update_list
  end

  private

  def sort_founded_indexes(indexes)
    return if indexes.blank?

    # Get key ids from array of arrays of indexes
    indexes = combine_all_atributes_to_find(indexes.compact) if indexes.count > 1

    # Counting the most common indexes which we got from filtrating
    # And sort them by descending
    uniq_numbers = indexes.uniq.flatten
    hash_with_count = uniq_numbers.map do |uniq_num|
                        # counts all same indexes and creating hash with index => amount in array
                        amount_of_num = indexes.flatten.count(uniq_num)
                        { uniq_num => amount_of_num }
                      end
    # sorting hash by previosly counted indexes in array
    sorted = hash_with_count.sort_by {|hash| hash.values}.reverse

    # mapping keys,get original indexes, already sorted
    indexes = sorted.map(&:keys).flatten
  end

  def get_searched_elements_from_list
    skip_index = nil

    @query.map.with_index do |word, index|
      next if index == skip_index

      # Check if next word in query by combining creates a full language name
      if two_word_named_language?(index)
        two_words_query = get_correct_two_word_named_language(index)
        skip_index = index + 1
        find_similar_language_by_word(two_words_query)
      # Check if it's one word language name
      elsif languege?(word)
        find_particular_language_by_word(word)
      # Check if it's one word language name
      elsif author?(word)
        # Find word is author, find simmilar words to it
        find_similar_author_by_word(word)
      # Check if it's name
      elsif name?(word)
        # If it'name, check weather it last element in arr
        # Also check if combination of current word and next word creates existing author
        if !last_index?(index) && check_arr_has_author?(find_similar_full_name_among_language_devs("#{@query[index]} #{@query[index + 1]}"))
          # Skip next iteration if it's successful
          skip_index = index + 1
          # If any simmilar author was found
          # Find all similar authors in origin list and return arr of indexes
          find_particular_author_by_arr(find_similar_full_name_among_language_devs("#{@query[index]} #{@query[index + 1]}"))
        else
          # If it isn't full name, try to find all simmilar names
          # Find all similar names in origin list and return arr of indexes
          find_similar_name_by_word(word)
        end
        # Check if it's surname
      elsif surname?(word)
        # If it's surname, check weather it's last element in arr
        # Also check if combination of current word and next word creates existing author
        if !last_index?(index) && check_arr_has_author?(find_similar_full_name_among_language_devs("#{@query[index + 1]} #{@query[index]}"))
          # Skip next iteration if it's successful
          skip_index = index + 1
          # If any simmilar author was found
          # Find all similar authors in origin list and return arr of indexes
          find_particular_author_by_arr(find_similar_full_name_among_language_devs("#{@query[index + 1]} #{@query[index]}"))
        else
          # If it's just a surname, try to find any similar surnames and return arr of it's indexes
          find_similar_surname_by_word(word)
        end
        # Check if it's one word type
      elsif type?(word)
        # If it type word, try to find and return all indexes with that particular type
        find_particular_type_by_word(word)
        # Check if it's two word type
      elsif type?("#{@query[index]} #{@query[index + 1]}")
        # Skip next iteration if it's successful
        skip_index = index + 1
        # If it type word, try to find and return all indexes with that particular type
        find_particular_type_by_word("#{@query[index]} #{@query[index + 1]}")
      # If we don't find any particular object which we were searching
      # We enter to else and try to find at least something which matches that query
      else
        # Skip if it's negative prompt
        next if negative_prompt?(word)

        # Try to find any similar languages and authors with that query
        simmilar_languages = find_similar_language_by_word(word)
        simmilar_authors = find_particular_author_by_arr(find_similar_full_name_among_language_devs(word))

        # If we found anything store to mapping and continue
        if simmilar_languages.present? && simmilar_authors.present?
          simmilar_authors + simmilar_languages
        elsif simmilar_languages.present?
          simmilar_languages
        elsif simmilar_authors.present?
          simmilar_authors
        end

      end
    end.compact
  end

  # return arr of strings, query without negative prompts
  def get_query_without_negative_prompts
    temp = @query.dup
    find_negative_prompt_words.map do |word|
      temp.delete(word)
    end
    temp
  end

  # return arr of strings, negative prompts with '-'
  def find_negative_prompt_words
    @query.map do |word|
      if negative_prompt?(word)
        word
      end
    end
  end

  # return arr of strings, negative prompts without '-'
  def find_negative_prompts_in_query
    @query.map do |word|
      if negative_prompt?(word)
        negative_prompt_word(word)
      end
    end
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

  # return bool, check if next query word combined with current creates any particular language in language list
  def two_word_named_language?(index)
    languege?("#{@query[index]} #{@query[index + 1]}") || languege?("#{@query[index + 1]} #{@query[index]}")
  end

  # returns word(String) which matches some language in language list
  def get_correct_two_word_named_language(index)
    languege?("#{@query[index]} #{@query[index + 1]}") ? "#{@query[index]} #{@query[index + 1]}" : "#{@query[index + 1]} #{@query[index]}"
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
  # used only with find_similar_full_name_among_language_devs (line 171)
  def find_particular_author_by_arr(arr)
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
  def find_similar_full_name_among_language_devs(word)
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

  def find_particular_type_by_arr(arr)
    all_types.map.with_index do |types_arr, i|
      arr.map do |el|
        i if types_arr.include?(el)
      end.compact
    end.compact.reject(&:blank?).flatten
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

  # Update list using wireless turbo
  def update_list
    turbo_stream.update 'list', partial: 'list', locals: { list: @updated_list }
  end
end
