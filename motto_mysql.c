#include "ruby.h"
#include "version.h"
#ifdef HAVE_MYSQL_H
#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>
#endif

extern VALUE cMysqlRes;
extern VALUE cMysqlStmt;
extern VALUE cMysqlTime;
extern VALUE eMysql;
extern VALUE cMysql;


#include "motto_mysql.h"


#include <time.h>
#include <assert.h>
#include <alloca.h>

#define MAX_IVAR_LENGTH 31

ID id_new;
ID id_initialize;
ID id_create_timestamp;
ID id_close;
ID id_mktime;
ID id_free;
ID id_free_result;

static VALUE create_ruby_timestamp(VALUE obj, VALUE year, VALUE month, VALUE mday,
                                   VALUE hour, VALUE min, VALUE sec,
                                   VALUE neg, VALUE arg)
{
    if (year  == Qnil) year  = INT2FIX(1970);
    if (month == Qnil) month = INT2FIX(1);
    if (mday  == Qnil) mday  = INT2FIX(1);
    return rb_funcall(rb_cTime, id_mktime, 6,
                      year, month, mday, hour, min, sec);
}

static VALUE create_mysql_timestamp(VALUE obj, VALUE year, VALUE month, VALUE mday,
                                    VALUE hour, VALUE min, VALUE sec,
                                    VALUE neg, VALUE arg)
{
    /*
    if (year != Qnil)
        year = INT2FIX(FIX2INT(year) + 1900);
    if (month != Qnil)
        month = INT2FIX(FIX2INT(month) + 1);
    */
    VALUE val = rb_obj_alloc(cMysqlTime);
    rb_funcall(val, id_initialize, 8,
               year, month, mday, hour, min, sec, neg, arg);
    return val;
}


static VALUE _result_get_value(char *str, unsigned int length, int type) {
    if (str == NULL)
        return Qnil;
    assert(str != NULL);
    fflush(stderr);
    VALUE string;
    struct time_object *tobj;
    struct tm t;
    switch (type) {
    case MYSQL_TYPE_STRING:
        string = rb_tainted_str_new(str, length);
        return string;
    case MYSQL_TYPE_LONG:
    case MYSQL_TYPE_TINY:
    case MYSQL_TYPE_SHORT:
    case MYSQL_TYPE_INT24:
        string = rb_tainted_str_new(str, length);
        return rb_Integer(string);
    case MYSQL_TYPE_LONGLONG:
        string = rb_tainted_str_new(str, length);
        return rb_Integer(string);
    case MYSQL_TYPE_FLOAT:
    case MYSQL_TYPE_DOUBLE:
        string = rb_tainted_str_new(str, length);
        return rb_Float(string);
    case MYSQL_TYPE_TIMESTAMP:
        strptime(str, "%Y-%m-%d %H:%M:%S", &t);
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          INT2FIX(t.tm_year+1900), INT2FIX(t.tm_mon+1), INT2FIX(t.tm_mday),
                          INT2FIX(t.tm_hour), INT2FIX(t.tm_min), INT2FIX(t.tm_sec),
                          Qnil, Qnil);
    case MYSQL_TYPE_DATETIME:
        strptime(str, "%Y-%m-%d %H:%M:%S", &t);
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          INT2FIX(t.tm_year+1900), INT2FIX(t.tm_mon+1), INT2FIX(t.tm_mday),
                          INT2FIX(t.tm_hour), INT2FIX(t.tm_min), INT2FIX(t.tm_sec),
                          Qnil, Qnil);
    case MYSQL_TYPE_DATE:
        strptime(str, "%Y-%m-%d", &t);
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          INT2FIX(t.tm_year+1900), INT2FIX(t.tm_mon+1), INT2FIX(t.tm_mday),
                          Qnil, Qnil, Qnil,
                          Qnil, Qnil);
    case MYSQL_TYPE_TIME:
        strptime(str, "%H:%M:%S", &t);
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          Qnil, Qnil, Qnil,
                          INT2FIX(t.tm_hour), INT2FIX(t.tm_min), INT2FIX(t.tm_sec),
                          Qnil, Qnil);
    /*case MYSQL_TYPE_BLOB:*/
    default:
        string = rb_tainted_str_new(str, length);
        return string;
    }
}

