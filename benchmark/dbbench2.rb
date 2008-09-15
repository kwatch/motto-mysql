#!/usr/local/bin/ruby

require 'mysql'
class Mysql::Result
  include Enumerable
end

class StockInfo
  def initialize(*args)
  #def initialize(args)
  #def populate_array(*args)
    @id, @name, @url, @symbol, @price, @change, @ratio = args
  end
  #def initialize(hash={})
  def populate(hash={})
    @id     = hash['id']
    @name   = hash['name']
    @url    = hash['url']
    @symbol = hash['symbol']
    @price  = hash['price']
    @change = hash['change']
    @ratio  = hash['ratio']
  end
  attr_accessor :id, :name, :url, :symbol, :price, :change, :ratio
end

host = 'localhost'
user = 'user1'
pass = 'passwd1'
dbname = 'example1'

use_dbi = $DBI

if use_dbi
  require 'dbi'
  database = "DBI:Mysql:#{dbname}:#{host}"
  conn = DBI.connect(database, user, pass)
else
  conn = Mysql::connect(host, user, pass, dbname)
end

#sql = 'select * from stocks order by name'
sql = 'select * from stocks'
stocks = nil
$N.to_i.times do
  stmt = conn.prepare(sql)
  stmt.execute()
  #while row = stmt.fetch() do p row end                   # mysql / DBI

  #while row = stmt.fetch() do end                          # 9.5 / 32.1

  #list = []; while row = stmt.fetch(); list << row end     # 9.6  / 32.3

  #list = []; stmt.each do |row| list << row end              # 9.6  /
  #list = []; stmt.fetch do |row| list << row end                    / 32.2

  #list = []; while row = stmt.fetch_array; list << row; end  #      / 31.8
  #list = []; while hash = stmt.fetch_hash; list << hash; end #      / 37.7
  #list = []; stmt.fetch_array do |row| list << row end       #      / 31.7
  #list = []; stmt.fetch_hash do |hash| list << hash end      #      / 37.1

  #list = stmt.collect {|row| list << row}             #

  list = stmt.fetch_all_rows                                # 10.1 /

  #list = stmt.fetch_all_hash()                             # 11.6 / 
  #list = stmt.fetch_all_hashes2()                         
  #list.each {|item| p item}

  #list = []                                                # 12.3 / 
  #while row = stmt.fetch()
  #  list << StockInfo.new(*row)
  #end

  #list = []                                                # 13.0 /
  #while row = stmt.fetch()
  #  list << { 'id'=>row[0], 'name'=>row[1], 'url'=>row[2], 'symbol'=>row[3],
  #            'price'=>row[4], 'change'=>row[5], 'ratio'=>row[6], }
  #end

  #list = []                                                # 12.3 /
  #stmt.each do |row|
  #  list << { :id=>row[0], :name=>row[1], :url=>row[2], :symbol=>row[3],
  #            :price=>row[4], :change=>row[5], :ratio=>row[6], }
  #end

  stmt.close()

end
if $P; p stocks; end
if use_dbi
  conn.disconnect()
else
  conn.close()
end
