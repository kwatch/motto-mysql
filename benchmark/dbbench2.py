import MySQLdb

conn = MySQLdb.connect(host='localhost', user='user1', passwd='passwd1', db='example1')
sql = 'select * from stocks'
N = 10000
for i in xrange(N):
    #cursor = conn.cursor()                              # 12.3
    cursor = conn.cursor(MySQLdb.cursors.DictCursor)   # 14.1
    cursor.execute(sql)
    L = cursor.fetchall()                              # 10.4 / 12.4
    #L = []
    #row = cursor.fetchone()
    #while row is not None:
    #    #print repr(row)
    #    #L.append(row)                                  # 12.0
    #    row = cursor.fetchone()
    cursor.close()
conn.close()
