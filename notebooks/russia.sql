--- Полнота данных здесь
--- ЧИСТОВИК СОЗДАЕМ BUILDINGS
DROP TABLE IF EXISTS buildings;

-- Создаем таблицу зданий
CREATE TABLE buildings (
	id varchar PRIMARY key,
	geometry public.geometry(multipolygon, 4326) NULL,
	addr varchar NULL
);

-- Инсертим здания
INSERT INTO 
	buildings(id , geometry, addr)
SELECT
	COALESCE('R' ||  osm_id,'W' || osm_way_id), 
	wkb_geometry, 
	COALESCE(other_tags->'addr:city' || ', ', '') || COALESCE(other_tags->'addr:street' || ', ', '') || COALESCE(other_tags->'addr:housenumber', '')
FROM
	multipolygons m 
WHERE
	other_tags IS NOT NULL
AND
	other_tags->'addr:housenumber' IS NOT NULL;
	
-- Только потом наваливаем индекс
CREATE INDEX buildings_geo ON buildings USING gist (geometry);

-- Аналитика по кол-ву сущностей в базе
SELECT 
	count(*)
FROM
	buildings


-- Удаляем buffers20
DROP TABLE IF EXISTS buffers20;

-- Создаем таблицу без индексов
CREATE TABLE buffers20 (LIKE buildings);

INSERT INTO buffers20
SELECT
	id, ST_Multi(ST_Buffer(geometry, 0.0002)), addr
FROM
	buildings;

CREATE INDEX buffers_geo20 ON buffers20 USING gist (geometry);
-- Аналитика по кол-ву сущностей в базе
SELECT 
	count(*)
FROM
	buffers20

-- Удаляем buildings_houses
DROP TABLE IF EXISTS buildings_houses

CREATE TABLE buildings_houses (LIKE buildings);
	
-- Инсертим здания
INSERT INTO 
	buildings_houses(id , geometry, addr)
SELECT
	COALESCE('R' ||  osm_id,'W' || osm_way_id), 
	wkb_geometry, 
	COALESCE(other_tags->'addr:city' || ', ', '') || COALESCE(other_tags->'addr:street' || ', ', '') || COALESCE(other_tags->'addr:housenumber', '')
FROM
	multipolygons m 
WHERE
	building IS NOT NULL

CREATE INDEX buildings_houses_geo ON buildings_houses USING gist (geometry);

-- Аналитика по кол-ву сущностей в базе
SELECT 
	count(*)
FROM
	buildings_houses

--- Аналитика по lozonp
SELECT 
	count(*)
FROM
	lozonp


-- Создаем гео-индекс 
CREATE INDEX lozon_geo ON lozonp USING gist (geometry);
-- Создаем таблицу с результатом
DROP TABLE IF EXISTS lozon_result;
-- 
CREATE TABLE public.lozon_result (
	lid varchar NOT NULL,
	lgeom public.geometry(point, 4326) NULL,
	bgeom public.geometry(multipolygon, 4326) NULL,
	laddr varchar NULL,
	baddr varchar NULL,
	bid varchar NULL,
	CONSTRAINT lozon_result_pkey PRIMARY KEY (lid)
);
--
CREATE INDEX lozon_result_idx ON lozon_result USING gist (lgeom);

INSERT INTO
	lozon_result
SELECT 
	l.id AS lid, l.geometry AS lgeom, b.geometry AS bgeom,  l.addr AS laddr, b.addr AS baddr, b.id AS bid
FROM
	lozonp l
LEFT JOIN buildings b
ON ST_Covers(b.geometry, st_setsrid(l.geometry, 4326 ))
group by (l.id,l.geometry,b.geometry, l.addr, b.addr, b.id)
ON CONFLICT DO NOTHING;
	

SELECT
	count(*)
FROM
	lozon_result 
	
SELECT	
	ROUND(
		CAST( (SELECT
			count(*)
		FROM
			lozon_result
		WHERE
		 bid IS NOT NULL)::float
	/
		(SELECT
			count(*)
		FROM
			lozon_result)
	* 100 AS NUMERIC) , 2);
	
--- вхождения в буфера


-- Создаем индекс для фильтрации  
CREATE INDEX lozon_result_geo ON lozon_result USING gist (lgeom);
CREATE INDEX lozon_result_bid_nn ON lozon_result (bid) WHERE bid IS NULL;

