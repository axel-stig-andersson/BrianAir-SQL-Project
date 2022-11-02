/*QUESTION 2
Creating all our tables and their foreign keys. */
-- DROP TABLES --

DROP TABLE IF EXISTS reservedpass CASCADE;
DROP TABLE IF EXISTS ticket CASCADE;
DROP TABLE IF EXISTS booking CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS contact CASCADE;
DROP TABLE IF EXISTS passenger CASCADE;
DROP TABLE IF EXISTS flight CASCADE;
DROP TABLE IF EXISTS weeklyschedule CASCADE;
DROP TABLE IF EXISTS route CASCADE;
DROP TABLE IF EXISTS weekdays CASCADE;
DROP TABLE IF EXISTS airport CASCADE;
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS year CASCADE; 



-- ====================================================================== --
-- ====================================================================== --

DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addFlight;
DROP PROCEDURE IF EXISTS addRoute;

DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;

DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;

DROP VIEW IF EXISTS allFlights;


-- ====================================================================== --
-- ====================================================================== --
-- Creating the tables --
CREATE TABLE route
(id INT NOT NULL AUTO_INCREMENT,
arrivalcode VARCHAR(3), 
departurecode VARCHAR(3),
baseprice DOUBLE,
route_year INTEGER,
CONSTRAINT pk_route PRIMARY KEY(id)) ENGINE=InnoDB;
 

CREATE TABLE weeklyschedule 
(id INT NOT NULL AUTO_INCREMENT,
departuretime TIME,
arrivalcode VARCHAR(3),
departurecode VARCHAR(3), 
ws_year INTEGER,
ws_day VARCHAR(10),
CONSTRAINT pk_weeklyschedule PRIMARY KEY(id)) ENGINE=InnoDB;

CREATE TABLE weekdays
(year INTEGER,
day VARCHAR(10),
weekdayfactor DOUBLE,
CONSTRAINT pk_weekday PRIMARY KEY(day, year)) ENGINE=InnoDB;


CREATE TABLE airport 
(airportcode VARCHAR(3),
airportname VARCHAR (30),
country VARCHAR(30),
CONSTRAINT pk_airport PRIMARY KEY(airportcode)) ENGINE=InnoDB;

CREATE TABLE flight
(id INT NOT NULL AUTO_INCREMENT,
flightweek INTEGER,
weeklyscheduleid INTEGER,
CONSTRAINT pk_flight PRIMARY KEY(id)) ENGINE=InnoDB;

CREATE TABLE reservation
(reservationnr INTEGER,
numberofpass INTEGER,
resflight INTEGER,
res_contact INTEGER,
CONSTRAINT pk_reservation PRIMARY KEY(reservationnr)) ENGINE=InnoDB; 

CREATE TABLE booking  
(reservationnr INTEGER,
price DOUBLE,
paymentid INTEGER,
conf_contact INTEGER, 
CONSTRAINT pk_booking PRIMARY KEY(reservationnr)) ENGINE=InnoDB;

CREATE TABLE passenger
(passportnr INTEGER,
name VARCHAR(30),
CONSTRAINT pk_passenger PRIMARY KEY(passportnr)) ENGINE=InnoDB;

CREATE TABLE ticket
(ticketid INTEGER DEFAULT 0,
reservationnr INTEGER,
passportnr INTEGER,
CONSTRAINT pk_ticket PRIMARY KEY(ticketid)) ENGINE=innoDB;

CREATE TABLE reservedpass
(reservationnr INTEGER,
passportnr INTEGER,
CONSTRAINT pk_reservedpass PRIMARY KEY(reservationnr, passportnr)) ENGINE=InnoDB;

CREATE TABLE payment
(paymentid INT NOT NULL AUTO_INCREMENT,
cardname VARCHAR(30),
cardnumber BIGINT,
CONSTRAINT pk_payment PRIMARY KEY(paymentid)) ENGINE=InnoDB; 

