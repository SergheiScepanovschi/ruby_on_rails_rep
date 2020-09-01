#autor: SergheiScepanovschi
#ver 3.6
require 'date'
require 'watir'
require 'webdrivers'
require 'faker'
require 'rubygems'
require 'json'

class Transaction
  attr_accessor :date, :description, :amount # открываем доступ r/w
  def initialize(_date, _description, _amount)
    @date        = _date         #Дата
    @description = _description  #описание
    @amount      = _amount       #сумма
  end
  def exec
    puts @date, @description, @amount
  end
end

class Card
  attr_accessor :carrierName
  def initialize(_carrierName)
    @carrierName        = _carrierName       #имя владельца
  end
  def exec
    puts @carrierName
  end
end
class Accaunt
  attr_accessor :array_card
  def initialize(_nameAccaunt, _currency, _availableBalance, _classification)
    @nameAccaunt       = _nameAccaunt      #имя
    @currency          = _currency         #валюта
    @availableBalance  = _availableBalance #баланс
    @classification    = _classification   #природа
    @array_card        = Array.new         #карты
    @array_transaction = Array.new         #транзакции
  end
  # Добавляем карту
  def addCard(_carrierName)
    @array_card << Card.new(_carrierName)        #push карты
  end
  #Добавляем транзакцию
  def addTransaction(_date, _description, _amount)
    @array_transaction << Transaction.new(_date, _description, _amount)        #push карты
  end
  def exec
    puts @nameAccaunt, @currency, @availableBalance, @classification
    #@transaction.exec
    puts "===================="
    for item in @array_card do
      puts  item.exec # не подсвечивает метод
    end
    puts "===================="
  end
end

browser = Watir::Browser.new :chrome
#заходим на сайт
browser.goto "https://demo.bendigobank.com.au/banking/sign_in"
#кликаем на кнопку входа
browser.button(:name => "customer_type").click
#копируем необходимые данные
strct = browser.script(:id => "data").innertext
#Находим данные
pos1 = strct.rindex(/__DATA__/)

#одошол проблему с поиском третьего символа переноса строки нашол другую уникальную позцию
pos2 = strct.rindex(/__BOOTSTRAP_I18N__/)
pos1 =pos1+10
pos2 =pos2-69
# Выделяем строку с данными
strct = strct.slice(pos1,pos2)
puts strct
#здесь при парсинг JSON
my_hash = JSON.parse(strct)

puts "------------------------------------------------------------------------------------"
# создаём массив обььектов класса
array_accaunts = Array.new
i=0
for item in my_hash["accounts"] do

  array_accaunts << Accaunt.new(item["name"], item["currentBalance"]["currency"], item["currentBalance"]["value"],item["classification"])
  #j=0
  for card in item["cards"] do
    array_accaunts[i].addCard(card["carrierName"])
  end
  #for transaction in item["primaryActions"] do
  #  array_accaunts[i].addTransaction(transaction[semantic], transaction[semantic], _amount)
  #end
  i=i+1
end

for item in array_accaunts do
  puts  item.exec # не подсвечивает метод
  puts "+++++++++++++++++++++++++++++++++++++++++++"
end
puts "------------------------------------------------------------------------------------"