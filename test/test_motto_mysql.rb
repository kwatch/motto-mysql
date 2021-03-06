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


module MottoMysqlTestHelper

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
      assert_instance_of(Date,     hash['col_date'])
      assert_instance_of(DateTime, hash['col_datetime'])
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
      assert_equal(Date.new(    2008,1,1),          hash['col_date'])
      assert_equal(DateTime.new(2008,1,1,12,34,56), hash['col_datetime'])
      assert_equal(Time.mktime(2008,1,1,12,34,56), hash['col_timestamp'])
      assert_equal(true,       hash['col_boolean'])
    when 1
      assert_equal(-123,        hash['col_integer'])
      assert_equal(-3.14159,    hash['col_float'])
      assert_in_delta(-3.141592653589793238, hash['col_double'], 0.00000000000001)
      assert_equal('foobar',   hash['col_varchar'])
      assert_equal('A',        hash['col_char'])
      assert_equal('texttext', hash['col_text'])
      assert_equal(Date.new(    1971,1,1),       hash['col_date'])
      assert_equal(DateTime.new(1971,1,1,0,0,0), hash['col_datetime'])
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
      assert_instance_of(Date,     arr[6])
      assert_instance_of(DateTime, arr[7])
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
      assert_equal(Date.new(    2008,1,1),          arr[6])
      assert_equal(DateTime.new(2008,1,1,12,34,56), arr[7])
      assert_equal(Time.mktime(2008,1,1,12,34,56), arr[8])
      assert_equal(true,       arr[9])
    when 1
      assert_equal(-123,       arr[0])
      assert_equal(-3.14159,   arr[1])
      assert_in_delta(-3.141592653589793238, arr[2], 0.00000000000001)
      assert_equal('foobar',   arr[3])
      assert_equal('A',        arr[4])
      assert_equal('texttext', arr[5])
      assert_equal(Date.new(    1971,1,1),       arr[6])
      assert_equal(DateTime.new(1971,1,1,0,0,0), arr[7])
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
      assert_instance_of(Date,     obj.instance_variable_get('@col_date'))
      assert_instance_of(DateTime, obj.instance_variable_get('@col_datetime'))
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
      assert_equal(Date.new(    2008,1,1),          obj.instance_variable_get('@col_date'))
      assert_equal(DateTime.new(2008,1,1,12,34,56), obj.instance_variable_get('@col_datetime'))
      assert_equal(Time.mktime(2008,1,1,12,34,56), obj.instance_variable_get('@col_timestamp'))
      assert_equal(true,       obj.instance_variable_get('@col_boolean'))
    when 1
      assert_equal(-123,        obj.instance_variable_get('@col_integer'))
      assert_equal(-3.14159,       obj.instance_variable_get('@col_float'))
      assert_in_delta(-3.141592653589793238, obj.instance_variable_get('@col_double'), 0.00000000000001)
      assert_equal('foobar',   obj.instance_variable_get('@col_varchar'))
      assert_equal('A',        obj.instance_variable_get('@col_char'))
      assert_equal('texttext', obj.instance_variable_get('@col_text'))
      assert_equal(Date.new(    1971,1,1),       obj.instance_variable_get('@col_date'))
      assert_equal(DateTime.new(1971,1,1,0,0,0), obj.instance_variable_get('@col_datetime'))
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

  def _test_result_free!(result=@result)
    assert_nothing_raised(Mysql::Error) { result.free() }
  end

  def _test_stmt_close(stmt=@stmt)
    ex = assert_raise(Mysql::Error) { stmt.close() }
    errmsg = 'Mysql::Stmt object is already closed'
    assert_equal(errmsg, ex.message)
  end

  def _test_stmt_close!(stmt=@stmt)
    assert_nothing_raised(Mysql::Error) { stmt.close() }
  end

end


class MottoMysqlTest < Test::Unit::TestCase

  def test_motto_mysql_version
    ## Mysql::MOTTO_MYSQL_VERSION is a frozen string
    s = Mysql.const_get('MOTTO_MYSQL_VERSION')
    assert_not_nil(s)
    assert_instance_of(String, s)
    ex = assert_raise(TypeError) do
      s << "123"
    end
    assert_equal("can't modify frozen string", ex.message)
  end

end


