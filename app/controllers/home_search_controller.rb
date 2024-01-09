# frozen_string_literal: true

class HomeSearchController < ApplicationController # :nodoc:
  before_action :define_list

  def start; end

  def search
    @updated_list = List.new.search_with_query(params[:query])

    render turbo_stream:
    update_list
  end

  private

  def define_list
    # Initialize JSON data list and query from user
    @list = JSON.parse(File.read('storage/data.json'))
  end

  # Update list using wireless turbo
  def update_list
    turbo_stream.update 'list', partial: 'list', locals: { list: @updated_list }
  end
end
