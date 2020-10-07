# frozen_string_literal: true

# Information
# autor: Serghei Scepanovschi
# examplebank.rb ver 1.1
#

require 'date'
require 'json'
require 'nokogiri'
require 'watir'
require 'pry'
require 'webdrivers'
require_relative 'account'
# scroll down to bottom to find "No more activity" string

# main class to fetch and parse our site
class ExampleBank
  attr_accessor :browser , :accounts
  def initialize()
    @browser     = Watir::Browser.new :firefox
    @accounts    = []
  end

  def accounts
    @accounts
  end

  def connect
    # here you log in to the bank
    @browser.goto 'https://demo.bendigobank.com.au/banking/sign_in'
    @browser.button(name: 'customer_type').click
  end

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
    transaction_css_selector = 'li[data-semantic="activity-item"]'
    sleep 6
    @browser.elements(css: account_css_selector).each_with_index do |build, index|
      # binding.pry
      build.wait_until_present.click
      # set date for 2 month
      set_data_filter
      scroll_to_bottom
      # go to transactions
      @browser.elements(css: transaction_css_selector).each do |transaction|
        transaction.wait_until_present.scroll.to # we have to wait till object will be available
        sleep 2
        transaction.click
        sleep 2
        parse_transactions(index, @browser.html)
        @browser.back
        sleep 3
      end
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
    two_month = 5
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
    header_css_selector = 'span[data-semantic="payment-amount"]'
    properties_css_selector = 'nav[class="uilist"] > div[class="uilist__item"]'
    label__css_selector = 'span[class="uilist__item__label"]'
    detail_css_selector = 'span[class="uilist__item__label"] + span[class="uilist__item__detail"]'
    label_list = ['Paid on', 'Payment Date', 'Description']
    currency_transaction = @accounts[index].currency
    account_name = @accounts[index].name

    header_transaction = Nokogiri::HTML(transaction_html).css(header_css_selector)
    properties_transaction = Nokogiri::HTML(transaction_html).css(properties_css_selector)
    amount_transaction = header_transaction.children.last.text.delete('$')
    container_attributes = []
    properties_transaction.each do |list_item|
      label_item = list_item.css(label__css_selector).text
      detail_item = list_item.css(detail_css_selector)
      detail_item = detail_item ? detail_item.text : 'None'
      array_atr = [label_item, detail_item]
      container_attributes << array_atr
    end

    date = {}
    container_attributes.each do |item_atr|
      if item_atr.first.eql?(label_list.first) || item_atr.first.eql?(label_list[1])
        date[:date] = Date.parse(item_atr[1])
      elsif item_atr[0].eql?(label_list[2])
        date[:any] = item_atr[1]
      end
    end
    date_transaction = date[:date]
    description_transaction = date[:any]
    @accounts[index].add_transaction(
      date_transaction, description_transaction,
      amount_transaction, currency_transaction,
      account_name
    )
  end

  # in JSON file
  def save_result
    #temp_hash = @accounts.map(&:to_h).to_json
    my_object = { :accounts => @accounts.map(&:to_h) }
    File.open('temp.json', 'w') do |f|
      f.write(JSON.pretty_generate(my_object))
    end
  end

  def execute
    connect
    fetch_accounts
    fetch_transactions
    save_result
  end
end