static VALUE _result_fetch(VALUE obj_result, VALUE klass, int flag_fetch_one)
{
    check_free(obj_result);
    MYSQL_RES* res = GetMysqlRes(obj_result);
    int n = mysql_num_fields(res);
    MYSQL_FIELD *fields = mysql_fetch_fields(res);
    /* fetch data */
    MYSQL_ROW row;
    VALUE ret;
    int i;
    if (flag_fetch_one) {
        row = mysql_fetch_row(res);
        if (row == NULL) {
            ret = Qnil;
        }
        else {
            unsigned long *lengths = mysql_fetch_lengths(res);
            /* fetch_one_hash */
            if (klass == rb_cHash) {
                VALUE hash = rb_hash_new();
                for (i = 0; i < n; i++) {
                    VALUE key = rb_tainted_str_new2(fields[i].name);
                    //VALUE val = row[i] ? _result_get_value(row[i], lengths[i], fields[i].type) : Qnil;
                    VALUE val = _result_get_value(row[i], lengths[i], fields[i].type);
                    rb_hash_aset(hash, key, val);
                }
                ret = hash;
            }
            /* fetch_one_array */
            else if (klass == rb_cArray) {
                VALUE arr = rb_ary_new2(n);
                for (i = 0; i < n; i++) {
                    //VALUE val = row[i] ? _result_get_value(row[i], lengths[i], fields[i].type) : Qnil;
                    VALUE val = _result_get_value(row[i], lengths[i], fields[i].type);
                    rb_ary_push(arr, val);
                }
                ret = arr;
            }
            /* fetch_one_object */
            else {
                VALUE obj = rb_funcall(klass, id_new, 0);
                char buf[MAX_IVAR_LENGTH+1];
                buf[0] = '@';
                buf[MAX_IVAR_LENGTH] = '\0';
                for (i = 0; i < n; i++) {
                    //VALUE val = row[i] ? _result_get_value(row[i], lengths[i], fields[i].type) : Qnil;
                    VALUE val = _result_get_value(row[i], lengths[i], fields[i].type);
                    //rb_ivar_set(obj, rb_intern(fields[i].name), val);
                    strncpy(buf+1, fields[i].name, MAX_IVAR_LENGTH);
                    rb_ivar_set(obj, rb_intern(buf), val);
                }
                ret = obj;
            }
        }
    }
    else {
        VALUE list;
        int has_block = rb_block_given_p() == Qtrue;
        list = has_block ? Qnil : rb_ary_new();
        /* fetch_all_hash */
        if (klass == rb_cHash) {
            VALUE *keys = alloca(n * sizeof(VALUE));
            for (i = 0; i < n; i++)
                keys[i] = rb_tainted_str_new2(fields[i].name);
            while ((row = mysql_fetch_row(res)) != NULL) {
                unsigned long* lengths = mysql_fetch_lengths(res);
                VALUE hash = rb_hash_new();
                for (i = 0; i < n; i++) {
                    VALUE val = row[i] ? _result_get_value(row[i], lengths[i], fields[i].type) : Qnil;
                    rb_hash_aset(hash, keys[i], val);
                }
                has_block ? rb_yield(hash) : rb_ary_push(list, hash);
            }
        }
        /* fetch_all_array */
        else if (klass == rb_cArray) {
            while ((row = mysql_fetch_row(res)) != NULL) {
                unsigned long* lengths = mysql_fetch_lengths(res);
                VALUE arr = rb_ary_new2(n);
                for (i = 0; i < n; i++) {
                    VALUE val = row[i] ? _result_get_value(row[i], lengths[i], fields[i].type) : Qnil;
                    rb_ary_push(arr, val);
                }
                has_block ? rb_yield(arr) : rb_ary_push(list, arr);
            }
        }
        /* fetch_all_object */
        else {
            char buf[MAX_IVAR_LENGTH+1];
            buf[0] = '@';
            buf[MAX_IVAR_LENGTH] = '\0';
            VALUE *names = alloca(n * sizeof(VALUE));
            for (i = 0; i < n; i++) {
                strncpy(buf+1, fields[i].name, MAX_IVAR_LENGTH);
                names[i] = rb_intern(buf);
            }
            ID id_new_ = id_new;
            while ((row = mysql_fetch_row(res)) != NULL) {
                unsigned long* lengths = mysql_fetch_lengths(res);
                VALUE obj = rb_funcall(klass, id_new_, 0);
                for (i = 0; i < n; i++) {
                    //VALUE val = row[i] ? _result_get_value(row[i], lengths[i], fields[i].type) : Qnil;
                    VALUE val = _result_get_value(row[i], lengths[i], fields[i].type);
                    rb_ivar_set(obj, names[i], val);
                }
                has_block ? rb_yield(obj) : rb_ary_push(list, obj);
            }
        }
        ret = list;
    }
    /*res_free(obj_result);*/
    rb_funcall(obj_result, id_free, 0);
    return ret;
}