-- Создаем таблицу с результатами
DROP TABLE IF EXISTS lozon_b20_set;

CREATE TABLE lozon_b20_set (LIKE lozonp)

ALTER TABLE lozon_b20_set
  		ADD PRIMARY KEY (id);

INSERT INTO 
	lozon_b20_set(id , addr, geometry)
SELECT
	lid::bigint AS id, laddr AS addr, lgeom AS geometry
FROM
	lozon_result 
WHERE
	bid IS NULL;
	

SELECT
	count(*)
FROM
	lozon_b20_set

	
SELECT
	*
FROM
	lozon_b20_set

	
-- Создаем индекс для фильтрации  
CREATE INDEX lozon_b20_set_geo ON lozon_b20_set USING gist (geometry);

-- Создаем таблицу с результатом
DROP TABLE IF EXISTS lozon_b20_result;
-- 
CREATE TABLE lozon_b20_result (LIKE lozon_result);

ALTER TABLE lozon_b20_result
  		ADD PRIMARY KEY (lid);

  	
INSERT INTO
	lozon_b20_result
SELECT 
	l.id AS lid, l.geometry AS lgeom, b.geometry AS bgeom,  l.addr AS laddr, b.addr AS baddr, b.id AS bid
FROM
	lozon_b20_set  l
LEFT JOIN buffers20  b
ON
	ST_Covers(b.geometry, st_setsrid(l.geometry, 4326 ))
group by (l.id,l.geometry,b.geometry, l.addr, b.addr, b.id)
ON CONFLICT DO NOTHING;
	
	
SELECT	
	ROUND(
		CAST( (SELECT
			count(*)
		FROM
			lozon_b20_result
		WHERE
		 bid IS NOT NULL)::float
	/
		(SELECT
			count(*)
		FROM
			lozon_result)
	* 100 AS NUMERIC) , 2);
	

SELECT
	*
FROM
	lozon_b20_result

	
	
	
	
-- Создаем индекс для фильтрации  
CREATE INDEX lozon_b20_result_geo ON lozon_b20_result USING gist (lgeom);

CREATE INDEX lozon_b20_result_bid_nn ON lozon_b20_result (bid) WHERE bid IS NULL;

-- Создаем таблицу с результатами
DROP TABLE IF EXISTS lozon_houses_set;

CREATE TABLE lozon_houses_set (LIKE lozonp)

ALTER TABLE lozon_houses_set
  		ADD PRIMARY KEY (id);

INSERT INTO 
	lozon_houses_set(id , addr, geometry)
SELECT
	lid::bigint AS id, laddr AS addr, lgeom AS geometry
FROM
	lozon_b20_result 
WHERE
	bid IS NULL;
	

SELECT
	count(*)
FROM
	lozon_houses_set

	
SELECT
	*
FROM
	lozon_houses_set
	
	
-- Создаем индекс для фильтрации  
CREATE INDEX lozon_houses_set_geo ON lozon_houses_set USING gist (geometry);

-- Создаем таблицу с результатом
DROP TABLE IF EXISTS lozon_houses_result;
-- 
CREATE TABLE lozon_houses_result (LIKE lozon_result);

ALTER TABLE lozon_houses_result
  		ADD PRIMARY KEY (lid);

  	
INSERT INTO
	lozon_houses_result
SELECT 
	l.id AS lid, l.geometry AS lgeom, b.geometry AS bgeom,  l.addr AS laddr, b.addr AS baddr, b.id AS bid
FROM
	lozon_houses_set  l
LEFT JOIN buildings_houses  b
ON
	ST_Covers(b.geometry, st_setsrid(l.geometry, 4326 ))
group by (l.id,l.geometry,b.geometry, l.addr, b.addr, b.id)
ON CONFLICT DO NOTHING;
	
	
SELECT	
	ROUND(
		CAST( (SELECT
			count(*)
		FROM
			lozon_houses_result
		WHERE
		 bid IS NOT NULL)::float
	/
		(SELECT
			count(*)
		FROM
			lozon_result)
	* 100 AS NUMERIC) , 2);
	


SELECT
	count(*)
FROM
	lozon_houses_result
WHERE
	bid IS NOT NULL

SELECT
	lid AS id, ST_X(lgeom) AS lon, ST_Y(lgeom) AS lat, laddr AS addr
FROM
	lozon_houses_result
WHERE 
	bid IS NULL
	
	
	