CREATE TABLE contact
(passportnr INTEGER,
phonenumber BIGINT,
email VARCHAR(30),
CONSTRAINT pk_contact PRIMARY KEY(passportnr)) ENGINE=InnoDB;

CREATE TABLE year 
(year INTEGER,
factor DOUBLE,
CONSTRAINT pk_year PRIMARY KEY(year)) ENGINE=InnoDB;


-- ====================================================================== --
-- ====================================================================== --

-- Foreign Keys --

ALTER TABLE route ADD CONSTRAINT fk_route_arrivalcode FOREIGN KEY (arrivalcode) REFERENCES airport(airportcode);
ALTER TABLE route ADD CONSTRAINT fk_route_departurecode FOREIGN KEY (departurecode) REFERENCES airport(airportcode);
ALTER TABLE route ADD CONSTRAINT fk_route_year FOREIGN KEY (route_year) REFERENCES year(year); 

ALTER TABLE weekdays ADD CONSTRAINT fk_weekdays_year FOREIGN KEY (year) REFERENCES year(year); 

ALTER TABLE weeklyschedule ADD CONSTRAINT fk_weeklyschedule_arr FOREIGN KEY (arrivalcode) REFERENCES route(arrivalcode);
ALTER TABLE weeklyschedule ADD CONSTRAINT fk_weeklyschedule_dep FOREIGN KEY (departurecode) REFERENCES route(departurecode);
ALTER TABLE weeklyschedule ADD CONSTRAINT fk_weeklyschedule_day_year FOREIGN KEY (ws_day, ws_year) REFERENCES weekdays(day, year); 
ALTER TABLE weeklyschedule ADD CONSTRAINT fk_weeklyschedule_year FOREIGN KEY (ws_year) REFERENCES weekdays(year); 


ALTER TABLE flight ADD CONSTRAINT fk_flight_weeklyschedule FOREIGN KEY (weeklyscheduleid) REFERENCES weeklyschedule(id);  

ALTER TABLE reservation ADD CONSTRAINT fk_reservation_flight FOREIGN KEY (resflight) REFERENCES flight(id);
ALTER TABLE reservation ADD CONSTRAINT fk_reservation_contact FOREIGN KEY (res_contact) REFERENCES contact(passportnr); 

ALTER TABLE booking ADD CONSTRAINT fk_booking_reservation FOREIGN KEY (reservationnr) REFERENCES reservation(reservationnr) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE booking ADD CONSTRAINT fk_booking_payment FOREIGN KEY (paymentid) REFERENCES payment(paymentid);
ALTER TABLE booking ADD CONSTRAINT fk_booking_contact FOREIGN KEY (conf_contact) REFERENCES contact(passportnr); 

ALTER TABLE ticket ADD CONSTRAINT fk_ticket_reservation FOREIGN KEY (reservationnr) REFERENCES reservation(reservationnr);
ALTER TABLE ticket ADD CONSTRAINT fk_ticket_pass FOREIGN KEY (passportnr) REFERENCES passenger(passportnr); 

ALTER TABLE reservedpass ADD CONSTRAINT fk_reservedpass_reservation FOREIGN KEY (reservationnr) REFERENCES reservation(reservationnr);
ALTER TABLE reservedpass ADD CONSTRAINT fk_reservedpass_pass FOREIGN KEY (passportnr) REFERENCES passenger(passportnr);

ALTER TABLE contact ADD CONSTRAINT fk_contact_identity FOREIGN KEY (passportnr) REFERENCES passenger(passportnr); 



/*================== QUESTION 3 ==========================
Here, we create the procedures for filling the database with years, routes, flights, days adn destinations.
The first ones are pretty straight forward with regular insertions, but add flight requires a way of making sure 
the flight is available for all 52 weeks of the given year. In our case, we choose a WHILE loop. We switch delimiter 
to "//".
*/

delimiter //

