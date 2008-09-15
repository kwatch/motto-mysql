= README.txt

Release: $Release$

$Copyright$

http://rubyforge.org/projects/motto-mysql/


==  About

'Motto-mysql' is a complementary library to enhance 'mysql-ruby'.
It adds some methods into Mysql::Result and Mysql::Stmt classes.

Motto-mysql requires mysql-ruby 2.7.4 or later (recommended 2.7.5 or later).


== Features

* Add 'fetch_one_{hash,array,object}()' and 'fetch_all_{hash,array,object}()'
  methods into Mysql::Result and Mysql::Stmt classes.
  These methods returns proper data instead of String.
  For example, you can get 123 instead of "123", true/false instead of "1"/"0".

* Time object will be returned instead of Mysql::Time.

* True or false will be returned instead of 1 or 0 if column type is tinyint.

* 3.14 will be returned when Mysql::Stmt.fetch() returns 3.14000010490417.


==  Install

1. Be sure that header files of Ruby and MySQL are installed.
2. Install mysql-ruby (>= 2.7.4) if not installed yet.
3. Install motto-mysql.

The following is an example of steps to install.

    ### install mysql-ruby (if not installed yet)
    $ tar xzf mysql-ruby-2.8pre4.tar.gz
    $ cd mysql-ruby-2.8pre4
    $ ruby extconf.rb --with-mysql-dir=/usr/local/mysql
    $ make
    $ sudo make install
    $ cd ..
    ### install motto-mysql
    $ tar xzf motto-mysql-$Release$.tar.gz
    $ cd motto-mysql-$Release$
    $ ruby extconf.rb --with-mysql-dir=/usr/local/mysql
    $ make
    $ sudo make install


== Example

    require 'mysql'
    require 'motto_mysql'
    
    conn = Mysql.connect('localhost', 'username', 'password', 'dbname')
    sql = 'select * from items';
    
    ### Mysql::Result#fetch_hash() vs. Mysql::Result#fetch_one_hash()
    result = conn.query(sql)
    p result.fetch_hash      #=> {"id"=>"1", "name"=>"foo", "price"=>"3.14",
                             #    "created_at"=>#<Mysql::Time>, "flag"=>"1" }
    result.free()
    result = conn.query(sql)
    p result.fetch_one_hash  #=> {"id"=>1, "name"=>"foo", "price"=>3.14,
                             #    "created_at"=>#<Time>, "flag"=>true }
    result.free()            #=> Mysql::Error ("Mysql::Result object is freed.")
    
    ### Mysql::Result#fetch_row() vs. Mysql::Result#fetch_one_array()
    result = conn.query(sql)
    p result.fetch_row       #=> {"1", "foo", "3.14", #<Mysql::Time>, "1" }
    result.free()
    result = conn.query(sql)
    p result.fetch_one_hash  #=> {1, "foo", 3.14, #<Time>, true }
    result.free()            #=> Mysql::Error ("Mysql::Result object is freed.")
    
    ### Mysql::Result#fetch_one_object()
    class MyObject
    end
    result = conn.query(sql)
    result.fetch_one_object(MyClass)
                             #=> #<MyClass @id=1, @name="foo", @price=>3.14,
                                           @created_at=>#<Time>, @flag=>true>
    result.free()            #=> Mysql::Error ("Mysql::Result object is freed.")
    
    ### Mysql::Result#fetch_all_hash()
    result = conn.query(sql)
    p result.fetch_all_hash  #=> [ {"id"=>1, "name"=>"foo", ... },
                             #     {"id"=>2, "name"=>"bar", ... }, ]
    # or result.fetch_all_hash {|hash| p hash }
    
    ### Mysql::Result#fetch_all_array()
    result = conn.query(sql)
    p result.fetch_all_array #=> [ [1, "foo", 3.14, ...],
                             #     [2, "bar", 3.15, ...], ]
    # or result.fetch_all_array {|array| p array }
    
    ### Mysql::Result#fetch_all_object()
    result = conn.query(sql)
    p result.fetch_all_object(MyClass)
                             #=> [ #<MyObject @id=1, @name="foo", ...>,
                             #     #<MyObject @id=2, @name="bar", ...>, ]
    # or result.fetch_all_object(MyClass) {|object| p object }
    
    ### Change to return Mysql::Time object instead of Time object,
    ### because Time only supports limited range.
    ### For examle, Time.mktime(1800, 1, 1) will raise ArgumentError
    ### while Mysql::Time doesn't.
    class <<Mysql
      alias create_timestamp create_mysql_timestamp
      #alias create_timestamp create_ruby_timestamp
    end


== API

=== class Mysql::Result

: Mysql::Result#fetch_one_hash()
	Similar to Mysql::Result#fetch_hash(), but values are converted
	into proper class and Mysql::Result#free() is called automatically.
	For example, Mysql::Result#fetch_one_hash() returns
	{'id'=>1, 'float'=>3.14, 'date'=>Time.mktime(2008, 1, 1), 'flag'=>true}
	while Mysql::Result#fetch_hash() returns
	{'id'=>"1", 'float'=>"3.14", 'date'=>"2008-01-01", 'flag'=>"1"}
	.

: Mysql::Result#fetch_one_hash!()
	Same as Mysql::Result#fetch_one_hash() but this doesn't call
	Mysql::Result#free() automatically.

: Mysql::Result#fetch_one_array()
	Similar to Mysql::Result#fetch_row(), but values are converted
	into proper class and Mysql::Result#free() is called automatically.
	For example, Mysql::Result#fetch_one_arra() returns
	{1, 3.14, Time.mktime(2008, 1, 1), true}
	while Mysql::Result#fetch_row() returns
	{"1", "3.14", "2008-01-01", "1"}
	.

