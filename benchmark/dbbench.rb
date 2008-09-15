#!/usr/local/bin/ruby -s

require 'mysql'
#class Mysql::Result
#  include Enumerable
#end
require 'motto_mysql'


class Stock0
  attr_accessor :id, :name, :url, :symbol, :price, :change, :ratio
end

class Stock1
  def initialize(*args)
    @id, @name, @url, @symbol, @price, @change, @ratio = args
  end
  attr_accessor :id, :name, :url, :symbol, :price, :change, :ratio
end

class Stock2
  def initialize(hash={})
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

#require 'mysql_helper'


def bench1(ntimes, conn, sql)
  codes = [
           'nil',
           'list=[];',
           'list=[]; rs.each{|row| }',
           'list=[]; rs.each{|row| list << row}',
           'list=[]; rs.each{|row| list<<Stock1.new(*row)}',
           #'list=[]; record.each {|row| list << Stock1.new(row) }',
           #'list=[]; for row in rs do list << Stock1.new(*row) end',
           #'list=rs.collect {|row| StockInfo.new(*row) }',
           'list=[]; rs.each_hash{|hash| list << hash}',
           'list=[]; rs.each_hash{|h| list<<Stock2.new(h)}',
           'list = rs.fetch_all_hash()',
           'list = rs.fetch_all_array()',
           'list = rs.fetch_all_object(Stock0)',
           'list=[]; rs.fetch_all_hash{|hash| list << hash}',
           'list=[]; rs.fetch_all_array{|arr| list << arr}',
           'list=[]; rs.fetch_all_object(Stock0){|o|list<<o}',
           'list=[]; rs.fetch_all_hash{|h|list<<Stock2.new(h)}',
           'list=[]; rs.fetch_all_array{|a|list<<Stock1.new(*a)}',
  ]
  init_benchmark()
  puts "*** ntimes=#{ntimes}"
  Benchmark.bm(50) do |job|
    codes.each do |code|
      GC.start()
      eval <<-END
        job.report('#{code}') do
          ntimes.times do
            result = conn.query(sql)
            rs = result
            #{code}
          end
        end
      END
    end
  end
end

def bench2(ntimes, conn, sql)
  codes = [
           'nil',
           'lst=[];',
           'lst=[]; while row=st.fetch() do end',
           'lst=[]; while row=st.fetch();lst<<row;end',
           'lst=[]; st.each{|row| lst<<row}',
           'lst=[]; st.fetch{|row| lst<<row}',
           'lst=[]; st.each{|row| lst<<Stock1.new(row)}',
           'lst = st.fetch_all_hash',
           'lst = st.fetch_all_array',
           'lst = st.fetch_all_object(Stock0)',
           'lst=[]; st.fetch_all_hash{|hash| lst<<hash}',
           'lst=[]; st.fetch_all_array{|arr| lst<<arr}',
           'lst=[]; st.fetch_all_object(Stock0){|o|lst<<o}',
           'lst=[]; st.fetch_all_hash{|h|lst<<Stock1.new(h)}',
           'lst=[]; st.fetch_all_array{|a|lst<<Stock1.new(*a)}',
  ]
  init_benchmark
  puts "*** ntimes=#{ntimes}"
  Benchmark.bm(50) do |job|
    codes.each do |code|
      GC.start()
      eval <<-END
        job.report('#{code}') do
          ntimes.times do
            st = conn.prepare(sql)
            st.execute()
            #{code}
          end
        end
      END
    end
  end
end

def init_benchmark
  require 'benchmark'
  Benchmark.module_eval do
    remove_const(:FMTSTR)
    const_set(:FMTSTR, "%6.2u %6.2y %6.2t %6.2r\n")
    remove_const(:CAPTION)
    const_set(:CAPTION, "  user    sys  total    real\n")
  end
end


def bench3(ntimes, conn, sql)
  puts "*** ntimes=#{ntimes}"
  ntimes.times do
    result = conn.query(sql)
    #result.each do |row| p row end
    #result.each do |row|
    #  stock = StockInfo.new(*row)
    #end

                                                     # 8.3 / 7.0 / 9.6 s

    #stocks = []; result.each {|row| }                 # 9.8 / 8.3 / 11.0s

    #stocks = []; result.each {|row| stocks << row}   # 8.5 / 11.2s

    #stocks = []; result.each {|row| stocks << StockInfo.new(*row) }  # 10.4 / 12.9s

    #stocks = []; for row in result do stocks << StockInfo.new(*row) end  # 10.3 / 12.9s

    #stocks = result.collect {|row| StockInfo.new(*row) }  # - / 12.9s

    #stocks = []; result.each {|row| stocks << StockInfo.new(row) }  # 10.2 / 12.8s

    #stocks = []; result.each do |row|            # 10.9 / 13.5s
    #  stocks << (stock = StockInfo.new)
    #  stock.id     = row[0]
    #  stock.name   = row[1]
    #  stock.url    = row[2]
    #  stock.symbol = row[3]
    #  stock.price  = row[4]
    #  stock.change = row[5]
    #  stock.ratio  = row[6]
    #end

    #stocks = []; result.each do |row|            # 10.4 / 13.0s
    #  stocks << (stock = StockInfo.new)
    #  stock.id, stock.name, stock.url, stock.symbol, stock.price, stock.change, stock.ratio = row
    #end

    #stocks = []; result.each_hash {|h| stocks << h }     # 11.3 / 14.0s

    #stocks = []; result.each do |row|            # 10.9 / 13.5s
    #  stocks << {
    #    'id'=>row[0], 'name'=>row[1], 'url'=>row[2], 'symbol'=>row[3],
    #    'price'=>row[4], 'change'=>row[5], 'ratio'=>row[6],
    #  }
    #end

    #stocks = []; result.each do |row|            # 10.3 / 13.0s
    #  stocks << {
    #    :id=>row[0], :name=>row[1], :url=>row[2], :symbol=>row[3],
    #    :price=>row[4], :change=>row[5], :ratio=>row[6],
    #  }
    #end

    #stocks = []; result.each do |row|            # 11.9 / 14.6s
    #  stocks << (h = {})
    #  h[:id], h[:name], h[:url], h[:symbol], h[:price], h[:change], h[:ratio] = row
    #end

    #stocks = []; result.each_hash do |hash|   # 14.3 / 16.9s
    #  stocks << (stock = StockInfo.new)
    #  stock.id     = hash['id']
    #  stock.name   = hash['name']
    #  stock.url    = hash['url']
    #  stock.symbol = hash['symbol']
    #  stock.price  = hash['price']
    #  stock.change = hash['change']
    #  stock.ratio  = hash['ratio']
    #end

    #stocks = []; result.each_hash do |hash|   # 14.1 / 16.7s
    #  stocks << StockInfo.new(hash)
    #end

    #list = result.fetch_all_hash()             # 10.6
    #list = result.fetch_all_array()            # 9.2
    list = result.fetch_all_object(Stock0)            # 10.5
    #list.each do |e| p e end
  end
end


host = 'localhost'
user = 'user1'
pass = 'passwd1'
dbname = 'example1'
conn = Mysql::connect(host, user, pass, dbname)
#sql = 'select * from stocks order by name'
sql = 'select * from stocks'
stocks = nil

if    $bench1;  bench1($N.to_i, conn, sql)
elsif $bench2;  bench2($N.to_i, conn, sql)
elsif $bench3;  bench2($N.to_i, conn, sql)
else  puts "*** error: specify -benchN (N=1,2,3)"
end

conn.close()
