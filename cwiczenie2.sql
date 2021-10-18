-- Database: cwiczenia2

-- DROP DATABASE cwiczenia2;

CREATE DATABASE cwiczenia2
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
	
--3.	Dodaj funkcjonalności PostGIS’a do bazy poleceniem CREATE EXTENSION postgis;
	CREATE EXTENSION postgis;

--4.	Na podstawie poniższej mapy utwórz trzy tabele: buildings (id, geometry, name), roads (id, geometry, name), poi (id, geometry, name).
CREATE TABLE buildings
(buildings_id integer NOT NULL PRIMARY KEY, buildings_geometry geometry, buildings_name varchar);
 
CREATE TABLE roads
(roads_id integer NOT NULL PRIMARY KEY, roads_geometry geometry, roads_name varchar);
 
CREATE TABLE poi
(poi_id integer NOT NULL PRIMARY KEY, poi_geometry geometry, poi_name varchar);

--5.	Współrzędne obiektów oraz nazwy (np. BuildingA) należy odczytać z mapki umieszczonej poniżej. Układ współrzędnych ustaw jako niezdefiniowany.
INSERT INTO buildings(buildings_id, buildings_geometry, buildings_name) 
	VALUES(1, ST_GeomFromText('POLYGON ((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))', 0), 'BUDYNEK_A' );
INSERT INTO buildings(buildings_id, buildings_geometry, buildings_name) 
	VALUES(2, ST_GeomFromText('POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))', 0), 'BUDYNEK_B' );
INSERT INTO buildings(buildings_id, buildings_geometry, buildings_name) 
	VALUES(3, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))', 0), 'BUDYNEK_C' );
INSERT INTO buildings(buildings_id, buildings_geometry, buildings_name) 
	VALUES(4, ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))', 0), 'BUDYNEK_D' );
INSERT INTO buildings(buildings_id, buildings_geometry, buildings_name) 
	VALUES(5, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))', 0), 'BUDYNEK_F' );
	

INSERT INTO roads(roads_id, roads_geometry, roads_name) 
	VALUES(1, ST_GeomFromText('LINESTRING (0 4.5, 12 4.5)', 0), 'ROAD_X' );
INSERT INTO roads(roads_id, roads_geometry, roads_name) 
	VALUES(2, ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)', 0), 'ROAD_Y' );
	

INSERT INTO poi(poi_id, poi_geometry, poi_name) 
	VALUES(1, ST_GeomFromText('POINT (1 3.5)', 0), 'G' );
INSERT INTO poi(poi_id, poi_geometry, poi_name) 
	VALUES(2, ST_GeomFromText('POINT(5.5 1.5)', 0), 'H' );
INSERT INTO poi(poi_id, poi_geometry, poi_name) 
	VALUES(3, ST_GeomFromText('POINT(9.5 6)', 0), 'I' );
INSERT INTO poi(poi_id, poi_geometry, poi_name) 
	VALUES(4, ST_GeomFromText('POINT(6.5 6)', 0), 'J' );
	INSERT INTO poi(poi_id, poi_geometry, poi_name) 
	VALUES(5, ST_GeomFromText('POINT(6 9.5)', 0), 'K' );
	
	
--6.	Na bazie przygotowanych tabel wykonaj poniższe polecenia:	
--a.	Wyznacz całkowitą długość dróg w analizowanym mieście.  
 SELECT SUM(ST_Length(roads_geometry)) AS roadsLength
 FROM roads;
 
 --b.	Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA
 SELECT buildings_name, ST_Area(buildings_geometry) AS pole_powierzchni, 
 		ST_Perimeter(buildings_geometry) AS obwod
 FROM buildings
 WHERE buildings_name = 'BUDYNEK_A';
 
 --c. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.  
 
SELECT buildings_name, 
		ST_Area(buildings_geometry) AS pole_powierzchni 
FROM buildings
ORDER BY buildings_name;

--d.	Wypisz nazwy i obwody 2 budynków o największej powierzchni. 
SELECT buildings_name, ST_Area(buildings_geometry) AS pole_powierzchni
FROM buildings
ORDER BY pole_powierzchni DESC
LIMIT 2;


--e.	Wyznacz najkrótszą odległość między budynkiem Building C a punktem G.  
SELECT ST_Distance(buildings_geometry, poi_geometry) AS odleglosc
FROM buildings, poi
WHERE buildings_name = 'BUDYNEK_C' AND poi_name = 'G';

--f.	Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB. 

SELECT ST_Area(ST_Difference
			   ((SELECT buildings_geometry FROM buildings WHERE buildings_name = 'BUDYNEK_C'),
				ST_Buffer((SELECT buildings_geometry FROM buildings WHERE buildings_name = 'BUDYNEK_B'), 0.5)));
--g.	Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi 
--		o nazwie RoadX.  
SELECT buildings_name, ST_Centroid(buildings_geometry) FROM buildings, roads
WHERE ST_Y(ST_Centroid(buildings_geometry)) > ST_Y(ST_Centroid(roads_geometry)) AND roads_name = 'ROAD_X';

--8. 	Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.
SELECT ST_Area(ST_AsText(ST_SymDifference(buildings_geometry, ST_AsText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))))
FROM buildings WHERE buildings_name = 'BUDYNEK_C';

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 