static VALUE result_fetch_one_hash(VALUE obj_result)
{
    return _result_fetch(obj_result, rb_cHash, 1);
}

static VALUE result_fetch_one_array(VALUE obj_result)
{
    return _result_fetch(obj_result, rb_cArray, 1);
}

static VALUE result_fetch_one_object(VALUE obj_result, VALUE klass)
{
    return _result_fetch(obj_result, klass, 1);
}

static VALUE result_fetch_all_hash(VALUE obj_result)
{
    return _result_fetch(obj_result, rb_cHash, 0);
}

static VALUE result_fetch_all_array(VALUE obj_result)
{
    return _result_fetch(obj_result, rb_cArray, 0);
}

static VALUE result_fetch_all_object(VALUE obj_result, VALUE klass)
{
    return _result_fetch(obj_result, klass, 0);
}


static VALUE _stmt_get_value(struct mysql_stmt *s, int i, int buffer_type)
{
    if (s->result.is_null[i])
        return Qnil;
    VALUE val;
    MYSQL_TIME *t;
    MYSQL_BIND *bind = &(s->result.bind[i]);
    /*switch (bind->buffer_type) {*/
    switch (buffer_type) {
    case MYSQL_TYPE_STRING:
        return rb_tainted_str_new(bind->buffer, s->result.length[i]);
    case MYSQL_TYPE_LONG:
        return INT2NUM(*(long*)bind->buffer);
    case MYSQL_TYPE_LONGLONG:
        return rb_ll2inum(*(LONG_LONG*)bind->buffer);
    case MYSQL_TYPE_DOUBLE:
        /*return rb_float_new(*(double*)bind->buffer);*/
        return rb_Float(rb_tainted_str_new(bind->buffer, s->result.length[i]));
    /*
    case MYSQL_TYPE_TIMESTAMP:
    case MYSQL_TYPE_DATE:
    case MYSQL_TYPE_TIME:
    case MYSQL_TYPE_DATETIME:
        t = (MYSQL_TIME*)bind->buffer;
        val = rb_obj_alloc(cMysqlTime);
        rb_funcall(val, id_initialize, 8,
                   INT2FIX(t->year), INT2FIX(t->month),
                   INT2FIX(t->day), INT2FIX(t->hour),
                   INT2FIX(t->minute), INT2FIX(t->second),
                   (t->neg ? Qtrue : Qfalse),
                   INT2FIX(t->second_part));
    */
    case MYSQL_TYPE_TIMESTAMP:
    case MYSQL_TYPE_DATETIME:
        t = (MYSQL_TIME*)bind->buffer;
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          INT2FIX(t->year), INT2FIX(t->month), INT2FIX(t->day),
                          INT2FIX(t->hour), INT2FIX(t->minute), INT2FIX(t->second),
                          (t->neg ? Qtrue : Qfalse), INT2FIX(t->second_part));
    case MYSQL_TYPE_DATE:
        t = (MYSQL_TIME*)bind->buffer;
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          INT2FIX(t->year), INT2FIX(t->month), INT2FIX(t->day),
                          Qnil, Qnil, Qnil,
                          (t->neg ? Qtrue : Qfalse), INT2FIX(t->second_part));
    case MYSQL_TYPE_TIME:
        t = (MYSQL_TIME*)bind->buffer;
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          Qnil, Qnil, Qnil,
                          INT2FIX(t->hour), INT2FIX(t->minute), INT2FIX(t->second),
                          (t->neg ? Qtrue : Qfalse), INT2FIX(t->second_part));
    case MYSQL_TYPE_BLOB:
        return rb_tainted_str_new(bind->buffer, s->result.length[i]);
    default:
        rb_raise(rb_eTypeError, "unknown buffer_type: %d", bind->buffer_type);
    }
    /* unreachable */
    return Qnil;
}