SELECT
	lgeom, laddr
FROM
	lozon_houses_result 
WHERE 
	BID IS NULL
	
	


SELECT 
 *
FROM
	points p 
WHERE 
	other_tags->'addr:street' IS NOT NULL
AND
 (other_tags->'train' IS null)
 
 
 
SELECT
  *
FROM
  lines l  	
WHERE 
	other_tags->'addr:street' IS NOT NULL
	
	
	
	
SELECT
	count(*)
FROM 
	multipolygons m 
WHERE 
	building IS NOT NULL

	
SELECT
	count(*)
FROM 
	multipolygons m 
WHERE 
	other_tags->'addr:street' IS NOT NULL
	
SELECT
	*
FROM 
	multipolygons m 
WHERE 
	building IS NOT NULL
AND
	other_tags->'addr:street' IS NULL
	
	
	
SELECT
	*
FROM
	points p 
WHERE 
	ST_Covers( 
(SELECT
	m.wkb_geometry 
FROM
	multipolygons m 
WHERE 
	osm_id = '1528586') , p.wkb_geometry)
	
AND
	p.other_tags->'addr:street' IS NOT NULL
	
	
	
SELECT 
	*
FROM
	multipolygons m 
WHERE 
	TYPE = 'boundary'
AND
	admin_level = '4'
	
-- Костромская область
-- 85963
SELECT
	count(*)
FROM
	multipolygons m2 
WHERE 
	ST_Covers( 
(SELECT
	m.wkb_geometry 
FROM
	multipolygons m 
WHERE 
	m.osm_id = '85963') , m2.wkb_geometry)
AND
	m2.other_tags->'addr:street' IS NOT NULL

	
SELECT
	*
FROM
	buildings  b
WHERE 
	ST_Covers(b.geometry,st_setsrid(st_point(30.22144318, 59.83517838), 4326 ))
	
CREATE INDEX idx_any_label ON buildings USING gist (geometry);



SELECT
	geometry, ST_Buffer(geometry, 0.00002)
FROM
	buildings
LIMIT 1


SELECT
	*
FROM
	buildings

-- buffers 2

CREATE TABLE buffers (LIKE buildings);

INSERT INTO buffers
SELECT
	id, ST_Multi(ST_Buffer(geometry, 0.00002)), addr
FROM
	buildings;

CREATE INDEX buffers_geo ON buffers USING gist (geometry);


SELECT *
FROM
	buffers 
ORDER BY
	ST_Perimeter(geometry) DESC
	
-- W173429686
-- R6067905
	
	
-- buffers20

CREATE TABLE buffers20 (LIKE buildings);

INSERT INTO buffers20
SELECT
	id, ST_Multi(ST_Buffer(geometry, 0.0002)), addr
FROM
	buildings;

CREATE INDEX buffers_geo20 ON buffers20 USING gist (geometry);


SELECT *
FROM
	buffers20
	
	
ORDER BY
	ST_Perimeter(geometry) DESC

	
CREATE INDEX lozon_geo ON lozonp USING gist (geometry);
	
DROP TABLE IF EXISTS lozon_result;

CREATE TABLE public.lozon_result (
	lid varchar NOT NULL,
	lgeom public.geometry(point, 4326) NULL,
	bgeom public.geometry(multipolygon, 4326) NULL,
	laddr varchar NULL,
	baddr varchar NULL,
	bid varchar NULL,
	CONSTRAINT lozon_result_pkey PRIMARY KEY (lid)
);

CREATE INDEX idx_any_label ON public.buildings USING gist (geometry);

SELECT 
	l.id AS lid, l.geometry AS lgeom, b.geometry AS bgeom,  l.addr AS laddr, b.addr AS baddr, b.id AS bid
FROM
	lozonp l
LEFT JOIN buildings b
ON ST_Covers(b.geometry, st_setsrid(l.geometry, 4326 ))



-- Проверяем 
INSERT INTO
	lozon_result
SELECT 
	l.id AS lid, l.geometry AS lgeom, b.geometry AS bgeom,  l.addr AS laddr, b.addr AS baddr, b.id AS bid
FROM
	lozonp l
LEFT JOIN buildings b
ON ST_Covers(b.geometry, st_setsrid(l.geometry, 4326 ))
group by (l.id,l.geometry,b.geometry, l.addr, b.addr, b.id)
ON CONFLICT DO NOTHING;

