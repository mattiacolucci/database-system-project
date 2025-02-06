-- OPERATION 4 (get total number of orders handled by a team)
SET AUTOTRACE ON;
/

SELECT num_orders FROM Team WHERE code=3;
/


-- OPERATION 5 (show teams ordered by their score)
SELECT * FROM Team ORDER BY ((score.feedback_score+score.delivery_score)/2) DESC;
/

-- Try create an index on the score
-- NOT IMPLEMENTED ANYMORE (motivations in the documentation)
--CREATE INDEX SCORE_TEAM_IDX ON Team(score.delivery_score, score.feedback_score);
--/

--DROP INDEX SCORE_TEAM_IDX;
--/



--USEFUL COMMANDS

-- get block size
select block_size, tablespace_name from dba_tablespaces;
/

-- get 'code' Team attribute length
SELECT all_tab.column_name,
       all_tab.data_type,
       all_tab.data_length,
       (SELECT COMMENTS
          FROM user_col_comments t
         where t.TABLE_NAME = all_tab.TABLE_NAME
           and t.COLUMN_NAME = all_tab.column_name)
  FROM all_tab_columns all_tab
 WHERE all_tab.TABLE_NAME = 'TEAM'
/

--get pointer dimension
ANALYZE INDEX SYS_C008610 VALIDATE STRUCTURE;
/
SELECT * FROM INDEX_STATS;
/
