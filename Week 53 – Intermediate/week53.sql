--ロール指定
use role accountadmin;

--ウェアハウス作成
create warehouse if not exists frosty_friday_wh
    WAREHOUSE_SIZE = 'x-small'
    AUTO_SUSPEND = 300
    AUTO_RESUME = true
    INITIALLY_SUSPENDED = true
;

--データベース作成
create database frosty_friday;

--スキーマ作成 
create schema frosty_friday.ff_week53;

--内部ステージ作成
create stage if not exists ff_week53_stage;

--ステージ確認
list @ff_week53_stage;

--フォーマット作成
create or replace file format ff_week53_format
  field_optionally_enclosed_by = '"'
  skip_header = 1
;
----------------------------------------------
--SnowSQL
----------------------------------------------
snowsql -a cb60066.ap-northeast-1.aws -u kayo
＜パスワード＞

use warehouse frosty_friday_wh;
use database frosty_friday;
use schema ff_week53;

--内部ステージ確認
list @ff_week53_stage;

--内部ステージへアップロード
put file://C:\tmp\Snowflake\FF\employees.csv @ff_week53_stage;

--内部ステージ確認
list @ff_week53_stage;

----------------------------------------------
--Snowsight
----------------------------------------------
--infer_schemaで列定義の確認
select *
from table(
  infer_schema(
    location => '@ff_week53_stage',
    file_format => 'ff_week53_format'
  )
)
;

----------------------------------------------
--week53回答
----------------------------------------------
select ORDER_ID as COLUMN_POSITION, TYPE as DATA_TYPE
from table(
  infer_schema(
    location => '@ff_week53_stage',
    file_format => 'ff_week53_format'
  )
);

-- 内部ステージのファイルからテーブル作成
create or replace table week53_table
as
select ORDER_ID AS COLUMN_POSITION, TYPE as DATA_TYPE
from table(
  infer_schema(
    location => '@ff_week53_stage',
    file_format => 'ff_week53_format'
  )
);

--テーブル確認
select * from week53_table;


----------------------------------------------
--week53別解
--infer_schema情報を全てテーブルにロード
----------------------------------------------
create or replace table infer_schema_table
as
select *
from table(
  infer_schema(
    location => '@ff_week53_stage',
    file_format => 'ff_week53_format'
  )
)
;

--テーブル確認
select * from infer_schema_table;

--回答に必要な対象列のみビュー作成
create or replace view week53_view
as
  select
      ORDER_ID as COLUMN_POSITION
    , TYPE as DATA_TYPE
  from infer_schema_table
;


-- ビュー参照
select * from week53_view;


----------------------------------------------
--week53おまけ
----------------------------------------------
--parse_headerフォーマット作成
create or replace file format ff_format_parseheader
parse_header = true;

--テーブル作成
create or replace table WEEK53_TABLE_OMAKE
  using template (
    select array_agg(object_construct(*))
      from table(
        infer_schema(
          location => '@ff_week53_stage'
          , file_format => 'ff_format_parseheader'
          , ignore_case => true
        )
    )
);

--テーブル確認
select * from week53_table_omake;

--テーブル情報確認
select * from information_schema.columns where table_name='week53_table_omake' order by ordinal_position;

--ステージからテーブルへロード
copy into week53_table_omake 
    from @ff_week53_stage 
        file_format = (format_name= 'ff_format_parseheader') 
        match_by_column_name=case_insensitive;

--テーブル確認
select * from week53_table_omake;