class MottoMysqlResultTest < Test::Unit::TestCase
  include MottoMysqlTestHelper

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


  def test_fetch_as_hash
    (0..2).each do |i|
      result = @results[i]
      hash = result.fetch_as_hash()
      assert_instance_of(Hash, hash)
      _test_hash_data(hash, i)
      _test_result_free(result)
    end
  end

  def test_fetch_as_hash!
    (0..2).each do |i|
      result = @results[i]
      hash = result.fetch_as_hash!()
      assert_instance_of(Hash, hash)
      _test_hash_data(hash, i)
      _test_result_free!(result)
    end
  end


  def test_fetch_as_array
    (0..2).each do |i|
      result = @results[i]
      array = result.fetch_as_array()
      assert_instance_of(Array, array)
      _test_array_data(array, i)
      _test_result_free(result)
    end
  end

  def test_fetch_as_array!
    (0..2).each do |i|
      result = @results[i]
      array = result.fetch_as_array!()
      assert_instance_of(Array, array)
      _test_array_data(array, i)
      _test_result_free!(result)
    end
  end


  def test_fetch_as_object
    (0..2).each do |i|
      result = @results[i]
      obj = result.fetch_as_object(MyObject)
      assert_instance_of(MyObject, obj)
      _test_object_data(obj, i)
      _test_result_free(result)
    end
  end

  def test_fetch_as_object!
    (0..2).each do |i|
      result = @results[i]
      obj = result.fetch_as_object!(MyObject)
      assert_instance_of(MyObject, obj)
      _test_object_data(obj, i)
      _test_result_free!(result)
    end
  end


  def test_fetch_all_as_hashes
    hashes = @result.fetch_all_as_hashes()
    _test_fetch_all_as_hashes(hashes)
    _test_result_free(@result)
  end

  def test_fetch_all_as_hashes!
    hashes = @result.fetch_all_as_hashes!()
    _test_fetch_all_as_hashes(hashes)
    _test_result_free!(@result)
  end

  def _test_fetch_all_as_hashes(hashes)
    assert_instance_of(Array,  hashes)
    assert_instance_of(Hash, hashes[0])
    _test_hash_data(hashes[0], 0)
    _test_hash_data(hashes[1], 1)
    _test_hash_data(hashes[2], 2)
  end


  def test_fetch_all_as_arrays
    arrays = @result.fetch_all_as_arrays()
    _test_fetch_all_as_arrays(arrays)
    _test_result_free(@result)
  end

  def test_fetch_all_as_arrays!
    arrays = @result.fetch_all_as_arrays!()
    _test_fetch_all_as_arrays(arrays)
    _test_result_free!(@result)
  end

  def _test_fetch_all_as_arrays(arrays)
    assert_instance_of(Array, arrays)
    assert_instance_of(Array, arrays[0])
    _test_array_data(arrays[0], 0)
    _test_array_data(arrays[1], 1)
    _test_array_data(arrays[2], 2)
  end


  def test_fetch_all_as_objects
    objs = @result.fetch_all_as_objects(MyObject)
    _test_fetch_all_as_objects(objs)
    _test_result_free(@result)
  end

  def test_fetch_all_as_objects!
    objs = @result.fetch_all_as_objects!(MyObject)
    _test_fetch_all_as_objects(objs)
    _test_result_free!(@result)
  end

  def _test_fetch_all_as_objects(objs)
    assert_instance_of(Array, objs)
    assert_instance_of(MyObject, objs[0])
    _test_object_data(objs[0], 0)
    _test_object_data(objs[1], 1)
    _test_object_data(objs[2], 2)
  end


  def test_fetch_all_as_hashes_with_block
    i = 0
    @result.fetch_all_as_hashes() do |hash|
      _test_hash_data(hash, i)
      i += 1
    end
    _test_result_free(@result)
  end

  def test_fetch_all_as_hashes_with_block!
    i = 0
    @result.fetch_all_as_hashes!() do |hash|
      _test_hash_data(hash, i)
      i += 1
    end
    _test_result_free!(@result)
  end


  def test_fetch_all_as_arrays_with_block
    i = 0
    @result.fetch_all_as_arrays() do |arr|
      _test_array_data(arr, i)
      i += 1
    end
    _test_result_free(@result)
  end

  def test_fetch_all_as_arrays_with_block!
    i = 0
    @result.fetch_all_as_arrays!() do |arr|
      _test_array_data(arr, i)
      i += 1
    end
    _test_result_free!(@result)
  end


  def test_fetch_all_as_objects_with_block
    i = 0
    @result.fetch_all_as_objects(MyObject) do |obj|
      _test_object_data(obj, i)
      i += 1
    end
    _test_result_free(@result)
  end

  def test_fetch_all_as_objects_with_block!
    i = 0
    @result.fetch_all_as_objects!(MyObject) do |obj|
      _test_object_data(obj, i)
      i += 1
    end
    _test_result_free!(@result)
  end