: Mysql::Result#fetch_one_array!()
	Same as Mysql::Result#fetch_one_array() but this doesn't call
	Mysql::Result#free() automatically.

: Mysql::Result#fetch_one_object(ClassObject)
	Similar to Mysql::Result#fetch_one_hash(), but instance object
	of ClassObject is returned instead of hash object.
	Column data are set as instance variables of the object.

: Mysql::Result#fetch_one_object!(ClassObject)
	Same as Mysql::Result#fetch_one_object() but this doesn't call
	Mysql::Result#free() automatically.


: Mysql::Result#fetch_all_hash(), Mysql::Result#fetch_all_hashes()
	Fetch all records by Result#fetch_one_hash().
	If block is given, it is called with each fetched hash object.
	If block is not given, just returns an array of fetched hash objects.
	Mysql::Result#free() is called automatically.

: Mysql::Result#fetch_all_hash!(), Mysql::Result#fetch_all_hashes!(), 
	Same as Mysql::Result#fetch_all_hash() but this doesn't call
	Mysql::Result#free() automatically.

: Mysql::Result#fetch_all_array(), Mysql::Result#fetch_all_arrays()
	Fetch all records by Result#fetch_one_array().
	If block is given, it is called with each fetched array object.
	If block is not given, just returns an array of fetched array objects.
	Mysql::Result#free() is called automatically.

: Mysql::Result#fetch_all_array!(), Mysql::Result#fetch_all_arrays!()
	Same as Mysql::Result#fetch_all_array() but this doesn't call
	Mysql::Result#free() automatically.

: Mysql::Result#fetch_all_object(ClassObject), Mysql::Result#fetch_all_objectss(ClassObject)
	Fetch all records by Result#fetch_one_object().
	If block is given, it is called with each fetched object.
	If block is not given, just returns an array of fetched objects.
	Mysql::Result#free() is called automatically.

: Mysql::Result#fetch_all_object!(), Mysql::Result#fetch_all_objects!()
	Same as Mysql::Result#fetch_all_object() but this doesn't call
	Mysql::Result#free() automatically.


=== class Mysql::Stmt

: Mysql::Stmt#fetch_one_hash()
	Equivarent to Mysql::Resutl#fetch_one_hash().
	Mysql::Stmt#free_result() and Mysql::Stmt#close() are called automatically.

: Mysql::Stmt#fetch_one_hash!()
	Same as Mysql::Stmt#fetch_one_hash() but this doesn't call
	Mysql::Stmt#free_result() and Mysql::Stmt#close().

: Mysql::Stmt#fetch_one_array()
	Equivarent to Mysql::Resutl#fetch_one_array().
	Mysql::Stmt#free_result() and Mysql::Stmt#close() are called automatically.

: Mysql::Stmt#fetch_one_array!()
	Same as Mysql::Stmt#fetch_one_array() but this doesn't call
	Mysql::Stmt#free_result() and Mysql::Stmt#close().

: Mysql::Stmt#fetch_one_object(class)
	Equivarent to Mysql::Result#fetch_one_object().
	Mysql::Stmt#free_result() and Mysql::Stmt#close() are called automatically.

: Mysql::Stmt#fetch_one_object!(class)
	Same as Mysql::Stmt#fetch_one_object() but this doesn't call
	Mysql::Stmt#free_result() and Mysql::Stmt#close().


: Mysql::Result#fetch_all_hash(), Mysql::Result#fetch_all_hashes()
	Equivarent to Mysql::Result#fetch_all_hash().
	Mysql::Stmt#free_result() and Mysql::Stmt#close() are called automatically.

: Mysql::Result#fetch_all_hash!(), Mysql::Result#fetch_all_hashes!(), 
	Same as Mysql::Result#fetch_all_hash() but this doesn't call
	Mysql::Stmt#free_result() and Mysql::Stmt#close() automatically.


: Mysql::Result#fetch_all_array(), Mysql::Result#fetch_all_arrays()
	Equivarent to Mysql::Result#fetch_all_array().
	Mysql::Stmt#free_result() and Mysql::Stmt#close() are called automatically.

: Mysql::Result#fetch_all_array!(), Mysql::Result#fetch_all_arrays!()
	Same as Mysql::Result#fetch_all_array() but this doesn't call
	Mysql::Stmt#free_result() and Mysql::Stmt#close() automatically.

: Mysql::Result#fetch_all_object(class), Mysql::Result#fetch_all_objectss(class)
	Equivarent to Mysql::Result#fetch_all_object().
	Mysql::Stmt#free_result() and Mysql::Stmt#close() are called automatically.

: Mysql::Result#fetch_all_object!(class), Mysql::Result#fetch_all_objects!(class)
	Same as Mysql::Result#fetch_all_object() but this doesn't call
	Mysql::Stmt#free_result() and Mysql::Stmt#close() automatically.

== Trouble shooting

=== ArgumentError raised

If you got ArgumentError, it mean that date or timestamp is too old for Ruby's
Time class to support.
For example, '1960-01-01' will raise ArgumentError because
Time.mktime(1960, 1, 1) will raise ArgumentError.

In this case, you should use Mysql::Time class instead of Ruby's Time class.

    ### Change to return Mysql::Time object instead of Time object,
    ### because Time only supports limited range.
    ### For examle, Time.mktime(1800, 1, 1) will raise ArgumentError
    ### while Mysql::Time doesn't.
    class <<Mysql
      alias create_timestamp create_mysql_timestamp
      #alias create_timestamp create_ruby_timestamp
    end


== License

Ruby's license


== Author

makoto kuwata <kwa(at)kuwata-lab.com>


== Bug reports

If you have bugs or questions, join http://kuwata-lab-products.googlegroups.com.
