/**
 **  $Rev$
 **  $Release: $
 **  $Copyright$
 **  $License$
 **/

#include "ruby.h"
#include "version.h"

#ifdef HAVE_MYSQL_H
#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>
#else
#include <mysql/mysql.h>
#include <mysql/errmsg.h>
#include <mysql/mysqld_error.h>
#endif

#include <time.h>
#include <assert.h>
#include <alloca.h>

extern VALUE cMysqlRes;
extern VALUE cMysqlStmt;
extern VALUE cMysqlTime;
extern VALUE eMysql;
extern VALUE cMysql;
static VALUE cDate;          /* require 'date' */
static VALUE cDateTime;      /* require 'date' */

#include "motto_mysql.h"

char *MOTTO_MYSQL_VERSION = "$Release$";

#define MAX_IVAR_LENGTH 31

ID id_new;
ID id_initialize;
ID id_create_timestamp;
ID id_create_datetime;
ID id_create_date;
ID id_create_time;
ID id_close;
ID id_mktime;
ID id_free;
ID id_free_result;


static VALUE create_ruby_timestamp(VALUE obj, VALUE year, VALUE month, VALUE mday,
                                   VALUE hour, VALUE min, VALUE sec,
                                   VALUE neg, VALUE arg)
{
    return rb_funcall(rb_cTime, id_mktime, 6,
                      year, month, mday, hour, min, sec);
}

/*
static VALUE create_mysql_timestamp(VALUE obj, VALUE year, VALUE month, VALUE mday,
                                    VALUE hour, VALUE min, VALUE sec,
                                    VALUE neg, VALUE arg)
{
    VALUE val = rb_obj_alloc(cMysqlTime);
    rb_funcall(val, id_initialize, 8,
               year, month, mday, hour, min, sec, neg, arg);
    return val;
}
*/

static VALUE create_ruby_datetime(VALUE obj, VALUE year, VALUE month, VALUE mday,
                                  VALUE hour, VALUE min, VALUE sec,
                                  VALUE neg, VALUE arg)
{
    return rb_funcall(cDateTime, id_new, 6,
                      year, month, mday, hour, min, sec);
}

/*
static VALUE create_mysql_datetime(VALUE obj, VALUE year, VALUE month, VALUE mday,
                                   VALUE hour, VALUE min, VALUE sec,
                                   VALUE neg, VALUE arg)
{
    VALUE val = rb_obj_alloc(cMysqlTime);
    rb_funcall(val, id_initialize, 8,
               year, month, mday, hour, min, sec, neg, arg);
    return val;
}
*/

static VALUE create_ruby_date(VALUE obj, VALUE year, VALUE month, VALUE mday,
                              VALUE neg, VALUE arg)
{
    return rb_funcall(cDate, id_new, 3,
                      year, month, mday);
}

/*
static VALUE create_mysql_date(VALUE obj, VALUE year, VALUE month, VALUE mday,
                               VALUE neg, VALUE arg)
{
    VALUE val = rb_obj_alloc(cMysqlTime);
    rb_funcall(val, id_initialize, 8,
               year, month, mday, Qnil, Qnil, Qnil, neg, arg);
    return val;
}
*/

static VALUE create_ruby_time(VALUE obj, VALUE hour, VALUE min, VALUE sec,
                              VALUE neg, VALUE arg)
{
    return rb_funcall(rb_cTime, id_mktime, 6,
                      INT2FIX(1970), INT2FIX(1), INT2FIX(1), hour, min, sec);
}

/*
static VALUE create_mysql_time(VALUE obj, VALUE hour, VALUE min, VALUE sec,
                               VALUE neg, VALUE arg)
{
    VALUE val = rb_obj_alloc(cMysqlTime);
    rb_funcall(val, id_initialize, 8,
               Qnil, Qnil, Qnil, hour, min, sec, neg, arg);
    return val;
}
*/

static VALUE create_ruby_timestamp_or_datetime(VALUE obj,
                                   VALUE year, VALUE month, VALUE mday,
                                   VALUE hour, VALUE min, VALUE sec,
                                   VALUE neg, VALUE arg)
{
    int y = FIX2INT(year);
    return 1970 <= y && y < 2038
           ? create_ruby_timestamp(obj, year, month, mday, hour, min, sec, neg, arg)
           : create_ruby_datetime(obj, year, month, mday, hour, min, sec, neg, arg);
}