end


class MottoMysqlStatementTest < Test::Unit::TestCase
  include MottoMysqlTestHelper

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


  def test_fetch_as_hash
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      hash = stmt.fetch_as_hash()
      assert_instance_of(Hash, hash)
      _test_hash_data(hash, i)
      _test_stmt_close(stmt)
    end
  end

  def test_fetch_as_hash!
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      hash = stmt.fetch_as_hash!()
      assert_instance_of(Hash, hash)
      _test_hash_data(hash, i)
      _test_stmt_close!(stmt)
    end
  end


  def test_fetch_as_array
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      array = stmt.fetch_as_array()
      assert_instance_of(Array, array)
      _test_array_data(array, i)
      _test_stmt_close(stmt)
    end
  end

  def test_fetch_as_array!
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      array = stmt.fetch_as_array!()
      assert_instance_of(Array, array)
      _test_array_data(array, i)
      _test_stmt_close!(stmt)
    end
  end


  def test_fetch_as_object
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      obj = stmt.fetch_as_object(MyObject)
      assert_instance_of(MyObject, obj)
      _test_object_data(obj, i)
      _test_stmt_close(stmt)
    end
  end

  def test_fetch_as_object!
    (0..2).each do |i|
      (stmt = @stmts[i]).execute()
      obj = stmt.fetch_as_object!(MyObject)
      assert_instance_of(MyObject, obj)
      _test_object_data(obj, i)
      _test_stmt_close!(stmt)
    end
  end


  def test_fetch_all_as_hashes
    hashes = @stmt.fetch_all_as_hashes()
    _test_fetch_all_as_hashes(hashes)
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_as_hashes!
    hashes = @stmt.fetch_all_as_hashes!()
    _test_fetch_all_as_hashes(hashes)
    _test_stmt_close!(@stmt)
  end

  def _test_fetch_all_as_hashes(hashes)
    assert_instance_of(Array, hashes)
    assert_instance_of(Hash, hashes[0])
    _test_hash_data(hashes[0], 0)
    _test_hash_data(hashes[1], 1)
    _test_hash_data(hashes[2], 2)
  end


  def test_fetch_all_as_arrays
    arrays = @stmt.fetch_all_as_arrays()
    _test_fetch_all_as_arrays(arrays)
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_as_arrays!
    arrays = @stmt.fetch_all_as_arrays!()
    _test_fetch_all_as_arrays(arrays)
    _test_stmt_close!(@stmt)
  end

  def _test_fetch_all_as_arrays(arrays)
    assert_instance_of(Array, arrays)
    assert_instance_of(Array, arrays[0])
    _test_array_data(arrays[0], 0)
    _test_array_data(arrays[1], 1)
    _test_array_data(arrays[2], 2)
  end


  def test_fetch_all_as_objects
    objs = @stmt.fetch_all_as_objects(MyObject)
    _test_fetch_all_as_objects(objs)
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_as_objects!
    objs = @stmt.fetch_all_as_objects!(MyObject)
    _test_fetch_all_as_objects(objs)
    _test_stmt_close!(@stmt)
  end

  def _test_fetch_all_as_objects(objs)
    assert_instance_of(Array, objs)
    assert_instance_of(MyObject, objs[0])
    _test_object_data(objs[0], 0)
    _test_object_data(objs[1], 1)
    _test_object_data(objs[2], 2)
  end


  def test_fetch_all_as_hashes_with_block
    i = 0
    @stmt.fetch_all_as_hashes() do |hash|
      _test_hash_data(hash, i)
      i += 1
    end
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_as_hashes_with_block!
    i = 0
    @stmt.fetch_all_as_hashes!() do |hash|
      _test_hash_data(hash, i)
      i += 1
    end
    _test_stmt_close!(@stmt)
  end


  def test_fetch_all_as_arrays_with_block
    i = 0
    @stmt.fetch_all_as_arrays() do |arr|
      _test_array_data(arr, i)
      i += 1
    end
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_as_arrays_with_block!
    i = 0
    @stmt.fetch_all_as_arrays!() do |arr|
      _test_array_data(arr, i)
      i += 1
    end
    _test_stmt_close!(@stmt)
  end


  def test_fetch_all_as_objects_with_block
    i = 0
    @stmt.fetch_all_as_objects(MyObject) do |arr|
      _test_object_data(arr, i)
      i += 1
    end
    _test_stmt_close(@stmt)
  end

  def test_fetch_all_as_objects_with_block!
    i = 0
    @stmt.fetch_all_as_objects!(MyObject) do |arr|
      _test_object_data(arr, i)
      i += 1
    end
    _test_stmt_close!(@stmt)
  end

