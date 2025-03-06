!set variable_substitution=true

USE ROLE ACCOUNTADMIN;

CREATE OR ALTER WAREHOUSE SNOWFLAKE_WH 
  WAREHOUSE_SIZE = XSMALL 
  AUTO_SUSPEND = 300 
  AUTO_RESUME= TRUE;

-- Separate database for git repository
CREATE OR ALTER DATABASE SNOWFLAKE_COMMON;

CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/&USERNAME')
  ENABLED = TRUE;

-- Git repository object is similar to external stage
CREATE OR REPLACE GIT REPOSITORY snowflake_common.public.snowflake_repo
  API_INTEGRATION = git_api_integration
  ORIGIN = '&REPOURL'; -- INSERT URL OF FORKED REPO HERE

CREATE OR ALTER DATABASE SNOWFLAKE_PROD;

-- To monitor data pipeline's completion
CREATE OR REPLACE NOTIFICATION INTEGRATION email_integration
  TYPE=EMAIL
  ENABLED=TRUE;

-- Database level objects
CREATE OR ALTER SCHEMA bronze;
CREATE OR ALTER SCHEMA silver;
CREATE OR ALTER SCHEMA gold;

-- Schema level objects
CREATE OR REPLACE FILE FORMAT bronze.json_format TYPE = 'json';
CREATE OR ALTER STAGE bronze.raw;

-- Copy file from GitHub to internal stage
copy files into @bronze.raw from @snowflake_common.public.snowflake_repo/branches/main/data/airport_list.json;

USE ROLE SECURITYADMIN;

CREATE USER SECONDARY_ACCOUNTADMIN
PASSWORD = 'Password123'
DEFAULT_ROLE = 'ACCOUNTADMIN'
MUST_CHANGE_PASSWORD = TRUE;