static VALUE _stmt_fetch(VALUE obj_stmt, VALUE klass, int flag_fetch_one) {
    check_stmt_closed(obj_stmt);
    struct mysql_stmt* s = DATA_PTR(obj_stmt);
    MYSQL_RES* res = s->res;
    int n = mysql_num_fields(res);
    /* to avoid rounding error, change field type to string if it is double or float */
    int *buffer_types = alloca(n * sizeof(int));
    int i;
    for (i = 0; i < n; i++) {
        int t = buffer_types[i] = s->result.bind[i].buffer_type;
        if (t == MYSQL_TYPE_DOUBLE || t == MYSQL_TYPE_FLOAT) {
            s->result.bind[i].buffer_type = MYSQL_TYPE_STRING;
        }
    }
    if (mysql_stmt_bind_result(s->stmt, s->result.bind))
        mysql_stmt_raise(s->stmt);
    /* fetch data */
    VALUE ret;
    int r;
    if (flag_fetch_one) {
        r = mysql_stmt_fetch(s->stmt);
        if (r == MYSQL_NO_DATA) {
            ret = Qnil;
        }
        else if (r == 1) {
            ret = Qnil; /* dummy */
            mysql_stmt_raise(s->stmt);
        }
        /* fetch_one_hash */
        else if (klass == rb_cHash) {
            MYSQL_FIELD *fields = mysql_fetch_fields(res);
            VALUE hash = rb_hash_new();
            for (i = 0; i < n; i++) {
                VALUE key = rb_tainted_str_new2(fields[i].name);
                VALUE val = _stmt_get_value(s, i, buffer_types[i]);
                rb_hash_aset(hash, key, val);
            }
            ret = hash;
        }
        /* fetch_one_array */
        else if (klass == rb_cArray) {
            VALUE arr = rb_ary_new();
            for (i = 0; i < n; i++) {
                VALUE val = _stmt_get_value(s, i, buffer_types[i]);
                rb_ary_push(arr, val);
            }
            ret = arr;
        }
        /* fetch_one_object */
        else {
            MYSQL_FIELD *fields = mysql_fetch_fields(res);
            VALUE obj = rb_funcall(klass, id_new, 0);
            char buf[MAX_IVAR_LENGTH+1];
            buf[0] = '@';
            buf[MAX_IVAR_LENGTH] = '\0';
            for (i = 0; i < n; i++) {
                VALUE val = _stmt_get_value(s, i, buffer_types[i]);
                strncpy(buf+1, fields[i].name, MAX_IVAR_LENGTH);
                rb_ivar_set(obj, rb_intern(buf), val);
            }
            ret = obj;
        }
    }
    else {
        VALUE list;
        int has_block = rb_block_given_p() == Qtrue;
        list = has_block ? Qnil : rb_ary_new();
        /* fetch_all_hash */
        if (klass == rb_cHash) {
            MYSQL_FIELD *fields = mysql_fetch_fields(res);
            VALUE *keys = alloca(n * sizeof(VALUE));
            for (i = 0; i < n; i++) {
                keys[i] = rb_tainted_str_new2(fields[i].name);
            }
            while ((r = mysql_stmt_fetch(s->stmt)) != MYSQL_NO_DATA && r != 1) {
                VALUE hash = rb_hash_new();
                for (i = 0; i < n; i++) {
                    //VALUE val = s->result.is_null[i] ? Qnil : _stmt_get_value(s, i, buffer_types[i]);
                    VALUE val = _stmt_get_value(s, i, buffer_types[i]);
                    rb_hash_aset(hash, keys[i], val);
                }
                has_block ? rb_yield(hash) : rb_ary_push(list, hash);
            }
        }
        /* fetch_all_array */
        else if (klass == rb_cArray) {
            while ((r = mysql_stmt_fetch(s->stmt)) != MYSQL_NO_DATA && r != 1) {
                VALUE arr = rb_ary_new2(n);
                for (i = 0; i < n; i++) {
                    //VALUE val = s->result.is_null[i] ? Qnil : _stmt_get_value(s, i, buffer_types[i]);
                    VALUE val = _stmt_get_value(s, i, buffer_types[i]);
                    rb_ary_push(arr, val);
                }
                has_block ? rb_yield(arr) : rb_ary_push(list, arr);
            }
        }
        /* fetch_all_object */
        else {
            MYSQL_FIELD *fields = mysql_fetch_fields(res);
            char buf[MAX_IVAR_LENGTH+1];
            buf[0] = '@';
            buf[MAX_IVAR_LENGTH] = '\0';
            VALUE *names = alloca(n * sizeof(VALUE));
            for (i = 0; i < n; i++) {
                strncpy(buf+1, fields[i].name, MAX_IVAR_LENGTH);
                names[i] = rb_intern(buf);
            }
            ID id_new_ = id_new;
            while ((r = mysql_stmt_fetch(s->stmt)) != MYSQL_NO_DATA && r != 1) {
                VALUE obj = rb_funcall(klass, id_new_, 0);
                for (i = 0; i < n; i++) {
                    VALUE val = _stmt_get_value(s, i, buffer_types[i]);
                    rb_ivar_set(obj, names[i], val);
                }
                has_block ? rb_yield(obj) : rb_ary_push(list, obj);
            }
        }
        if (r == 1)
            mysql_stmt_raise(s->stmt);
        ret = list;
    }
    /*
    stmt_free_result(obj_stmt);
    stmt_close(obj_stmt);
    */
    rb_funcall(obj_stmt, id_free_result, 0);
    rb_funcall(obj_stmt, id_close, 0);
    return ret;
}