CREATE PROCEDURE addYear
(IN year INTEGER, 
IN factor DOUBLE)
BEGIN
	INSERT INTO year 
    VALUES (year, factor);
END;  
//

CREATE PROCEDURE addDay 
(IN year INTEGER,
IN day VARCHAR(10),
IN weekdayfactor DOUBLE)
BEGIN
	INSERT INTO weekdays
    VALUES (year, day, weekdayfactor);
END; 
//


CREATE PROCEDURE addDestination 
(IN airportcode VARCHAR(3),
IN airportname VARCHAR(30),
IN country VARCHAR(30))
BEGIN
	INSERT INTO airport
    VALUES (airportcode, airportname, country);
END;
//
CREATE PROCEDURE addRoute
(IN departure_airport_code VARCHAR(3),
IN arrival_airport_code VARCHAR(3),
IN ryear INTEGER,
IN route_price DOUBLE)
BEGIN 
	INSERT INTO route (arrivalcode, departurecode, baseprice, route_year)
    VALUES (arrival_airport_code, departure_airport_code, route_price, ryear);
END; 
//


CREATE PROCEDURE addFlight
(IN departure_airport_code VARCHAR(3),
IN arrival_airport_code VARCHAR(3),
IN fyear INTEGER, 
IN fday VARCHAR(10),
IN departure_time TIME)
BEGIN
	DECLARE weekcount INT;
    DECLARE lastid INT;
    SET weekcount = 0;
	INSERT INTO weeklyschedule (departuretime, arrivalcode, departurecode, ws_year, ws_day)
	VALUES(departure_time, arrival_airport_code, departure_airport_code, fyear, fday); 
	 



	SELECT MAX(id) INTO lastid FROM weeklyschedule; 
    
    WHILE weekcount < 52 DO
		SET weekcount = weekcount + 1;
		INSERT INTO flight
		VALUES(NULL, weekcount, lastid);
	END WHILE; 
 
END;
//

/*====================== QUESTION 4 ==============================
Here, we create to functions to be able to calculate the price of a ticket and the number of free seats in the flight.
 */

CREATE FUNCTION calculateFreeSeats (flightnumber INT)
RETURNS INT
BEGIN
	DECLARE takenseats INT;
    DECLARE freeseats INT; 
    SET takenseats = 0;
   
    
    IF NOT EXISTS (SELECT reservationnr FROM reservation WHERE resflight = flightnumber) THEN
		SET freeseats = 40;
	ELSE  
		SELECT SUM(numberofpass) INTO takenseats 
		FROM reservation
		WHERE reservationnr IN
			(SELECT reservationnr
			FROM reservation 
			WHERE resflight = flightnumber);
	
    SET freeseats = (40 - takenseats); 
	END IF; 
    RETURN freeseats; 
END; 
// 



CREATE FUNCTION calculatePrice (flightnumber INT)
RETURNS DOUBLE
BEGIN

		DECLARE routePrice INT;
		DECLARE dayfactor DOUBLE;
		DECLARE bookedSeats INT; 
		DECLARE yearFactor DOUBLE; 
		DECLARE thisyear INT;
		DECLARE weekSchedId INT; 
		DECLARE thisday VARCHAR(10); 
		DECLARE arr VARCHAR(3);
		DECLARE dep VARCHAR(3); 
    
		SET bookedSeats = (40 - calculateFreeSeats(flightnumber));
		SELECT weeklyscheduleid INTO weekSchedId
			FROM flight
			WHERE id = flightnumber; 
	
		SELECT year INTO thisyear
			FROM year 
			WHERE year IN
				(SELECT ws_year
					FROM weeklyschedule
					WHERE id = weekSchedId);
	
		SELECT arrivalcode INTO arr FROM weeklyschedule WHERE id = weekSchedId;
		SELECT departurecode INTO dep FROM weeklyschedule WHERE id = weekSchedId;
    
		SELECT baseprice INTO routePrice
			FROM route
			WHERE route_year = thisyear AND arrivalcode = arr AND departurecode = dep;
	
		SELECT ws_day INTO thisday
			FROM weeklyschedule
			WHERE id = weekSchedId;
	
		SELECT weekdayfactor INTO dayfactor 
			FROM weekdays
			WHERE day = thisday AND year = thisyear;
	
		SELECT factor INTO yearFactor 
			FROM year
			WHERE year = thisyear; 
	
    RETURN (routePrice * dayfactor * ((bookedSeats + 1)/40) * yearFactor);

