
-- get columns:

SELECT  count(distinct column_name) ,  (select  count(*) from  `your-project.staging.churn`)
FROM `your-project.staging.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'churn'

-- You can now use INFORMATION_SCHEMA - a series of views that provide access to metadata about datasets, tables, and views
SELECT * EXCEPT(is_generated, generation_expression, is_stored, is_updatable)
FROM `your-project.staging.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'churn'

-- nunique():

DECLARE columns ARRAY<STRING>;
DECLARE query STRING;
SET columns = (
  WITH all_columns AS (
    SELECT column_name
    FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'churn'
  )
  SELECT ARRAY_AGG((column_name) ) AS columns
  FROM all_columns
);

SET query = (select STRING_AGG('(select count(distinct '||x||')  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );
EXECUTE IMMEDIATE 
"SELECT  "|| query
;

-- mean:
DECLARE columns ARRAY<STRING>;
DECLARE query STRING;
SET columns = (
  WITH all_columns AS (
    SELECT column_name
    FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'churn' 
        and  data_type IN ('INT64','FLOAT64')
  )
  SELECT ARRAY_AGG((column_name) ) AS columns
  FROM all_columns
);

SET query = (select STRING_AGG('(select avg( '||x||')  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );
EXECUTE IMMEDIATE 
"SELECT  "|| query
;

-- added ST_DEV:

DECLARE columns ARRAY<STRING>;
DECLARE query1, query2, query3 STRING;
SET columns = (
  WITH all_columns AS (
    SELECT column_name
    FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'churn' 
        and  data_type IN ('INT64','FLOAT64')
  )
  SELECT ARRAY_AGG((column_name) ) AS columns
  FROM all_columns
);

SET query1 = (select STRING_AGG('(select stddev( '||x||')  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );
SET query2 = (select STRING_AGG('(select avg( '||x||')  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );
EXECUTE IMMEDIATE (
"SELECT 'stddev: ' ,"|| query1 || " UNION ALL " ||
"SELECT 'mean: '   ,"|| query2
)
;

-- add all:

DECLARE columns ARRAY<STRING>;
DECLARE query1, query2, query3, query4, query5, query6, query7, query8 STRING;
SET columns = (
  WITH all_columns AS (
    SELECT column_name
    FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'churn' 
        and  data_type IN ('INT64','FLOAT64')
  )
  SELECT ARRAY_AGG((column_name) ) AS columns
  FROM all_columns
);

SET query1 = (select STRING_AGG('(select stddev( '||x||')  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );
SET query2 = (select STRING_AGG('(select avg( '||x||')  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );
SET query3 = (select STRING_AGG('(select PERCENTILE_CONT( '||x||', 0.5) over()  from `your-client.staging.churn` limit 1) '||x ) AS string_agg from unnest(columns) x );
SET query4 = (select STRING_AGG('(select PERCENTILE_CONT( '||x||', 0.25) over()  from `your-client.staging.churn` limit 1) '||x ) AS string_agg from unnest(columns) x );
SET query5 = (select STRING_AGG('(select PERCENTILE_CONT( '||x||', 0.75) over()  from `your-client.staging.churn` limit 1) '||x ) AS string_agg from unnest(columns) x );
SET query6 = (select STRING_AGG('(select max( '||x||')  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );
SET query7 = (select STRING_AGG('(select min( '||x||')  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );
SET query8 = (select STRING_AGG('(select countif( '||x||' is null)  from `your-client.staging.churn`) '||x ) AS string_agg from unnest(columns) x );

EXECUTE IMMEDIATE (
"SELECT 'stddev' ,"|| query1 || " UNION ALL " ||
"SELECT 'mean'   ,"|| query2 || " UNION ALL " ||
"SELECT 'median' ,"|| query3 || " UNION ALL " ||
"SELECT '0.25' ,"|| query4 || " UNION ALL " ||
"SELECT '0.75' ,"|| query5 || " UNION ALL " ||
"SELECT 'max' ,"|| query6 || " UNION ALL " ||
"SELECT 'min' ,"|| query7 || " UNION ALL " ||
"SELECT 'nulls' ,"|| query8
)
;



-- Remove outliers:
DECLARE lower, upper, mean FLOAT64;
SET mean = (select avg( EstimatedSalary)  from `your-client.staging.churn`);
SET lower = mean - 3 * (select stddev( EstimatedSalary)  from `your-client.staging.churn`);
SET upper = mean + 3 * (select stddev( EstimatedSalary)  from `your-client.staging.churn`);
EXECUTE IMMEDIATE (
"SELECT * from `your-client.staging.churn` WHERE EstimatedSalary >"|| upper ||" OR EstimatedSalary < " || lower

)


-- dropna()
-- Simply iterate and delete rows:

DECLARE columns ARRAY<STRING>;
DECLARE query STRING DEFAULT '';
DECLARE i INT64 DEFAULT 0;

SET columns = (
  WITH all_columns AS (
    SELECT column_name
    FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'churn' 
        -- and  data_type IN ('INT64','FLOAT64')
  )
  SELECT ARRAY_AGG((column_name) ) AS columns
  FROM all_columns
);

LOOP
    SET i = i + 1;

    IF i > ARRAY_LENGTH(columns) THEN 
        LEAVE;
    END IF;
 
    SET query = ' DELETE FROM  `your-client.staging.churn` WHERE ' || columns[ORDINAL(i)] || ' is null '  ;
    EXECUTE IMMEDIATE (
        query
    );

END LOOP;

-- EXECUTE IMMEDIATE 
-- " select distinct " || (select  STRING_AGG( x ) AS string_agg from unnest(columns) x) || " FROM (  "|| query || ");"
-- ;

-- EXECUTE IMMEDIATE '''
--     INSERT result
--     SELECT "''' || FIELDS_TO_CHECK[ORDINAL(i)] || '''", COUNT(''' || FIELDS_TO_CHECK[ORDINAL(i)] || ''') / COUNT(*) FROM `table_name`
--   ''';


--- dropna() with just SELECT:
DECLARE columns ARRAY<STRING>;
DECLARE query STRING DEFAULT '';
DECLARE i INT64 DEFAULT 0;

SET columns = (
  WITH all_columns AS (
    SELECT column_name
    FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'churn' 
        -- and  data_type IN ('INT64','FLOAT64')
  )
  SELECT ARRAY_AGG((column_name) ) AS columns
  FROM all_columns
);

LOOP
    SET i = i + 1;

    IF i > ARRAY_LENGTH(columns) THEN 
        LEAVE;
    END IF;

    IF i > 1 THEN
        SET query = query || ' AND ';
    END IF;
 
    SET query = query || ' ' || columns[ORDINAL(i)] || ' is not null '  ;
    

END LOOP;

EXECUTE IMMEDIATE (
        ' SELECT * FROM  `your-client.staging.churn` WHERE ' || query
    );




-- How to do while loop:
DECLARE x INT64 DEFAULT 0;
WHILE x < 10 
DO
  SET x = x + 1;
END WHILE;
SELECT x;
-- How to do a loop:
DECLARE x INT64 DEFAULT 0;
LOOP
  SET x = x + 1;
  IF x >= 10 THEN
    BREAK;
  END IF;
END LOOP;
SELECT x;




-- correlation matrix:

DECLARE columns ARRAY<STRING>;
DECLARE query STRING DEFAULT '';
DECLARE i,j INT64 DEFAULT 0;

SET columns = (
  WITH all_columns AS (
    SELECT column_name
    FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'churn' 
        and column_name not in ('RowNumber', 'CustomerId', 'Surname')
        and  data_type IN ('INT64','FLOAT64')
  )
  SELECT ARRAY_AGG((column_name) ) AS columns
  FROM all_columns
);

LOOP
    SET i = i + 1;

    IF i > ARRAY_LENGTH(columns) THEN 
        LEAVE;
    END IF;

    IF i > 1 THEN 
        SET query = query || ' UNION ALL ';
    END IF;
        SET query = query || ' SELECT '|| i || ","||"'"||columns[ORDINAL(i)]|| "'" ;
        
        LOOP
            SET j = j + 1;

            IF j > ARRAY_LENGTH(columns) THEN 
                LEAVE;
            END IF;
 
            SET query = query || ' , round(corr('|| columns[ORDINAL(i)] ||','|| columns[ORDINAL(j)] ||'),4)  as ' ||" "||columns[ORDINAL(j)]|| " "  ;
        END LOOP;
        SET query = query || ' FROM  `your-client.staging.churn` ' ;
        SET j = 0;
    

END LOOP;

--select query;


EXECUTE IMMEDIATE (
        query || " order by 1;"
    );

SELECT  corr(CreditScore,Balance) FROM `your-client.staging.churn`
------------------------------------------------------------------------------------------------------------------------------------------


-- churn count:

SELECT  countif(exited = 1)                     as amount_lost
, countif(exited = 0)                           as amount_retained
, count(*) total, countif(exited = 1)/count(*)  as churn_percent
, countif(exited = 0)/count(*)                  as retained_percent
FROM `your-client.staging.churn`
;



SELECT  *
    , if(exited = 1,'amount_lost', 'amount_retained')   as exited_category
    , 1/ count(*)    over()                             as percent
FROM `your-client.staging.churn`
;




-- box plot:
select 
exited
,stat
,avg(min) min
,avg(q25) q25
,avg(median) median
,avg(q75) q75
,avg(max) max
from (
    SELECT exited, 'balance' as stat ,
  PERCENTILE_CONT(balance, 0) OVER(partition by exited)     AS min,
  PERCENTILE_CONT(balance, 0.25) OVER(partition by exited)  AS q25,
  PERCENTILE_CONT(balance, 0.5) OVER(partition by exited)   AS median,
  PERCENTILE_CONT(balance, 0.75) OVER(partition by exited)  AS q75,
  PERCENTILE_CONT(balance, 1) OVER(partition by exited)     AS max
  FROM `your-client.staging.churn` 
)
  group by 1,2
;


-- Age. box plot:

select 
exited
,stat
,avg(min) min
,avg(q25) q25
,avg(median) median
,avg(q75) q75
,avg(max) max
from (
    SELECT exited, 'age' as stat ,
  PERCENTILE_CONT(age, 0) OVER(partition by exited)     AS min,
  PERCENTILE_CONT(age, 0.25) OVER(partition by exited)  AS q25,
  PERCENTILE_CONT(age, 0.5) OVER(partition by exited)   AS median,
  PERCENTILE_CONT(age, 0.75) OVER(partition by exited)  AS q75,
  PERCENTILE_CONT(age, 1) OVER(partition by exited)     AS max
  FROM `your-client.staging.churn` 
)
  group by 1,2


-- Histogram
SELECT count(*) frequency, bucket 
FROM (
    SELECT customerId, round(Age / 10)* 10 as bucket FROM `your-client.staging.churn`)
GROUP BY bucket
order by 2




-- ntiles:
select ntile, min(Age) min, max(Age) max , count(*) frequency
from (
    select Age, 
    ntile(4) over (order by Age) ntile
    from `your-client.staging.churn`
) x
group by ntile 
order by ntile 




- outliers:
-- To determine which points are outliers, you must first determine the interquartile range (IQR). It's the difference between q1 and q3. Outliers are values that fall 1.5x IQR below q1 or 1.5x IQR above q3.

-- This query returns outlier values as a string of comma-separated values. It also replaces the minimum and maximum values with non-outlier values.

SELECT series,
       ARRAY_TO_STRING(ARRAY_AGG(CASE WHEN value < q1 - ((q3-q1) * 1.5) 
         THEN value::VARCHAR ELSE NULL END),',') AS lower_outliers,
       MIN(CASE WHEN value >= q1 - ((q3-q1) * 1.5) THEN value ELSE NULL END) AS minimum,
       AVG(q1) AS q1,
       AVG(median) AS median,
       AVG(q3) AS q3,
       MAX(CASE WHEN value <= q3 + ((q3-q1) * 1.5) THEN value ELSE NULL END) AS maximum,
       ARRAY_TO_STRING(ARRAY_AGG(CASE WHEN value > q3 + ((q3-q1) * 1.5) 
         THEN value::VARCHAR ELSE NULL END),',') AS upper_outliers
  FROM quartiles
GROUP BY 1








--SQL:
SELECT distinct column_name 
FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'churn'

DECLARE col_0 STRING;
SET col_0 = 'EstimatedSalary';
EXECUTE IMMEDIATE format("""
  SELECT 
     RowNumber, 
     %s AS EstimatedSalary
  FROM `your-client`.staging.churn
  ORDER BY EstimatedSalary DESC
""", col_0);


DECLARE columns ARRAY<STRUCT<column_name STRING>>;
SET columns = (
  WITH all_columns AS (
    SELECT column_name
    FROM `your-client.staging.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'churn'
  )
  SELECT ARRAY_AGG(STRUCT(column_name) ) AS columns
  FROM all_columns
);

select columns, (SELECT STRING_AGG(x) FROM UNNEST(columns) x);

---
---

-- pivot:
CREATE OR REPLACE FUNCTION 
`fhoffa.x.normalize_col_name`(col_name STRING) AS (
  REGEXP_REPLACE(col_name,r'[/+#|]', '_'
)CREATE OR REPLACE PROCEDURE `fhoffa.x.pivot`(
  table_name STRING
  , destination_table STRING
  , row_ids ARRAY<STRING>
  , pivot_col_name STRING
  , pivot_col_value STRING
  , max_columns INT64
  , aggregation STRING
  , optional_limit STRING
  )
BEGIN  DECLARE pivotter STRING;  EXECUTE IMMEDIATE (
    "SELECT STRING_AGG(' "||aggregation
    ||"""(IF('||@pivot_col_name||'="'||x.value||'", '||@pivot_col_value||', null)) e_'||fhoffa.x.normalize_col_name(x.value))
   FROM UNNEST((
       SELECT APPROX_TOP_COUNT("""||pivot_col_name||", @max_columns) FROM `"||table_name||"`)) x"
  ) INTO pivotter 
  USING pivot_col_name AS pivot_col_name, pivot_col_value AS pivot_col_value, max_columns AS max_columns;  EXECUTE IMMEDIATE (
   'CREATE OR REPLACE TABLE `'||destination_table
   ||'` AS SELECT '
   ||(SELECT STRING_AGG(x) FROM UNNEST(row_ids) x)
   ||', '||pivotter
   ||' FROM `'||table_name||'` GROUP BY '
   || (SELECT STRING_AGG(''||(i+1)) FROM UNNEST(row_ids) WITH OFFSET i)||' ORDER BY '
   || (SELECT STRING_AGG(''||(i+1)) FROM UNNEST(row_ids) WITH OFFSET i)
   ||' '||optional_limit
  );
END;