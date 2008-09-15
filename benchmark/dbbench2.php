<?php
$conn = mysql_connect('localhost', 'user1', 'passwd1', 'example1');
mysql_select_db('example1');
$N = 10000;
for ($i = 0; $i < $N; $i++) {
    $result = mysql_query('select * from stocks');
    $list = array();
    while ($row = mysql_fetch_array($result, MYSQL_BOTH)) {
        //print_r($row);
        //var_dump($row);
        $list[] = $row;
    }
    mysql_free_result($result);
}
mysql_close($conn);
?>