static VALUE _result_get_value(char *str, unsigned int length, int type)
{
    if (str == NULL)
        return Qnil;
    assert(str != NULL);
    fflush(stderr);
    VALUE string;
    struct time_object *tobj;
    struct tm t;
    switch (type) {
    case MYSQL_TYPE_VAR_STRING:
    case MYSQL_TYPE_STRING:
        string = rb_tainted_str_new(str, length);
        return string;
    case MYSQL_TYPE_LONG:
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
    case MYSQL_TYPE_TINY:
        if (length == 1) {
            return str[0] == '1' ? Qtrue : Qfalse;
        } else {
            string = rb_tainted_str_new(str, length);
            return rb_Integer(string);
        }
    case MYSQL_TYPE_TIMESTAMP:
        strptime(str, "%Y-%m-%d %H:%M:%S", &t);
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          INT2FIX(t.tm_year+1900), INT2FIX(t.tm_mon+1), INT2FIX(t.tm_mday),
                          INT2FIX(t.tm_hour), INT2FIX(t.tm_min), INT2FIX(t.tm_sec),
                          Qnil, Qnil);
    case MYSQL_TYPE_DATETIME:
        strptime(str, "%Y-%m-%d %H:%M:%S", &t);
        return rb_funcall(cMysql, id_create_datetime, 8,
                          INT2FIX(t.tm_year+1900), INT2FIX(t.tm_mon+1), INT2FIX(t.tm_mday),
                          INT2FIX(t.tm_hour), INT2FIX(t.tm_min), INT2FIX(t.tm_sec),
                          Qnil, Qnil);
    case MYSQL_TYPE_DATE:
        strptime(str, "%Y-%m-%d", &t);
        return rb_funcall(cMysql, id_create_date, 5,
                          INT2FIX(t.tm_year+1900), INT2FIX(t.tm_mon+1), INT2FIX(t.tm_mday),
                          Qnil, Qnil);
    case MYSQL_TYPE_TIME:
        strptime(str, "%H:%M:%S", &t);
        return rb_funcall(cMysql, id_create_time, 5,
                          INT2FIX(t.tm_hour), INT2FIX(t.tm_min), INT2FIX(t.tm_sec),
                          Qnil, Qnil);
    /*case MYSQL_TYPE_BLOB:*/
    default:
        string = rb_tainted_str_new(str, length);
        return string;
    }
}

