set serveroutput on buffer 1000000
declare
  t_amount            number(8,2) := 203000;
  t_orig_amount       constant number(8,2)  := 280000;
  T_APR               number(2,1) :=3;
  t_monthly_repayment pls_integer :=2000;
  t_looper pls_integer:=1;
  t_old_amount number(8,2);
  t_amount_took_off number(8,2);
  t_percent number (5,2);
  t_total_repayed number(9,2):=0;
begin
  dbms_output.put_line('t amount is '||t_amount||' apr is '||T_APR||'% monthly repayments are '||t_monthly_repayment);

  while t_amount > t_monthly_repayment loop


    t_amount:=t_amount+trunc((((t_amount*t_apr)/100)/12),2) -t_monthly_repayment;
    t_amount_took_off:=t_old_amount-t_amount;
    t_percent:=100 - to_number((t_amount/t_orig_amount)*100);

	IF MOD(t_looper,12) = 0 then
      dbms_output.put_line('Amount remaining is '||t_amount||' for '||trunc(add_months(sysdate,t_looper),'MONTH'));
--    dbms_output.put_line('Amount took off is '||nvl(t_amount_took_off,0));
      dbms_output.put_line('percentage of loan paid off '|| t_percent);
	END IF;

    t_old_amount:=t_amount;
    t_looper:= t_looper+1;
    t_total_repayed := t_total_repayed + t_monthly_repayment;
	
  end loop;
  --Should have a bit left over from t_amount
  dbms_output.put_line('CONGRATS ***** t_amount is zero for '||trunc(add_months(sysdate,t_looper),'MONTH'));
  t_total_repayed := t_total_repayed + t_amount;
  dbms_output.put_line('Total Repayed '||t_total_repayed);
  dbms_output.put_line('END');
end;
/

t amount is 203000 apr is 3% monthly repayments are 3000
Amount remaining is 172675.24 for 01-AUG-15
percentage of loan paid off 38.33
Amount remaining is 141428.11 for 01-AUG-16
percentage of loan paid off 49.49
Amount remaining is 109230.58 for 01-AUG-17
percentage of loan paid off 60.99
Amount remaining is 76053.72 for 01-AUG-18
percentage of loan paid off 72.84
Amount remaining is 41867.76 for 01-AUG-19
percentage of loan paid off 85.05
Amount remaining is 6641.99 for 01-AUG-20
percentage of loan paid off 97.63
CONGRATS ***** t_amount is zero for 01-NOV-20
Total Repayed 222667.73
END

t amount is 203000 apr is 3% monthly repayments are 2000
Amount remaining is 184841.61 for 01-AUG-15
percentage of loan paid off 33.99
Amount remaining is 166130.92 for 01-AUG-16
percentage of loan paid off 40.67
Amount remaining is 146851.12 for 01-AUG-17
percentage of loan paid off 47.55
Amount remaining is 126984.91 for 01-AUG-18
percentage of loan paid off 54.65
Amount remaining is 106514.45 for 01-AUG-19
percentage of loan paid off 61.96
Amount remaining is 85421.36 for 01-AUG-20
percentage of loan paid off 69.49
Amount remaining is 63686.71 for 01-AUG-21
percentage of loan paid off 77.25
Amount remaining is 41290.98 for 01-AUG-22
percentage of loan paid off 85.25
Amount remaining is 18214.05 for 01-AUG-23
percentage of loan paid off 93.49
CONGRATS ***** t_amount is zero for 01-JUN-24
Total Repayed 234446.89
END


/*
set serveroutput on buffer 1000000
declare
  t_amount            number(8,2) := 203000;
  T_APR               number(2,1) :=4.2;
  t_monthly_repayment pls_integer :=2041;
  t_looper pls_integer:=0;
begin
  dbms_output.put_line('t amount is '||t_amount);
  while t_amount > 0 loop
    t_amount:=t_amount+trunc((((t_amount*t_apr)/100)/12),2) -t_monthly_repayment;
    dbms_output.put_line('Amount remaining is '||t_amount||' for '||trunc(add_months(sysdate,t_looper),'MONTH'));
    t_looper:= t_looper+1;
  end loop;
  dbms_output.put_line('END');
end;
*/
