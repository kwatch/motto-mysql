###
### $Rev$
### $Release: $
### $Copyright$
### $License$
###

require 'test/unit'
require 'mysql'
require 'motto_mysql'

TABLE = 'motto_mysql_test'
CREATE_TABLE = <<END
create table #{TABLE} (
  col_integer    integer,
  col_float      float,
  col_double     double,
  col_varchar    varchar(256),
  col_char       char(1),
  col_text       text,
  col_date       date,
  col_datetime   datetime,
  col_timestamp  timestamp,
  col_boolean    boolean
)
END

class MyObject
end


module MysqlTestHelper

  def setup
    @conn = Mysql.connect('localhost', 'username', 'password', 'dbname')
    tables = @conn.list_tables()
    unless tables.include?(TABLE)
      @conn.query(CREATE_TABLE)
      @conn.query("insert into #{TABLE} values(123, 3.14159, 3.141592653589793238, 'foobar', 'A', 'texttext', '2008-01-01', '2008-01-01 12:34:56', '2008-01-01 12:34:56', true)")
      @conn.query("insert into #{TABLE} values(-123, -3.14159, -3.141592653589793238, 'foobar', 'A', 'texttext', '1971-01-01', '1971-01-01 00:00:00', '1971-01-01 00:00:00', false)")
      @conn.query("insert into #{TABLE} values(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)")
    end
  end

  def teardown
    @conn.close()
  end

  def _test_hash_data(hash, id)
    #
    if id <= 1
      assert_instance_of(Fixnum, hash['col_integer'])
      assert_instance_of(Float,  hash['col_float'])
      assert_instance_of(Float,  hash['col_double'])
      assert_instance_of(String, hash['col_varchar'])
      assert_instance_of(String, hash['col_char'])
      assert_instance_of(String, hash['col_text'])
      assert_instance_of(Time,   hash['col_date'])
      assert_instance_of(Time,   hash['col_datetime'])
      assert_instance_of(Time,   hash['col_timestamp'])
      klass = id == 0 ? TrueClass : FalseClass
      assert_instance_of(klass, hash['col_boolean'])
    end
    #
    case id
    when 0
      assert_equal(123,        hash['col_integer'])
      assert_equal(3.14159,    hash['col_float'])
      assert_in_delta(3.141592653589793238, hash['col_double'], 0.00000000000001)
      assert_equal('foobar',   hash['col_varchar'])
      assert_equal('A',        hash['col_char'])
      assert_equal('texttext', hash['col_text'])
      assert_equal(Time.mktime(2008,1,1),          hash['col_date'])
      assert_equal(Time.mktime(2008,1,1,12,34,56), hash['col_datetime'])
      assert_equal(Time.mktime(2008,1,1,12,34,56), hash['col_timestamp'])
      assert_equal(true,       hash['col_boolean'])
    when 1
      assert_equal(-123,        hash['col_integer'])
      assert_equal(-3.14159,    hash['col_float'])
      assert_in_delta(-3.141592653589793238, hash['col_double'], 0.00000000000001)
      assert_equal('foobar',   hash['col_varchar'])
      assert_equal('A',        hash['col_char'])
      assert_equal('texttext', hash['col_text'])
      assert_equal(Time.mktime(1971,1,1),       hash['col_date'])
      assert_equal(Time.mktime(1971,1,1,0,0,0), hash['col_datetime'])
      assert_equal(Time.mktime(1971,1,1,0,0,0), hash['col_timestamp'])
      assert_equal(false,       hash['col_boolean'])
    when 2
      assert_nil(hash['col_integer'])
      assert_nil(hash['col_float'])
      assert_nil(hash['col_double'])
      assert_nil(hash['col_varchar'])
      assert_nil(hash['col_char'])
      assert_nil(hash['col_text'])
      assert_nil(hash['col_date'])
      assert_nil(hash['col_datetime'])
      #assert_nil(hash['col_timestamp'])
      assert_nil(hash['col_boolean'])
    end
  end

  def _test_hash_null(hash)
    assert_nil(hash['col_integer'])
    assert_nil(hash['col_float'])
    assert_nil(hash['col_double'])
    assert_nil(hash['col_varchar'])
    assert_nil(hash['col_char'])
    assert_nil(hash['col_text'])
    assert_nil(hash['col_date'])
    assert_nil(hash['col_datetime'])
    #assert_nil(hash['col_timestamp'])
    assert_nil(hash['col_boolean'])
  end


  def _test_array_data(arr, id)
    #
    if id <= 1
      assert_instance_of(Fixnum, arr[0])
      assert_instance_of(Float,  arr[1])
      assert_instance_of(Float,  arr[2])
      assert_instance_of(String, arr[3])
      assert_instance_of(String, arr[4])
      assert_instance_of(String, arr[5])
      assert_instance_of(Time,   arr[6])
      assert_instance_of(Time,   arr[7])
      assert_instance_of(Time,   arr[8])
      klass = id == 0 ? TrueClass : FalseClass
      assert_instance_of(klass, arr[9])
    end
    #
    case id
    when 0
      assert_equal(123,        arr[0])
      assert_equal(3.14159,    arr[1])
      assert_in_delta(3.141592653589793238, arr[2], 0.00000000000001)
      assert_equal('foobar',   arr[3])
      assert_equal('A',        arr[4])
      assert_equal('texttext', arr[5])
      assert_equal(Time.mktime(2008,1,1),          arr[6])
      assert_equal(Time.mktime(2008,1,1,12,34,56), arr[7])
      assert_equal(Time.mktime(2008,1,1,12,34,56), arr[8])
      assert_equal(true,       arr[9])
    when 1
      assert_equal(-123,       arr[0])
      assert_equal(-3.14159,   arr[1])
      assert_in_delta(-3.141592653589793238, arr[2], 0.00000000000001)
      assert_equal('foobar',   arr[3])
      assert_equal('A',        arr[4])
      assert_equal('texttext', arr[5])
      assert_equal(Time.mktime(1971,1,1),       arr[6])
      assert_equal(Time.mktime(1971,1,1,0,0,0), arr[7])
      assert_equal(Time.mktime(1971,1,1,0,0,0), arr[8])
      assert_equal(false,       arr[9])
    when 2
      assert_nil(arr[0])
      assert_nil(arr[1])
      assert_nil(arr[2])
      assert_nil(arr[3])
      assert_nil(arr[4])
      assert_nil(arr[5])
      assert_nil(arr[6])
      assert_nil(arr[7])
      #assert_nil(arr[8])
      assert_nil(arr[9])
    end
  end

  def _test_array_null(arr)
    #
    assert_nil(arr[0])
    assert_nil(arr[1])
    assert_nil(arr[2])
    assert_nil(arr[3])
    assert_nil(arr[4])
    assert_nil(arr[5])
    assert_nil(arr[6])
    assert_nil(arr[7])
    #assert_nil(arr[8])
    assert_nil(arr[9])
  end


  def _test_object_data(obj, index)
    #
    if index <= 1
      assert_instance_of(Fixnum, obj.instance_variable_get('@col_integer'))
      assert_instance_of(Float,  obj.instance_variable_get('@col_float'))
      assert_instance_of(Float,  obj.instance_variable_get('@col_double'))
      assert_instance_of(String, obj.instance_variable_get('@col_varchar'))
      assert_instance_of(String, obj.instance_variable_get('@col_char'))
      assert_instance_of(String, obj.instance_variable_get('@col_text'))
      assert_instance_of(Time,   obj.instance_variable_get('@col_date'))
      assert_instance_of(Time,   obj.instance_variable_get('@col_datetime'))
      assert_instance_of(Time,   obj.instance_variable_get('@col_timestamp'))
      klass = index == 0 ? TrueClass : FalseClass
      assert_instance_of(klass, obj.instance_variable_get('@col_boolean'))
    end
    #
    case index
    when 0
      assert_equal(123,        obj.instance_variable_get('@col_integer'))
      assert_equal(3.14159,       obj.instance_variable_get('@col_float'))
      assert_in_delta(3.141592653589793238, obj.instance_variable_get('@col_double'), 0.00000000000001)
      assert_equal('foobar',   obj.instance_variable_get('@col_varchar'))
      assert_equal('A',        obj.instance_variable_get('@col_char'))
      assert_equal('texttext', obj.instance_variable_get('@col_text'))
      assert_equal(Time.mktime(2008,1,1),          obj.instance_variable_get('@col_date'))
      assert_equal(Time.mktime(2008,1,1,12,34,56), obj.instance_variable_get('@col_datetime'))
      assert_equal(Time.mktime(2008,1,1,12,34,56), obj.instance_variable_get('@col_timestamp'))
      assert_equal(true,       obj.instance_variable_get('@col_boolean'))
    when 1
      assert_equal(-123,        obj.instance_variable_get('@col_integer'))
      assert_equal(-3.14159,       obj.instance_variable_get('@col_float'))
      assert_in_delta(-3.141592653589793238, obj.instance_variable_get('@col_double'), 0.00000000000001)
      assert_equal('foobar',   obj.instance_variable_get('@col_varchar'))
      assert_equal('A',        obj.instance_variable_get('@col_char'))
      assert_equal('texttext', obj.instance_variable_get('@col_text'))
      assert_equal(Time.mktime(1971,1,1),       obj.instance_variable_get('@col_date'))
      assert_equal(Time.mktime(1971,1,1,0,0,0), obj.instance_variable_get('@col_datetime'))
      assert_equal(Time.mktime(1971,1,1,0,0,0), obj.instance_variable_get('@col_timestamp'))
      assert_equal(false,       obj.instance_variable_get('@col_boolean'))
    when 2
      assert_nil(obj.instance_variable_get('@col_integer'))
      assert_nil(obj.instance_variable_get('@col_float'))
      assert_nil(obj.instance_variable_get('@col_double'))
      assert_nil(obj.instance_variable_get('@col_varchar'))
      assert_nil(obj.instance_variable_get('@col_char'))
      assert_nil(obj.instance_variable_get('@col_text'))
      assert_nil(obj.instance_variable_get('@col_date'))
      assert_nil(obj.instance_variable_get('@col_datetime'))
      #assert_nil(obj.instance_variable_get('@col_timestamp'))
      assert_nil(obj.instance_variable_get('@col_boolean'))
    end
  end

  def _test_object_null(obj)
    assert_nil(obj.instance_variable_get('@col_integer'))
    assert_nil(obj.instance_variable_get('@col_float'))
    assert_nil(obj.instance_variable_get('@col_double'))
    assert_nil(obj.instance_variable_get('@col_varchar'))
    assert_nil(obj.instance_variable_get('@col_char'))
    assert_nil(obj.instance_variable_get('@col_text'))
    assert_nil(obj.instance_variable_get('@col_date'))
    assert_nil(obj.instance_variable_get('@col_datetime'))
    #assert_nil(obj.instance_variable_get('@col_timestamp'))
    assert_nil(obj.instance_variable_get('@col_boolean'))
  end

  def _test_result_free(result=@result)
    ex = assert_raise(Mysql::Error) { result.free() }
    errmsg = 'Mysql::Result object is already freed'
    assert_equal(errmsg, ex.message)
  end

  def _test_stmt_close(stmt=@stmt)
    ex = assert_raise(Mysql::Error) { stmt.close() }
    errmsg = 'Mysql::Stmt object is already closed'
    assert_equal(errmsg, ex.message)
  end

