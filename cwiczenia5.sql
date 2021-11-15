CREATE EXTENSION postgis;
drop table obiekty;
CREATE TABLE obiekty(id integer, name varchar, geom geometry);

INSERT INTO obiekty(id, name, geom) VALUES
(1, 'obiekt1',
 ST_GeomFromText('MULTICURVE(LINESTRING(0 1, 1 1),  
				 CIRCULARSTRING(1 1, 2 0, 3 1), 
				 CIRCULARSTRING(3 1, 4 2, 5 1), 
				 LINESTRING(5 1, 6 1))', 0)),
(2, 'obiekt2',
 ST_GeomFromText('CURVEPOLYGON(COMPOUNDCURVE(LINESTRING(10 6, 10 2),  
				 CIRCULARSTRING(10 2, 12 0, 14 2), 
				 CIRCULARSTRING(14 2, 16 4, 14 6), 
				 LINESTRING(14 6, 10 6)), 
				 CIRCULARSTRING(12 2, 13 2, 12 2))', 0)),
(3, 'obiekt3', 
 ST_GeomFromText('LINESTRING(2 15, 12 13, 10 17, 2 15)', 0)),
(4, 'obiekt4',
 ST_GeomFromText('LINESTRING(20.5 19.5, 22 19, 26 21, 25 22, 27 24, 25 25, 20 20)', 0)),
(5, 'obiekt5', 
 ST_GeomFromText('MULTIPOINT((30 30 59),(38 32 234))', 0)),
(6, 'obiekt6', 
 ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), 
				 POINT(4 2))', 0));

				  
select id, name, ST_CurveToLine(obiekty.geom) from obiekty;


--1
SELECT ST_Area(ST_Buffer(ST_ShortestLine(fig3.geom, fig4.geom), 5))
FROM obiekty fig3, obiekty fig4
WHERE fig3.name='obiekt3' AND fig4.name='obiekt4';

--2
--musi być to zamknięty obiekt
UPDATE obiekty
SET geom = ST_GeomFromText('POLYGON((20.5 19.5, 22 19, 26 21, 25 22, 27 24, 25 25, 20 20, 20.5 19.5))', 0)
WHERE name='obiekt4';

--3
INSERT INTO obiekty(id, name, geom) VALUES
(7, 'obiekt7',
 (SELECT ST_Union(fig3.geom, fig4.geom)
 FROM obiekty fig3, obiekty fig4
 WHERE fig3.name='obiekt3' AND fig4.name='obiekt4'));
 
 --4
SELECT SUM(ST_Area(ST_Buffer(geom, 5)))
FROM obiekty
WHERE name!='obiekt1' and name!='obiekt2';
