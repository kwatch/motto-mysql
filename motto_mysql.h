/* -------------- copied from mysql-ruby-2.7.6/mysql.c.in -------------- */

#define MYSQL_RUBY_VERSION 20706

/* struct mysql_res */
struct mysql_res {
    MYSQL_RES* res;
    char freed;
};

/* macro GetMysqlRes */
#define GetMysqlRes(obj)	(Check_Type(obj, T_DATA), ((struct mysql_res*)DATA_PTR(obj))->res)

/* struct mysql_stmt */
struct mysql_stmt {
    MYSQL_STMT *stmt;
    char closed;
    struct {
	int n;
	MYSQL_BIND *bind;
	unsigned long *length;
	MYSQL_TIME *buffer;
    } param;
    struct {
	int n;
	MYSQL_BIND *bind;
	my_bool *is_null;
	unsigned long *length;
    } result;
    MYSQL_RES *res;
};

/* macro GetMysqlStmt */
#define GetMysqlStmt(obj)	(Check_Type(obj, T_DATA), ((struct mysql_stmt*)DATA_PTR(obj))->stmt)

/* check_free() */
static void check_free(VALUE obj)
{
    struct mysql_res* resp = DATA_PTR(obj);
    if (resp->freed == Qtrue)
        rb_raise(eMysql, "Mysql::Result object is already freed");
}

/* check_stmt_closed() */
static void check_stmt_closed(VALUE obj)
{
    struct mysql_stmt* s = DATA_PTR(obj);
    if (s->closed == Qtrue)
	rb_raise(eMysql, "Mysql::Stmt object is already closed");
}

/* mysql_stmt_raise() */
static void mysql_stmt_raise(MYSQL_STMT* s)
{
    VALUE e = rb_exc_new2(eMysql, mysql_stmt_error(s));
    rb_iv_set(e, "errno", INT2FIX(mysql_stmt_errno(s)));
    rb_iv_set(e, "sqlstate", rb_tainted_str_new2(mysql_stmt_sqlstate(s)));
    rb_exc_raise(e);
}

/* --------------------------------------------------------------------- */
