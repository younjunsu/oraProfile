#!/bin/bash
# Readme
#--------------------------------------------------------------------------------
# Version1 : 230810
#--------------------------------------------------------------------------------

# user configuration
#--------------------------------------------------------------------------------
SQLPLUS_USER=""
SQLPLUS_PASSWORD=""
#SQLPLUS_SQLPATH=""
SQL_GLOIN_PATH="$ORACLE_HOME/sqlplus/admin/gloin"
#--------------------------------------------------------------------------------
#NLS_LANG=UTF8
#LANG=ko_KR.utf8
#stty erase ^H
#stty erase ^?
#--------------------------------------------------------------------------------

# oraProfiler system configuration
#--------------------------------------------------------------------------------
rlwrap_vaild_check="Y"
#--------------------------------------------------------------------------------


# SQL_TRACE_FILE_PATH mkdir
#--------------------------------------------------------------------------------
if [ -n "$SQL_TRACE_FILE_PATH" ]
then
    mkdir $SQL_TRACE_FILE_PATH 2>/dev/null
fi
#--------------------------------------------------------------------------------


# working directory init function
#--------------------------------------------------------------------------------
function fn_work_directory_init(){
    2>/dev/null
    # mkdir $TB_SQLPATH/log 2>/dev/null
    # rm -f $TB_SQLPATH/log/trc.outfile 2>/dev/null
    # rm -f $TB_SQLPATH/log/sql_capture.txt 2>/dev/null
}
#--------------------------------------------------------------------------------


# display init function
#--------------------------------------------------------------------------------
function fn_display_init(){
    clear
}
#--------------------------------------------------------------------------------


# characterset check function
#--------------------------------------------------------------------------------
function fn_system_env_check(){
    # TB_SQLPATH_COPY="$TB_SQLPATH"
    
    if [ -z "$db_charset" ]
    then
        cd $HOME
db_charset=`
sqlplus "$SQLPLUS_USER/$SQLPLUS_PASSWORD" -s <<EOF
select name, value$ from sys.props$ where name in ('NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET');
EOF
`
        db_nls_charset=`echo "$db_charset" |grep "NLS_CHARACTERSET" |awk '{print $2}' 2>/dev/null`
        db_national_charset=`echo "$db_charset" |grep "NLS_NCHAR_CHARACTERSET" |awk '{print $3}' 2>/dev/null` 
    fi

    oracle_proc_check=`ps -ef|grep ora |grep -w $TB_SID 2>/dev/null`
}
#--------------------------------------------------------------------------------


# help message function
#--------------------------------------------------------------------------------
function fn_help_message(){
    echo ""
    echo "###############################"
    echo " oraProfiler mode help message"
    echo "###############################"
    echo " usage: sh oraProfiler.sh [option]"
    echo "-----------------------------"
    echo "  run  : start sqlplus Profiler"
    echo "  help : help message"
    echo "-----------------------------"
    echo ""
}
#--------------------------------------------------------------------------------


