# frozen_string_literal: true

# Information
# autor: Serghei Scepanovschi
# examplebank.rb ver 2.0

require 'date'
require 'json'
require 'nokogiri'
require 'watir'
require 'pry'
require 'webdrivers'
require_relative 'account'

# main class to fetch and parse our site
class ExampleBank
  attr_accessor :browser , :accounts
  def initialize()
    @browser     = Watir::Browser.new :firefox
    @accounts    = []
    @accounts_hash
  end

  def accounts
    @accounts
  end

  def connect
    # here you log in to the bank
    @browser.goto 'https://demo.bendigobank.com.au/banking/sign_in'
    @browser.button(name: 'customer_type').click
  end


  # scroll down to bottom to find "No more activity" or 'No matching activity found.'  string
  def scroll_to_bottom
    loop do
      @browser.scroll.to :bottom
      break if @browser.text.include?('No more activity') || @browser.text.include?('No matching activity found.')
    end
  end

  def fetch_accounts
    # fetch html data using nokogiri, take only fragment of html.
    strct = Nokogiri::HTML(@browser.html).css('script[id="data"]')
    parse_accounts(strct)
  end

  def fetch_transactions
    #accounts_box = @browser.elements(css: 'li[data-semantic="account-group"]')[0]
    account_css_selector = 'li[data-semantic="account-item"]'
    sleep 6
    @browser.elements(css: account_css_selector).each_with_index do |build, index|
      # binding.pry
      build.wait_until_present.click
      # set date for 2 month
      set_data_filter
      scroll_to_bottom
      parse_transactions(index, @browser.html)
    end
  end

  def parse_accounts(html)
    strct = html.text
    # parse accounts here
    pos1 = strct.rindex(/__DATA__/)
    pos2 = strct.rindex(/__BOOTSTRAP_I18N__/)
    pos1 += 10
    pos2 -= 69

    strct = strct.slice(pos1, pos2)
    my_hash = JSON.parse(strct)
    my_hash['accounts'].each do |item|
      @accounts << Account.new(
        item['name'],
        item['currentBalance']['currency'],
        item['currentBalance']['value'].to_f,
        item['classification']
      )
    end
  end

  def set_data_filter
    two_month = 60
    current_date = Time.now.strftime('%d/%m/%Y') # DD/MM/YYYY
    edge_date = Date.parse(current_date) - two_month
    @browser.element(css: 'a[data-semantic="filter"]').wait_until_present.click
    @browser.element(css: 'a[data-semantic="date-filter"]').wait_until_present.click
    b = @browser.element(css: 'li[aria-label="Custom Date Range"]')
    b.wait_until_present.click
    b.wait_until_present.scroll.to
    @browser.text_field(id: /fromDate/).set edge_date.strftime('%d/%m/%Y')
    @browser.text_field(id: /toDate/).set current_date

    @browser.element(css: 'button[data-semantic="apply-filter-button"]').wait_until_present.click
    @browser.element(css: 'button[data-semantic="apply-filters-button"]').wait_until_present.click
  end

  # parse transactions here
  def parse_transactions(index, transaction_html)
    currency_transaction = @accounts[index].currency
    account_name = @accounts[index].name

    date_box_selector= 'li[data-semantic="activity-group"]'
    date_selector = 'h3[data-semantic="activity-group-heading"]'

    transaction_selector = 'li[data-semantic="activity-item"]'
    description_selector = 'span[data-semantic="transaction-secondary-title"]'
    amount_selector = 'span[data-semantic="amount"]'


    @browser.elements(css: date_box_selector).each do |date_transactions_box|
      date_transaction  =  Nokogiri::HTML(date_transactions_box.html).css(date_selector).text
      date_transactions_box.wait_until_present.scroll.to # we have to wait till object will be available
      date_transactions_box.elements(css: transaction_selector).each do |transaction|
        transaction.wait_until_present.scroll.to # we have to wait till object will be available
        amount_transaction = Nokogiri::HTML(transaction.html).css(amount_selector).text.delete('$')
        description_transaction =  Nokogiri::HTML(transaction.html).css(description_selector).text
        # add data to account
        @accounts[index].add_transaction(
          date_transaction, description_transaction,
          amount_transaction, currency_transaction,
          account_name
        )
      end
    end
  end

  # in JSON file
  def save_result
    @accounts_hash = { :accounts => @accounts.map(&:to_h) }
    File.open('temp.json', 'w') do |f|
      f.write(JSON.pretty_generate(@accounts_hash))
    end
  end

  def print
    puts JSON.pretty_generate(@accounts_hash)
  end
  def execute
    connect
    fetch_accounts
    fetch_transactions
    save_result
    print
  end
end

