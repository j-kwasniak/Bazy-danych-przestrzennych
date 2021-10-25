CREATE EXTENSION postgis;

--4.	Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
-- 		położonych w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające to kryterium 
--		zapisz do osobnej tabeli tableB.

SELECT COUNT(popp.f_codedesc) FROM popp, rivers WHERE popp.f_codedesc = 'Building' AND ST_Distance(rivers.geom, popp.geom) < 1000;
SELECT * FROM popp;

CREATE TABLE tableB(building varchar(80));
INSERT INTO tableB (SELECT (popp.f_codedesc) FROM popp, rivers WHERE popp.f_codedesc = 'Building' AND ST_Distance(rivers.geom, popp.geom) < 1000);
SELECT * FROM tableB;
					
--5.	Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.  
		CREATE TABLE airportsNew(name varchar(80), geom geometry, elev numeric);
		INSERT INTO airportsNew(SELECT name, geom, elev FROM airports);
		SELECT * FROM airportsNew;
	--a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.
		SELECT name, ST_Y(airportsNew.geom) AS WEST FROM airportsNew 
		ORDER BY WEST  LIMIT 1 ;
		
		SELECT name, ST_Y(airportsNew.geom) AS EAST FROM airportsNew 
		ORDER BY EAST  DESC LIMIT 1 ;
		
	--b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. 
	--	Wysokość n.p.m. przyjmij dowolną.
	INSERT INTO airportsNew(name, geom, elev) VALUES ('airportB',(SELECT ST_Centroid(ST_ShortestLine(A.geom,B.geom))
	FROM airportsNew A, airportsNew B WHERE A.name = 'NOATAK' and B.name = 'NIKOLSKI AS'), 12);
	
	SELECT * FROM airportsNew ORDER BY name;
	
-- 6.	Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer((SELECT ST_ShortestLine(lakes.geom, airports.geom) FROM lakes, airports WHERE  lakes.names = 'Iliamna Lake' AND airports.name = 'AMBLER'), 1000));

--7.	Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).  
select * from trees;

SELECT SUM(ST_Area(trees.geom)), trees.vegdesc
FROM trees, swamp, tundra
WHERE ST_Contains(trees.geom, swamp.geom) OR ST_Contains(trees.geom, tundra.geom)
GROUP BY trees.vegdesc;

					