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
RSpec.describe HomeSearchHelper, type: :helper do
  describe '#search_elements_from_list' do
    before { @list = JSON.parse(File.read('storage/data.json')) }

    it 'ruturns blank array when nonsense' do
      params[:query] = 'lalallalalalalal dasdsadsadsa bsadsadsa'

      expect(helper.search_elements_from_list).to eq([])
    end

    it 'ruturns particular language' do
      params[:query] = 'Lisp'
      response = helper.search_elements_from_list.map { |el| el['Name'] }

      expect(response.length).to eq(1)
      expect(response.first).to eq('Lisp')

      params[:query] = 'Common Lisp'
      response = helper.search_elements_from_list.map { |el| el['Name'] }

      expect(response.first).to eq('Common Lisp')
      expect(response.length).to eq(1)

      params[:query] = 'Lisp Common'
      response = helper.search_elements_from_list.map { |el| el['Name'] }

      expect(response.first).to eq('Common Lisp')
      expect(response.length).to eq(1)
    end

    it 'ruturns @list when query blank' do
      params[:query] = '    '
      expect(helper.search_elements_from_list).to eq(@list)

      params[:query] = ''
      expect(helper.search_elements_from_list).to eq(@list)
    end

    it 'support for negative searches' do
      params[:query] = 'john -array'

      response = helper.search_elements_from_list.map { |el| el['Name'] }
      expect(response).to eq(%w[Haskell S-Lang Lisp BASIC])
    end

    it 'match each field' do
      params[:query] = 'microsoft'
      response = helper.search_elements_from_list
      expect(response.length).to eq(8)

      params[:query] = 'scripting'
      response = helper.search_elements_from_list
      expect(response.length).to eq(25)
    end

    it 'support for exact matches' do
      params[:query] = 'Thomas Eugene'
      response = helper.search_elements_from_list
      expect(response.length).to eq(1)
      expect(response.first['Name']).to eq('BASIC')
    end

    it 'match different fields' do
      params[:query] = 'microsoft scripting'

      response = helper.search_elements_from_list.map { |el| el['Type'].split(', ') & ['Scripting'] }.flatten
      expect(response).to eq(%w[Scripting Scripting Scripting])
      response = helper.search_elements_from_list.map { |el| el['Designed by'] }
      expect(response).to eq(%w[Microsoft Microsoft Microsoft])

      params[:query] = 'John Interpreted -Metaprogramming'

      response = helper.search_elements_from_list.map { |el| el['Name'] }
      expect(response).to eq(%w[S-Lang BASIC])

      # return arr to each el, Check if there is author John
      response = helper.search_elements_from_list.map { |el| el['Designed by'].split(', ').map{ |author| author.include?('John')} }.flatten.reject(&:blank?)
      expect(response).to eq([true, true])

      # return arr to each el, if there is type Metaprogramming leave it
      response = helper.search_elements_from_list.map { |el| el['Type'].split(', ') }.flatten
      expect(response).not_to include('Metaprogramming')
    end
  end
end