END;
//

/*=========================== QUESTION 5 ============================
This is triggered right before inserting into the ticket table, more about that later on in the addPayment procedure.
When the insertion of the other attributes of a ticket is made, the unique and randomly generated ticketid has already been calculated.
*/

CREATE TRIGGER randomticketnr
	BEFORE INSERT ON ticket
    FOR EACH ROW
	BEGIN 


		DECLARE randnr INT;
        SET randnr = rand() * 100000000; 
        SET NEW.ticketid = randnr; 
	
    END;
//


/*========================== QUESTION 6 =============================
Creating stored procedures for adding reservations, contacts, passengers and payments. This also means inserting into 
other tables like reservedpass, ticket and booking. Note that the addreservation procedure only controls 
whether the given number of passengers is at all possible (<=40), and only the addPayment procedure controls
the number of free seats. Regarding the addPassenger procedure, we compare the initial registrated nr of passengers
(when adding the reservation) to the actual added nr. We only update the numberofpass value when it goes beyond the registered 
amount. For instance, if you make a reservation for 3 passengers we don't want to change the value to 1 as soon as you
add your first passenger (unnessecary and could give wrong info on how many seats are reservated) BUT we do want to increase it if you want 
to add a fourth person. 
 */


CREATE PROCEDURE addReservation (IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN ryear INT, IN rweek INT, IN rday VARCHAR(10), IN rtime TIME, number_of_passengers INT, OUT output_reservation_nr INT )
BEGIN 

	DECLARE intended_flight INT; 
    DECLARE weeksched_of_flight INT DEFAULT 0; 
    DECLARE newreservation INT; 

  
    SELECT id INTO weeksched_of_flight
		FROM weeklyschedule
		WHERE departuretime = rtime AND arrivalcode = arrival_airport_code AND departurecode = departure_airport_code AND ws_year = ryear AND ws_day = rday;
    SELECT id INTO intended_flight 
		FROM flight
		WHERE flightweek = rweek AND weeklyscheduleid = weeksched_of_flight; 


    IF (weeksched_of_flight = 0) THEN 
		SELECT 'There exist no flight for the given route, date and time' AS 'Message';
	ELSE

        
        IF (40 < number_of_passengers) THEN
			SELECT 'There are not enough seats available on the chosen flight' AS 'Message';
		ELSE 
			SET newreservation = rand() * 10000000;
			INSERT INTO reservation (reservationnr, numberofpass, resflight, res_contact)
				VALUES (newreservation, number_of_passengers, intended_flight, NULL);
            SET output_reservation_nr = newreservation; 
            SELECT 'OK result' AS 'Message';
		END IF;
	END IF; 
END;
//

