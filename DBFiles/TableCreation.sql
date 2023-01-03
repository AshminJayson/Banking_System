CREATE DATABASE `bankingsystem` /*!40100 DEFAULT CHARACTER SET utf8mb3 */ /*!80016 DEFAULT ENCRYPTION='N' */;


CREATE TABLE `accounts` (
  `accno` int NOT NULL AUTO_INCREMENT,
  `name` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `ifsc_code` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `branch` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `phone_number` bigint NOT NULL,
  `account_type` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `password` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  PRIMARY KEY (`accno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
SELECT * FROM bankingsystem.accounts;

CREATE TABLE `investments` (
  `investment_id` int NOT NULL AUTO_INCREMENT,
  `accno` int NOT NULL,
  `amount` int NOT NULL,
  `interest_rate` float DEFAULT NULL,
  `investment_date` date NOT NULL,
  `maturity_date` date NOT NULL,
  `duration` varchar(45) DEFAULT NULL,
  `matured_amount` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`investment_id`),
  KEY `Deposits_Accounts_idx` (`accno`),
  CONSTRAINT `Deposits_Accounts` FOREIGN KEY (`accno`) REFERENCES `accounts` (`accno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `balance_details` (
  `accno` int NOT NULL,
  `balance` int NOT NULL,
  `min_balance` int NOT NULL,
  PRIMARY KEY (`accno`),
  CONSTRAINT `Balance_Accounts` FOREIGN KEY (`accno`) REFERENCES `accounts` (`accno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `loans` (
  `loan_id` int NOT NULL AUTO_INCREMENT,
  `accno` int NOT NULL,
  `amount` int NOT NULL,
  `interest_rate` float DEFAULT NULL,
  `procurement_date` date NOT NULL,
  `repayment_deadline` date NOT NULL,
  `duration` int DEFAULT NULL,
  `repayable_amount` int DEFAULT NULL,
  `status` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`loan_id`),
  KEY `Loans_Accounts_idx` (`accno`),
  CONSTRAINT `Loans_Accounts` FOREIGN KEY (`accno`) REFERENCES `accounts` (`accno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `transactions` (
  `transaction_id` int NOT NULL AUTO_INCREMENT,
  `sender_accno` int NOT NULL,
  `recipient_accno` int NOT NULL,
  `amount` int NOT NULL,
  `transaction_date` date NOT NULL,
  `status` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`transaction_id`),
  KEY `Transaction_Accounts_idx` (`sender_accno`),
  KEY `TTransaction_Accounts_Recipient_idx` (`recipient_accno`),
  CONSTRAINT `Transaction_Accounts_Sender` FOREIGN KEY (`sender_accno`) REFERENCES `accounts` (`accno`),
  CONSTRAINT `TTransaction_Accounts_Recipient` FOREIGN KEY (`recipient_accno`) REFERENCES `accounts` (`accno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;







-- Triggers : 

CREATE DEFINER=`bankadmin`@`localhost` TRIGGER `accounts_AFTER_INSERT` AFTER INSERT ON `accounts` FOR EACH ROW BEGIN
	if new.account_type = 'SB' then
		insert into balance_details values(new.accno, 3000, 3000);
	elseif new.account_type = 'NRI' then
		insert into balance_details values(new.accno, 10000,10000);
	else 
		insert into balance_details values(new.accno, 5000, 5000);
	end if;
END

CREATE DEFINER=`bankadmin`@`localhost` TRIGGER `accounts_AFTER_UPDATE` AFTER UPDATE ON `accounts` FOR EACH ROW BEGIN
	
	if new.account_type = 'SB' then
		update balance_details set min_balance = 3000 where accno = old.accno;
	elseif new.account_type = 'NRI' then
		update balance_details set min_balance = 10000 where accno = old.accno;
	else 
		update balance_details set min_balance = 5000 where accno = old.accno;
	end if;
END

CREATE DEFINER=`bankadmin`@`localhost` TRIGGER `investments_BEFORE_INSERT` BEFORE INSERT ON `investments` FOR EACH ROW BEGIN
	declare period int;
    declare pyears float;
    declare interesttemp float;
    
    set new.duration = datediff(new.maturity_date, new.investment_date);
	set period = new.duration / 30;
    set pyears = new.duration / 365;
    
    set interesttemp = 0;
    while period > 0 do
		set period = period - 1;
        set interesttemp = interesttemp + 0.1;
	end while;
    
    if interesttemp > 7 then
		set interesttemp = 7;
	end if;
    
    set new.interest_rate = interesttemp;
	set new.matured_amount = ((interesttemp * new.amount * pyears) / 100) + new.amount;
	
END

CREATE DEFINER=`bankadmin`@`localhost` TRIGGER `investments_AFTER_DELETE` AFTER DELETE ON `investments` FOR EACH ROW BEGIN
	declare today date;
    set today = curdate();
    
    if today < old.maturity_date then
		update balance_details set balance = balance + old.amount where
        accno = old.accno;
	else
		update balance_details set balance = balance + old.matured_amount where
        accno = old.accno;
	end if;
END

CREATE DEFINER=`bankadmin`@`localhost` TRIGGER `loans_BEFORE_INSERT` BEFORE INSERT ON `loans` FOR EACH ROW BEGIN
	declare period int;
    declare pyears float;
    declare interesttemp float;
    
    set new.duration = datediff(new.repayment_deadline, new.procurement_date);
	set period = new.duration / 30;
    set pyears = new.duration / 365;
    
    set interesttemp = 5;
    while period > 0 do
		set period = period - 1;
        set interesttemp = interesttemp + 0.15;
	end while;
    
    if interesttemp > 25 then
		set interesttemp = 25;
	end if;
    
    set new.interest_rate = interesttemp;
	  set new.repayable_amount = ((interesttemp * new.amount * pyears) / 100) + new.amount;
    set new.status = 'Pending Sanction';
END

CREATE DEFINER=`bankadmin`@`localhost` TRIGGER `transactions_BEFORE_INSERT` BEFORE INSERT ON `transactions` FOR EACH ROW BEGIN
	declare senderbal float;
    declare senderminbal float;
    
    select balance,min_balance into senderbal,senderminbal from balance_details where 
    accno = new.sender_accno;
    
    if senderbal - new.amount < senderminbal then
		set new.status = 'FAILED';
	else 
		set new.status = 'SUCCESS';
        update balance_details set balance = balance - new.amount where
        accno = new.sender_accno;
        update balance_details set balance = balance + new.amount where
        accno = new.recipient_accno;
	end if;
        
    
END

-- Functions : 



DELIMITER $$
CREATE DEFINER=`bankadmin`@`localhost` FUNCTION `openInvestment`(iaccno int, iamount int, mdate date, cdate date) RETURNS int
BEGIN
	declare ibalance int;
    declare iminbalance int;
    
    select balance, min_balance into ibalance, iminbalance from balance_details
    where iaccno = accno;
    
    if ibalance - iamount >= iminbalance then
		update balance_details set balance = ibalance - iamount where accno = iaccno;
		insert into investments values(null,iaccno,iamount,null,cdate,mdate,null,null);
		RETURN 1;
    end if;
RETURN 0;
END$$
DELIMITER ;



CREATE DEFINER=`bankadmin`@`localhost` FUNCTION `repayLoan`(iaccno int, iloan_id int) RETURNS int
BEGIN
	declare payableamount float;
    declare accbalance float;
    declare minaccbalance float;
    
    select balance into accbalance from balance_details where iaccno = accno;
    select min_balance into minaccbalance from balance_details where iaccno = accno;
    select repayable_amount into payableamount from loans where loan_id = iloan_id;
    
    if accbalance - payableamount > minaccbalance then
		delete from loans where loan_id = iloan_id;
        update balance_details set balance = accbalance - payableamount where accno = iaccno;
		RETURN 1;
    end if;
return 0;
END

DELIMITER $$
CREATE DEFINER=`bankadmin`@`localhost` FUNCTION `passwordCheck`(iaccno int, ipassword varchar(30)) RETURNS int
BEGIN
	declare validpass varchar(30);
    
    select password into validpass from accounts where accno = iaccno;
    
    if validpass = ipassword then
		return 1;
	else
		return 0;
	end if;

END$$
DELIMITER ;


DELIMITER $$
CREATE DEFINER=`bankadmin`@`localhost` FUNCTION `sanctionLoan`(iaccno int, iloan_id int, iamount int) RETURNS int
BEGIN
	update loans set status = 'Sanctioned' where loan_id = iloan_id;
  update balance_details set balance = balance + iamount where accno = iaccno;
RETURN 1;
END$$
DELIMITER ;