end


class MysqlResultTest < Test::Unit::TestCase
  include MysqlTestHelper

  def setup
    super
    @results = [
      @conn.query("select * from #{TABLE} where col_integer > 0"),
      @conn.query("select * from #{TABLE} where col_integer < 0"),
      @conn.query("select * from #{TABLE} where col_integer is null"),
    ]
    @result = @conn.query("select * from #{TABLE}")
  end

  def teardown
    begin @result.free; rescue => ex; end
    begin @results[0].free; rescue => ex; end
    begin @results[1].free; rescue => ex; end
    begin @results[2].free; rescue => ex; end
  end


  def test_fetch_one_hash
    (0..2).each do |i|
      result = @results[i]
      hash = result.fetch_one_hash()
      assert_instance_of(Hash, hash)
      _test_hash_data(hash, i)
      _test_result_free(result)
    end
  end

  def test_fetch_one_array
    (0..2).each do |i|
      result = @results[i]
      array = result.fetch_one_array()
      assert_instance_of(Array, array)
      _test_array_data(array, i)
      _test_result_free(result)
    end
  end

  def test_fetch_one_object
    (0..2).each do |i|
      result = @results[i]
      obj = result.fetch_one_object(MyObject)
      assert_instance_of(MyObject, obj)
      _test_object_data(obj, i)
      _test_result_free(result)
    end
  end

  def test_fetch_all_hash
    hashes = @result.fetch_all_hash()
    assert_instance_of(Array,  hashes)
    assert_instance_of(Hash, hashes[0])
    _test_hash_data(hashes[0], 0)
    _test_hash_data(hashes[1], 1)
    _test_hash_data(hashes[2], 2)
    _test_result_free(@result)
  end

  def test_fetch_all_array
    arrays = @result.fetch_all_array()
    assert_instance_of(Array, arrays)
    assert_instance_of(Array, arrays[0])
    _test_array_data(arrays[0], 0)
    _test_array_data(arrays[1], 1)
    _test_array_data(arrays[2], 2)
    _test_result_free(@result)
  end

  def test_fetch_all_object
    objs = @result.fetch_all_object(MyObject)
    assert_instance_of(Array, objs)
    assert_instance_of(MyObject, objs[0])
    _test_object_data(objs[0], 0)
    _test_object_data(objs[1], 1)
    _test_object_data(objs[2], 2)
    _test_result_free(@result)
  end

  def test_fetch_all_hash_with_block
    i = 0
    @result.fetch_all_hash() do |hash|
      _test_hash_data(hash, i)
      i += 1
    end
    _test_result_free(@result)
  end

  def test_fetch_all_array_with_block
    i = 0
    @result.fetch_all_array() do |arr|
      _test_array_data(arr, i)
      i += 1
    end
    _test_result_free(@result)
  end

  def test_fetch_all_object_with_block
    i = 0
    @result.fetch_all_object(MyObject) do |obj|
      _test_object_data(obj, i)
      i += 1
    end
    _test_result_free(@result)
  end