CREATE PROCEDURE addPassenger (IN reservation_nr INT, IN passport_nr INT, IN name VARCHAR(30))
BEGIN

	DECLARE alreadypaid INT DEFAULT 0; 
    DECLARE passenger_exists INT DEFAULT 0; 
    DECLARE res_exists INT; 
    DECLARE added_nr_of_pass INT;
    DECLARE registered_nr_of_pass INT; 
    
    SELECT COUNT(*) INTO alreadypaid FROM booking WHERE reservationnr = reservation_nr; 
    SELECT passportnr INTO passenger_exists FROM passenger WHERE passportnr = passport_nr; 
    SELECT COUNT(*) INTO res_exists FROM reservation WHERE reservationnr = reservation_nr; 

    IF (res_exists = 0) THEN 
		SELECT 'The given reservation number does not exist' AS 'Message';
	ELSE
		IF (alreadypaid != 0) THEN
			SELECT 'The booking has already been payed and no futher passengers can be added' AS 'Message'; 
		ELSE 
			IF passenger_exists = 0 THEN
				INSERT INTO passenger 
				VALUES (passport_nr, name);
			END IF; 
            
			INSERT INTO reservedpass
			VALUES (reservation_nr, passport_nr);
            SELECT COUNT(*) INTO added_nr_of_pass FROM reservedpass WHERE reservationnr = reservation_nr;
            SELECT numberofpass INTO registered_nr_of_pass FROM reservation WHERE reservationnr = reservation_nr; 
            IF (added_nr_of_pass > registered_nr_of_pass) THEN 
				UPDATE reservation 
					SET numberofpass = numberofpass + 1
					WHERE reservationnr = reservation_nr; 
			END IF;
            SELECT 'OK result' AS 'Message';

		END IF; 
	END IF; 
END;
//

CREATE PROCEDURE addContact (IN reservation_nr INT, IN passport_number INT, IN email VARCHAR(30), IN phone BIGINT)
BEGIN

    DECLARE truepassenger INT DEFAULT 0; 
    DECLARE iscontact INT DEFAULT 0; 
    
    SELECT COUNT(*) INTO truepassenger FROM reservedpass WHERE passportnr = passport_number AND reservationnr = reservation_nr; 
    IF EXISTS (SELECT passportnr FROM contact WHERE passportnr = passport_number) THEN
		SET iscontact = 1; 
	END IF; 
    
    
    IF NOT EXISTS (SELECT reservationnr FROM reservation WHERE reservationnr = reservation_nr) THEN
		SELECT 'The given reservation number does not exist' AS 'Message'; 
	ELSE 
		IF (truepassenger = 0) THEN 
			SELECT 'The person is not a passenger of the reservation' AS 'Message'; 
		ELSE 
			IF (iscontact = 0) THEN 
				INSERT INTO contact 
				VALUES (passport_number, phone, email); 
			END IF; 
			UPDATE reservation
				SET res_contact = passport_number
                WHERE reservationnr = reservation_nr; 
			SELECT 'OK result' AS 'Message';
		END IF;
	END IF;
END;
//

CREATE PROCEDURE addPayment (IN reservation_nr INT, IN cardholder_name VARCHAR(30), IN credit_card_number BIGINT)
BEGIN
	DECLARE reservation_true INT;
    DECLARE contact_exists INT DEFAULT 0; 
    DECLARE nr_of_passengers INT; 
    DECLARE unpaid_seats INT; 
    DECLARE this_flight INT; 
    DECLARE tot_price DOUBLE DEFAULT 0; 
    DECLARE passcount INT;
    DECLARE new_payment INT; 
    
    SET tot_price = 0; 
    SET passcount = 0; 

    SELECT count(*) INTO reservation_true FROM reservation WHERE reservationnr = reservation_nr; 
    SELECT res_contact INTO contact_exists FROM reservation WHERE reservationnr = reservation_nr; 
    IF (reservation_true = 0) THEN
		SELECT 'The given reservation number does not exist' AS 'Message'; 
	ELSE 
		IF (contact_exists = 0) THEN 
			SELECT 'The reservation has no contact yet' AS 'Message'; 
		ELSE 
			SELECT count(*) INTO nr_of_passengers FROM reservedpass WHERE reservationnr = reservation_nr;
            SELECT resflight INTO this_flight FROM reservation WHERE reservationnr = reservation_nr; 
            SET unpaid_seats = calculateFreeSeats(this_flight); 
           /*SELECT SLEEP(5); */
            
            IF (nr_of_passengers > unpaid_seats) THEN 
				SELECT 'There are not enough seats available on the flight anymore, deleting reservation' AS 'Message';
                DELETE FROM reservedpass WHERE reservationnr = reservation_nr;
                DELETE FROM reservation WHERE reservationnr = reservation_nr; 
                

			ELSE 
				WHILE passcount < nr_of_passengers DO
					SET tot_price = tot_price + calculatePrice(this_flight); 
                    SET passcount = passcount + 1;
				END WHILE; 


                INSERT INTO payment (cardname, cardnumber) VALUES (cardholder_name, credit_card_number); 
                SELECT MAX(paymentid) INTO new_payment FROM payment;
                INSERT INTO booking (reservationnr, price, paymentid, conf_contact) VALUES (reservation_nr,tot_price, new_payment, contact_exists); 

                INSERT INTO ticket (reservationnr, passportnr)  
					SELECT * 
                    FROM reservedpass
                    WHERE reservationnr = reservation_nr; 
				SELECT 'OK result' AS 'Message';
			END IF; 
		END IF; 
	END IF; 
