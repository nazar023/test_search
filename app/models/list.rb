# frozen_string_literal: true

class List # :nodoc:
  attr_reader :list

  def initialize
    @list = JSON.parse(File.read('storage/data.json'))
  end

  def search_with_query(query_params)
    # Initialize query by params
    query = Query.new(query_params)
    temp_list = query.search_result

    # Get sorted list without negative prompts elements
    sorted_list = sort_founded_indexes(temp_list) - query.negative_prompts

    # If list is blank and in query wasn't any other queries
    # That means in queary was only prompt eg. "-Iterative" or "-Compiled -Iterative"
    # Initialize original list of indexes to @updated list
    sorted_list = (0..@list.length).to_a if sorted_list.blank? && query.without_negative_prompts.blank?

    # Deleting all unpropriate indexes, which include @negative_prompts
    # If no prompt was entered @negative_prompts = []
    # list -= negative_prompts
    # Get from original list elements by index
    sorted_list = sorted_list.map { |index| @list[index] }

    # If query is fully blank assign full list
    sorted_list = List.all_elements if query_params.blank?
    # return list
    sorted_list
  end

  # returns all elements in list
  def self.all_elements
    JSON.parse(File.read('storage/data.json'))
  end

  # returns all types of object
  def self.all_types
    uniq = []
    List.all_elements.each do |hash|
      types_of_el = hash['Type']
      uniq << types_of_el.downcase.split(', ')
    end
    uniq
  end

  # returns all names of objects(languages)
  def self.all_languages
    languages = []
    List.all_elements.each do |hash|
      language = hash['Name']
      languages << language.downcase unless languages.include?(language)
    end
    languages
  end

  # returns arr of arrys, inside arrs authors(full names) of object splited by comma
  def self.all_authors
    authors = []
    List.all_elements.each do |hash|
      authors_of_el = hash['Designed by']
      authors << authors_of_el.downcase.split(', ')
    end
    authors
  end

  # returns arr of arrys, inside arrs names(ONLY NAMES) authors of object splited by comma
  def self.authors_names
    List.all_authors.map do |bunch_authors|
      bunch_authors.map do |author|
        author.split(' ')[0]
      end
    end
  end

  # returns arr of arrys inside each of them are only surnames of developers
  def self.authors_surnames
    List.all_authors.map do |bunch_authors|
      bunch_authors.map do |author|
        author.split(' ').drop(1)
      end.flatten
    end
  end

  private

  def loop_query_search
    @skip_index = nil

    @query.map.with_index do |word, index|
      # Skip if it's negative prompt or already processed index
      next if index == @skip_index || negative_prompt?(word)

      # Classify each element using word and index
      classify_elements(word, index)
    end
  end

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
