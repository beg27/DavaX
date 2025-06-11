CREATE TABLE Angajati (
    angajat_id NUMBER PRIMARY KEY,
    nume VARCHAR2(100) NOT NULL,
    email VARCHAR2(150) UNIQUE NOT NULL,
    status VARCHAR2(20) DEFAULT 'activ' CHECK (status IN ('activ', 'inactiv'))
);

CREATE TABLE Proiecte (
    proiect_id NUMBER PRIMARY KEY,
    nume VARCHAR2(100) NOT NULL,
    activ CHAR(1) DEFAULT 'Y' CHECK (activ IN ('Y', 'N'))
);

CREATE TABLE Taskuri (
    task_id NUMBER PRIMARY KEY,
    proiect_id NUMBER REFERENCES Proiecte(proiect_id),
    descriere VARCHAR2(200) NOT NULL,
    deadline DATE,
    detalii_xml XMLTYPE
);

CREATE TABLE Pontaj (
    pontaj_id NUMBER PRIMARY KEY,
    angajat_id NUMBER NOT NULL REFERENCES Angajati(angajat_id),
    proiect_id NUMBER NOT NULL REFERENCES Proiecte(proiect_id),
    task_id NUMBER REFERENCES Taskuri(task_id),
    data_zi DATE NOT NULL,
    durata_ore NUMBER(3,1) NOT NULL CHECK (durata_ore > 0),
    observatii_json CLOB CHECK (observatii_json IS JSON)
);

CREATE INDEX idx_pontaj_data ON Pontaj(data_zi);
CREATE INDEX idx_pontaj_durata ON Pontaj(durata_ore);

INSERT INTO Angajati (angajat_id, nume, email, status) VALUES (1, 'Andrei Pop', 'andrei.pop@example.com', 'activ');
INSERT INTO Angajati (angajat_id, nume, email, status) VALUES (2, 'Ioana Ionescu', 'ioana.ionescu@example.com', 'activ');
INSERT INTO Angajati (angajat_id, nume, email, status) VALUES (3, 'Mihai Georgescu', 'mihai.georgescu@example.com', 'inactiv');


INSERT INTO Proiecte (proiect_id, nume, activ) VALUES (100, 'Sistem HR', 'Y');
INSERT INTO Proiecte (proiect_id, nume, activ) VALUES (200, 'Website Intranet', 'Y');
INSERT INTO Proiecte (proiect_id, nume, activ) VALUES (300, 'Aplicatie Contabilitate', 'N');

INSERT INTO Taskuri (task_id, proiect_id, descriere, deadline, detalii_xml)
VALUES (
  1000, 100, 'Analiza cerintelor', TO_DATE('2025-06-10', 'YYYY-MM-DD'),
  XMLTYPE('<task><prioritate>ridicata</prioritate><durata>3</durata></task>')
);

INSERT INTO Taskuri (task_id, proiect_id, descriere, deadline, detalii_xml)
VALUES (
  1001, 200, 'Design interfata', TO_DATE('2025-06-15', 'YYYY-MM-DD'),
  XMLTYPE('<task><prioritate>medie</prioritate><durata>5</durata></task>')
);


INSERT INTO Pontaj (pontaj_id, angajat_id, proiect_id, task_id, data_zi, durata_ore, observatii_json)
VALUES (
  1, 1, 100, 1000, TO_DATE('2025-06-01', 'YYYY-MM-DD'), 4.5,
  '{ "comentariu": "Analiza functionalitatilor", "tip": "analiza" }'
);

INSERT INTO Pontaj (pontaj_id, angajat_id, proiect_id, task_id, data_zi, durata_ore, observatii_json)
VALUES (
  2, 2, 200, 1001, TO_DATE('2025-06-02', 'YYYY-MM-DD'), 3,
  '{ "comentariu": "Discutii cu echipa UI", "tip": "design" }'
);

INSERT INTO Pontaj (pontaj_id, angajat_id, proiect_id, task_id, data_zi, durata_ore, observatii_json)
VALUES (
  3, 1, 100, 1000, TO_DATE('2025-06-03', 'YYYY-MM-DD'), 5,
  '{ "comentariu": "Scriere documentatie", "tip": "documentare" }'
);

SELECT * FROM Angajati;
SELECT * FROM Pontaj;


-- View pentru afișarea pontajelor complete, cu numele angajatului, proiectului și taskului
CREATE OR REPLACE VIEW View_Pontaj_Extins AS
SELECT
  p.pontaj_id,
  a.nume AS angajat,
  pr.nume AS proiect,
  t.descriere AS task,
  p.data_zi,
  p.durata_ore
FROM Pontaj p
JOIN Angajati a ON p.angajat_id = a.angajat_id
JOIN Proiecte pr ON p.proiect_id = pr.proiect_id
LEFT JOIN Taskuri t ON p.task_id = t.task_id;



-- Materialized view cu totalul orelor per angajat și proiect
CREATE MATERIALIZED VIEW MV_Total_Ore_Angajat_Proiect
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
  p.angajat_id,
  a.nume AS angajat,
  p.proiect_id,
  pr.nume AS proiect,
  SUM(p.durata_ore) AS total_ore
FROM Pontaj p
JOIN Angajati a ON p.angajat_id = a.angajat_id
JOIN Proiecte pr ON p.proiect_id = pr.proiect_id
GROUP BY p.angajat_id, a.nume, p.proiect_id, pr.nume;


SELECT * FROM View_Pontaj_Extins;
SELECT * FROM MV_Total_Ore_Angajat_Proiect;

-- Grupăm orele lucrate pe lună, pentru fiecare angajat
SELECT 
  a.nume AS angajat,
  TO_CHAR(p.data_zi, 'YYYY-MM') AS luna,
  SUM(p.durata_ore) AS total_ore
FROM Pontaj p
JOIN Angajati a ON p.angajat_id = a.angajat_id
GROUP BY a.nume, TO_CHAR(p.data_zi, 'YYYY-MM')
ORDER BY a.nume, luna;


-- Afișăm toate taskurile și orele lucrate, chiar dacă unele taskuri nu au fost încă pontate
SELECT 
  t.task_id,
  t.descriere,
  p.durata_ore,
  p.data_zi
FROM Taskuri t
LEFT JOIN Pontaj p ON t.task_id = p.task_id
ORDER BY t.task_id, p.data_zi;


-- Afișăm topul celor mai lungi pontaje pentru fiecare angajat, clasificate cu RANK()
SELECT 
  a.nume AS angajat,
  p.data_zi,
  p.durata_ore,
  RANK() OVER (PARTITION BY a.angajat_id ORDER BY p.durata_ore DESC) AS durata_rank
FROM Pontaj p
JOIN Angajati a ON p.angajat_id = a.angajat_id
ORDER BY a.nume, durata_rank;


