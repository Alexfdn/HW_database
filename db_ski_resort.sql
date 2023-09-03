
CREATE TABLE clients
(
	id SERIAL PRIMARY KEY,
	surname VARCHAR(30) NOT NULL,
	first_name VARCHAR(20) NOT NULL,
	last_name VARCHAR(20) NOT NULL,
	pasport VARCHAR(20) NOT NULL,
	phone VARCHAR(20) NOT NULL
);
CREATE TABLE instructors
(
	id SERIAL PRIMARY KEY,
	surname VARCHAR(30) NOT NULL,
	first_name VARCHAR(20) NOT NULL,
	last_name VARCHAR(20) NOT NULL,
	pasport VARCHAR(20) NOT NULL,
	specialization VARCHAR(20) NOT NULL,
	price_hour_rub FLOAT NOT NULL
);
CREATE TABLE classes_instructors
(
	id SERIAL PRIMARY KEY,
	date_from TIMESTAMP NOT NULL,
	date_to TIMESTAMP,
	client_id INTEGER REFERENCES clients (id) ON DELETE SET NULL,
	instructor_id INTEGER REFERENCES instructors (id) ON DELETE SET NULL
);
CREATE TABLE ski_trails
(
	id SERIAL PRIMARY KEY,
	type_trails VARCHAR(20) NOT NULL,
	opening_hours TIME NOT NULL,
	price_per_lift FLOAT NOT NULL
);
CREATE TABLE lift_trails
(
	id SERIAL PRIMARY KEY,
	date_lift TIMESTAMP NOT NULL,
	client_id INTEGER REFERENCES clients (id) ON DELETE SET NULL,
	trail_id INTEGER REFERENCES ski_trails (id) ON DELETE SET NULL
);
CREATE TABLE balance_client
( 
	id SERIAL PRIMARY KEY,
	client_id INTEGER REFERENCES clients (id) ON DELETE SET NULL,
	current_balance FLOAT NOT NULL
);
CREATE OR REPLACE PROCEDURE add_client
(
	add_id INOUT INT,
	add_surname VARCHAR(30),
	add_first_name VARCHAR(20),
	add_last_name VARCHAR(20),
	add_pasport VARCHAR(20),
	add_phone VARCHAR(20)
)
LANGUAGE plpgsql AS
$$
BEGIN
	IF NOT EXISTS(SELECT pasport FROM clients WHERE pasport = add_pasport) THEN
		INSERT INTO clients (surname, first_name, last_name, pasport, phone)
		VALUES (add_surname, add_first_name, add_last_name, add_pasport, add_phone)
		RETURNING id INTO add_id;
	ELSE
		RAISE NOTICE 'Один и тот же клиент не может быть зарегистрирован';
	END IF;
END
$$;
CREATE OR REPLACE PROCEDURE add_instructor
(
	add_id INOUT INT,
	add_surname VARCHAR(30),
	add_first_name VARCHAR(20),
	add_last_name VARCHAR(20),
	add_pasport VARCHAR(20),
	add_specialization VARCHAR(20),
	add_price_hour_rub FLOAT
)
LANGUAGE plpgsql AS
$$
BEGIN
	IF NOT EXISTS (SELECT pasport FROM instructors WHERE pasport = add_pasport) THEN
		INSERT INTO instructors (surname, first_name, last_name, pasport, specialization, price_hour_rub)
		VALUES (add_surname, add_first_name, add_last_name, add_pasport, add_specialization, add_price_hour_rub)
		RETURNING id INTO add_id;
	ELSE
		RAISE NOTICE 'Инструктор уже добавлен';
	END IF;
END
$$;
CREATE OR REPLACE PROCEDURE add_ski_trail
(
	add_id INOUT INT,
	add_type_trails VARCHAR(20),
	add_opening_hours TIME,
	add_price_per_lift FLOAT
)
LANGUAGE plpgsql AS
$$
BEGIN
	INSERT INTO ski_trails (type_trails, opening_hours, price_per_lift)
	VALUES (add_type_trails, add_opening_hours, add_price_per_lift)
	RETURNING id INTO add_id;
