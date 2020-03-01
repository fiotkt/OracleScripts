---------------VERSION v1.1
---------------Author: Lee Hallwood (LLH)
---------------Version  Date           Author  Change
---------------V1.0     19 April 2013  LLH     Initial Version
---------------V1.1     24 April 2013  LLH     1. Only check for NBK% or Z% when reporting users that have app support grants 
--                                                but not part of the app supp team
--                                             2. Remove Create session from the explicit SYS grants
--             V1.2     02 May 2013    LLH     1. For the assigning of roles to the support staff select now uses distinct
--                                        If the user had two APP%SUPP% roles assigned they would appear twice in this list
--             V1.3     16 May 2013    LLH     1. Changed the db link to point to the new one
--             V1.4     16 May 2013    LLH     1. Remove order by 
--             V1.5     19 June 2013   LLH     Various Fixes/improvements
--                                             1. Grants for Directories was not correct - Fixed
--                                             2. Grants to APPS_SUPPORT_L2 now instead of APP_SUPPORT_L2 - Fixed
--                                             3. Last block of granting roles to the users was not working - Fixed
--                                             4. At end of program revoke apps support from current apps support team
--                                             5. At beginning of output script that revokes app support from those users not in L2 nor L3
--                                             6. Output the command to revoke Explicit grants/sys grants to L2/L3 staff
--                                             7. All ***Warning output now replaced with --*Warning so can copy and paste output and run
--                                             8. Select DISTINCT on the replication of APPS_SUPPORT grants and also omit APPS_SUPPORT_L2
--                                                and APPS_SUPPORT_L3 in case script has been ran previous and these rules have been created
--                                             9. Warns if APPS%SUPP% is allocated to non NBK/ZK accounts
set feedback off echo off termout off
column name new_value db_name
select name from v$database;
spool &db_name..sql
set pages 0 lines 150
set serveroutput on
DECLARE
  t_counter PLS_INTEGER;
  b_can_drop       BOOLEAN := TRUE;
  b_ok_to_continue BOOLEAN := TRUE;
  g_list_of_nbks sys.dbms_debug_vc2coll := new sys.dbms_debug_vc2coll();
  PROCEDURE populate_nbks IS
  BEGIN
    g_list_of_nbks.extend;
    g_list_of_nbks(g_list_of_nbks.count):='ZXASSE:L3:JESUS:JAPPSTAM';
    g_list_of_nbks.extend;
    g_list_of_nbks(g_list_of_nbks.count):='ABCDEF:L3:LEE:HAIMSTEAD';
    g_list_of_nbks.extend;
  END;
