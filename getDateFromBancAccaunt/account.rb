# frozen_string_literal: true

# Information
# autor: Serghei Scepanovschi
# account.rb ver 1.0
#
require_relative 'transaction'

# class to store Accounts data
class Account
  attr_accessor :name, :currency, :balance, :nature, :transactions

  def initialize(v_name, v_currency, v_balance, v_nature)
    @name         = v_name     # name of account
    @currency     = v_currency # currency of account
    @balance      = v_balance  # available balance of account
    @nature       = v_nature   # nature of account
    @transactions = []         # transactions of account
  end

  def to_h
  {
    name:         name,
    currency:     currency,
    balance:      balance,
    nature:       nature,
    transactions: transactions.map(&:to_h)
  }
  end

  # method to add transaction
  def add_transaction(v_date, v_description, v_amount, v_currency, v_account_name)
    transactions << Transaction.new(v_date, v_description, v_amount, v_currency, v_account_name)
  end
end