static VALUE _result_fetch(VALUE obj_result, VALUE klass, int flag_fetch_one, int flag_free)
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
            /* fetch_as_hash */
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
            /* fetch_as_array */
            else if (klass == rb_cArray) {
                VALUE arr = rb_ary_new2(n);
                for (i = 0; i < n; i++) {
                    //VALUE val = row[i] ? _result_get_value(row[i], lengths[i], fields[i].type) : Qnil;
                    VALUE val = _result_get_value(row[i], lengths[i], fields[i].type);
                    rb_ary_push(arr, val);
                }
                ret = arr;
            }
            /* fetch_as_object */
            else {
                VALUE obj = rb_funcall(klass, id_new, 0);
                char buf[MAX_IVAR_LENGTH + 1];
                buf[0] = '@';
                buf[MAX_IVAR_LENGTH] = '\0';
                for (i = 0; i < n; i++) {
                    //VALUE val = row[i] ? _result_get_value(row[i], lengths[i], fields[i].type) : Qnil;
                    VALUE val = _result_get_value(row[i], lengths[i], fields[i].type);
                    //rb_ivar_set(obj, rb_intern(fields[i].name), val);
                    strncpy(buf+1, fields[i].name, MAX_IVAR_LENGTH - 1);
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
        /* fetch_all_as_hashes */
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
        /* fetch_all_as_arrays */
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
        /* fetch_all_as_objects */
        else {
            char buf[MAX_IVAR_LENGTH + 1];
            buf[0] = '@';
            buf[MAX_IVAR_LENGTH] = '\0';
            VALUE *names = alloca(n * sizeof(VALUE));
            for (i = 0; i < n; i++) {
                strncpy(buf+1, fields[i].name, MAX_IVAR_LENGTH - 1);
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
    if (flag_free) {
        rb_funcall(obj_result, id_free, 0);
    }
    return ret;
}

static VALUE result_fetch_as_hash (VALUE obj_result) { return _result_fetch(obj_result, rb_cHash, 1, 1); }
static VALUE result_fetch_as_hash2(VALUE obj_result) { return _result_fetch(obj_result, rb_cHash, 1, 0); }
static VALUE result_fetch_all_as_hashes (VALUE obj_result) { return _result_fetch(obj_result, rb_cHash, 0, 1); }
static VALUE result_fetch_all_as_hashes2(VALUE obj_result) { return _result_fetch(obj_result, rb_cHash, 0, 0); }

static VALUE result_fetch_as_array (VALUE obj_result) { return _result_fetch(obj_result, rb_cArray, 1, 1); }
static VALUE result_fetch_as_array2(VALUE obj_result) { return _result_fetch(obj_result, rb_cArray, 1, 0); }
static VALUE result_fetch_all_as_arrays (VALUE obj_result) { return _result_fetch(obj_result, rb_cArray, 0, 1); }
static VALUE result_fetch_all_as_arrays2(VALUE obj_result) { return _result_fetch(obj_result, rb_cArray, 0, 0); }

static VALUE result_fetch_as_object (VALUE obj_result, VALUE klass) { return _result_fetch(obj_result, klass, 1, 1); }
static VALUE result_fetch_as_object2(VALUE obj_result, VALUE klass) { return _result_fetch(obj_result, klass, 1, 0); }
static VALUE result_fetch_all_as_objects (VALUE obj_result, VALUE klass) { return _result_fetch(obj_result, klass, 0, 1); }
static VALUE result_fetch_all_as_objects2(VALUE obj_result, VALUE klass) { return _result_fetch(obj_result, klass, 0, 0); }



static VALUE _stmt_get_value(struct mysql_stmt *s, int i, int buffer_type)
{
    if (s->result.is_null[i])
        return Qnil;
    VALUE val;
    MYSQL_TIME *t;
    MYSQL_BIND *bind = &(s->result.bind[i]);
    /*switch (bind->buffer_type) {*/
    switch (buffer_type) {
#if MYSQL_RUBY_VERSION == 20704
    case MYSQL_TYPE_STRING:
        return rb_tainted_str_new(bind->buffer, s->result.length[i]);
    case MYSQL_TYPE_LONG:
        return INT2NUM(*(long*)bind->buffer);
    case MYSQL_TYPE_LONGLONG:
        return rb_ll2inum(*(LONG_LONG*)bind->buffer);
    case MYSQL_TYPE_DOUBLE:
        /*return rb_float_new(*(double*)bind->buffer);*/
        return rb_Float(rb_tainted_str_new(bind->buffer, s->result.length[i]));
#elif MYSQL_RUBY_VERSION >= 20705
    case MYSQL_TYPE_STRING:
    case MYSQL_TYPE_VAR_STRING:
        return rb_tainted_str_new(bind->buffer, s->result.length[i]);
    case MYSQL_TYPE_INT24:
    case MYSQL_TYPE_LONG:
        return (bind->is_unsigned) ? UINT2NUM(*(unsigned int *)bind->buffer)
                                   : INT2NUM(*(signed int *)bind->buffer);
    case MYSQL_TYPE_LONGLONG:
        return (bind->is_unsigned) ? ULL2NUM(*(unsigned long long *)bind->buffer)
                                   : LL2NUM(*(signed long long *)bind->buffer);
    case MYSQL_TYPE_FLOAT:
        //return rb_float_new((double)(*(float *)bind->buffer));
        return rb_Float(rb_tainted_str_new(bind->buffer, s->result.length[i]));
    case MYSQL_TYPE_DOUBLE:
        return rb_float_new(*(double *)bind->buffer);
        //return rb_Float(rb_tainted_str_new(bind->buffer, s->result.length[i]));
    case MYSQL_TYPE_TINY:
        if (s->result.length[i] == 1) {
            return ((char *)bind->buffer)[0] == 1 ? Qtrue : Qfalse;
        } else {
            return (bind->is_unsigned) ? UINT2NUM(*(unsigned char *)bind->buffer)
                                       : INT2NUM(*(signed char *)bind->buffer);
        }
#endif
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
        t = (MYSQL_TIME*)bind->buffer;
        return rb_funcall(cMysql, id_create_timestamp, 8,
                          INT2FIX(t->year), INT2FIX(t->month), INT2FIX(t->day),
                          INT2FIX(t->hour), INT2FIX(t->minute), INT2FIX(t->second),
                          (t->neg ? Qtrue : Qfalse), INT2FIX(t->second_part));
    case MYSQL_TYPE_DATETIME:
        t = (MYSQL_TIME*)bind->buffer;
        return rb_funcall(cMysql, id_create_datetime, 8,
                          INT2FIX(t->year), INT2FIX(t->month), INT2FIX(t->day),
                          INT2FIX(t->hour), INT2FIX(t->minute), INT2FIX(t->second),
                          (t->neg ? Qtrue : Qfalse), INT2FIX(t->second_part));
    case MYSQL_TYPE_DATE:
        t = (MYSQL_TIME*)bind->buffer;
        return rb_funcall(cMysql, id_create_date, 5,
                          INT2FIX(t->year), INT2FIX(t->month), INT2FIX(t->day),
                          (t->neg ? Qtrue : Qfalse), INT2FIX(t->second_part));
    case MYSQL_TYPE_TIME:
        t = (MYSQL_TIME*)bind->buffer;
        return rb_funcall(cMysql, id_create_time, 5,
                          INT2FIX(t->hour), INT2FIX(t->minute), INT2FIX(t->second),
                          (t->neg ? Qtrue : Qfalse), INT2FIX(t->second_part));
#if MYSQL_RUBY_VERSION == 20704
    case MYSQL_TYPE_BLOB:
        return rb_tainted_str_new(bind->buffer, s->result.length[i]);
#elif MYSQL_RUBY_VERSION >= 20705
    case MYSQL_TYPE_SHORT:
    case MYSQL_TYPE_YEAR:
        return (bind->is_unsigned) ? UINT2NUM(*(unsigned short *)bind->buffer)
                                   : INT2NUM(*(signed short *)bind->buffer);
    case MYSQL_TYPE_DECIMAL:
    case MYSQL_TYPE_BLOB:
    case MYSQL_TYPE_TINY_BLOB:
    case MYSQL_TYPE_MEDIUM_BLOB:
    case MYSQL_TYPE_LONG_BLOB:
#if MYSQL_VERSION_ID >= 50003
    case MYSQL_TYPE_NEWDECIMAL:
    case MYSQL_TYPE_BIT:
#endif
        return rb_tainted_str_new(bind->buffer, s->result.length[i]);
#endif
    default:
        rb_raise(rb_eTypeError, "unknown buffer_type: %d", bind->buffer_type);
    }
    /* unreachable */
    return Qnil;
}

static VALUE _stmt_fetch(VALUE obj_stmt, VALUE klass, int flag_fetch_one, int flag_free)
{
    check_stmt_closed(obj_stmt);
    struct mysql_stmt* s = DATA_PTR(obj_stmt);
    MYSQL_RES* res = s->res;
    int n = mysql_num_fields(res);
    /* to avoid rounding error, change field type to string if it is double or float */
    int *buffer_types = alloca(n * sizeof(int));
    int i;
    for (i = 0; i < n; i++) {
        int t = buffer_types[i] = s->result.bind[i].buffer_type;
#if MYSQL_RUBY_VERSION == 20704
        if (t == MYSQL_TYPE_DOUBLE || t == MYSQL_TYPE_FLOAT) {
#elif MYSQL_RUBY_VERSION >= 20705
        if (t == MYSQL_TYPE_FLOAT) {
#endif
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
        /* fetch_as_hash */
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
        /* fetch_as_array */
        else if (klass == rb_cArray) {
            VALUE arr = rb_ary_new();
            for (i = 0; i < n; i++) {
                VALUE val = _stmt_get_value(s, i, buffer_types[i]);
                rb_ary_push(arr, val);
            }
            ret = arr;
        }
        /* fetch_as_object */
        else {
            MYSQL_FIELD *fields = mysql_fetch_fields(res);
            VALUE obj = rb_funcall(klass, id_new, 0);
            char buf[MAX_IVAR_LENGTH + 1];
            buf[0] = '@';
            buf[MAX_IVAR_LENGTH] = '\0';
            for (i = 0; i < n; i++) {
                VALUE val = _stmt_get_value(s, i, buffer_types[i]);
                strncpy(buf+1, fields[i].name, MAX_IVAR_LENGTH - 1);
                rb_ivar_set(obj, rb_intern(buf), val);
            }
            ret = obj;
        }
    }
    else {
        VALUE list;
        int has_block = rb_block_given_p() == Qtrue;
        list = has_block ? Qnil : rb_ary_new();
        /* fetch_all_as_hashes */
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
        /* fetch_all_as_arrays */
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
        /* fetch_all_as_objects */
        else {
            MYSQL_FIELD *fields = mysql_fetch_fields(res);
            char buf[MAX_IVAR_LENGTH + 1];
            buf[0] = '@';
            buf[MAX_IVAR_LENGTH] = '\0';
            VALUE *names = alloca(n * sizeof(VALUE));
            for (i = 0; i < n; i++) {
                strncpy(buf+1, fields[i].name, MAX_IVAR_LENGTH - 1);
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
    if (flag_free) {
      rb_funcall(obj_stmt, id_free_result, 0);
      rb_funcall(obj_stmt, id_close, 0);
    }
    return ret;
}

static VALUE stmt_fetch_as_hash (VALUE obj_stmt) { return _stmt_fetch(obj_stmt, rb_cHash, 1, 1); }
static VALUE stmt_fetch_as_hash2(VALUE obj_stmt) { return _stmt_fetch(obj_stmt, rb_cHash, 1, 0); }
static VALUE stmt_fetch_all_as_hashes (VALUE obj_stmt) { return _stmt_fetch(obj_stmt, rb_cHash, 0, 1); }
static VALUE stmt_fetch_all_as_hashes2(VALUE obj_stmt) { return _stmt_fetch(obj_stmt, rb_cHash, 0, 0); }

static VALUE stmt_fetch_as_array (VALUE obj_stmt) { return _stmt_fetch(obj_stmt, rb_cArray, 1, 1); }
static VALUE stmt_fetch_as_array2(VALUE obj_stmt) { return _stmt_fetch(obj_stmt, rb_cArray, 1, 0); }
static VALUE stmt_fetch_all_as_arrays (VALUE obj_stmt) { return _stmt_fetch(obj_stmt, rb_cArray, 0, 1); }
static VALUE stmt_fetch_all_as_arrays2(VALUE obj_stmt) { return _stmt_fetch(obj_stmt, rb_cArray, 0, 0); }

static VALUE stmt_fetch_as_object (VALUE obj_stmt, VALUE klass) { return _stmt_fetch(obj_stmt, klass, 1, 1); }
static VALUE stmt_fetch_as_object2(VALUE obj_stmt, VALUE klass) { return _stmt_fetch(obj_stmt, klass, 1, 0); }
static VALUE stmt_fetch_all_as_objects (VALUE obj_stmt, VALUE klass) { return _stmt_fetch(obj_stmt, klass, 0, 1); }
static VALUE stmt_fetch_all_as_objects2(VALUE obj_stmt, VALUE klass) { return _stmt_fetch(obj_stmt, klass, 0, 0); }



void Init_motto_mysql(void)
{
    id_new              = rb_intern("new");
    id_initialize       = rb_intern("initialize");
    id_create_timestamp = rb_intern("create_timestamp");
    id_create_datetime  = rb_intern("create_datetime");
    id_create_date      = rb_intern("create_date");
    id_create_time      = rb_intern("create_time");
    id_close            = rb_intern("close");
    id_mktime           = rb_intern("mktime");
    id_free             = rb_intern("free");
    id_free_result      = rb_intern("free_result");

    rb_define_const(cMysql, "MOTTO_MYSQL_VERSION",  rb_str_freeze(rb_str_new2(MOTTO_MYSQL_VERSION)));

    /* require 'date' */
    rb_require("date");
    cDate     = rb_const_get(rb_cObject, rb_intern("Date"));
    cDateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));


    /* Mysql::create_{timestamp,datetime,date,time,timestamp_or_datetime} */
if (sizeof(time_t) == 8) {
    rb_define_singleton_method(cMysql, "create_timestamp", create_ruby_timestamp, 8);
} else {
    rb_define_singleton_method(cMysql, "create_timestamp", create_ruby_timestamp_or_datetime,  8);
}
    rb_define_singleton_method(cMysql, "create_datetime",  create_ruby_datetime,  8);
    rb_define_singleton_method(cMysql, "create_date",      create_ruby_date,      5);
    rb_define_singleton_method(cMysql, "create_time",      create_ruby_time,      5);
    rb_define_singleton_method(cMysql, "create_timestamp_or_datetime", create_ruby_timestamp_or_datetime,  8);


    /* Mysql::Result */
    rb_define_method(cMysqlRes, "fetch_as_hash",         result_fetch_as_hash,   0);
    rb_define_method(cMysqlRes, "fetch_as_array",        result_fetch_as_array,  0);
    rb_define_method(cMysqlRes, "fetch_as_object",       result_fetch_as_object, 1);
    rb_define_method(cMysqlRes, "fetch_as",              result_fetch_as_object, 1);
    rb_define_method(cMysqlRes, "fetch_all_as_hashes",   result_fetch_all_as_hashes,  0);
    rb_define_method(cMysqlRes, "fetch_all_as_arrays",   result_fetch_all_as_arrays,  0);
    rb_define_method(cMysqlRes, "fetch_all_as_objects",  result_fetch_all_as_objects, 1);
    rb_define_method(cMysqlRes, "fetch_all_as",          result_fetch_all_as_objects, 1);

    rb_define_method(cMysqlRes, "fetch_as_hash!",        result_fetch_as_hash2,   0);
    rb_define_method(cMysqlRes, "fetch_as_array!",       result_fetch_as_array2,  0);
    rb_define_method(cMysqlRes, "fetch_as_object!",      result_fetch_as_object2, 1);
    rb_define_method(cMysqlRes, "fetch_as!",             result_fetch_as_object2, 1);
    rb_define_method(cMysqlRes, "fetch_all_as_hashes!",  result_fetch_all_as_hashes2,  0);
    rb_define_method(cMysqlRes, "fetch_all_as_arrays!",  result_fetch_all_as_arrays2,  0);
    rb_define_method(cMysqlRes, "fetch_all_as_objects!", result_fetch_all_as_objects2, 1);
    rb_define_method(cMysqlRes, "fetch_all_as!",         result_fetch_all_as_objects2, 1);


    /* Mysql::Stmt */
    rb_define_method(cMysqlStmt, "fetch_as_hash",         stmt_fetch_as_hash,    0);
    rb_define_method(cMysqlStmt, "fetch_as_array",        stmt_fetch_as_array,   0);
    rb_define_method(cMysqlStmt, "fetch_as_object",       stmt_fetch_as_object,  1);
    rb_define_method(cMysqlStmt, "fetch_as",              stmt_fetch_as_object,  1);
    rb_define_method(cMysqlStmt, "fetch_all_as_hashes",   stmt_fetch_all_as_hashes,   0);
    rb_define_method(cMysqlStmt, "fetch_all_as_arrays",   stmt_fetch_all_as_arrays,   0);
    rb_define_method(cMysqlStmt, "fetch_all_as_objects",  stmt_fetch_all_as_objects,  1);
    rb_define_method(cMysqlStmt, "fetch_all_as",          stmt_fetch_all_as_objects,  1);

    rb_define_method(cMysqlStmt, "fetch_as_hash!",        stmt_fetch_as_hash2,   0);
    rb_define_method(cMysqlStmt, "fetch_as_array!",       stmt_fetch_as_array2,  0);
    rb_define_method(cMysqlStmt, "fetch_as_object!",      stmt_fetch_as_object2, 1);
    rb_define_method(cMysqlStmt, "fetch_as!",             stmt_fetch_as_object2, 1);
    rb_define_method(cMysqlStmt, "fetch_all_as_hashes!",  stmt_fetch_all_as_hashes2,  0);
    rb_define_method(cMysqlStmt, "fetch_all_as_arrays!",  stmt_fetch_all_as_arrays2,  0);
    rb_define_method(cMysqlStmt, "fetch_all_as_objects!", stmt_fetch_all_as_objects2, 1);
    rb_define_method(cMysqlStmt, "fetch_all_as!",         stmt_fetch_all_as_objects2, 1);

}