END
$$;

CREATE OR REPLACE PROCEDURE add_balance_client
(
	add_id INOUT INT,
	add_client_id INTEGER,
	add_current_balance FLOAT

)
LANGUAGE plpgsql AS
$$
BEGIN
	INSERT INTO balance_client(client_id, current_balance)
	VALUES
	(
		add_client_id,
		add_current_balance
	)
	RETURNING id INTO add_id;
END
$$;

CREATE OR REPLACE PROCEDURE add_class_inst_update_balance
(
	add_id INOUT INT,
	add_date_from TIMESTAMP,
	add_date_to TIMESTAMP,
	add_client_id INTEGER,
	add_instructor_id INTEGER,
	up_price FLOAT
)
LANGUAGE plpgsql AS
$$
BEGIN
	IF(SELECT current_balance FROM balance_client WHERE client_id = add_client_id) >= up_price THEN
		INSERT INTO classes_instructors(date_from, date_to, client_id, instructor_id)
		VALUES
		(
		add_date_from,
		add_date_to,
		add_client_id,
		add_instructor_id
		)
		RETURNING id INTO add_id;
		UPDATE balance_client
		SET
		current_balance = (SELECT current_balance FROM balance_client WHERE client_id = add_client_id) - up_price
		WHERE client_id = add_client_id;
	ELSE RAISE NOTICE 'Недостаточно средств';
END IF;
END
$$;

CREATE OR REPLACE PROCEDURE add_lift_trail_update_balance
(
	add_id INOUT INT,
	add_date_lift TIMESTAMP,
	add_client_id INTEGER,
	add_trail_id INTEGER,
	up_price FLOAT
)
LANGUAGE plpgsql AS
$$
BEGIN
	IF(SELECT current_balance FROM balance_client WHERE client_id = add_client_id) >= up_price THEN
		INSERT INTO lift_trails(date_lift, client_id, trail_id)
		VALUES
		(
		add_date_lift,
		add_client_id,
		add_trail_id
		)
		RETURNING id INTO add_id;
		UPDATE balance_client
		SET
		current_balance = (SELECT current_balance FROM balance_client WHERE client_id = add_client_id) - up_price
		WHERE client_id = add_client_id;
	ELSE RAISE NOTICE 'Недостаточно средств';
	END IF;
END
$$;

CREATE OR REPLACE PROCEDURE update_balance_client
(
	up_client_id INT,
	up_balance FLOAT
)
LANGUAGE plpgsql AS
$$
BEGIN
	UPDATE balance_client
	SET current_balance = (SELECT current_balance FROM balance_client WHERE client_id = up_client_id) + up_balance
	WHERE client_id = up_client_id;
END
$$;


CREATE OR REPLACE VIEW current_client_balanse AS
	SELECT surname, first_name, last_name, current_balance, clients.id
	FROM clients
	INNER JOIN balance_client
	ON clients.id = balance_client.client_id

CREATE ROLE administrator;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA PUBLIC TO administrator;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA PUBLIC TO administrator;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA PUBLIC TO administrator;

CREATE ROLE manager;
GRANT ALL PRIVILEGES ON TABLE clients TO manager;
GRANT ALL PRIVILEGES ON TABLE instructors TO manager;
GRANT ALL PRIVILEGES ON TABLE ski_trails TO manager;
GRANT EXECUTE ON PROCEDURE add_ski_trail TO manager;
GRANT ALL PRIVILEGES ON PROCEDURE add_client TO manager;
GRANT ALL PRIVILEGES ON PROCEDURE add_instructor TO manager;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA PUBLIC TO manager;
GRANT ALL PRIVILEGES ON PROCEDURE add_class_inst_update_balance TO manager;
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO manager;