-- Что там
SELECT
	*
FROM
	lozon_result lr 

-- Все 

SELECT
	count(*)
FROM
	lozon_result lr 
	
-- Сматченные
	
SELECT
	count(*)
FROM
	lozon_result lr 
WHERE 
	baddr IS NOT NULL
	
-- Отношение
	
SELECT 
	(SELECT
	count(*)
FROM
	lozon_result lr 
WHERE 
	baddr IS NOT NULL)::float 
/ (SELECT
	count(*)
FROM
	lozon_result lr ) * 100
	
	
-- Отсеиваем те, кто не вошел 
	
DROP TABLE emptyrez

CREATE TABLE emptyrez (LIKE lozon_result);

INSERT INTO emptyrez
SELECT 
	*
FROM
	lozon_result 
WHERE 
	baddr IS NULL
	
SELECT
	*
FROM
	emptyrez

CREATE INDEX emptyrez_geo ON emptyrez USING gist (lgeom);
	
-- Тестируем вхождение
	
SELECT 
	e.lid AS lid, e.lgeom AS lgeom, b.geometry AS bgeom,  e.laddr AS laddr, b.addr AS baddr, b.id AS bid
FROM
	emptyrez e
LEFT JOIN buffers20 b
ON ST_Covers(b.geometry, st_setsrid(e.lgeom, 4326 ))

-- АддБуфферс
DROP TABLE withbuffers;

CREATE TABLE withbuffers (LIKE lozon_result);

ALTER TABLE withbuffers ADD PRIMARY KEY (lid)

SELECT 
	*
FROM 
	withbuffers w 

INSERT INTO withbuffers
SELECT 
	e.lid AS lid, e.lgeom AS lgeom, b.geometry AS bgeom,  e.laddr AS laddr, b.addr AS baddr, b.id AS bid
FROM
	emptyrez e
LEFT JOIN buffers20 b
ON ST_Covers(b.geometry, st_setsrid(e.lgeom, 4326 ))
group by (e.lid,e.lgeom,b.geometry, e.laddr, b.addr, b.id)
ON CONFLICT DO NOTHING;

SELECT
	count(*)
FROM
	withbuffers
WHERE 
	baddr IS NOT NULL
	

SELECT
((SELECT
	count(*)
FROM
	lozon_result lr 
WHERE 
	baddr IS NOT NULL) + (SELECT
	count(*)
FROM
	withbuffers
WHERE 
	baddr IS NOT NULL))::float / (SELECT
	count(*)
FROM
	lozon_result lr ) * 100
	
SELECT
	lid, ST_X(lgeom) AS lon, ST_Y(lgeom) AS lat, laddr, lgeom 
FROM 
	withbuffers w 
WHERE 
	baddr IS NULL
	

SELECT
	*
FROM 
	withbuffers w
WHERE
	bid IS NULL 
	
	
	







--- ПОХОД НОМЕР 3
-- Что будем делать
-- Вытащим все полигоны, которые house
	
SELECT
	*
FROM
	multipolygons m
WHERE
	building IS NOT NULL
	
	
CREATE TABLE buildings_houses (LIKE buildings INCLUDING INDEXES);
-- id 
-- geometry
-- addr	
	
-- Инсертим здания
INSERT INTO 
	buildings_houses(id , geometry, addr)
SELECT
	COALESCE('R' ||  osm_id,'W' || osm_way_id), 
	wkb_geometry, 
	COALESCE(other_tags->'addr:city' || ', ', '') || COALESCE(other_tags->'addr:street' || ', ', '') || COALESCE(other_tags->'addr:housenumber', '')
FROM
	multipolygons m 
WHERE
	building IS NOT NULL

CREATE INDEX buildings_houses_geo ON buildings_houses USING gist (geometry);

--- 
DROP TABLE emptyrez2

CREATE TABLE emptyrez2 (LIKE lozon_result);

INSERT INTO emptyrez2
SELECT
	*
FROM 
	withbuffers w
WHERE
	bid IS NULL
	
CREATE INDEX emptyrez2_geo ON emptyrez2 USING gist (lgeom);

CREATE TABLE noaddr_result (LIKE lozon_result);

ALTER TABLE noaddr_result ADD PRIMARY KEY (lid)
	
INSERT INTO
	noaddr_result
SELECT 
	l.lid AS lid, l.lgeom AS lgeom, b.geometry AS bgeom,  l.laddr AS laddr, b.addr AS baddr, b.id AS bid
