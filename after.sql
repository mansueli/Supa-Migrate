set statement_timeout = '2min';
set work_mem = '1GB';
select pg_reload_conf();
