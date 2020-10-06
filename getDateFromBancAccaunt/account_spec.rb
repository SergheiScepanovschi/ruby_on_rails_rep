# frozen_string_literal: true

# Information
# autor: Serghei Scepanovschi
# account_spe.rb ver2.0
#

require_relative 'example_bank'
require 'rspec'
str = IO.read("temp.json")
my_hash = JSON.parse(str)
accounts = []
my_hash['account'].each do |item|
  accounts << Account.new(
    item['name'],
    item['currency'],
    item['balance'].to_f,
    item['nature']
  )
end
example_bank = ExampleBank.new
describe 'accounts' do
  it 'should receive 5 for accounts' do
    example_bank.connect
    example_bank.fetch_accounts
    expect(example_bank.accounts.count).to eq(5)
  end
  it 'should match data account' do
    expect(example_bank.accounts[0].name).to eq(accounts[0].name)
    expect(example_bank.accounts[0].currency).to eq(accounts[0].currency)
    expect(example_bank.accounts[0].balance).to eq(accounts[0].balance)
    expect(example_bank.accounts[0].nature).to eq(accounts[0].nature)
  end

  it 'should match data transaction' do
   example_bank.fetch_transactions
   expect(example_bank.accounts[0].transactions[0].date).to eq(accounts[0].transactions[0].date)
   expect(example_bank.accounts[0].transactions[0].description).to eq(accounts[0].transactions[0].description)
   expect(example_bank.accounts[0].transactions[0].amount).to eq(accounts[0].transactions[0].amount)
   expect(example_bank.accounts[0].transactions[0].currency).to eq(accounts[0].transactions[0].currency)
   expect(example_bank.accounts[0].transactions[0].account_name).to eq(accounts[0].transactions[0].account_name)
  end
end