END; 
//

delimiter ;



/* ================ QUESTION 7 ======================
Here we create the view allFlights. to be able to refer to airport twice like two instances, 
and to make the code more efficient (shorter), we use aliases. 

%%%%%%%%%%%%%%%%% ATTENTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This does NOT give the empty set as response when runnning the question7 script.
That is because for the first 52 flights (the ones with departuretime 09:00) the obtained price when calculating next ticket
price is not 115, but 114.999999999999999 for some reason. Same applies for the one with 6 reserved seats, 804.999999999999
instead of 805. This is why these 52 flights still appear.  */ 
CREATE VIEW allFlights AS
	SELECT airport_dep.airportname AS 'departure_city_name', 
		airport_arr.airportname AS 'destination_city_name',
		weeksched.departuretime AS 'departure_time', 
		weeksched.ws_day AS 'departure_day',
		fli.flightweek AS 'departure_week', 
		weeksched.ws_year AS 'departure_year',
		calculateFreeSeats(fli.id) AS 'nr_of_free_seats', 
		calculatePrice(fli.id) AS 'current_price_per_seat'
	FROM airport AS airport_dep, airport AS airport_arr, weeklyschedule AS weeksched, flight AS fli, route AS r
    WHERE airport_dep.airportcode = weeksched.departurecode
		AND airport_arr.airportcode = weeksched.arrivalcode
        AND weeksched.id = fli.weeklyscheduleid
        AND weeksched.ws_year = r.route_year
        AND weeksched.arrivalcode = r.arrivalcode;
        
/* ################## CHANGES IN DB STRUCTURE ######################
When we started implementing the project, we realised a couple of things from our initial structure that we wanted to change.
First of all, we decided to implement "year" as a entity type instead of an attribute. This felt obvious when we started coding,
but we kind of missunderstood the meaning of year before. That led to adding the attribute year in relevant tables along with the foreign
key constraints. Secondly, we removed unnessecary attributes like ID for route for example. Route already has a unique permutation of 
arrivalcode and departurecode, and therefore doesn't need any extra keys. 
The last change was that contact needed relations with reservations to function properly, unless we wanted to implement some other table 
defining the reserved contact or something like that. 
        

/*======================= QUESTION 8 ============================
a) How can you protect the credit card information in the database from hackers?
	
    Use some form of encryption. Either third party handling the info, or 
    for example AES encryption with a rather large key.

b) Give three advantages of using stored procedures in the database (and thereby
execute them on the server) instead of writing the same functions in the frontend of the 
system (in for example java-script on a web-page)?
	
    1. SECURITY. It is possible to call these procedures with just the CALL and the
    parameters, without access to the actual tables.
    
    2. The peformance is higher. The stored procedures are quicker because they can be 
    accessed directly in executable form. This together with the fact that they are cached 
    reduces both memory access time and total execution time. 
    
    3. Since they are stored in one location they are easier to alter or update --> easier 
    maintenance. You can basically reduce the aount of codde that needs to be updated when 
    you want to make a change. 
*/