# oracle version check function
#-------------------------------------------------------------------------------
function fn_oracle_version_check(){
    oracle_sqlplus_version=`sqlplus -v  |grep "Release" |sed 's/   / /g'`

oracle_dbms_version=`
sqlplus "$SQLPLUS_USER/$SQLPLUS_PASSWORD" -s <<EOF
SELECT 'Oracle DBMS Version', banner FROM v$version WHERE banner LIKE ('%Database%');
EOF
`
    oracle_dbms_version=`echo "$oracle_dbms_version" |grep "Oracle DBMS Version" |awk '{print $2}' >/dev/null
}
#-------------------------------------------------------------------------------


# exception check function 
#-------------------------------------------------------------------------------
function fn_error_check(){
    error_check="success"
    
    fn_oracle_version_check
    fn_system_env_check
            

    if [ -z "$oracle_proc_check" ]
    then
        echo " ERROR : Check the tbsvr process"
        error_check="error"
    fi

    if [ -z "$TB_SID" ]
    then
        echo " ERROR : TB_SID variable is empty"
        error_check="error"
    fi

    if [ -z "$SQLPLUS_USER" ]
    then
        echo "ERROR : SQLPLUS_USER variable is empty"
        error_check="error"
    fi

    if [ -z "$SQLPLUS_PASSWORD" ]
    then
        echo "ERROR : SQLPLUS_PASSWORD variable is empty"
        error_check="error"
    fi

    if [ -z "$TB_SQLPATH" ]
    then
        echo "ERROR : TB_SQLPATH variable is empty"
        error_check="error"
    fi

    if [ -z "$SQL_TRACE_FILE_PATH" ]
    then
        echo "ERROR : SQL_TRACE_FILE_PATH variable is empty"
        error_check="error"
    fi

    if [ ! -e "$SQL_TRACE_FILE_PATH" ]
    then
        echo "ERROR : SQL_TRACE_FILE_PATH path dose not exist"
        error_check="error"
    fi
      
    if [ ! -e "$TB_SQLPATH" ]
    then
        echo "ERROR : TB_SQLPATH path dose not exist"
        error_check="error"
    fi

    if [ "$error_check" == "error" ]
    then
        exit 1
    elif [ "$error_check" == "success" ]
    then
        fn_work_directory_init
        continue
    else
        exit 0
    fi
}
#-------------------------------------------------------------------------------


# oraProfiler meta display message function
#-------------------------------------------------------------------------------
function fn_oraProfiler_options_message(){
    fn_display_init    
    fn_oracle_version_check
    echo "###############################"
    echo "# oraProfiler mode options"
    echo "###############################"
    echo "  - Oracle DBMS    VERSION             : $oracle_version"
    echo "  - Oracle SQLPLUS VERSION             : $oracle_sqlplus_version"
    echo "  - oracle USER                : $SQLPLUS_USER"
    echo "  - TB_SQLPATH                 : $TB_SQLPATH"
    # echo "  - SQL_TRACE_FILE_PATH        : $SQL_TRACE_FILE_PATH"
    echo "  - NLS_LANG                : $NLS_LANG"
    echo "  - DB CHARACTERSET_NAME       : $db_nls_charset"
    echo "  - DB NCHAR_CHARACTERSET_NAME : $db_national_charset"
    echo "-----------------------------"
    # echo "  sql tbprof file count : "`ls $TB_SQLPATH/log |grep trc |wc -l`
    # echo "    - $TB_SQLPATH"    
    # echo "  sql trace file count  : "`ls $SQL_TRACE_FILE_PATH |wc -l`
    # echo "    - $SQL_TRACE_FILE_PATH"
    # echo "-----------------------------"
    echo ""
}
#-------------------------------------------------------------------------------


# sql autot trace apply function
#-------------------------------------------------------------------------------
function fn_set_autot_trace_check(){
    cd $TB_SQLPATH
    echo ""
    echo "###############################"
    echo "# Please select the trace option."
    echo "###############################"
    echo " - set autot on exp stat          : 1"
    echo " - set autot on                   : 2"
    echo " - set autot on exp               : 3"
    echo " - set autot on stat              : 4"
    echo " - set autot trace exp stat       : 5"
    echo " - set autot trace                : 6"
    echo " - set autot trace exp            : 7"
    echo " - set autot trace stat           : 8"
    echo "-----------------------------"
    echo " - quit : q"
    echo "-----------------------------"
    echo " - other key no trace"
    echo "-----------------------------"
    echo ""
    echo -n "  press key : "
    read press_key
    echo ""
    case "$press_key" in
        1)
            echo "  - apply : set autot on exp stat plans"
            sed -i '/    ;/c\set autot on exp stat plans    ;' tbsql.login        
        ;;
        2)
            echo "  - apply : set autot on"
            sed -i '/    ;/c\set autot on    ;' tbsql.login
        ;;
        3)
            echo "  - apply : set autot on exp"
            sed -i  '/    ;/c\set autot on exp    ;' tbsql.login
        ;;
        4)
            echo "  - apply : set autot on stat"
            sed -i '/    ;/c\set autot on stat    ;' tbsql.login
        ;;
        5)
            echo "  - apply : set autot on plans"
            sed -i '/    ;/c\set autot on plans    ;' tbsql.login
        ;;
        6)
            echo "  - apply : set autot trace exp stat plans"
            sed -i '/    ;/c\set autot trace exp stat plans    ;' tbsql.login
        ;;
        7)
            echo "  - apply : set autot trace"
            sed -i '/    ;/c\set autot trace    ;' $.login
        ;;
        8)
            echo "  - apply : set autot trace exp"
            sed -i '/    ;/c\set autot trace exp    ;' tbsql.login
        ;;
        9)
            echo "  - apply : set autot trace stat"
            sed -i '/    ;/c\set autot trace stat    ;' tbsql.login
        ;;
        "q")
            exit 1
        ;;
        *)
            echo "  - no trace option"
            sed -i '/    ;/c\    ;' tbsql.login
        ;;
    esac
    echo ""
}
#-------------------------------------------------------------------------------


# oraProfiler mode function
#-------------------------------------------------------------------------------
function fn_oraProfiler_mode(){
    # oraProfiler mode options display
    #---------------------------------------------------------------------------        
    fn_oraProfiler_options_message
    #---------------------------------------------------------------------------        
        
    # autot setting
    #---------------------------------------------------------------------------        
    fn_set_autot_trace_check
    #---------------------------------------------------------------------------

    # oraProfiler mode query press and tools message display
    #---------------------------------------------------------------------------
    cd $TB_SQLPATH

    echo "###############################"
    echo "# tbsql.loing options apply"
    echo "###############################"
    echo ""
    rlwrap_check=`whereis rlwrap |sed 's/rlwrap://g'`
    
    
    if [ -z "$rlwrap_check" ] || [ "$rlwrap_vaild_check" == "N" ]
    then
        tbsql $SQLPLUS_USER/$SQLPLUS_PASSWORD -s 
    elif [ -n "$rlwrap_check" ]
    then
        rlwrap tbsql $SQLPLUS_USER/$SQLPLUS_PASSWORD -s 
    fi       
    # tbsql.login apply  
    # query running
    #---------------------------------------------------------------------------

    # xplan running
    #---------------------------------------------------------------------------
    fn_xplan_execute
    #---------------------------------------------------------------------------
}
#-------------------------------------------------------------------------------

# exit message function
#-------------------------------------------------------------------------------
function fn_exit(){
    echo ""
    echo "###############################"
    echo "# oraProfiler mode menu"
    echo "###############################"
    echo ""
    echo "  - oraProfiler  : re"
    echo "  - tbprof      : tr"
    echo "  - quit        : q"
    echo "-----------------------------"
    echo "    other key retry."
    echo "-----------------------------"
    echo ""
    echo -n  "  press key : "
    read press_key

    case "$press_key" in 
        "re")
            echo ""
            fn_oraProfiler_mode
        ;;
        "tr")
            echo ""
            fn_tbporf_execute
        ;;
        "q")
            echo ""
            echo "###############################"
            echo "# oraProfiler mode stop"
            echo "###############################"
            echo " ....exit"
            echo ""
            exit 1
        ;;
        *)
            fn_exit
        ;;
    esac
}
#-------------------------------------------------------------------------------


# functions process
#--------------------------------------------------------------------------------
    vaild_option=$1
    case "$vaild_option" in
        "run")
            fn_error_check
            fn_oraProfiler_mode
        ;;
        *)
            fn_help_message
        ;;
    esac
#--------------------------------------------------------------------------------
