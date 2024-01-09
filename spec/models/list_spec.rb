require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the HomeSearchHelper. For example:
#
# describe HomeSearchHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe List, type: :model do
  it '#intitalize' do
    expect(List.new.list).to eq(JSON.parse(File.read('storage/data.json')))
  end

  describe '#search_with_query' do
    before { @list = List.new }

    it 'ruturns blank array when nonsense' do
      expect(@list.search_with_query('nnonsense')).to be_empty
      expect(@list.search_with_query('dsadsadasda')).to be_empty
    end

    it 'matches particular language' do
      # index of 'Lisp' in list is 60
      # index of 'Common Lisp' in list is 26

      expect(@list.search_with_query('Lisp').count).to eq(1)
      expect(@list.search_with_query('Lisp').first).to eq(@list.list[60])

      expect(@list.search_with_query('Common Lisp').count).to eq(1)
      expect(@list.search_with_query('Common Lisp').first).to eq(@list.list[26])

      expect(@list.search_with_query('Lisp Common').count).to eq(1)
      expect(@list.search_with_query('Lisp Common').first).to eq(@list.list[26])
    end

    it 'return full list when query blank' do
      expect(@list.search_with_query(' ')).to eq(List.all_elements)
    end

    it 'support for negative searches' do
      expect(@list.search_with_query('john -array').count).to eq(4)

      names = @list.search_with_query('john -array').map { |el| el['Name'] }
      expect(names).to eq(%w[Haskell S-Lang Lisp BASIC])
    end

    it 'matches each field' do
      expect(@list.search_with_query('microsoft').count).to eq(8)
      expect(@list.search_with_query('scripting').count).to eq(25)
    end

    it 'support exact matches' do
      expect(@list.search_with_query('Thomas Eugene').count).to eq(1)
      expect(@list.search_with_query('Thomas Eugene').first['Name']).to eq('BASIC')
    end

    it 'matches different fields' do
      response = @list.search_with_query('microsoft scripting')
      # Get all types and leave only Scrpting if it's inside
      types = response.map { |el| el['Type'].split(', ') & ['Scripting'] }.flatten
      # Get all Authors
      authors = response.map { |el| el['Designed by'] }

      expect(response.count).to eq(3)
      expect(types).to eq(%w[Scripting Scripting Scripting])
      expect(authors).to eq(%w[Microsoft Microsoft Microsoft])
    end
  end
end
