##
# Execute db query on mongodb and export output to csv
# Pre-requisite:
# - pip3 install pymongo
# -
##

import os
import sys
import yaml

## Variables
dbMappingFile = os.environ['DB_MAPPING_FILE'] if 'DB_MAPPING_FILE' in os.environ else 'db_mapping_file.yml'
dbName = os.environ['DB_NAME'] if 'DB_NAME' in os.environ else False

## GET DB info
def getDBInfo():
    try:
        global dbInfo, dbType, dbURL, dbQueryFile, dbColName
        data = yaml.load(open(dbMappingFile), Loader=yaml.FullLoader)['db_info']
        dbInfo = [ d for d in data if d['name'] == dbName ][0]
        dbType = dbInfo['db_type']
        if dbType ==  'mongodb':
            dbColName = 'state_machines'
        dbURL = dbInfo['db_url']
        dbQueryFile = dbInfo['db_query_file']
    except Exception as err:
        ERR='FAILED: With Error: {}'.format(str(err))
        print(ERR)
        fail_msg(ERR)


## Read RB Query
def readDBQueryFromFile(FLE):
    if os.path.isfile(FLE) and os.path.getsize(FLE) > 0:
        return open(CF).read()
    else:
        fail_msg('FAILED: DB Query File {}, not exist or blank!!'.format(FLE))


## Function to execute MSSQL QUERY
def db_query_execute(QUERY, ACT):
    try:
        sql =
        conn = pyodbc.connect(sql)
        cursor = conn.cursor()
        result = cursor.execute(QUERY)
        if ACT == 'AU':
            conn.commit()
        return result
    except Exception as err:
        ERR='Script Failed in db_query_execute function with Error: {}'.format(str(err))
        print(ERR)
        errorTracking.append(ERR)
        pass


## MAIN
if __name__ == "__main__":
    # get db info
    dbName = db_name
    if dbName:
        fail_msg("DB Name can't be blank!!")
    else:
        getDBInfo()
        print('Processing, DBName: {}\nDBType: {}\nDBURL: {}, DBQueryFile: {}'.format(dbName, dbType, dbURL, dbQueryFile))
        dbQuery = readDBQueryFromFile(dbQueryFile)

        if dbType == 'mongodb':
            print('Processing for mongodb')
            from pymongo import MongoClient
            dbClient = MongoClient(dbURL)
            db = dbClient[dbName]
            curser = db.get_collection(dbColName).find(dbQuery) // this needs to be tested for csv op
            print(curser)
        elif dbType == 'db2':
            print('Processing for db2, NOT YET SUPPORTED!!')
        elif dbType == 'mssql':
            print('Processing for mssql, NOT YET SUPPORTED!!')
        elif dbType == 'mssql':
            print('Processing for mssql, NOT YET SUPPORTED!!')
        else:
            fail_msg('Unsupported DB Type {}, NOT YET SUPPORTED!!   '.format(dbType))

## FAIL MESSAGE
def fail_msg(MSG):
    print(MSG)
    sys.exit()


## END