BEGIN
  --Build up a list of NBKs and corresponding support level
  populate_nbks;
  --
  --Check to see if APPS_SUPPORT_L2/L3 already exist in this database
  SELECT count(1)
    INTO t_counter
    FROM dba_roles
   WHERE ROLE IN ('APPS_SUPPORT_L2','APPS_SUPPORT_L3');
  --
  IF t_counter > 0 THEN
    DBMS_OUTPUT.PUT_LINE('--*WARNING ROLES APPS_SUPPORT_L2 and/or APPS_SUPPORT_L3 Have already been created in this database');
    b_ok_to_continue:=FALSE;
  END IF;
  --
  --Check if APP%SUP roles exist within the database
  SELECT count(1)
    INTO t_counter
    FROM dba_roles
   WHERE role like 'APP%SUP%'
   AND ROLE NOT IN ('APPS_SUPPORT_L2','APPS_SUPPORT_L3');
  --
  --IF App support roles not in this database then raise a warning
  IF t_counter = 0 THEN
    DBMS_OUTPUT.PUT_LINE('--*WARNING ROLES APPS_SUPPORT, APPLICATION_SUPPORT nor APPS_SUP_ROLE EXIST IN THIS DATABASE');
    b_ok_to_continue:=FALSE;
  END IF;
  --
  --Check if other roles are granted to the APP%SUP% roles, if so then warn that needs to be reviewed
  FOR r_other_roles_granted IN (SELECT grantee, granted_role,
                                       row_number () over (partition by grantee ORDER BY grantee, granted_role) as reset_counter
                                  FROM dba_role_privs
                                 WHERE grantee IN (SELECT role 
                                                     FROM dba_roles 
                                                    WHERE role LIKE 'APP%SUP%'
                                                      AND role NOT IN ('APPS_SUPPORT_L2','APPS_SUPPORT_L3'))
                                 ORDER BY grantee, granted_role) LOOP
    IF r_other_roles_granted.reset_counter=1 THEN
      DBMS_OUTPUT.PUT_LINE('--*WARNING ROLES GRANTED TO ROLE '||r_other_roles_granted.grantee);
    END IF;
    DBMS_OUTPUT.PUT_LINE('     ROLE Assigned to  '||r_other_roles_granted.grantee||':-' ||r_other_roles_granted.granted_role);
    b_ok_to_continue := FALSE;
  END LOOP;
  --Is APP%SUPP% roles applied to NON-NBK accounts?
  FOR r_can_we_drop_app_supp IN (SELECT grantee, granted_role
                                   FROM dba_role_privs
                                  WHERE (grantee NOT LIKE 'NBK%' AND grantee NOT LIKE 'ZK%')
                                    AND granted_role like 'APP%SUP%' 
                                    AND granted_role NOT IN ('APPS_SUPPORT_L2','APPS_SUPPORT_L3')
                                  ORDER BY granted_role) LOOP
     DBMS_OUTPUT.PUT_LINE('--WARNING Role '||r_can_we_drop_app_supp.granted_role||' is allocated to NON NBK/ZK account - '
                                           ||r_can_we_drop_app_supp.grantee);
    b_can_drop       := FALSE;    
    b_ok_to_continue := FALSE;
  END LOOP;
  --Check all L2 and L3 users are setup in the database
  FOR r_L2_L3_Users_Not_In_DB IN (SELECT substr(column_value,1,instr(column_value,':')-1) as nbk,
                                         substr(column_value,instr(column_value,':',1,2)+1,
                                                             instr(column_value,':',1,3)-instr(column_value,':',1,2)-1) as forename,
                                         substr(column_value,instr(column_value,':',1,3)+1,
                                                             length(column_value)-instr(column_value,':',1,2)-1) as surname
                                    FROM table(cast(g_list_of_nbks as sys.dbms_debug_vc2coll)) supp_users, dba_users
                                   WHERE substr(column_value,1,instr(column_value,':')-1)=dba_users.username(+)
                                     AND dba_users.username is null) LOOP
    DBMS_OUTPUT.PUT_LINE('--*WARNING: User '||r_L2_L3_Users_Not_In_DB.nbk||' '||'('
                                            ||r_L2_L3_Users_Not_In_DB.forename||' '
                                            ||r_L2_L3_Users_Not_In_DB.surname||')'
                                            ||' is not set up in the database but is part of L2_L3 users, please review');
    --Ok to ignore this warning, don't need to stop output
    --b_ok_to_continue := FALSE;
  END LOOP;
  --
  --Now check the users assigned to the APP_SUPP roles, those not in the L2 or L3 support roles are highlighted
  --V1.5 Also, the revoke command is outputted
  FOR r_nbk_users_assigned_appsupp IN (SELECT grantee, granted_role,
                                       decode(cd.firstname||cd.lastname,null,'Not in corp dir',
                                              cd.firstname||' '||cd.lastname) as name
                                         FROM dba_role_privs, pbics.corp_dir_v@pbicsp cd
                                        WHERE granted_role like 'APP%SUP%'
                                          AND dba_role_privs.grantee=cd.nbk(+)
                                          AND dba_role_privs.grantee NOT IN
                                       (SELECT substr(column_value,1,instr(column_value,':')-1) as nbk
                                         FROM table(cast(g_list_of_nbks as sys.dbms_debug_vc2coll)))
                                          AND dba_role_privs.grantee NOT IN
                                              (SELECT role FROM DBA_ROLES)
                                          --V1.1 Only report those users begining with NBK or Z
                                          AND (dba_role_privs.grantee LIKE 'NBK%' OR dba_role_privs.grantee LIKE 'Z%'))   LOOP
    DBMS_OUTPUT.PUT_LINE('--*WARNING: User '||r_nbk_users_assigned_appsupp.grantee||' ('||r_nbk_users_assigned_appsupp.name||')'||
                         ' is not part of L2 or L3 yet has '||r_nbk_users_assigned_appsupp.granted_role||' granted, please review');
    DBMS_OUTPUT.PUT_LINE('Revoke '||r_nbk_users_assigned_appsupp.granted_role|| ' from '||r_nbk_users_assigned_appsupp.grantee||';');
    b_ok_to_continue := FALSE;
  END LOOP;
  --
  --List those users that are in the L2 and L3 teams and are setup in the DB but do not have APPS%SUP% role applied
  FOR r_unassigned_users IN (SELECT username as nbk,
                                    substr(column_value,instr(column_value,':',1,2)+1,
                                                        instr(column_value,':',1,3)-instr(column_value,':',1,2)-1) as forename,
                                    substr(column_value,instr(column_value,':',1,3)+1,
                                                        length(column_value)-instr(column_value,':',1,2)-1) as surname
                              FROM dba_users, table(cast(g_list_of_nbks as sys.dbms_debug_vc2coll)) support_users
                             WHERE username = substr(column_value,1,instr(column_value,':')-1)
                              AND dba_users.username NOT IN
                             (SELECT grantee
                               FROM dba_role_privs
                              WHERE granted_role like 'APP%SUP%')) LOOP
    DBMS_OUTPUT.PUT_LINE('--*WARNING: User '||r_unassigned_users.nbk||' ('
                                            ||r_unassigned_users.forename||' '
                                            ||r_unassigned_users.surname||')'
                                            ||' IS part of L2 or L3 yet DOES NOT HAVE APPSSUP role granted, please review');
    --Ok to ignore this warning, don't need to stop output
    --b_ok_to_continue := FALSE;
  END LOOP;
  --
  --List those Support Staff that have explicit grants assigned to them
  FOR r_support_with_explict_grants IN (SELECT grantee nbk, privilege,
                                               owner, table_name,
                                               substr(column_value,instr(column_value,':',1,2)+1,
                                                                   instr(column_value,':',1,3)-instr(column_value,':',1,2)-1) as forename,
                                               substr(column_value,instr(column_value,':',1,3)+1,
                                                                   length(column_value)-instr(column_value,':',1,2)-1) as surname
                                          FROM dba_tab_privs, table(cast(g_list_of_nbks as sys.dbms_debug_vc2coll)) support_staff
                                         WHERE dba_tab_privs.grantor = substr(column_value,1,instr(column_value,':')-1)) LOOP
    DBMS_OUTPUT.PUT_LINE('--WARNING EXPLICIT GRANT TO '||r_support_with_explict_grants.nbk||' ('
                                                       ||r_support_with_explict_grants.forename||' '
                                                       ||r_support_with_explict_grants.surname||'):'
                                                       ||r_support_with_explict_grants.privilege||' on '
                                                       ||r_support_with_explict_grants.owner||'.'
                                                       ||r_support_with_explict_grants.table_name);
    DBMS_OUTPUT.PUT_LINE('Revoke '||r_support_with_explict_grants.privilege||' on '||r_support_with_explict_grants.owner||'.'||
                                    r_support_with_explict_grants.table_name||' from '||r_support_with_explict_grants.nbk||';');
    b_ok_to_continue := FALSE;
  END LOOP;
  --
  --Check for any explicit grants to the NBK users
  FOR r_support_with_sys_privs IN (SELECT support_users.nbk, privilege, support_users.forename,  support_users.surname
                                     FROM dba_sys_privs,
                                         (SELECT substr(column_value,1,instr(column_value,':')-1) as nbk,
                                                 substr(column_value,instr(column_value,':',1,2)+1,
                                                   instr(column_value,':',1,3)-instr(column_value,':',1,2)-1) as forename,
                                                 substr(column_value,instr(column_value,':',1,3)+1,
                                                   length(column_value)-instr(column_value,':',1,2)-1) as surname
                                            FROM table(cast(g_list_of_nbks as sys.dbms_debug_vc2coll))) support_users
                                    WHERE dba_sys_privs.grantee=support_users.nbk
                                          --V1.1 Do not report CREATE SESSION
                                      AND  dba_sys_privs.privilege !='CREATE SESSION') LOOP
    DBMS_OUTPUT.PUT_LINE('--WARNING EXPLICIT SYS PRIV TO '||r_support_with_sys_privs.nbk||' ('||r_support_with_sys_privs.forename||' '
    ||r_support_with_sys_privs.surname||') '||':'||r_support_with_sys_privs.privilege);
    DBMS_OUTPUT.PUT_LINE('Revoke '||r_support_with_sys_privs.privilege||' from '||r_support_with_sys_privs.nbk||';');
    b_ok_to_continue := FALSE;
  END LOOP;
  --
  --Check any sys privs assigned to the APPSUPP roles
  FOR r_sys_privs_to_roles IN (SELECT privilege, grantee
                                 FROM dba_sys_privs a, dba_roles b
                                WHERE a.grantee=b.role
                                  AND b.role LIKE 'APP%SUP%'
                                   -- V1.1 Do not report CREATE SESSION
                                  AND a.privilege !='CREATE SESSION') LOOP
    DBMS_OUTPUT.PUT_LINE('--WARNING SYS Privilege '||r_sys_privs_to_roles.privilege||' granted to role '||r_sys_privs_to_roles.grantee);
    b_ok_to_continue := FALSE;
  END LOOP;
  --
  --If any warnings have been raised then do not proceed
  IF NOT b_ok_to_continue THEN
    DBMS_OUTPUT.PUT_LINE('Please review the WARNINGS, until these issues are addressed L2-L3 support roles will not be created');
  --If no warnings have been raised then proceed
  ELSE
    --Build up the script NB Does not execute anything, once script built up DBA can review and decide to run or not.
    DBMS_OUTPUT.PUT_LINE('PROMPT Copying Select privs from role');
    DBMS_OUTPUT.PUT_LINE('spool roles_l1_l2.log');
    DBMS_OUTPUT.PUT_LINE('set pages 200 lines 150 feedback on echo on');
    DBMS_OUTPUT.PUT_LINE('CREATE ROLE APPS_SUPPORT_L3;');
    DBMS_OUTPUT.PUT_LINE('CREATE ROLE APPS_SUPPORT_L2;');
    DBMS_OUTPUT.PUT_LINE('GRANT APPS_SUPPORT_L3 TO APPS_SUPPORT_L2;');
    --Grant SELECT to L3 and everything else to L2 (using decode Privilege)
    FOR r_create_roles IN (SELECT DISTINCT execute_me, orderby 
                             FROM (SELECT 'GRANT '||privilege||' ON '||case privilege  when 'WRITE' then 
                                                                                            'Directory '||owner
                                                                                       when 'READ' then 
                                                                                            'Directory '||owner
                                                                                       else owner end
                                                 ||'.'||'"'||table_name||'"'||' to '||
                                          decode (privilege,'SELECT','APPS_SUPPORT_L3','APPS_SUPPORT_L2')||';' execute_me,
                                          decode (privilege,'SELECT','1SELECT',privilege)||owner||table_name orderby
                                     FROM dba_tab_privs
                                    WHERE grantee LIKE 'APP%SUP%'
                                      AND grantee NOT IN ('APPS_SUPPORT_L2','APPS_SUPPORT_L3')
                                      AND table_name NOT LIKE 'BIN$%') 
                            ORDER BY orderby) LOOP
      DBMS_OUTPUT.PUT_LINE(r_create_roles.execute_me);
    END LOOP;
    --Grant APPS_SUPPORT_L2 to those users flagged as L2 users and L3 to anyone else (should only be L2 or L3 support levels)
    --V1.2 - Added DISTINCT so users that have more than one APP%SUPP role assigned (i.e. APP_SUPPORT and APPS_SUPP) only appears once
    FOR r_assign_to_L2_L3 IN (SELECT DISTINCT 'GRANT '||decode(support_level,'L2','APPS_SUPPORT_L2','APPS_SUPPORT_L3')||' to '||nbk
                                             ||';' execute_me
                                FROM dba_users, dba_role_privs,
                                    (SELECT substr(column_value,1,instr(column_value,':')-1) as nbk,
                                            substr(column_value,instr(column_value,':')+1,
                                                   instr(column_value,':',1,2)- instr(column_value,':')-1) as support_level,
                                                 substr(column_value,instr(column_value,':',1,2)+1,
                                                   instr(column_value,':',1,3)-instr(column_value,':',1,2)-1) as forename,
                                                 substr(column_value,instr(column_value,':',1,3)+1,
                                                   length(column_value)-instr(column_value,':',1,2)-1) as surname
                                       FROM table(cast(g_list_of_nbks as sys.dbms_debug_vc2coll)))
                               WHERE nbk=dba_users.username AND
                                     dba_role_privs.grantee=nbk AND
                                     dba_role_privs.granted_role LIKE 'APP%SUP%' AND
                                     dba_role_privs.granted_role NOT IN ('APPS_SUPPORT_L2','APPS_SUPPORT_L3')) LOOP
      DBMS_OUTPUT.PUT_LINE(r_assign_to_L2_L3.execute_me);
    END LOOP;
    FOR r_revoke_apps_supp IN (SELECT DISTINCT 'revoke '||dba_role_privs.granted_role||' from '
                                ||nbk||';' execute_me
                                FROM dba_users, dba_role_privs,
                                    (SELECT substr(column_value,1,instr(column_value,':')-1) as nbk,
                                            substr(column_value,instr(column_value,':')+1,
                                                   instr(column_value,':',1,2)- instr(column_value,':')-1) as support_level,
                                                 substr(column_value,instr(column_value,':',1,2)+1,
                                                   instr(column_value,':',1,3)-instr(column_value,':',1,2)-1) as forename,
                                                 substr(column_value,instr(column_value,':',1,3)+1,
                                                   length(column_value)-instr(column_value,':',1,2)-1) as surname
                                       FROM table(cast(g_list_of_nbks as sys.dbms_debug_vc2coll)))
                               WHERE nbk=dba_users.username AND
                                     dba_role_privs.grantee=nbk AND
                                     dba_role_privs.granted_role LIKE 'APP%SUP%' AND
                                     dba_role_privs.granted_role NOT IN ('APPS_SUPPORT_L2','APPS_SUPPORT_L3')) LOOP
      DBMS_OUTPUT.PUT_LINE(r_revoke_apps_supp.execute_me);
    END LOOP;
    IF b_can_drop THEN
      FOR r_drop_role IN (SELECT role
                            FROM dba_roles
                           WHERE role like 'APP%SUP%'
                             AND role NOT IN ('APPS_SUPPORT_L2','APPS_SUPPORT_L3')) LOOP
        DBMS_OUTPUT.PUT_LINE('Drop role '||r_drop_role.role);
      END LOOP; 
    END IF;
    DBMS_OUTPUT.PUT_LINE('spool off');
  END IF;
END;
/
spool off
exit
