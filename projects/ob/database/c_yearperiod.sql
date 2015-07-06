set scan off;

create or replace PROCEDURE C_YEARPERIODS(pinstance_id IN VARCHAR2) 
AS
/*************************************************************************
  * The contents of this file are subject to the Compiere Public
  * License 1.1 ("License"); You may not use this file except in
  * compliance with the License. You may obtain a copy of the License in
  * the legal folder of your Openbravo installation.
  * Software distributed under the License is distributed on an
  * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  * implied. See the License for the specific language governing rights
  * and limitations under the License.
  * The Original Code is  Compiere  ERP &  Business Solution
  * The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
  * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
  * parts created by ComPiere are Copyright (C) ComPiere, Inc.;
  * All Rights Reserved.
  * Contributor(s): Openbravo SLU
  * Contributions are Copyright (C) 2001-2009 Openbravo, S.L.U.
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: C_YearPeriods.sql,v 1.2 2002/05/22 02:48:28 jjanke Exp $
  ***
  * Title: Create missing standard periods for Year_ID
  * Description:
  ************************************************************************/
  -- Parameter
  TYPE RECORD IS REF CURSOR;
    Cur_Parameter RECORD;
    v_Year_ID VARCHAR2(32);
    --
    v_NextNo VARCHAR2(32);
    v_MonthNo NUMBER;
    v_StartDate DATE;
    Test NUMBER;
    v_ResultStr VARCHAR(300) ;
    --  C_Year Variables
    v_Client_ID VARCHAR2(32);
    v_Org_ID VARCHAR2(32);
    v_Calendar_ID VARCHAR2(32);
    v_Year_Str VARCHAR(20) ;
    v_User_ID VARCHAR2(32);
    v_year_num NUMBER;
    v_language VARCHAR2(6);
  BEGIN
    --  Update AD_PInstance
    --  DBMS_OUTPUT.PUT_LINE('Updating PInstance - Processing');
    v_ResultStr:='PInstanceNotFound';
    AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID,
        p.ParameterName,
        p.P_String,
        p.P_Number,
        p.P_Date
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      IF Cur_Parameter.ParameterName = 'AD_LANGUAGE_ID' THEN
        SELECT AD_LANGUAGE INTO v_language FROM AD_LANGUAGE WHERE AD_LANGUAGE_ID = Cur_Parameter.P_String;
        v_language := COALESCE(v_language, 'en_US');
      END IF;
      v_Year_ID:=Cur_Parameter.Record_ID;
    END LOOP; -- Get Parameter
    
    DBMS_OUTPUT.PUT_LINE('  Record_ID=' || v_Year_ID) ;
    --  Get C_Year Record

    DBMS_OUTPUT.PUT_LINE('Get Year info') ;
    v_ResultStr:='YearNotFound';
    SELECT AD_Client_ID,
      AD_Org_ID,
      C_Calendar_ID,
      Year,
      UpdatedBy
    INTO v_Client_ID,
      v_Org_ID,
      v_Calendar_ID,
      v_Year_Str,
      v_User_ID
    FROM C_Year
    WHERE C_Year_ID=v_Year_ID;

    -- Check the format
    DBMS_OUTPUT.PUT_LINE('Checking format') ;
    v_ResultStr:='Year not numeric: '||v_Year_Str;
    BEGIN
    SELECT TO_NUMBER(v_Year_Str) INTO v_year_num FROM DUAL;

    -- Postgres hack
    IF (v_year_num IS NULL OR v_year_num<=0) THEN
      RAISE_APPLICATION_ERROR(-20000, '@NotValidNumber@');
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20000, '@NotValidNumber@');
    END;

    --  Start Date
    DBMS_OUTPUT.PUT_LINE('Calculating start date') ;
    v_ResultStr:='Year not numeric: '||v_Year_Str;
    SELECT TO_DATE('07/01/'||v_Year_Str, 'MM/DD/YYYY') INTO v_StartDate FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('Start: '||v_StartDate) ;
    -- Loop to all months and add missing periods
    FOR v_MonthNo IN 1..12
    LOOP
      --  Do we have the month already:1
      --      DBMS_OUTPUT.PUT_LINE('Checking Month No: '||v_MonthNo);
      v_ResultStr:='Checking Month '||v_MonthNo;
      SELECT MAX(PeriodNo)
      INTO Test
      FROM C_Period
      WHERE C_Year_ID=v_Year_ID
        AND PeriodNo=v_MonthNo;

      IF Test IS NULL THEN
        -- get new v_NextNo
        AD_Sequence_Next('C_Period', v_Year_ID, v_NextNo) ;

        --          DBMS_OUTPUT.PUT_LINE('Adding Period ID: '||v_NextNo);
        INSERT
        INTO C_Period
          (
            C_Period_ID, AD_Client_ID, AD_Org_ID, IsActive,
            Created, CreatedBy, Updated, UpdatedBy,
            C_Year_ID, PeriodNo, StartDate, PeriodType,
            Name
          )
          VALUES
          (
            v_NextNo, v_Client_ID, v_Org_ID, 'Y',
            now(), v_User_ID, now(), v_User_ID,
            v_Year_ID, v_MonthNo, TO_DATE(ADD_MONTHS(v_StartDate, v_MonthNo-1)), 'C_YEARPERIOD',
            (SELECT SUBSTR(COALESCE(AD_MONTH_TRL.NAME, AD_MONTH.NAME), 1,3) || '-' || SUBSTR(C_YEAR.YEAR,3,2)
                 FROM AD_MONTH LEFT OUTER JOIN AD_MONTH_TRL ON AD_MONTH.AD_MONTH_ID = AD_MONTH_TRL.AD_MONTH_ID AND AD_MONTH_TRL.AD_LANGUAGE = v_language, C_YEAR
                 WHERE  TO_NUMBER(AD_MONTH.VALUE) = v_MonthNo
                 AND C_YEAR.C_YEAR_ID = v_Year_ID)
           );
        DBMS_OUTPUT.PUT_LINE('Month Added') ;
      END IF;
    END LOOP;

    --  Update AD_PInstance
    --<<END_PROCEDURE>>
    --  DBMS_OUTPUT.PUT_LINE('Updating PInstance - Finished');
    AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 1, NULL) ;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  --      DBMS_OUTPUT.PUT_LINE('No Data Found Exception');
  v_ResultStr:= '@ERROR=' || SQLERRM;
  AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END C_YEARPERIODS
;
  