static VALUE stmt_fetch_one_hash(VALUE obj_stmt)
{
    return _stmt_fetch(obj_stmt, rb_cHash, 1);
}

static VALUE stmt_fetch_one_array(VALUE obj_stmt)
{
    return _stmt_fetch(obj_stmt, rb_cArray, 1);
}

static VALUE stmt_fetch_one_object(VALUE obj_stmt, VALUE klass)
{
    return _stmt_fetch(obj_stmt, klass, 1);
}

static VALUE stmt_fetch_all_hash(VALUE obj_stmt)
{
    return _stmt_fetch(obj_stmt, rb_cHash, 0);
}

static VALUE stmt_fetch_all_array(VALUE obj_stmt)
{
    return _stmt_fetch(obj_stmt, rb_cArray, 0);
}

static VALUE stmt_fetch_all_object(VALUE obj_stmt, VALUE klass)
{
    return _stmt_fetch(obj_stmt, klass, 0);
}



void Init_motto_mysql(void)
{
    id_new              = rb_intern("new");
    id_initialize       = rb_intern("initialize");
    id_create_timestamp = rb_intern("create_timestamp");
    id_close            = rb_intern("close");
    id_mktime           = rb_intern("mktime");
    id_free             = rb_intern("free");
    id_free_result      = rb_intern("free_result");

    rb_define_singleton_method(cMysql, "create_timestamp",       create_mysql_timestamp, 8);
    rb_define_singleton_method(cMysql, "create_mysql_timestamp", create_mysql_timestamp, 8);
    rb_define_singleton_method(cMysql, "create_ruby_timestamp",  create_ruby_timestamp,  8);

    rb_define_method(cMysqlRes, "fetch_one_hash",   result_fetch_one_hash,   0);
    rb_define_method(cMysqlRes, "fetch_one_array",  result_fetch_one_array,  0);
    rb_define_method(cMysqlRes, "fetch_one_object", result_fetch_one_object, 1);
    rb_define_method(cMysqlRes, "fetch_all_hash",   result_fetch_all_hash,   0);
    rb_define_method(cMysqlRes, "fetch_all_array",  result_fetch_all_array,  0);
    rb_define_method(cMysqlRes, "fetch_all_object", result_fetch_all_object, 1);

    rb_define_method(cMysqlStmt, "fetch_one_hash",   stmt_fetch_one_hash,   0);
    rb_define_method(cMysqlStmt, "fetch_one_array",  stmt_fetch_one_array,  0);
    rb_define_method(cMysqlStmt, "fetch_one_object", stmt_fetch_one_object, 1);
    rb_define_method(cMysqlStmt, "fetch_all_hash",   stmt_fetch_all_hash,   0);
    rb_define_method(cMysqlStmt, "fetch_all_array",  stmt_fetch_all_array,  0);
    rb_define_method(cMysqlStmt, "fetch_all_object", stmt_fetch_all_object, 1);

}