end


class InstanceVariableNameLengthTest < Test::Unit::TestCase
  include MottoMysqlTestHelper

  TABLE  =  'foo123'
  COLUMN =  '_123456789_123456789_123456789_123456789'
  IVAR   = '@_123456789_123456789_123456789'

  def setup
    super
    @conn.query("drop table if exists #{TABLE}")
    @conn.query("create table #{TABLE}(#{COLUMN} integer)")
    @conn.query("insert into #{TABLE} values(123)")
  end

  def teardown
    @conn.query("drop table if exists #{TABLE}")
    super
  end

  def test_ivar_name_length_for_result_fetch_as_object
    result = @conn.query("select * from #{TABLE}")
    obj = result.fetch_as_object(MyObject)
    assert_equal([IVAR], obj.instance_variables)
  end

  def test_ivar_name_length_for_result_fetch_all_as_objects
    result = @conn.query("select * from #{TABLE}")
    objs = result.fetch_all_as_objects(MyObject)
    assert_equal([IVAR], objs[0].instance_variables)
  end

  def test_ivar_name_length_for_stmt_fetch_as_object
    stmt = @conn.prepare("select * from #{TABLE}")
    stmt.execute()
    obj = stmt.fetch_as_object(MyObject)
    assert_equal([IVAR], obj.instance_variables)
  end

  def test_ivar_name_length_for_stmt_fetch_all_as_objects
    stmt = @conn.prepare("select * from #{TABLE}")
    stmt.execute()
    objs = stmt.fetch_all_as_objects(MyObject)
    assert_equal([IVAR], objs[0].instance_variables)
  end

end



class CreateTimestampTest < Test::Unit::TestCase

  def test_create_timestamp
    actual = Mysql.create_timestamp(2001, 2, 3, 12, 34, 56, nil, nil)
    assert_instance_of(Time, actual)
    assert_equal(Time.mktime(2001, 2, 3, 12, 34, 56), actual)
  end

  def test_create_datetime
    actual = Mysql.create_datetime(2001, 2, 3, 12, 34, 56, nil, nil)
    assert_instance_of(DateTime, actual)
    assert_equal(DateTime.new(2001, 2, 3, 12, 34, 56), actual)
  end

  def test_create_date
    actual = Mysql.create_date(2001, 2, 3, nil, nil)
    assert_instance_of(Date, actual)
    assert_equal(Date.new(2001, 2, 3), actual)
  end

  def test_create_time
    actual = Mysql.create_time(12, 34, 56, nil, nil)
    assert_instance_of(Time, actual)
    assert_equal(Time.mktime(1970, 1, 1, 12, 34, 56), actual)
  end

  def test_create_timestamp_or_datetime
    actual = Mysql.create_timestamp_or_datetime(1969, 12, 31, 23, 59, 59, nil, nil)
    assert_instance_of(DateTime, actual)
    assert_equal(DateTime.new(1969, 12, 31, 23, 59, 59), actual)
    #
    actual = Mysql.create_timestamp_or_datetime(1970, 1, 1, 0, 0, 0, nil, nil)
    assert_instance_of(Time, actual)
    assert_equal(Time.mktime(1970, 1, 1, 0, 0, 0), actual)
    #
    actual = Mysql.create_timestamp_or_datetime(2037, 12, 31, 23, 59, 59, nil, nil)
    assert_instance_of(Time, actual)
    assert_equal(Time.mktime(2037, 12, 31, 23, 59, 59), actual)
    #
    actual = Mysql.create_timestamp_or_datetime(2038, 1, 1, 0, 0, 0, nil, nil)
    assert_instance_of(DateTime, actual)
    assert_equal(DateTime.new(2038, 1, 1, 0, 0, 0), actual)
  end

end