/* ========================== QUESTION 9 =================================== 
a) In session A, add a new reservation,
	Done.

b) Is this reservation visible in session B? Why? Why not?
	No. Since the change in session A is not committed efter just START TRANSACTION
    session B cannot read it yet. It is the commit statement that actually writes the change 
    to the database. 
    
c) What happens if you try to modify the reservation from A in B? Explain what
happens and why this happens and how this relates to the concept of isolation
of transactions.
	We are not able to do that, and get an error adn session timeout instead. This is because Session B can't 
    write to the table before session A has committed the changes. It waits for a "green light" to start manipulating
    the reservation table, but does not get one and therefore aborts.*/
    
    
/* =========================== QUESTION 10 ===================================
a) Did overbooking occur when the scripts were executed? If so, why? If not,
why not?
	
    No, it did not. The first session succeeded in both reservation and payment, leaving 19 freeseats.
    The second session managed to create the reservation, since we only check if numberofpass is greater than
    40 (to allow overreservation), but could not proceed to payment since the booking was denied (only 19 seats left).
    
b) Can an overbooking theoretically occur? If an overbooking is possible, in what
order must the lines of code in your procedures/functions be executed.
	
    Yes, but the time window is very narrow. If the A session calls addPayment first and proceeds to calling calculateFreeSeats, finds it possible 
    and therefore proceeds to booking and session B calculates free seats in between those two events, they could both generate "valid" bookings
    even though the flight is full. 

c) Try to make the theoretical case occur in reality by simulating that multiple
sessions call the procedure at the same time. To specify the order in which the
lines of code are executed use the MySQL query SELECT sleep(5); which
makes the session sleep for 5 seconds. Note that it is not always possible to
make the theoretical case occur, if not, motivate why.

	We were able to make it happen by inserting SLEEP(5) directly after calculating the free seats. By using two sessions both adding 
    the 21 passengers from the question10 script we obtained -2 as free seats for that flight. For some reason, it took several attempts 
    to succeed even with the sleep(5) statement. We assumed that it would be certain because of the long "wait", but yet several attempt were 
    needed to finally make it.

d) Modify the testscripts so that overbookings are no longer possible using
(some of) the commands START TRANSACTION, COMMIT, LOCK TABLES, UNLOCK
TABLES, ROLLBACK, SAVEPOINT, and SELECT…FOR UPDATE. Motivate why your
solution solves the issue, and test that this also is the case using the sleep
implemented in 10c. Note that it is not ok that one of the sessions ends up in a
deadlock scenario. Also, try to hold locks on the common resources for as
short time as possible to allow multiple sessions to be active at the same time.

	Since we do not have any problem with the stored procedures for adding reservations, passengers or contacts
    (These do not leave any room for duplicate entrys or anything else that could affect us) we only need to worry about addPayment. 
    We really wanted to apply a lock tables - solution but could not figure out how to use aliases combined with ON READ/WRITE
    in time for the hand in, so we went back to the argument about transactions and commits in 8b) and just started a transaction
    before the call on addPayment and we commit to the database right after it. As mentioned earlier, this locks the tables temporarely. */
    

/*====================== SECONDARY INDEX ================================== 

	Assuming that brianair will be growing rapidly and becoming one of the largest airlines on the market,
    they will probably end up with thousands of thousands, maybe millions, of customers (passengers)
    If that is the case, many of them are likely to have the same name. Searching for information about a customers flight,
    lounge-rights, payment details, tickets etc will probably be a very popular way of accessing the database, and we don't want them
    to have to wait for long querys. Therefore, a secondary index based on customer names might be a good idea to speed up the search.
    If passengers are first ordered (and accessed) by name and then their passportnr the process could be way more efficient when 
    the business elevates to a larger scale.*/
    
    





	

 
 

        
        
		
    
	











    











 








