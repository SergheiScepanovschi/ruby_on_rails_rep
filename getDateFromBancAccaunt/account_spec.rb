# frozen_string_literal: true

# Information
# autor: Serghei Scepanovschi
# account_spe.rb ver2.0
#

require_relative 'example_bank'
require 'rspec'

def copyhash(inputhash)
  h = Hash.new
  inputhash.each_with_index do |pair, index|
    h.store(pair[0], pair[1])
    if index > 2
      break
    end
  end
  return h
end

str = IO.read("temp.json")
my_hash = JSON.parse(str)
accounts = []
my_hash['accounts'].each do |item|
  accounts << copyhash(item)
end

example_bank = ExampleBank.new
describe 'accounts' do
  it 'should receive 5 for accounts' do
    html_example = Nokogiri::HTML(File.read('account/index0.html'))
    strct = Nokogiri::HTML(html_example).css('script[id="data"]')
    example_bank.parse_accounts(strct)
    expect(example_bank.accounts.count).to eq(5)
  end
  it 'should match data account' do
    hash_temp = example_bank.accounts[0].to_h
    hash_temp.delete(:transactions)
    expect(hash_temp.to_json).to eq(accounts[0].to_json)
  end
  it 'should match data transaction' do
    accounts = []
    my_hash['accounts'].each do |item|
      accounts << item
    end
    html_example = ['transactions/index0.html', 'transactions/index1.html', 'transactions/index2.html',
                    'transactions/index3.html', 'transactions/index4.html', 'transactions/index5.html',
                    'transactions/index6.html', 'transactions/index7.html', 'transactions/index8.html',
                    'transactions/index9.html']
    html_example.each_with_index do |item, Index|
      html_example = Nokogiri::HTML(File.read(item))
      example_bank.parse_transactions(1, html_example)
      expect(example_bank.accounts[0].transactions[Index].to_json).to eq(accounts[0].transactions[Index].to_json)
    end
  end
  it 'should receive 10 for transactions' do
    expect(example_bank.accounts[0].transactions.count).to eq(10)
  end
end