FROM
	emptyrez2 l
LEFT JOIN buildings_houses b
ON ST_Covers(b.geometry, st_setsrid(l.lgeom, 4326 ))
group by (l.lid,l.lgeom,b.geometry, l.laddr, b.addr, b.id)
ON CONFLICT DO NOTHING;


SELECT (SELECT 
	count(*)
FROM
	noaddr_result 
WHERE 
	BId IS NOT NULL)::float
/
(SELECT 
	count(*)
FROM
	noaddr_result) * 100
	
SELECT 
	count(*)
FROM
	noaddr_result 
WHERE 
	BId IS NOT NULL

SELECT 
	*
FROM
	noaddr_result 
WHERE 
	BId IS NOT NULL
	
	
	
SELECT
	count(*)
FROM
	lozon_result
WHERE
	 bid IS NOT NULL
	 
	 
SELECT
	count(*)
FROM
	lozon_b20_result
WHERE
	 bid IS NOT NULL
	 
	 
SELECT
	count(*)
FROM
	lozon_houses_result
WHERE
	 bid IS NOT NULL
	 
	 
SELECT
	count(*)
FROM
	lozon_houses_result
WHERE
	 bid IS NULL

	
	
	 
SELECT 
	lgeom 
FROM
	noaddr_result nr 
WHERE 
	lid = '17074788845000'
	
	
SELECT 
	lgeom 
FROM
	noaddr_result nr 
WHERE 
	lid = '17075054498000'
	
	
	
SELECT 
	( 90000.0 * 1.58 / 22 / 8) /60 * 3 * 1000000
	
SELECT
	wkb_geometry, name,other_tags, building  
FROM
	multipolygons m 
WHERE 
	ST_Covers(m.wkb_geometry ,
(SELECT 
	lgeom 
FROM
	noaddr_result nr 
WHERE 
	lid = '17075054498000'
	))
	
	
SELECT
	wkb_geometry, name,other_tags, building  
FROM
	multipolygons m 
WHERE 
	ST_Covers(m.wkb_geometry ,
(SELECT 
	lgeom 
FROM
	noaddr_result nr 
WHERE 
	lid = '17075371729000'
	))
	
SELECT 
	lgeom 
FROM
	noaddr_result nr 
WHERE 
 lid = '17075371729000'
 
 
 
SELECT 
	lgeom
FROM
	noaddr_result nr 
WHERE 
	lid = '17078207115000'
	
-- Объекты с адресами, которые задани поли-линиями
SELECT 
	count(*)
FROM
	lines l 
WHERE 	
	other_tags IS NOT NULL
AND
	other_tags->'addr:housenumber' IS NOT null

--- Что еще есть в полилиниях
	
SELECT 
	name, barrier, other_tags, wkb_geometry 
FROM
	lines l 
WHERE 	
	other_tags IS NOT NULL
AND
	other_tags->'addr:housenumber' IS NOT null

	
	
-- https://gis.stackexchange.com/questions/113029/polygon-from-line-creation-problem
SELECT 
	wkb_geometry
FROM
	lines l 
WHERE 	
	other_tags IS NOT NULL
AND
	other_tags->'addr:housenumber' IS NOT NULL
AND 
	other_tags->'ruins' IS NULL
	
	
	
--- Интересные места
	
SELECT
	count(*)
FROM
	multipolygons m 
WHERE 
	building  IS NOT NULL
AND ((
	other_tags IS NOT NULL
AND
	other_tags->'addr:housenumber' IS NULL)
OR 
	other_tags IS NULL)
	
SELECT
	count(*)--,building , other_tags , wkb_geometry
FROM
	multipolygons m 
WHERE 
	building  IS NOT NULL
AND
	building NOT IN ('')