end


class MysqlStatementTest < Test::Unit::TestCase
  include MysqlTestHelper

  def setup
    super
    @stmts = [
      @conn.prepare("select * from #{TABLE} where col_integer > 0"),
      @conn.prepare("select * from #{TABLE} where col_integer < 0"),
      @conn.prepare("select * from #{TABLE} where col_integer is null"),
    ]
    @stmt = @conn.prepare("select * from #{TABLE}")
    @stmt.execute
  end

  def teardown
    begin @stmt.close; rescue => ex; end
    begin @stmts[0].close; rescue => ex; end
    begin @stmts[1].close; rescue => ex; end
    begin @stmts[2].close; rescue => ex; end
  end


  def test_fetch_one_hash
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      hash = stmt.fetch_one_hash()
      assert_instance_of(Hash, hash)
      _test_hash_data(hash, i)
      _test_stmt_close(stmt)
    end
  end

  def test_fetch_one_array
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      array = stmt.fetch_one_array()
      assert_instance_of(Array, array)
      _test_array_data(array, i)
      _test_stmt_close(stmt)
    end
  end

  def test_fetch_one_object
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      obj = stmt.fetch_one_object(MyObject)
      assert_instance_of(MyObject, obj)
      _test_object_data(obj, i)
      _test_stmt_close(stmt)
    end
  end

  def test_fetch_all_hash
    hashes = @stmt.fetch_all_hash()
    assert_instance_of(Array, hashes)
    assert_instance_of(Hash, hashes[0])
    _test_hash_data(hashes[0], 0)
    _test_hash_data(hashes[1], 1)
    _test_hash_data(hashes[2], 2)
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_array
    arrays = @stmt.fetch_all_array()
    assert_instance_of(Array, arrays)
    assert_instance_of(Array, arrays[0])
    _test_array_data(arrays[0], 0)
    _test_array_data(arrays[1], 1)
    _test_array_data(arrays[2], 2)
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_object
    objs = @stmt.fetch_all_object(MyObject)
    assert_instance_of(Array, objs)
    assert_instance_of(MyObject, objs[0])
    _test_object_data(objs[0], 0)
    _test_object_data(objs[1], 1)
    _test_object_data(objs[2], 2)
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_hash_with_block
    i = 0
    @stmt.fetch_all_hash() do |hash|
      _test_hash_data(hash, i)
      i += 1
    end
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_array_with_block
    i = 0
    @stmt.fetch_all_array() do |arr|
      _test_array_data(arr, i)
      i += 1
    end
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_object_with_block
    i = 0
    @stmt.fetch_all_object(MyObject) do |arr|
      _test_object_data(arr, i)
      i += 1
    end
    _test_stmt_close(@stmt)
  end

end
