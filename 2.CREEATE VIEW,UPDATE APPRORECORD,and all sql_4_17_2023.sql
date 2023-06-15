use  bb_bank;

-- Creat view of assetaverage with checking and saving table  
CREATE VIEW assetaverage( custid, assetquantity)
AS SELECT S.custid, (C.camount + S.samount) AS assetquantity
FROM saving AS S, checking AS C
WHERE S.custid = C.custid;

-- Drop view to make the query run well
DROP VIEW assetaverage;

-- Drop  constraint of approverecord
-- ALTER TABLE approverecord
-- DROP CONSTRAINT custid_approverecord;

-- Update the approverecord with  creditscore and assetquantity condition
UPDATE approverecord AS AR
JOIN  credit AS CD on CD.custid= AR.custid
JOIN  assetaverage AS AA on AA.custid = AR.custid
SET 
  result_y_n = 
    CASE 
      WHEN CD.creditscore >= 700 THEN 'YES'
      WHEN CD.creditscore >= 600 THEN 'YES'
      WHEN CD.creditscore >= 500 THEN 'YES'
      ELSE 'NO'
    END,
  totalamount =
    CASE
      WHEN CD.creditscore >= 700 THEN 3 * AA.assetquantity
      WHEN CD.creditscore >= 600 THEN 2 * AA.assetquantity
      WHEN CD.creditscore >= 500 THEN 1 * AA.assetquantity
      ELSE 0
    END;


-- 1.Simple query

-- retrieve all data from Other bank account(AccountOtherBank).
SELECT *
FROM accountotherbank;

-- retrieve the Account Number & Savings Amount, where Savings amount greater than 2500.
SELECT  accountnr, samount  
FROM saving
WHERE samount > 2500;

-- retrieve the Top 5 custid, accountnr and amount from checkings table.
SELECT custid, accountnr, camount 
FROM checking
Order BY camount desc limit 5;


-- 2.Aggregate query
-- retrieve the number of female customer.
SELECT  count(gender) as female_gender 
FROM customer
WHERE gender='F';

-- retrieve the number of different gender customer.
SELECT  gender, count(gender) as numberofgender
FROM customer
group by gender
order by numberofgender desc;

-- 3.Inner join/outer join
-- (Inner)audit department need to retrieve all the saving rate which is greater than 4, 
-- and the Staffid, staff name, staff level who maintiain the rate in the system. 
SELECT SR.savingrateid, SR.rate, SR.staffid, BS.staffname, BS.stafflevel
FROM savingrate SR, bbstaff BS
WHERE SR.staffid=BS.staffid
AND SR.rate>=4.3;

-- (Outter)audit department need to retrieve all the saving rate, 
-- and the Staffid, staff name, staff level who maintiain the rate in the system. 
SELECT SR.savingrateid, SR.rate, SR.staffid, BS.staffname, BS.stafflevel
FROM savingrate SR left join bbstaff BS
On (SR.staffid=BS.staffid)
order by SR.rate;


-- 4.Nest query
-- audit department need to retrieve the customers
-- who is approved to loan, including name, custID, and totalamount
SELECT CM.custid, CM.custname, AR1.totalamount
FROM customer CM, approverecord AR1
WHERE CM.custid in
  ( SELECT AR.custid
    FROM approverecord AR
    WHERE AR.result_y_n = "YES"
  )
AND CM.custid=AR1.custid;


-- 5.Correlated query
-- audit department need to retrieve the customers
-- who is approved to loan, and totalamount is more than 13000, including name, custID, and totalamount
SELECT CM.custid, CM.custname, AR1.totalamount
FROM customer CM, approverecord AR1
WHERE   13000<
  ( SELECT AR.totalamount
	FROM  approverecord  AR
	WHERE result_y_n = "YES"
	AND CM.custid = AR.custid
    )
AND CM.custid=AR1.custid;


-- 6.ALL/>ANY/Exists/Not Exists
-- (ALL)retrieve customer who have the highest loan totalamount, including customerid, customername, and totalamount
SELECT CM.custid, CM.custname, AR.totalamount
FROM customer CM, approverecord AR
WHERE CM.custid = AR.custid
AND AR.totalamount >= ALL
  ( SELECT totalamount
	FROM  approverecord 
	WHERE result_y_n = "YES"
    );

-- (>ANY)retrieve customer who does not have  the lowest loan totalamount, including customerid, customername, and totalamount
SELECT CM.custid, CM.custname, AR.totalamount
FROM customer CM, approverecord AR
WHERE CM.custid = AR.custid
AND AR.totalamount > ANY
  ( SELECT totalamount
	FROM  approverecord 
	WHERE result_y_n = "YES"
    );

-- (Exists)retrieve customer whose creditscore is more than 700, including customerid, customername
SELECT CM.custid, CM.custname
FROM customer CM 
WHERE EXISTS
  ( SELECT *
	FROM  credit C1
	WHERE CM.custid = C1.custid
    AND  C1.creditscore >=700
    )
;

-- (NOT Exists)retrieve customer whose creditscore is no less than 500, including customerid, customername
SELECT CM.custid, CM.custname
FROM customer CM 
WHERE NOT EXISTS
  ( SELECT *
	FROM  credit C1
	WHERE CM.custid = C1.custid
    AND  C1.creditscore <=500
    )
;

-- 7.Set operations (Union)
-- (union) retrieve the customers whose saving amount is more than 3900
-- and the customers whose checking amount is more than 950.
SELECT CM.custid, CM.custname
FROM customer CM
WHERE CM.custid in 
(
SELECT SA.custid 
FROM  saving SA
WHERE SA.samount >3900
)
UNION
SELECT CM.custid, CM.custname
FROM customer CM
WHERE CM.custid in 
(
SELECT CH.custid 
FROM  checking CH
WHERE CH.camount >950
)
;

-- 8.Subqueries in Select and From
-- (Select)retrieve customerid, customername, and the saving amount
SELECT CM.custid, CM.custname,
(SELECT SA.samount 
FROM saving SA 
WHERE CM.custid = SA.custid 
) AS savingamount
FROM customer CM;

-- (From)retrieve customerid, customername, and the sum of saving/checking amount.
SELECT M.custid, M.custname, (M.samount+M.camount) as averagequantity
FROM
(SELECT CM.custid,CM.custname,SA.samount, CH.camount
FROM customer CM, saving SA, checking CH
WHERE CM.custid = SA.custid 
AND  CM.custid = CH.custid
) AS M;