--AND
--	building NOT IN ('yes', 'roof', 'house', 'school', 'public', 'industrial','retail','detached','service', 'apartments',
--		'commercial','residental','hospital','college','warehouse','residential', 'hotel','kindergarten',
--		'kindergarten','store','semidetached_house','construction','dormitory','factory','office','synagogue','pavilion',
--		'university','bungalow','supermarket','hut','manufacture','heat_station','mosque','temple','chapel','shop','guest_house',
--		'civic','presbytery', 'outbuilding','sports_centre','cottage','sanatorium','yes;school', 'public_building', 'administrative','cafe',
--		'fire_station','townhouse','stream','marketplace','museum','home', 'sports_hall','hotel_house','sport_hall',
--		'clinic','commerce','community_centre','chalet','bakehouse','barracks','bathhouse','education',
--		'post_office','post')
AND
	building NOT IN ('garage','garages','cathedral','church','train_station', 'collapsed','kiosk','stands','shed', 'carport',
		'tank','hangar','ruins','greenhouse','storage_tank','grandstand','pavilion','tower','military','transportation',
		'parking','font','station','farm','terrace','cabin','cowshed','barn','gazebo','tribune','sauna','checkpoint',
		'chimney','kitchen','stable','allotment_house','transformer_tower','shelter','riding_hall','silo','sheds','yurt','ail',
		'water_tower','henhouse','bridge','gatehouse','destroyed','ger','proposed','veranda','boathouse', 'bunker',
		'bath','tent','guardhouse','no','railway','entrance','abandoned','cover','reservoir_covered','utility',
		'greenhouse_horticulture','sty','stadium','static_caravan','toilets','lighthouse','houseboat','container',
		'glasshouse','chicken_coop','bus_stop','government','gasometer','watermill','stilt_house','privat_garages',
		'underground_crossing_entrance','police','castle_tower','reservoir','storage','dovecote','garbage_shed','wall',
		'part','shack','shrine','parking_entrance', 'exs_militari','ventilation_kiosk','grandstands','palace','elevator',
		'historic','beach_hut','castle_wall','cellar','pumping_station','power','damaged','trade_pavilion',
		'gas_station','bleachers','prison','gate','boat','ruined', 'scene', 'buld','basilica', 'ship','ramp','windmill',
		'tanks','farmhouse','capacity','oil_tank','barrack','slurry_tank','mineshaft','empty_warehouse', 'storehouse',
		'navigation','railway_car','fuel','colm','colonnade','cols','column','comn','contrainer','convenience','greenfield',
		'marquee','model','building_passage','cabine','burnt','check','bell_tower','demolished','depot','disused',
		'ex_military','electricity','ferry','lift','monastery','privat_garage','private_garage','pole','railway_station',
		'power_substation','religious','farm_auxiliary')
AND ((
	other_tags IS NOT NULL
AND
	other_tags->'addr:housenumber' IS NULL)
OR 
	other_tags IS NULL)
--ORDER BY building 
	
	
SELECT
	* 
FROM
	multipolygons m 
WHERE 
	ST_Covers(m.wkb_geometry ,
(SELECT 
	lgeom 
FROM
	noaddr_result nr 
WHERE 
	lid = '17075371729000'
	))
	
	
-- Для того, чтобы вытащить границы:
-- Нужно:
--   - type = 'boundary'
--   - admin_level
--   -  3 : Северо-Западный федеральный округ
--   -  4 : Калининградская область
--   -  6 : городской округ Калининград
--   -  9 : Ленинградский район
	
	
-- "ref"=>"RU-VLA", "int_ref"=>"RU-VLA", "name:ar"=>"فلاديمير أوبلاست", "name:ca"=>"Província de Vladímir", "name:cs"=>"Vladimirská oblast", "name:de"=>"Oblast Wladimir", "name:en"=>"Vladimir Oblast", "name:es"=>"Óblast de Vladímir", "name:fr"=>"Oblast de Vladimir", "name:hr"=>"Vladimirska oblast", "name:hu"=>"Vlagyimiri terület", "name:lt"=>"Vladimiro sritis", "name:pl"=>"Obwód włodzimierski", "name:ru"=>"Владимирская область", "name:sk"=>"Vladimírska oblasť", "name:zh"=>"弗拉基米爾州", "wikidata"=>"Q2702", "ISO3166-2"=>"RU-VLA", "wikipedia"=>"ru:Владимирская область", "border_type"=>"region", "addr:country"=>"RU", "name:zh-Hans"=>"弗拉基米尔州", "name:zh-Hant"=>"弗拉基米爾州", "gost_7.67-2003"=>"РОФ-ВЛА", "is_in:country_code"=>"RU"
	
SELECT
	*--,wkb_geometry, other_tags->'name:ru'
FROM
	multipolygons m 
WHERE 
	type = 'boundary'
AND
	boundary = 'administrative'
AND
	admin_level = '4'
ORDER BY other_tags->'name:ru'