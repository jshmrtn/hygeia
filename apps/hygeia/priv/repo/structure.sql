--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2 (Debian 13.2-1.pgdg100+1)
-- Dumped by pg_dump version 13.3 (Ubuntu 13.3-1.pgdg20.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: affiliation_kind; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.affiliation_kind AS ENUM (
    'employee',
    'scholar',
    'member',
    'other'
);


--
-- Name: case_complexity; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.case_complexity AS ENUM (
    'low',
    'medium',
    'high',
    'extreme'
);


--
-- Name: case_phase_index_end_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.case_phase_index_end_reason AS ENUM (
    'healed',
    'death',
    'no_follow_up',
    'other'
);


--
-- Name: case_phase_possible_index_end_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.case_phase_possible_index_end_reason AS ENUM (
    'asymptomatic',
    'converted_to_index',
    'no_follow_up',
    'negative_test',
    'other'
);


--
-- Name: case_phase_possible_index_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.case_phase_possible_index_type AS ENUM (
    'contact_person',
    'travel',
    'outbreak',
    'covid_app',
    'other'
);


--
-- Name: case_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.case_status AS ENUM (
    'first_contact',
    'first_contact_unreachable',
    'code_pending',
    'waiting_for_contact_person_list',
    'other_actions_todo',
    'next_contact_agreed',
    'hospitalization',
    'home_resident',
    'done',
    'canceled'
);


--
-- Name: communication_direction; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.communication_direction AS ENUM (
    'incoming',
    'outgoing'
);


--
-- Name: contact_method_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.contact_method_type AS ENUM (
    'mobile',
    'landline',
    'email',
    'other'
);


--
-- Name: email_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.email_status AS ENUM (
    'in_progress',
    'success',
    'temporary_failure',
    'permanent_failure',
    'retries_exceeded'
);


--
-- Name: external_reference_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.external_reference_type AS ENUM (
    'ism_case',
    'ism_report',
    'other'
);


--
-- Name: grant_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.grant_role AS ENUM (
    'tracer',
    'supervisor',
    'admin',
    'webmaster',
    'viewer',
    'statistics_viewer',
    'data_exporter',
    'super_user'
);


--
-- Name: infection_place_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.infection_place_type AS ENUM (
    'work_place',
    'army',
    'asyl',
    'choir',
    'club',
    'hh',
    'high_school',
    'childcare',
    'erotica',
    'flight',
    'medical',
    'hotel',
    'child_home',
    'cinema',
    'shop',
    'school',
    'less_300',
    'more_300',
    'public_transp',
    'massage',
    'nursing_home',
    'religion',
    'restaurant',
    'school_camp',
    'indoor_sport',
    'outdoor_sport',
    'gathering',
    'zoo',
    'prison',
    'other'
);


--
-- Name: isolation_location; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.isolation_location AS ENUM (
    'home',
    'social_medical_facility',
    'hospital',
    'hotel',
    'asylum_center',
    'other'
);


--
-- Name: noga_code; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.noga_code AS ENUM (
    '014900',
    '0240',
    '011600',
    '015000',
    '014200',
    '021000',
    '0170',
    '012200',
    '0141',
    '012900',
    '014700',
    '011200',
    '016200',
    '011300',
    '012',
    '0311',
    '012102',
    '011500',
    '0220',
    '032',
    '014',
    '013',
    '0123',
    '013000',
    '0210',
    '0162',
    '012800',
    '0121',
    '012700',
    '0145',
    '032200',
    '022',
    '0322',
    '017000',
    '0147',
    '03',
    '0127',
    '022000',
    '01',
    '032100',
    '0230',
    '0312',
    '021',
    '0149',
    '0116',
    '0150',
    '012500',
    '014500',
    '0124',
    '014300',
    '0164',
    '0130',
    '0128',
    '0321',
    '024',
    '016',
    '0161',
    '0129',
    '015',
    '023',
    '031100',
    '023000',
    '031',
    '0142',
    '0125',
    '031200',
    '0146',
    '0122',
    '0114',
    '0144',
    '0163',
    '014400',
    '024000',
    '0111',
    '0119',
    '0112',
    '012300',
    '016300',
    '014600',
    '016400',
    '011',
    '02',
    '0126',
    '012600',
    '012400',
    '011100',
    '0143',
    '016100',
    '012101',
    '014100',
    '017',
    '011900',
    '0113',
    '0115',
    '011400',
    '0812',
    '089',
    '0510',
    '0892',
    '05',
    '0891',
    '081200',
    '062',
    '062000',
    '089900',
    '089200',
    '0990',
    '0899',
    '052',
    '071000',
    '089300',
    '0910',
    '081',
    '072',
    '072100',
    '0520',
    '0893',
    '09',
    '089100',
    '06',
    '0721',
    '051000',
    '08',
    '0710',
    '0811',
    '081100',
    '099000',
    '051',
    '099',
    '072900',
    '0610',
    '07',
    '0729',
    '061',
    '052000',
    '061000',
    '0620',
    '091000',
    '091',
    '071',
    '108500',
    '236400',
    '132003',
    '273300',
    '161003',
    '2711',
    '245400',
    '321201',
    '2442',
    '191',
    '108300',
    '265100',
    '310900',
    '332000',
    '141403',
    '289500',
    '2892',
    '2312',
    '172400',
    '221900',
    '108201',
    '141402',
    '267000',
    '2221',
    '1629',
    '303',
    '104',
    '104200',
    '289902',
    '201100',
    '1062',
    '110400',
    '162302',
    '2821',
    '1085',
    '2053',
    '261',
    '141900',
    '3012',
    '255000',
    '105',
    '2445',
    '263',
    '242000',
    '191000',
    '108',
    '211000',
    '2410',
    '255',
    '131004',
    '1392',
    '274',
    '3291',
    '133000',
    '142',
    '105200',
    '103100',
    '101200',
    '2651',
    '2444',
    '12',
    '3220',
    '32',
    '1020',
    '2540',
    '268',
    '162900',
    '245100',
    '2452',
    '13',
    '10',
    '152',
    '162301',
    '139100',
    '2811',
    '331100',
    '1812',
    '257',
    '1101',
    '211',
    '2331',
    '181302',
    '201',
    '203000',
    '1910',
    '3211',
    '1042',
    '222100',
    '16',
    '2030',
    '104100',
    '181201',
    '254000',
    '301',
    '2431',
    '1811',
    '303000',
    '171',
    '2896',
    '2823',
    '205900',
    '243400',
    '3212',
    '266',
    '1610',
    '256202',
    '162',
    '109',
    '273200',
    '266000',
    '261100',
    '1052',
    '29',
    '139',
    '1086',
    '259400',
    '102000',
    '1320',
    '2920',
    '257100',
    '324000',
    '2446',
    '222200',
    '304',
    '1395',
    '33',
    '265',
    '2344',
    '284100',
    '235200',
    '133',
    '236500',
    '239100',
    '2550',
    '103200',
    '259100',
    '284900',
    '1394',
    '141100',
    '2599',
    '234400',
    '243200',
    '3020',
    '2014',
    '2020',
    '281',
    '108900',
    '3040',
    '2630',
    '141303',
    '232000',
    '11',
    '3213',
    '2313',
    '2364',
    '21',
    '2894',
    '279',
    '1511',
    '2680',
    '263000',
    '101300',
    '252',
    '162200',
    '1083',
    '108202',
    '141301',
    '243',
    '309100',
    '234100',
    '1032',
    '1414',
    '2571',
    '2932',
    '131',
    '2561',
    '151200',
    '2660',
    '293200',
    '301100',
    '1814',
    '242',
    '161001',
    '1623',
    '3030',
    '2017',
    '2521',
    '265204',
    '162303',
    '139201',
    '234300',
    '265205',
    '141200',
    '251200',
    '325001',
    '310300',
    '1624',
    '139500',
    '321202',
    '2060',
    '3091',
    '2592',
    '1071',
    '3312',
    '2812',
    '2530',
    '231200',
    '1711',
    '28',
    '332',
    '256100',
    '204',
    '309202',
    '2016',
    '107',
    '239',
    '24',
    '325004',
    '291000',
    '2370',
    '151',
    '141',
    '131002',
    '259',
    '181203',
    '1412',
    '2712',
    '1200',
    '3319',
    '2120',
    '2529',
    '257200',
    '172100',
    '304000',
    '325',
    '132',
    '221',
    '108400',
    '282400',
    '241',
    '2013',
    '2849',
    '309201',
    '239901',
    '3230',
    '2825',
    '203',
    '2895',
    '2363',
    '2841',
    '324',
    '2790',
    '325002',
    '18',
    '282',
    '3320',
    '2365',
    '1051',
    '1729',
    '236200',
    '1039',
    '289901',
    '162100',
    '1089',
    '205200',
    '253000',
    '205100',
    '329900',
    '3317',
    '107200',
    '2740',
    '241000',
    '17',
    '201500',
    '212',
    '289200',
    '143100',
    '259300',
    '236900',
    '106100',
    '272',
    '1073',
    '243300',
    '1104',
    '256203',
    '281400',
    '1722',
    '2593',
    '3240',
    '206000',
    '201400',
    '271200',
    '292',
    '1105',
    '3101',
    '329',
    '110200',
    '2612',
    '289100',
    '245200',
    '201300',
    '1920',
    '1813',
    '1820',
    '2652',
    '275200',
    '243100',
    '329100',
    '310100',
    '237',
    '1413',
    '141401',
    '110100',
    '2015',
    '106200',
    '235',
    '282500',
    '139300',
    '1411',
    '293100',
    '109200',
    '2219',
    '2432',
    '1072',
    '106',
    '2640',
    '2420',
    '289400',
    '201600',
    '222',
    '254',
    '1721',
    '310200',
    '110',
    '244200',
    '172300',
    '2720',
    '2454',
    '2572',
    '331500',
    '244500',
    '271',
    '2369',
    '181204',
    '105102',
    '26',
    '1011',
    '293',
    '2211',
    '141302',
    '281200',
    '281100',
    '171200',
    '1512',
    '2813',
    '274000',
    '309900',
    '3011',
    '171100',
    '222300',
    '1041',
    '2931',
    '2511',
    '1431',
    '2751',
    '231',
    '162400',
    '2434',
    '281300',
    '1103',
    '232',
    '309',
    '1081',
    '103900',
    '252100',
    '2731',
    '2824',
    '322',
    '212000',
    '131003',
    '1082',
    '205',
    '283000',
    '204100',
    '234',
    '192000',
    '282100',
    '132001',
    '15',
    '1391',
    '172900',
    '282300',
    '2670',
    '202000',
    '2332',
    '2512',
    '1396',
    '264000',
    '1621',
    '245300',
    '282200',
    '2910',
    '2041',
    '283',
    '302',
    '289',
    '2352',
    '143',
    '107300',
    '231100',
    '275100',
    '2899',
    '181202',
    '161002',
    '3316',
    '236100',
    '331600',
    '2441',
    '2314',
    '2042',
    '181301',
    '3299',
    '1399',
    '252900',
    '2453',
    '322000',
    '1013',
    '202',
    '262',
    '237000',
    '1622',
    '2611',
    '244100',
    '3092',
    '259200',
    '1724',
    '151100',
    '222900',
    '1330',
    '2822',
    '1106',
    '236300',
    '244',
    '3102',
    '19',
    '325003',
    '235100',
    '30',
    '256',
    '2343',
    '3250',
    '265202',
    '2891',
    '2451',
    '289600',
    '182000',
    '120000',
    '2351',
    '273100',
    '2433',
    '321100',
    '172200',
    '234900',
    '139901',
    '233200',
    '110600',
    '323',
    '139600',
    '101100',
    '108600',
    '233100',
    '3313',
    '236',
    '244600',
    '1393',
    '2391',
    '132002',
    '201700',
    '284',
    '2362',
    '2011',
    '1419',
    '2110',
    '289300',
    '2319',
    '139203',
    '331400',
    '233',
    '261200',
    '331300',
    '291',
    '221100',
    '231900',
    '331200',
    '2361',
    '2223',
    '110300',
    '2229',
    '2830',
    '139902',
    '2815',
    '152000',
    '120',
    '271100',
    '2752',
    '103',
    '265203',
    '204200',
    '2059',
    '262000',
    '27',
    '257300',
    '1420',
    '3103',
    '1084',
    '23',
    '1520',
    '234200',
    '2342',
    '2311',
    '1310',
    '25',
    '292000',
    '3311',
    '22',
    '142000',
    '3314',
    '264',
    '2443',
    '2573',
    '14',
    '275',
    '2222',
    '110500',
    '282900',
    '1061',
    '268000',
    '244400',
    '251',
    '105103',
    '102',
    '105101',
    '301200',
    '31',
    '2052',
    '161',
    '2320',
    '131001',
    '2732',
    '2620',
    '231300',
    '256201',
    '2562',
    '244300',
    '110700',
    '205300',
    '323000',
    '3109',
    '1092',
    '2893',
    '2829',
    '281500',
    '107100',
    '143900',
    '1107',
    '109100',
    '1439',
    '321300',
    '3099',
    '259900',
    '201200',
    '182',
    '2399',
    '2814',
    '310',
    '2012',
    '1012',
    '192',
    '265201',
    '267',
    '239902',
    '181100',
    '20',
    '1712',
    '331900',
    '172',
    '139903',
    '2594',
    '1031',
    '251100',
    '139202',
    '245',
    '272000',
    '108100',
    '1723',
    '2051',
    '206',
    '2349',
    '302000',
    '2733',
    '2341',
    '101',
    '231400',
    '1091',
    '3315',
    '279000',
    '253',
    '181',
    '2591',
    '321',
    '331700',
    '1102',
    '331',
    '139400',
    '273',
    '181400',
    '351100',
    '352300',
    '35',
    '351200',
    '3530',
    '3511',
    '351300',
    '353',
    '351',
    '352',
    '3522',
    '3523',
    '352200',
    '353000',
    '3512',
    '351400',
    '3521',
    '3514',
    '3513',
    '352100',
    '370000',
    '382',
    '3600',
    '383',
    '381',
    '3811',
    '37',
    '383100',
    '390',
    '3822',
    '38',
    '3821',
    '381100',
    '381200',
    '3812',
    '390000',
    '360000',
    '383200',
    '382200',
    '370',
    '39',
    '3832',
    '382100',
    '360',
    '3900',
    '3700',
    '36',
    '3831',
    '433900',
    '412003',
    '431100',
    '421200',
    '422100',
    '432902',
    '421',
    '439103',
    '433100',
    '4312',
    '4313',
    '412004',
    '4299',
    '432',
    '4322',
    '411',
    '43',
    '42',
    '432204',
    '439902',
    '429900',
    '4331',
    '429',
    '439102',
    '421100',
    '439903',
    '431',
    '4291',
    '4211',
    '4334',
    '432201',
    '411000',
    '439101',
    '433403',
    '433',
    '4110',
    '433302',
    '412002',
    '4213',
    '433301',
    '439',
    '422200',
    '431200',
    '432202',
    '429100',
    '4222',
    '4321',
    '432203',
    '412',
    '4212',
    '439904',
    '4399',
    '412001',
    '432901',
    '4391',
    '4329',
    '422',
    '431300',
    '439905',
    '433402',
    '4221',
    '433200',
    '432100',
    '421300',
    '433303',
    '4332',
    '433401',
    '4339',
    '4120',
    '4333',
    '4311',
    '41',
    '439901',
    '467600',
    '4665',
    '452001',
    '463100',
    '4646',
    '471104',
    '475201',
    '464201',
    '4661',
    '4729',
    '476',
    '4651',
    '464302',
    '4617',
    '4648',
    '476201',
    '475902',
    '451',
    '4619',
    '4772',
    '471105',
    '477300',
    '462200',
    '478200',
    '4751',
    '461400',
    '4671',
    '475202',
    '477101',
    '463401',
    '4719',
    '4616',
    '477801',
    '463',
    '4730',
    '4771',
    '463700',
    '4743',
    '4634',
    '471101',
    '4652',
    '475100',
    '477805',
    '451102',
    '4676',
    '472500',
    '463500',
    '4764',
    '477105',
    '4711',
    '4673',
    '471902',
    '474100',
    '452',
    '4540',
    '464905',
    '4763',
    '464303',
    '477901',
    '467301',
    '473000',
    '4726',
    '464901',
    '466100',
    '477103',
    '477502',
    '4633',
    '4611',
    '4690',
    '477804',
    '4618',
    '477603',
    '4724',
    '464400',
    '472401',
    '4623',
    '4532',
    '453',
    '464602',
    '466400',
    '461300',
    '477202',
    '4519',
    '464202',
    '461',
    '476500',
    '461600',
    '4721',
    '477700',
    '476402',
    '4675',
    '477802',
    '467302',
    '472901',
    '462300',
    '4645',
    '474200',
    '4722',
    '465102',
    '4777',
    '461500',
    '461100',
    '464906',
    '475',
    '4632',
    '4799',
    '46',
    '464904',
    '467200',
    '462400',
    '4622',
    '461200',
    '461700',
    '4663',
    '463402',
    '477102',
    '464801',
    '471102',
    '464301',
    '471103',
    '4741',
    '474',
    '4782',
    '4647',
    '472200',
    '472',
    '4637',
    '464100',
    '4669',
    '4778',
    '4672',
    '4759',
    '463600',
    '476100',
    '463800',
    '462',
    '467100',
    '4641',
    '4664',
    '45',
    '467',
    '477601',
    '472100',
    '476202',
    '466',
    '472300',
    '4644',
    '462100',
    '475903',
    '4635',
    '466200',
    '4725',
    '477602',
    '4614',
    '478100',
    '466900',
    '477400',
    '4779',
    '4636',
    '466300',
    '464500',
    '4753',
    '464',
    '477803',
    '4612',
    '4776',
    '464902',
    '461900',
    '4531',
    '479100',
    '463900',
    '4621',
    '4662',
    '469000',
    '4511',
    '466500',
    '4613',
    '472902',
    '467701',
    '4754',
    '4765',
    '467400',
    '467702',
    '453100',
    '4520',
    '4615',
    '467303',
    '4781',
    '469',
    '472600',
    '477902',
    '471901',
    '47',
    '4649',
    '477201',
    '451101',
    '4677',
    '465',
    '466600',
    '454000',
    '451902',
    '477501',
    '454',
    '478900',
    '475400',
    '4631',
    '479900',
    '4624',
    '465101',
    '4666',
    '464700',
    '4761',
    '453200',
    '474300',
    '451901',
    '471',
    '463300',
    '461800',
    '473',
    '465200',
    '452002',
    '464802',
    '4775',
    '4774',
    '4642',
    '478',
    '464903',
    '463200',
    '4791',
    '477806',
    '475901',
    '4643',
    '464601',
    '475300',
    '477',
    '4789',
    '4762',
    '476401',
    '4773',
    '467500',
    '472402',
    '4742',
    '479',
    '476300',
    '4752',
    '4638',
    '477104',
    '4723',
    '4674',
    '4639',
    '532',
    '493901',
    '5210',
    '492000',
    '512100',
    '495',
    '512200',
    '502',
    '501000',
    '521000',
    '491',
    '5122',
    '511',
    '503000',
    '5030',
    '5040',
    '493902',
    '5121',
    '5224',
    '5223',
    '4941',
    '494',
    '51',
    '5221',
    '512',
    '504',
    '5020',
    '532000',
    '50',
    '503',
    '493903',
    '493',
    '492',
    '522900',
    '4939',
    '53',
    '4950',
    '5310',
    '5222',
    '4942',
    '5320',
    '501',
    '49',
    '4920',
    '522300',
    '502000',
    '494100',
    '504000',
    '491000',
    '52',
    '521',
    '522400',
    '522',
    '494200',
    '495000',
    '493100',
    '531',
    '493200',
    '5010',
    '522100',
    '511000',
    '531000',
    '4910',
    '5229',
    '5110',
    '4931',
    '4932',
    '522200',
    '56',
    '5630',
    '553002',
    '552002',
    '563002',
    '5520',
    '5610',
    '561002',
    '563001',
    '551003',
    '5510',
    '551001',
    '5629',
    '562100',
    '562900',
    '561',
    '552001',
    '552',
    '559',
    '5530',
    '5590',
    '559000',
    '562',
    '552003',
    '561003',
    '551002',
    '563',
    '551',
    '55',
    '553001',
    '561001',
    '5621',
    '553',
    '6202',
    '602',
    '620300',
    '6020',
    '582900',
    '591100',
    '591',
    '592000',
    '6130',
    '58',
    '631100',
    '5829',
    '611',
    '613',
    '6312',
    '602000',
    '639',
    '591200',
    '581200',
    '5821',
    '5914',
    '601',
    '6209',
    '581300',
    '581100',
    '5813',
    '620200',
    '581900',
    '620900',
    '582',
    '631',
    '619',
    '620',
    '613000',
    '6010',
    '639100',
    '5812',
    '62',
    '5911',
    '620100',
    '5920',
    '6391',
    '60',
    '59',
    '611000',
    '592',
    '591400',
    '582100',
    '6120',
    '5912',
    '619000',
    '6110',
    '5819',
    '631200',
    '591300',
    '639900',
    '5913',
    '5811',
    '63',
    '6311',
    '612',
    '6399',
    '612000',
    '6203',
    '6190',
    '581',
    '5814',
    '6201',
    '581400',
    '601000',
    '61',
    '6430',
    '6492',
    '641902',
    '651201',
    '6411',
    '662901',
    '641907',
    '651203',
    '641909',
    '651100',
    '6499',
    '661',
    '642001',
    '649201',
    '6419',
    '6621',
    '653',
    '649',
    '662',
    '6619',
    '6520',
    '651202',
    '643',
    '662200',
    '661900',
    '651',
    '661100',
    '643000',
    '64',
    '641908',
    '6629',
    '663',
    '6491',
    '662902',
    '641910',
    '6612',
    '641904',
    '649202',
    '649100',
    '6611',
    '642',
    '6622',
    '649901',
    '652000',
    '6420',
    '663001',
    '6512',
    '661200',
    '641912',
    '6630',
    '641',
    '6530',
    '641905',
    '641911',
    '663002',
    '641901',
    '652',
    '641906',
    '641100',
    '641903',
    '66',
    '651204',
    '642002',
    '6511',
    '662100',
    '649903',
    '653000',
    '649902',
    '65',
    '6832',
    '683',
    '683100',
    '682002',
    '683200',
    '6820',
    '682001',
    '681',
    '6810',
    '68',
    '682',
    '681000',
    '6831',
    '6910',
    '711203',
    '7312',
    '69',
    '741003',
    '7311',
    '702200',
    '7112',
    '731200',
    '711201',
    '741001',
    '750000',
    '7410',
    '721100',
    '73',
    '742002',
    '711205',
    '742',
    '702',
    '749',
    '749000',
    '691',
    '701',
    '692000',
    '741',
    '732000',
    '731',
    '7500',
    '70',
    '711202',
    '731100',
    '741002',
    '711103',
    '721',
    '712',
    '7430',
    '7219',
    '701002',
    '701001',
    '72',
    '6920',
    '722000',
    '7111',
    '7021',
    '691001',
    '742001',
    '712000',
    '722',
    '743000',
    '702100',
    '692',
    '721900',
    '7420',
    '7220',
    '7120',
    '750',
    '7320',
    '732',
    '71',
    '743',
    '75',
    '711102',
    '691002',
    '711101',
    '74',
    '711',
    '711204',
    '7010',
    '7211',
    '7022',
    '7490',
    '812100',
    '821100',
    '799',
    '79',
    '774',
    '773500',
    '7820',
    '7810',
    '8010',
    '811000',
    '773400',
    '781000',
    '803',
    '77',
    '813',
    '7729',
    '7830',
    '791200',
    '801',
    '823',
    '812202',
    '8110',
    '80',
    '8230',
    '822',
    '772',
    '7735',
    '813000',
    '8211',
    '803000',
    '8220',
    '772100',
    '7732',
    '8129',
    '791',
    '7722',
    '783',
    '791100',
    '8299',
    '821901',
    '802000',
    '799001',
    '771100',
    '82',
    '829100',
    '7721',
    '781',
    '801000',
    '772200',
    '802',
    '829200',
    '812201',
    '773100',
    '8121',
    '8122',
    '799002',
    '8291',
    '821',
    '7990',
    '773300',
    '783000',
    '7912',
    '7712',
    '8130',
    '821902',
    '8030',
    '7740',
    '8020',
    '7733',
    '8219',
    '8292',
    '829900',
    '7911',
    '7711',
    '811',
    '7739',
    '782000',
    '771200',
    '772900',
    '7734',
    '823000',
    '7731',
    '782',
    '822000',
    '773200',
    '812',
    '774000',
    '773900',
    '81',
    '78',
    '829',
    '771',
    '773',
    '812900',
    '841',
    '843',
    '8413',
    '8425',
    '842400',
    '8430',
    '842500',
    '842202',
    '841200',
    '842100',
    '8411',
    '841100',
    '8421',
    '842301',
    '842302',
    '841300',
    '842',
    '842201',
    '84',
    '843000',
    '8424',
    '8422',
    '8423',
    '8412',
    '855903',
    '854202',
    '855100',
    '856000',
    '85',
    '852003',
    '8532',
    '853',
    '855200',
    '852002',
    '854201',
    '854',
    '855904',
    '8559',
    '853103',
    '854203',
    '855',
    '851',
    '855300',
    '854100',
    '8552',
    '8560',
    '851000',
    '853101',
    '8541',
    '852001',
    '852',
    '855901',
    '855902',
    '853200',
    '8553',
    '8531',
    '853102',
    '8542',
    '856',
    '8520',
    '8551',
    '8510',
    '8623',
    '862100',
    '8690',
    '879001',
    '872002',
    '872',
    '869001',
    '889902',
    '889',
    '869005',
    '8899',
    '8610',
    '889100',
    '881',
    '879003',
    '8891',
    '869006',
    '871000',
    '861001',
    '8710',
    '869004',
    '873002',
    '879002',
    '87',
    '8720',
    '8730',
    '862200',
    '869007',
    '869',
    '889901',
    '873001',
    '861',
    '8621',
    '869002',
    '871',
    '88',
    '873',
    '862300',
    '8810',
    '86',
    '869003',
    '862',
    '881000',
    '879',
    '872001',
    '8790',
    '861002',
    '8622',
    '9104',
    '900',
    '910100',
    '9329',
    '9002',
    '9313',
    '900303',
    '932100',
    '931300',
    '910',
    '9312',
    '91',
    '920',
    '920000',
    '9004',
    '92',
    '910200',
    '9101',
    '900400',
    '9001',
    '900101',
    '931900',
    '932',
    '9321',
    '931200',
    '90',
    '900302',
    '910300',
    '900102',
    '932900',
    '9103',
    '910400',
    '9200',
    '9003',
    '900301',
    '93',
    '931',
    '9311',
    '900200',
    '9102',
    '931100',
    '9319',
    '9411',
    '951200',
    '952100',
    '9499',
    '9522',
    '949903',
    '9512',
    '960201',
    '9529',
    '960',
    '952500',
    '9412',
    '96',
    '960300',
    '960202',
    '9523',
    '952400',
    '949901',
    '9491',
    '9525',
    '949102',
    '952300',
    '941100',
    '949101',
    '9420',
    '9601',
    '952900',
    '960900',
    '949904',
    '951100',
    '9603',
    '9602',
    '960402',
    '951',
    '942000',
    '9609',
    '949',
    '9524',
    '9521',
    '960101',
    '949200',
    '9511',
    '941',
    '942',
    '9604',
    '941200',
    '949902',
    '960401',
    '960102',
    '952',
    '94',
    '9492',
    '952200',
    '95',
    '98',
    '97',
    '981000',
    '981',
    '970',
    '982000',
    '982',
    '9700',
    '9820',
    '9810',
    '970000',
    '990',
    '990002',
    '990001',
    '990003',
    '99',
    '9900'
);


--
-- Name: noga_section; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.noga_section AS ENUM (
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U'
);


--
-- Name: organisation_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.organisation_type AS ENUM (
    'club',
    'school',
    'healthcare',
    'corporation',
    'other'
);


--
-- Name: resource_view_action; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.resource_view_action AS ENUM (
    'list',
    'details'
);


--
-- Name: resource_view_auth_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.resource_view_auth_type AS ENUM (
    'user',
    'person',
    'anonymous'
);


--
-- Name: sedex_export_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sedex_export_status AS ENUM (
    'missed',
    'sent',
    'received',
    'error'
);


--
-- Name: sex; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sex AS ENUM (
    'male',
    'female',
    'other'
);


--
-- Name: sms_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sms_status AS ENUM (
    'in_progress',
    'success',
    'failure'
);


--
-- Name: symptom; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.symptom AS ENUM (
    'fever',
    'cough',
    'sore_throat',
    'loss_of_smell',
    'loss_of_taste',
    'body_aches',
    'headaches',
    'fatigue',
    'difficulty_breathing',
    'muscle_pain',
    'general_weakness',
    'gastrointestinal',
    'skin_rash',
    'other'
);


--
-- Name: test_kind; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.test_kind AS ENUM (
    'pcr',
    'serology',
    'quick',
    'antigen_quick',
    'antibody'
);


--
-- Name: test_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.test_reason AS ENUM (
    'symptoms',
    'outbreak_examination',
    'screening',
    'work_related',
    'quarantine',
    'app_report',
    'convenience',
    'contact_tracing',
    'quarantine_end'
);


--
-- Name: test_result; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.test_result AS ENUM (
    'positive',
    'negative'
);


--
-- Name: versioning_event; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.versioning_event AS ENUM (
    'insert',
    'update',
    'delete'
);


--
-- Name: versioning_origin; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.versioning_origin AS ENUM (
    'web',
    'api',
    'user_sync_job',
    'case_close_email_job',
    'email_sender',
    'sms_sender',
    'migration'
);


--
-- Name: case_assignee_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.case_assignee_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      IF (OLD.tracer_uuid <> NEW.tracer_uuid OR OLD IS NULL) AND NOT NEW.tracer_uuid IS NULL AND (NEW.tracer_uuid <> (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid OR CURRENT_SETTING('versioning.originator_id') = '') THEN
        INSERT INTO notifications
          (uuid, body, user_uuid, inserted_at, updated_at) VALUES
          (
            MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
            JSONB_BUILD_OBJECT('__type__', 'case_assignee', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'case_uuid', NEW.uuid),
            NEW.tracer_uuid,
            NOW(),
            NOW()
          );
      END IF;

      IF (OLD.supervisor_uuid <> NEW.supervisor_uuid OR OLD IS NULL) AND NOT NEW.supervisor_uuid IS NULL AND (NEW.supervisor_uuid <> (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid OR CURRENT_SETTING('versioning.originator_id') = '') THEN
        INSERT INTO notifications
          (uuid, body, user_uuid, inserted_at, updated_at) VALUES
          (
            MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
            JSONB_BUILD_OBJECT('__type__', 'case_assignee', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'case_uuid', NEW.uuid),
            NEW.supervisor_uuid,
            NOW(),
            NOW()
          );
      END IF;

      RETURN NEW;
    END
  $$;


--
-- Name: check_user_authorization_on_case(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_user_authorization_on_case() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT * FROM user_grants
    WHERE user_grants.tenant_uuid = NEW.tenant_uuid AND
      user_grants.user_uuid = NEW.tracer_uuid AND
      user_grants.role = 'tracer'
    ) THEN
    NEW.tracer_uuid = NULL;
  END IF;
  IF NOT EXISTS (
    SELECT * FROM user_grants
    WHERE user_grants.tenant_uuid = NEW.tenant_uuid AND
      user_grants.user_uuid = NEW.supervisor_uuid AND
      user_grants.role = 'supervisor'
    ) THEN
    NEW.supervisor_uuid = NULL;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: email_send_failed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.email_send_failed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      AFFECTED_TRACER_UUID UUID;
    BEGIN
      IF (OLD.status <> NEW.status OR OLD IS NULL) AND NEW.status IN ('retries_exceeded', 'permanent_failure') THEN
        SELECT tracer_uuid INTO AFFECTED_TRACER_UUID FROM cases WHERE uuid = NEW.case_uuid;

        IF NOT AFFECTED_TRACER_UUID IS NULL THEN
          INSERT INTO notifications
            (uuid, body, user_uuid, inserted_at, updated_at) VALUES
            (
              MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
              JSONB_BUILD_OBJECT('__type__', 'email_send_failed', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'case_uuid', NEW.case_uuid, 'email_uuid', NEW.uuid),
              AFFECTED_TRACER_UUID,
              NOW(),
              NOW()
            );
        END IF;
      END IF;

      RETURN NEW;
    END
  $$;


--
-- Name: jsonb_array_to_tsvector_with_path(jsonb[], jsonpath); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.jsonb_array_to_tsvector_with_path(jsonb[], jsonpath) RETURNS tsvector
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
    BEGIN
      RETURN JSONB_TO_TSVECTOR(
        'german',
        COALESCE(
          JSONB_PATH_QUERY_ARRAY(
            ARRAY_TO_JSON($1)::jsonb,
            $2
          ),
          '[]'::jsonb
        ),
        '["all"]'
      );
    END;
  $_$;


--
-- Name: jsonb_equal(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.jsonb_equal(a jsonb, b jsonb) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RETURN A @> B AND A <@ B;
    END
  $$;


--
-- Name: notification_created(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notification_created() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      PERFORM pg_notify(
        'notification_created',
        ROW_TO_JSON(NEW)::text
      );

      RETURN NEW;
    END
  $$;


--
-- Name: versioning_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.versioning_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      DATA JSONB;
      PK JSONB;
    BEGIN
      DATA := TO_JSONB(OLD);
      PK := versioning_pk(DATA, TG_TABLE_NAME::regclass, TG_TABLE_SCHEMA);

      INSERT INTO versions
        (uuid, event, item_table, item_pk, item_changes, origin, originator_id, inserted_at)
        VALUES
        (
          MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
          'delete'::public.versioning_event,
          TG_TABLE_NAME::text,
          PK,
          DATA,
          CURRENT_SETTING('versioning.origin')::public.versioning_origin,
          (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid,
          NOW()
        );

      RETURN NEW;
    END
  $$;


--
-- Name: versioning_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.versioning_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      DATA JSONB;
      PK JSONB;
    BEGIN
      DATA := TO_JSONB(NEW);
      PK := versioning_pk(DATA, TG_TABLE_NAME::regclass, TG_TABLE_SCHEMA);

      INSERT INTO versions
        (uuid, event, item_table, item_pk, item_changes, origin, originator_id, inserted_at)
        VALUES
        (
          MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
          'insert'::public.versioning_event,
          TG_TABLE_NAME::text,
          PK,
          DATA,
          CURRENT_SETTING('versioning.origin')::public.versioning_origin,
          (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid,
          NOW()
        );

      RETURN NEW;
    END
  $$;


--
-- Name: versioning_pk(jsonb, regclass, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.versioning_pk(new jsonb, table_name regclass, table_schema name) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
    DECLARE
      PK JSONB := '{}'::jsonb;
      PRIMARY_KEYS RECORD;
    BEGIN
      FOR PRIMARY_KEYS IN
        SELECT
          pg_attribute.attname AS field_name
        FROM pg_index, pg_class, pg_attribute, pg_namespace
        WHERE
          pg_class.oid = TABLE_NAME AND
          indrelid = pg_class.oid AND
          nspname =  TABLE_SCHEMA AND
          pg_class.relnamespace = pg_namespace.oid AND
          pg_attribute.attrelid = pg_class.oid AND
          pg_attribute.attnum = ANY(pg_index.indkey) AND
          indisprimary
      LOOP
        PK := PK || JSONB_BUILD_OBJECT(PRIMARY_KEYS.field_name, NEW->((PRIMARY_KEYS.field_name)::text));
      END LOOP;
      RETURN PK;
    END
  $$;


--
-- Name: versioning_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.versioning_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      DATA_OLD JSONB;
      DATA_NEW JSONB;
      PK_OLD JSONB;
      PK_NEW JSONB;
    BEGIN
      DATA_OLD := TO_JSONB(OLD);
      DATA_NEW := TO_JSONB(NEW);
      PK_OLD := versioning_pk(DATA_OLD, TG_TABLE_NAME::regclass, TG_TABLE_SCHEMA);
      PK_NEW := versioning_pk(DATA_NEW, TG_TABLE_NAME::regclass, TG_TABLE_SCHEMA);

      IF NOT jsonb_equal(PK_OLD, PK_NEW) THEN
        RAISE EXCEPTION
          'primary key is immutable for versioned tables'
          USING HINT = 'Entries should be droped and recreated instead.', ERRCODE = 'VE001';
      END IF;

      IF NOT jsonb_equal(DATA_OLD, DATA_NEW) THEN
        INSERT INTO versions
          (uuid, event, item_table, item_pk, item_changes, origin, originator_id, inserted_at)
          VALUES
          (
            MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
            'update'::public.versioning_event,
            TG_TABLE_NAME::text,
            PK_NEW,
            DATA_NEW,
            CURRENT_SETTING('versioning.origin')::public.versioning_origin,
            (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid,
            NOW()
          );
      END IF;

      RETURN NEW;
    END
  $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: affiliations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.affiliations (
    uuid uuid NOT NULL,
    kind public.affiliation_kind,
    kind_other text,
    person_uuid uuid NOT NULL,
    organisation_uuid uuid,
    comment text,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    division_uuid uuid,
    CONSTRAINT comment_required CHECK (((organisation_uuid IS NOT NULL) OR (comment IS NOT NULL))),
    CONSTRAINT kind_other_required CHECK (
CASE
    WHEN (kind = 'other'::public.affiliation_kind) THEN (kind_other IS NOT NULL)
    ELSE (kind_other IS NULL)
END)
);


--
-- Name: cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cases (
    uuid uuid NOT NULL,
    human_readable_id character varying(255),
    external_references jsonb[],
    complexity character varying(255),
    clinical jsonb,
    monitoring jsonb,
    phases jsonb[],
    tracer_uuid uuid,
    supervisor_uuid uuid,
    person_uuid uuid NOT NULL,
    tenant_uuid uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    fulltext tsvector GENERATED ALWAYS AS (((to_tsvector('german'::regconfig, (uuid)::text) || to_tsvector('german'::regconfig, (human_readable_id)::text)) || public.jsonb_array_to_tsvector_with_path(external_references, '$[*]."value"'::jsonpath))) STORED,
    status public.case_status NOT NULL
);


--
-- Name: divisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.divisions (
    uuid uuid NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    organisation_uuid uuid NOT NULL,
    shares_address boolean DEFAULT true,
    address jsonb,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT address_required CHECK (
CASE
    WHEN shares_address THEN (address IS NULL)
    ELSE (address IS NOT NULL)
END)
);


--
-- Name: emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emails (
    uuid uuid NOT NULL,
    direction public.communication_direction NOT NULL,
    status public.email_status NOT NULL,
    message bytea NOT NULL,
    last_try timestamp without time zone,
    case_uuid uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_uuid uuid,
    tenant_uuid uuid NOT NULL,
    CONSTRAINT context_must_be_provided CHECK (((case_uuid IS NOT NULL) OR (user_uuid IS NOT NULL)))
);


--
-- Name: hospitalizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hospitalizations (
    uuid uuid NOT NULL,
    start date,
    "end" date,
    organisation_uuid uuid,
    case_uuid uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    uuid uuid NOT NULL,
    note text NOT NULL,
    case_uuid uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    uuid uuid NOT NULL,
    body jsonb,
    read boolean DEFAULT false NOT NULL,
    notified boolean DEFAULT false NOT NULL,
    user_uuid uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: organisations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organisations (
    uuid uuid NOT NULL,
    name character varying(255) NOT NULL,
    address jsonb,
    notes character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    fulltext tsvector GENERATED ALWAYS AS ((((to_tsvector('german'::regconfig, (uuid)::text) || to_tsvector('german'::regconfig, (name)::text)) || to_tsvector('german'::regconfig, (COALESCE(notes, ''::character varying))::text)) || COALESCE(jsonb_to_tsvector('german'::regconfig, address, '["all"]'::jsonb), to_tsvector('german'::regconfig, ''::text)))) STORED,
    type public.organisation_type,
    type_other character varying(255)
);


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.people (
    uuid uuid NOT NULL,
    human_readable_id character varying(255),
    external_references jsonb[],
    first_name character varying(255),
    last_name character varying(255),
    sex public.sex,
    birth_date date,
    contact_methods jsonb[],
    address jsonb,
    tenant_uuid uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    vaccination jsonb,
    profession_category public.noga_code,
    profession_category_main public.noga_section,
    fulltext tsvector GENERATED ALWAYS AS (((((((to_tsvector('german'::regconfig, (uuid)::text) || to_tsvector('german'::regconfig, (human_readable_id)::text)) || to_tsvector('german'::regconfig, (COALESCE(first_name, ''::character varying))::text)) || to_tsvector('german'::regconfig, (COALESCE(last_name, ''::character varying))::text)) || public.jsonb_array_to_tsvector_with_path(contact_methods, '$[*]."value"'::jsonpath)) || public.jsonb_array_to_tsvector_with_path(external_references, '$[*]."value"'::jsonpath)) || COALESCE(jsonb_to_tsvector('german'::regconfig, address, '["all"]'::jsonb), to_tsvector('german'::regconfig, ''::text)))) STORED
);


--
-- Name: positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions (
    uuid uuid NOT NULL,
    "position" character varying(255) NOT NULL,
    person_uuid uuid NOT NULL,
    organisation_uuid uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: possible_index_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.possible_index_submissions (
    uuid uuid NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    mobile character varying(255),
    landline character varying(255),
    sex character varying(255),
    birth_date date,
    address jsonb,
    infection_place jsonb,
    transmission_date date,
    case_uuid uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    employer character varying(255),
    comment text
);


--
-- Name: resource_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_views (
    request_id bigint NOT NULL,
    auth_type public.resource_view_auth_type NOT NULL,
    auth_subject uuid,
    "time" timestamp without time zone NOT NULL,
    ip_address inet,
    uri text,
    action public.resource_view_action NOT NULL,
    resource_table character varying(255) NOT NULL,
    resource_pk jsonb NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: sedex_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sedex_exports (
    uuid uuid NOT NULL,
    scheduling_date timestamp(0) without time zone,
    status public.sedex_export_status,
    tenant_uuid uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sms (
    uuid uuid NOT NULL,
    direction public.communication_direction NOT NULL,
    status public.sms_status NOT NULL,
    message text NOT NULL,
    number character varying(255) NOT NULL,
    delivery_receipt_id character varying(255),
    case_uuid uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: statistics_active_cases_per_day_and_organisation; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_active_cases_per_day_and_organisation AS
 WITH ranked_active_cases AS (
         SELECT (date.date)::date AS date,
            cases.tenant_uuid,
            organisations.name AS organisation_name,
            count(cases.person_uuid) AS count,
            row_number() OVER (PARTITION BY date.date, cases.tenant_uuid ORDER BY (count(cases.person_uuid)) DESC) AS row_number
           FROM ((((public.cases
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
             CROSS JOIN LATERAL generate_series((((phase.phase ->> 'start'::text))::date)::timestamp with time zone, (((phase.phase ->> 'end'::text))::date)::timestamp with time zone, '1 day'::interval) date(date))
             LEFT JOIN public.affiliations ON ((affiliations.person_uuid = cases.person_uuid)))
             LEFT JOIN public.organisations ON ((organisations.uuid = affiliations.organisation_uuid)))
          WHERE ('{"details": {"__type__": "index"}, "quarantine_order": true}'::jsonb <@ phase.phase)
          GROUP BY cases.tenant_uuid, date.date, organisations.name
         HAVING (count(cases.person_uuid) > 0)
          ORDER BY ((date.date)::date), cases.tenant_uuid, (count(cases.person_uuid)) DESC
        )
 SELECT ranked_active_cases.tenant_uuid,
    ranked_active_cases.date,
    ranked_active_cases.organisation_name,
    ranked_active_cases.count
   FROM ranked_active_cases
  WHERE (ranked_active_cases.row_number <= 100)
  WITH NO DATA;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    uuid uuid NOT NULL,
    name character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    outgoing_mail_configuration jsonb,
    public_statistics boolean DEFAULT false NOT NULL,
    outgoing_sms_configuration jsonb,
    override_url character varying(255),
    template_variation character varying(255),
    iam_domain character varying(255),
    short_name character varying(255),
    case_management_enabled boolean DEFAULT false,
    from_email character varying(255),
    sedex_export_enabled boolean DEFAULT false NOT NULL,
    sedex_export_configuration jsonb,
    template_parameters jsonb,
    CONSTRAINT sedex_export_must_be_provided CHECK ((((sedex_export_enabled = true) AND (sedex_export_configuration IS NOT NULL)) OR ((sedex_export_enabled = false) AND (sedex_export_configuration IS NULL))))
);


--
-- Name: statistics_active_complexity_cases_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_active_complexity_cases_per_day AS
 WITH active_cases AS (
         SELECT cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            (cmp_date.cmp_date)::date AS cmp_date,
            (cases.complexity)::public.case_complexity AS cmp_complexity
           FROM ((public.cases
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
             CROSS JOIN LATERAL generate_series((((phase.phase ->> 'start'::text))::date)::timestamp with time zone, (((phase.phase ->> 'end'::text))::date)::timestamp with time zone, '1 day'::interval) cmp_date(cmp_date))
          WHERE ('{"details": {"__type__": "index"}, "quarantine_order": true}'::jsonb <@ phase.phase)
        )
 SELECT tenants.uuid AS tenant_uuid,
    (date.date)::date AS date,
    case_complexity.case_complexity,
    count(DISTINCT active_cases.cmp_person_uuid) AS count
   FROM (((generate_series(LEAST((( SELECT min((cases.inserted_at)::date) AS min
           FROM public.cases))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN public.tenants)
     CROSS JOIN unnest((enum_range(NULL::public.case_complexity) || ARRAY[NULL::public.case_complexity])) case_complexity(case_complexity))
     LEFT JOIN active_cases ON (((active_cases.cmp_tenant_uuid = tenants.uuid) AND (active_cases.cmp_date = date.date) AND ((active_cases.cmp_complexity = case_complexity.case_complexity) OR ((active_cases.cmp_complexity IS NULL) AND (case_complexity.case_complexity IS NULL))))))
  GROUP BY date.date, tenants.uuid, case_complexity.case_complexity
  ORDER BY ((date.date)::date), tenants.uuid, case_complexity.case_complexity
  WITH NO DATA;


--
-- Name: statistics_active_hospitalization_cases_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_active_hospitalization_cases_per_day AS
 WITH cases_with_hospitalizations AS (
         SELECT cases.tenant_uuid,
            cases.person_uuid,
            hospitalizations.start AS start_date,
            COALESCE(hospitalizations."end", CURRENT_DATE) AS end_date
           FROM (public.cases
             JOIN public.hospitalizations ON ((hospitalizations.case_uuid = cases.uuid)))
        )
 SELECT tenants.uuid AS tenant_uuid,
    (date.date)::date AS date,
    count(DISTINCT cases_with_hospitalizations.person_uuid) AS count
   FROM ((generate_series(LEAST((( SELECT min((cases.inserted_at)::date) AS min
           FROM public.cases))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN public.tenants)
     LEFT JOIN cases_with_hospitalizations ON (((tenants.uuid = cases_with_hospitalizations.tenant_uuid) AND (cases_with_hospitalizations.end_date >= date.date) AND (cases_with_hospitalizations.start_date <= date.date))))
  GROUP BY date.date, tenants.uuid
  ORDER BY ((date.date)::date), tenants.uuid
  WITH NO DATA;


--
-- Name: transmissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transmissions (
    uuid uuid NOT NULL,
    date date,
    recipient_internal boolean,
    recipient_ism_id character varying(255),
    propagator_internal boolean,
    propagator_ism_id character varying(255),
    recipient_case_uuid uuid,
    propagator_case_uuid uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    infection_place jsonb,
    comment text
);


--
-- Name: statistics_active_infection_place_cases_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_active_infection_place_cases_per_day AS
 WITH person_date_infection_place AS (
         SELECT cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            ((transmissions.infection_place ->> 'type'::text))::public.infection_place_type AS cmp_infection_place_type,
            (cmp_date.cmp_date)::date AS cmp_date
           FROM (((public.cases
             LEFT JOIN public.transmissions ON ((transmissions.recipient_case_uuid = cases.uuid)))
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
             CROSS JOIN LATERAL generate_series((((phase.phase ->> 'start'::text))::date)::timestamp with time zone, (((phase.phase ->> 'end'::text))::date)::timestamp with time zone, '1 day'::interval) cmp_date(cmp_date))
          WHERE ('{"details": {"__type__": "index"}, "quarantine_order": true}'::jsonb <@ phase.phase)
        )
 SELECT tenants.uuid AS tenant_uuid,
    (day.day)::date AS date,
    infection_place_type.infection_place_type,
    count(DISTINCT person_date_infection_place.cmp_person_uuid) AS count
   FROM (((generate_series(LEAST((( SELECT min((cases.inserted_at)::date) AS min
           FROM public.cases))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) day(day)
     CROSS JOIN public.tenants)
     CROSS JOIN unnest((enum_range(NULL::public.infection_place_type) || ARRAY[NULL::public.infection_place_type])) infection_place_type(infection_place_type))
     LEFT JOIN person_date_infection_place ON (((tenants.uuid = person_date_infection_place.cmp_tenant_uuid) AND (day.day = person_date_infection_place.cmp_date) AND ((infection_place_type.infection_place_type = person_date_infection_place.cmp_infection_place_type) OR ((infection_place_type.infection_place_type IS NULL) AND (person_date_infection_place.cmp_infection_place_type IS NULL))))))
  GROUP BY day.day, tenants.uuid, infection_place_type.infection_place_type
  ORDER BY day.day, tenants.uuid, infection_place_type.infection_place_type
  WITH NO DATA;


--
-- Name: statistics_active_isolation_cases_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_active_isolation_cases_per_day AS
 WITH active_cases AS (
         SELECT cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            (cmp_date.cmp_date)::date AS cmp_date
           FROM ((public.cases
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
             CROSS JOIN LATERAL generate_series((((phase.phase ->> 'start'::text))::date)::timestamp with time zone, (((phase.phase ->> 'end'::text))::date)::timestamp with time zone, '1 day'::interval) cmp_date(cmp_date))
          WHERE ('{"details": {"__type__": "index"}, "quarantine_order": true}'::jsonb <@ phase.phase)
        )
 SELECT tenants.uuid AS tenant_uuid,
    (date.date)::date AS date,
    count(DISTINCT active_cases.cmp_person_uuid) AS count
   FROM ((generate_series(LEAST((( SELECT min((cases.inserted_at)::date) AS min
           FROM public.cases))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN public.tenants)
     LEFT JOIN active_cases ON (((active_cases.cmp_tenant_uuid = tenants.uuid) AND (active_cases.cmp_date = date.date))))
  GROUP BY date.date, tenants.uuid
  ORDER BY ((date.date)::date), tenants.uuid
  WITH NO DATA;


--
-- Name: statistics_active_quarantine_cases_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_active_quarantine_cases_per_day AS
 WITH active_cases AS (
         SELECT cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            (((phase.phase -> 'details'::text) ->> 'type'::text))::public.case_phase_possible_index_type AS cmp_type,
            (cmp_date.cmp_date)::date AS cmp_date
           FROM ((public.cases
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
             CROSS JOIN LATERAL generate_series((((phase.phase ->> 'start'::text))::date)::timestamp with time zone, (((phase.phase ->> 'end'::text))::date)::timestamp with time zone, '1 day'::interval) cmp_date(cmp_date))
          WHERE ('{"details": {"__type__": "possible_index"}, "quarantine_order": true}'::jsonb <@ phase.phase)
        )
 SELECT tenants.uuid AS tenant_uuid,
    type.type,
    (date.date)::date AS date,
    count(DISTINCT active_cases.cmp_person_uuid) AS count
   FROM (((generate_series(LEAST((( SELECT min((cases.inserted_at)::date) AS min
           FROM public.cases))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN unnest(enum_range(NULL::public.case_phase_possible_index_type)) type(type))
     CROSS JOIN public.tenants)
     LEFT JOIN active_cases ON (((active_cases.cmp_tenant_uuid = tenants.uuid) AND (date.date = active_cases.cmp_date) AND (type.type = active_cases.cmp_type))))
  GROUP BY date.date, type.type, tenants.uuid
  ORDER BY ((date.date)::date), type.type, tenants.uuid
  WITH NO DATA;


--
-- Name: statistics_cumulative_index_case_end_reasons; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_cumulative_index_case_end_reasons AS
 WITH phases AS (
         SELECT cases.tenant_uuid,
            cases.person_uuid,
            ((phase.phase ->> 'end'::text))::date AS count_date,
            (((phase.phase -> 'details'::text) ->> 'end_reason'::text))::public.case_phase_index_end_reason AS count_end_reason
           FROM (public.cases
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
          WHERE ((((phase.phase ->> 'end'::text))::date IS NOT NULL) AND (((phase.phase -> 'details'::text) ->> '__type__'::text) = 'index'::text))
        )
 SELECT tenants.uuid AS tenant_uuid,
    (date.date)::date AS date,
    end_reason.end_reason,
    (sum(count(DISTINCT phases.person_uuid)) OVER (PARTITION BY end_reason.end_reason, tenants.uuid ORDER BY ((date.date)::date)))::integer AS count
   FROM (((generate_series(LEAST((( SELECT min(phases_1.count_date) AS min
           FROM phases phases_1))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN unnest((enum_range(NULL::public.case_phase_index_end_reason) || ARRAY[NULL::public.case_phase_index_end_reason])) end_reason(end_reason))
     CROSS JOIN public.tenants)
     LEFT JOIN phases ON (((tenants.uuid = phases.tenant_uuid) AND (date.date = phases.count_date) AND (((end_reason.end_reason IS NULL) AND (phases.count_end_reason IS NULL)) OR (end_reason.end_reason = phases.count_end_reason)))))
  GROUP BY date.date, end_reason.end_reason, tenants.uuid
  ORDER BY ((date.date)::date), end_reason.end_reason, tenants.uuid
  WITH NO DATA;


--
-- Name: statistics_cumulative_possible_index_case_end_reasons; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_cumulative_possible_index_case_end_reasons AS
 WITH phases AS (
         SELECT cases.tenant_uuid,
            cases.person_uuid,
            ((phase.phase ->> 'end'::text))::date AS count_date,
            (((phase.phase -> 'details'::text) ->> 'type'::text))::public.case_phase_possible_index_type AS count_type,
            (((phase.phase -> 'details'::text) ->> 'end_reason'::text))::public.case_phase_possible_index_end_reason AS count_end_reason
           FROM (public.cases
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
          WHERE ((((phase.phase ->> 'end'::text))::date IS NOT NULL) AND (((phase.phase -> 'details'::text) ->> '__type__'::text) = 'possible_index'::text))
        )
 SELECT tenants.uuid AS tenant_uuid,
    (date.date)::date AS date,
    type.type,
    end_reason.end_reason,
    (sum(count(DISTINCT phases.person_uuid)) OVER (PARTITION BY type.type, end_reason.end_reason, tenants.uuid ORDER BY ((date.date)::date)))::integer AS count
   FROM ((((generate_series(LEAST((( SELECT min(phases_1.count_date) AS min
           FROM phases phases_1))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN unnest((enum_range(NULL::public.case_phase_possible_index_end_reason) || ARRAY[NULL::public.case_phase_possible_index_end_reason])) end_reason(end_reason))
     CROSS JOIN unnest(enum_range(NULL::public.case_phase_possible_index_type)) type(type))
     CROSS JOIN public.tenants)
     LEFT JOIN phases ON (((tenants.uuid = phases.tenant_uuid) AND (date.date = phases.count_date) AND (type.type = phases.count_type) AND (((end_reason.end_reason IS NULL) AND (phases.count_end_reason IS NULL)) OR (end_reason.end_reason = phases.count_end_reason)))))
  GROUP BY date.date, type.type, end_reason.end_reason, tenants.uuid
  ORDER BY ((date.date)::date), type.type, end_reason.end_reason, tenants.uuid
  WITH NO DATA;


--
-- Name: statistics_new_cases_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_new_cases_per_day AS
 WITH phases AS (
         SELECT cases.tenant_uuid,
            cases.person_uuid,
            ((phase.phase -> 'details'::text) ->> '__type__'::text) AS count_type,
            (((phase.phase -> 'details'::text) ->> 'type'::text))::public.case_phase_possible_index_type AS count_sub_type,
                CASE
                    WHEN (((phase.phase -> 'details'::text) ->> '__type__'::text) = 'index'::text) THEN ((cases.clinical ->> 'laboratory_report'::text))::date
                    ELSE (cases.inserted_at)::date
                END AS count_date
           FROM (public.cases
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
        )
 SELECT tenants.uuid AS tenant_uuid,
    type.type,
    sub_type.sub_type,
    (date.date)::date AS date,
    count(DISTINCT phases.person_uuid) AS count
   FROM ((((generate_series(LEAST((( SELECT min(phases_1.count_date) AS min
           FROM phases phases_1))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN unnest(ARRAY['index'::text, 'possible_index'::text]) type(type))
     LEFT JOIN unnest(enum_range(NULL::public.case_phase_possible_index_type)) sub_type(sub_type) ON ((type.type = 'possible_index'::text)))
     CROSS JOIN public.tenants)
     LEFT JOIN phases ON (((tenants.uuid = phases.tenant_uuid) AND (date.date = phases.count_date) AND (phases.count_type = type.type) AND (((phases.count_sub_type IS NULL) AND (sub_type.sub_type IS NULL)) OR (phases.count_sub_type = sub_type.sub_type)))))
  GROUP BY date.date, type.type, sub_type.sub_type, tenants.uuid
  ORDER BY ((date.date)::date), type.type, sub_type.sub_type, tenants.uuid
  WITH NO DATA;


--
-- Name: statistics_transmission_country_cases_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_transmission_country_cases_per_day AS
 WITH countries AS (
         SELECT DISTINCT ((transmissions.infection_place -> 'address'::text) ->> 'country'::text) AS country
           FROM public.transmissions
        ), cases_with_transmissions AS (
         SELECT cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            COALESCE((transmissions.inserted_at)::date, ((phase.phase ->> 'start'::text))::date, (cases.inserted_at)::date) AS cmp_date,
            ((transmissions.infection_place -> 'address'::text) ->> 'country'::text) AS cmp_country
           FROM ((public.cases
             LEFT JOIN public.transmissions ON ((transmissions.recipient_case_uuid = cases.uuid)))
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
          WHERE (NOT (((transmissions.infection_place -> 'address'::text) ->> 'country'::text) IS NULL))
        )
 SELECT tenants.uuid AS tenant_uuid,
    (date.date)::date AS date,
    countries.country,
    count(DISTINCT cases_with_transmissions.cmp_person_uuid) AS count
   FROM (((generate_series(LEAST((( SELECT min((cases.inserted_at)::date) AS min
           FROM public.cases))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN public.tenants)
     CROSS JOIN countries)
     LEFT JOIN cases_with_transmissions ON (((cases_with_transmissions.cmp_tenant_uuid = tenants.uuid) AND (cases_with_transmissions.cmp_date = date.date) AND (cases_with_transmissions.cmp_country = countries.country))))
  GROUP BY date.date, tenants.uuid, countries.country
  ORDER BY ((date.date)::date), tenants.uuid, countries.country
  WITH NO DATA;


--
-- Name: system_message_tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_message_tenants (
    system_message_uuid uuid NOT NULL,
    tenant_uuid uuid NOT NULL
);


--
-- Name: system_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_messages (
    uuid uuid NOT NULL,
    text text,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    roles public.grant_role[] DEFAULT ARRAY[]::public.grant_role[],
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_grants (
    user_uuid uuid NOT NULL,
    tenant_uuid uuid NOT NULL,
    role public.grant_role NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    uuid uuid NOT NULL,
    email character varying(255),
    display_name character varying(255),
    iam_sub character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    event public.versioning_event NOT NULL,
    item_changes jsonb NOT NULL,
    originator_id uuid,
    origin public.versioning_origin NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    uuid uuid NOT NULL,
    item_pk jsonb NOT NULL,
    item_table text
);


--
-- Name: affiliations affiliations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliations
    ADD CONSTRAINT affiliations_pkey PRIMARY KEY (uuid);


--
-- Name: cases cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (uuid);


--
-- Name: divisions divisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.divisions
    ADD CONSTRAINT divisions_pkey PRIMARY KEY (uuid);


--
-- Name: emails emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (uuid);


--
-- Name: hospitalizations hospitalizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hospitalizations
    ADD CONSTRAINT hospitalizations_pkey PRIMARY KEY (uuid);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (uuid);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (uuid);


--
-- Name: organisations organisations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT organisations_pkey PRIMARY KEY (uuid);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (uuid);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (uuid);


--
-- Name: possible_index_submissions possible_index_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.possible_index_submissions
    ADD CONSTRAINT possible_index_submissions_pkey PRIMARY KEY (uuid);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sedex_exports sedex_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sedex_exports
    ADD CONSTRAINT sedex_exports_pkey PRIMARY KEY (uuid);


--
-- Name: sms sms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms
    ADD CONSTRAINT sms_pkey PRIMARY KEY (uuid);


--
-- Name: system_message_tenants system_message_tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_message_tenants
    ADD CONSTRAINT system_message_tenants_pkey PRIMARY KEY (system_message_uuid, tenant_uuid);


--
-- Name: system_messages system_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_messages
    ADD CONSTRAINT system_messages_pkey PRIMARY KEY (uuid);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (uuid);


--
-- Name: transmissions transmissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transmissions
    ADD CONSTRAINT transmissions_pkey PRIMARY KEY (uuid);


--
-- Name: user_grants user_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_grants
    ADD CONSTRAINT user_grants_pkey PRIMARY KEY (user_uuid, tenant_uuid, role);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (uuid);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (uuid);


--
-- Name: affiliations_division_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliations_division_uuid_index ON public.affiliations USING btree (division_uuid);


--
-- Name: affiliations_organisation_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliations_organisation_uuid_index ON public.affiliations USING btree (organisation_uuid);


--
-- Name: affiliations_person_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliations_person_uuid_index ON public.affiliations USING btree (person_uuid);


--
-- Name: cases_external_references_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_external_references_index ON public.cases USING gin (external_references);


--
-- Name: cases_fulltext_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_fulltext_index ON public.cases USING gin (fulltext);


--
-- Name: cases_person_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_person_uuid_index ON public.cases USING btree (person_uuid);


--
-- Name: cases_phases_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_phases_index ON public.cases USING gin (phases);


--
-- Name: cases_supervisor_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_supervisor_uuid_index ON public.cases USING btree (supervisor_uuid);


--
-- Name: cases_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_tenant_uuid_index ON public.cases USING btree (tenant_uuid);


--
-- Name: cases_tracer_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cases_tracer_uuid_index ON public.cases USING btree (tracer_uuid);


--
-- Name: divisions_organisation_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX divisions_organisation_uuid_index ON public.divisions USING btree (organisation_uuid);


--
-- Name: emails_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX emails_case_uuid_index ON public.emails USING btree (case_uuid);


--
-- Name: emails_direction_status_last_try_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX emails_direction_status_last_try_index ON public.emails USING btree (direction, status, last_try);


--
-- Name: notes_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_case_uuid_index ON public.notes USING btree (case_uuid);


--
-- Name: notifications_notified_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_notified_index ON public.notifications USING btree (notified);


--
-- Name: notifications_read_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_read_index ON public.notifications USING btree (read);


--
-- Name: notifications_user_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_user_uuid_index ON public.notifications USING btree (user_uuid);


--
-- Name: notifications_user_uuid_read_notified_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_user_uuid_read_notified_index ON public.notifications USING btree (user_uuid, read, notified);


--
-- Name: organisations_fulltext_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organisations_fulltext_index ON public.organisations USING gin (fulltext);


--
-- Name: people_contact_methods_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX people_contact_methods_index ON public.people USING gin (contact_methods);


--
-- Name: people_external_references_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX people_external_references_index ON public.people USING gin (external_references);


--
-- Name: people_fulltext_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX people_fulltext_index ON public.people USING gin (fulltext);


--
-- Name: people_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX people_tenant_uuid_index ON public.people USING btree (tenant_uuid);


--
-- Name: positions_organisation_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX positions_organisation_uuid_index ON public.positions USING btree (organisation_uuid);


--
-- Name: positions_person_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX positions_person_uuid_index ON public.positions USING btree (person_uuid);


--
-- Name: resource_views_request_id_action_resource_table_resource_pk_ind; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX resource_views_request_id_action_resource_table_resource_pk_ind ON public.resource_views USING btree (request_id, action, resource_table, resource_pk);


--
-- Name: sedex_exports_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sedex_exports_tenant_uuid_index ON public.sedex_exports USING btree (tenant_uuid);


--
-- Name: sedex_exports_tenant_uuid_scheduling_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sedex_exports_tenant_uuid_scheduling_date_index ON public.sedex_exports USING btree (tenant_uuid, scheduling_date);


--
-- Name: sms_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sms_case_uuid_index ON public.sms USING btree (case_uuid);


--
-- Name: sms_direction_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sms_direction_status_index ON public.sms USING btree (direction, status);


--
-- Name: statistics_active_cases_per_day_and_organisation_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_cases_per_day_and_organisation_date_index ON public.statistics_active_cases_per_day_and_organisation USING btree (date);


--
-- Name: statistics_active_cases_per_day_and_organisation_organisation_n; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_cases_per_day_and_organisation_organisation_n ON public.statistics_active_cases_per_day_and_organisation USING btree (organisation_name);


--
-- Name: statistics_active_cases_per_day_and_organisation_tenant_uuid_da; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_active_cases_per_day_and_organisation_tenant_uuid_da ON public.statistics_active_cases_per_day_and_organisation USING btree (tenant_uuid, date, organisation_name);


--
-- Name: statistics_active_cases_per_day_and_organisation_tenant_uuid_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_cases_per_day_and_organisation_tenant_uuid_in ON public.statistics_active_cases_per_day_and_organisation USING btree (tenant_uuid);


--
-- Name: statistics_active_complexity_cases_per_day_case_complexity_inde; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_complexity_cases_per_day_case_complexity_inde ON public.statistics_active_complexity_cases_per_day USING btree (case_complexity);


--
-- Name: statistics_active_complexity_cases_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_complexity_cases_per_day_date_index ON public.statistics_active_complexity_cases_per_day USING btree (date);


--
-- Name: statistics_active_complexity_cases_per_day_tenant_uuid_date_cas; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_active_complexity_cases_per_day_tenant_uuid_date_cas ON public.statistics_active_complexity_cases_per_day USING btree (tenant_uuid, date, case_complexity);


--
-- Name: statistics_active_complexity_cases_per_day_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_complexity_cases_per_day_tenant_uuid_index ON public.statistics_active_complexity_cases_per_day USING btree (tenant_uuid);


--
-- Name: statistics_active_hospitalization_cases_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_hospitalization_cases_per_day_date_index ON public.statistics_active_hospitalization_cases_per_day USING btree (date);


--
-- Name: statistics_active_hospitalization_cases_per_day_tenant_uuid_dat; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_active_hospitalization_cases_per_day_tenant_uuid_dat ON public.statistics_active_hospitalization_cases_per_day USING btree (tenant_uuid, date);


--
-- Name: statistics_active_hospitalization_cases_per_day_tenant_uuid_ind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_hospitalization_cases_per_day_tenant_uuid_ind ON public.statistics_active_hospitalization_cases_per_day USING btree (tenant_uuid);


--
-- Name: statistics_active_infection_place_cases_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_infection_place_cases_per_day_date_index ON public.statistics_active_infection_place_cases_per_day USING btree (date);


--
-- Name: statistics_active_infection_place_cases_per_day_infection_place; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_infection_place_cases_per_day_infection_place ON public.statistics_active_infection_place_cases_per_day USING btree (infection_place_type);


--
-- Name: statistics_active_infection_place_cases_per_day_tenant_uuid_dat; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_active_infection_place_cases_per_day_tenant_uuid_dat ON public.statistics_active_infection_place_cases_per_day USING btree (tenant_uuid, date, infection_place_type);


--
-- Name: statistics_active_infection_place_cases_per_day_tenant_uuid_ind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_infection_place_cases_per_day_tenant_uuid_ind ON public.statistics_active_infection_place_cases_per_day USING btree (tenant_uuid);


--
-- Name: statistics_active_isolation_cases_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_isolation_cases_per_day_date_index ON public.statistics_active_isolation_cases_per_day USING btree (date);


--
-- Name: statistics_active_isolation_cases_per_day_tenant_uuid_date_inde; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_active_isolation_cases_per_day_tenant_uuid_date_inde ON public.statistics_active_isolation_cases_per_day USING btree (tenant_uuid, date);


--
-- Name: statistics_active_isolation_cases_per_day_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_isolation_cases_per_day_tenant_uuid_index ON public.statistics_active_isolation_cases_per_day USING btree (tenant_uuid);


--
-- Name: statistics_active_quarantine_cases_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_quarantine_cases_per_day_date_index ON public.statistics_active_quarantine_cases_per_day USING btree (date);


--
-- Name: statistics_active_quarantine_cases_per_day_tenant_uuid_date_typ; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_active_quarantine_cases_per_day_tenant_uuid_date_typ ON public.statistics_active_quarantine_cases_per_day USING btree (tenant_uuid, date, type);


--
-- Name: statistics_active_quarantine_cases_per_day_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_quarantine_cases_per_day_tenant_uuid_index ON public.statistics_active_quarantine_cases_per_day USING btree (tenant_uuid);


--
-- Name: statistics_active_quarantine_cases_per_day_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_active_quarantine_cases_per_day_type_index ON public.statistics_active_quarantine_cases_per_day USING btree (type);


--
-- Name: statistics_cumulative_index_case_end_reasons_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_cumulative_index_case_end_reasons_date_index ON public.statistics_cumulative_index_case_end_reasons USING btree (date);


--
-- Name: statistics_cumulative_index_case_end_reasons_end_reason_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_cumulative_index_case_end_reasons_end_reason_index ON public.statistics_cumulative_index_case_end_reasons USING btree (end_reason);


--
-- Name: statistics_cumulative_index_case_end_reasons_tenant_uuid_date_e; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_cumulative_index_case_end_reasons_tenant_uuid_date_e ON public.statistics_cumulative_index_case_end_reasons USING btree (tenant_uuid, date, end_reason);


--
-- Name: statistics_cumulative_index_case_end_reasons_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_cumulative_index_case_end_reasons_tenant_uuid_index ON public.statistics_cumulative_index_case_end_reasons USING btree (tenant_uuid);


--
-- Name: statistics_cumulative_possible_index_case_end_reasons_date_inde; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_cumulative_possible_index_case_end_reasons_date_inde ON public.statistics_cumulative_possible_index_case_end_reasons USING btree (date);


--
-- Name: statistics_cumulative_possible_index_case_end_reasons_end_reaso; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_cumulative_possible_index_case_end_reasons_end_reaso ON public.statistics_cumulative_possible_index_case_end_reasons USING btree (end_reason);


--
-- Name: statistics_cumulative_possible_index_case_end_reasons_tenant_uu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_cumulative_possible_index_case_end_reasons_tenant_uu ON public.statistics_cumulative_possible_index_case_end_reasons USING btree (tenant_uuid);


--
-- Name: statistics_cumulative_possible_index_case_end_reasons_type_inde; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_cumulative_possible_index_case_end_reasons_type_inde ON public.statistics_cumulative_possible_index_case_end_reasons USING btree (type);


--
-- Name: statistics_new_cases_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_new_cases_per_day_date_index ON public.statistics_new_cases_per_day USING btree (date);


--
-- Name: statistics_new_cases_per_day_sub_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_new_cases_per_day_sub_type_index ON public.statistics_new_cases_per_day USING btree (sub_type);


--
-- Name: statistics_new_cases_per_day_tenant_uuid_date_type_sub_type_ind; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_new_cases_per_day_tenant_uuid_date_type_sub_type_ind ON public.statistics_new_cases_per_day USING btree (tenant_uuid, date, type, sub_type);


--
-- Name: statistics_new_cases_per_day_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_new_cases_per_day_tenant_uuid_index ON public.statistics_new_cases_per_day USING btree (tenant_uuid);


--
-- Name: statistics_new_cases_per_day_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_new_cases_per_day_type_index ON public.statistics_new_cases_per_day USING btree (type);


--
-- Name: statistics_transmission_country_cases_per_day_country_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_transmission_country_cases_per_day_country_index ON public.statistics_transmission_country_cases_per_day USING btree (country);


--
-- Name: statistics_transmission_country_cases_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_transmission_country_cases_per_day_date_index ON public.statistics_transmission_country_cases_per_day USING btree (date);


--
-- Name: statistics_transmission_country_cases_per_day_tenant_uuid_date_; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_transmission_country_cases_per_day_tenant_uuid_date_ ON public.statistics_transmission_country_cases_per_day USING btree (tenant_uuid, date, country);


--
-- Name: statistics_transmission_country_cases_per_day_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_transmission_country_cases_per_day_tenant_uuid_index ON public.statistics_transmission_country_cases_per_day USING btree (tenant_uuid);


--
-- Name: tenants_iam_domain_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tenants_iam_domain_index ON public.tenants USING btree (iam_domain);


--
-- Name: tenants_short_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tenants_short_name_index ON public.tenants USING btree (short_name);


--
-- Name: transmissions_propagator_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX transmissions_propagator_case_uuid_index ON public.transmissions USING btree (propagator_case_uuid);


--
-- Name: transmissions_recipient_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX transmissions_recipient_case_uuid_index ON public.transmissions USING btree (recipient_case_uuid);


--
-- Name: unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unique" ON public.statistics_cumulative_possible_index_case_end_reasons USING btree (tenant_uuid, date, type, end_reason);


--
-- Name: users_iam_sub_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_iam_sub_index ON public.users USING btree (iam_sub);


--
-- Name: versions_item_pk_item_table_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_item_pk_item_table_index ON public.versions USING btree (item_pk, item_table);


--
-- Name: versions_originator_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_originator_id_index ON public.versions USING btree (originator_id);


--
-- Name: affiliations affiliations_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER affiliations_versioning_delete AFTER DELETE ON public.affiliations FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: affiliations affiliations_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER affiliations_versioning_insert AFTER INSERT ON public.affiliations FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: affiliations affiliations_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER affiliations_versioning_update AFTER UPDATE ON public.affiliations FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: cases cases_assignee_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cases_assignee_changed AFTER INSERT OR UPDATE ON public.cases FOR EACH ROW EXECUTE FUNCTION public.case_assignee_notification();


--
-- Name: cases cases_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cases_versioning_delete AFTER DELETE ON public.cases FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: cases cases_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cases_versioning_insert AFTER INSERT ON public.cases FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: cases cases_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cases_versioning_update AFTER UPDATE ON public.cases FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: cases check_user_authorization_on_case; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_user_authorization_on_case BEFORE INSERT OR UPDATE ON public.cases FOR EACH ROW EXECUTE FUNCTION public.check_user_authorization_on_case();


--
-- Name: divisions divisions_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER divisions_versioning_delete AFTER DELETE ON public.divisions FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: divisions divisions_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER divisions_versioning_insert AFTER INSERT ON public.divisions FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: divisions divisions_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER divisions_versioning_update AFTER UPDATE ON public.divisions FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: emails email_status_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER email_status_changed AFTER INSERT OR UPDATE ON public.emails FOR EACH ROW EXECUTE FUNCTION public.email_send_failed();


--
-- Name: emails emails_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER emails_versioning_delete AFTER DELETE ON public.emails FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: emails emails_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER emails_versioning_insert AFTER INSERT ON public.emails FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: emails emails_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER emails_versioning_update AFTER UPDATE ON public.emails FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: hospitalizations hospitalizations_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER hospitalizations_versioning_delete AFTER DELETE ON public.hospitalizations FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: hospitalizations hospitalizations_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER hospitalizations_versioning_insert AFTER INSERT ON public.hospitalizations FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: hospitalizations hospitalizations_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER hospitalizations_versioning_update AFTER UPDATE ON public.hospitalizations FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: notes notes_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notes_versioning_delete AFTER DELETE ON public.notes FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: notes notes_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notes_versioning_insert AFTER INSERT ON public.notes FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: notes notes_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notes_versioning_update AFTER UPDATE ON public.notes FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: notifications notification_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notification_created AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.notification_created();


--
-- Name: notifications notifications_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notifications_versioning_delete AFTER DELETE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: notifications notifications_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notifications_versioning_insert AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: notifications notifications_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notifications_versioning_update AFTER UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: organisations organisations_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER organisations_versioning_delete AFTER DELETE ON public.organisations FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: organisations organisations_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER organisations_versioning_insert AFTER INSERT ON public.organisations FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: organisations organisations_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER organisations_versioning_update AFTER UPDATE ON public.organisations FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: people people_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER people_versioning_delete AFTER DELETE ON public.people FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: people people_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER people_versioning_insert AFTER INSERT ON public.people FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: people people_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER people_versioning_update AFTER UPDATE ON public.people FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: positions positions_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER positions_versioning_delete AFTER DELETE ON public.positions FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: positions positions_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER positions_versioning_insert AFTER INSERT ON public.positions FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: positions positions_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER positions_versioning_update AFTER UPDATE ON public.positions FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: possible_index_submissions possible_index_submissions_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER possible_index_submissions_versioning_delete AFTER DELETE ON public.possible_index_submissions FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: possible_index_submissions possible_index_submissions_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER possible_index_submissions_versioning_insert AFTER INSERT ON public.possible_index_submissions FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: possible_index_submissions possible_index_submissions_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER possible_index_submissions_versioning_update AFTER UPDATE ON public.possible_index_submissions FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: sedex_exports sedex_exports_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sedex_exports_versioning_delete AFTER DELETE ON public.sedex_exports FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: sedex_exports sedex_exports_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sedex_exports_versioning_insert AFTER INSERT ON public.sedex_exports FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: sedex_exports sedex_exports_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sedex_exports_versioning_update AFTER UPDATE ON public.sedex_exports FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: sms sms_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sms_versioning_delete AFTER DELETE ON public.sms FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: sms sms_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sms_versioning_insert AFTER INSERT ON public.sms FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: sms sms_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sms_versioning_update AFTER UPDATE ON public.sms FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: system_message_tenants system_message_tenants_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER system_message_tenants_versioning_delete AFTER DELETE ON public.system_message_tenants FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: system_message_tenants system_message_tenants_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER system_message_tenants_versioning_insert AFTER INSERT ON public.system_message_tenants FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: system_message_tenants system_message_tenants_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER system_message_tenants_versioning_update AFTER UPDATE ON public.system_message_tenants FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: system_messages system_messages_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER system_messages_versioning_delete AFTER DELETE ON public.system_messages FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: system_messages system_messages_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER system_messages_versioning_insert AFTER INSERT ON public.system_messages FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: system_messages system_messages_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER system_messages_versioning_update AFTER UPDATE ON public.system_messages FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: tenants tenants_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tenants_versioning_delete AFTER DELETE ON public.tenants FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: tenants tenants_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tenants_versioning_insert AFTER INSERT ON public.tenants FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: tenants tenants_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tenants_versioning_update AFTER UPDATE ON public.tenants FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: transmissions transmissions_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER transmissions_versioning_delete AFTER DELETE ON public.transmissions FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: transmissions transmissions_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER transmissions_versioning_insert AFTER INSERT ON public.transmissions FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: transmissions transmissions_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER transmissions_versioning_update AFTER UPDATE ON public.transmissions FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: user_grants user_grants_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER user_grants_versioning_delete AFTER DELETE ON public.user_grants FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: user_grants user_grants_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER user_grants_versioning_insert AFTER INSERT ON public.user_grants FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: user_grants user_grants_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER user_grants_versioning_update AFTER UPDATE ON public.user_grants FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: users users_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER users_versioning_delete AFTER DELETE ON public.users FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: users users_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER users_versioning_insert AFTER INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: users users_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER users_versioning_update AFTER UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: affiliations affiliations_division_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliations
    ADD CONSTRAINT affiliations_division_uuid_fkey FOREIGN KEY (division_uuid) REFERENCES public.divisions(uuid) ON DELETE SET NULL;


--
-- Name: affiliations affiliations_organisation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliations
    ADD CONSTRAINT affiliations_organisation_uuid_fkey FOREIGN KEY (organisation_uuid) REFERENCES public.organisations(uuid) ON DELETE SET NULL;


--
-- Name: affiliations affiliations_person_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliations
    ADD CONSTRAINT affiliations_person_uuid_fkey FOREIGN KEY (person_uuid) REFERENCES public.people(uuid) ON DELETE CASCADE;


--
-- Name: cases cases_person_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_person_uuid_fkey FOREIGN KEY (person_uuid) REFERENCES public.people(uuid);


--
-- Name: cases cases_supervisor_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_supervisor_uuid_fkey FOREIGN KEY (supervisor_uuid) REFERENCES public.users(uuid) ON DELETE SET NULL;


--
-- Name: cases cases_tenant_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_tenant_uuid_fkey FOREIGN KEY (tenant_uuid) REFERENCES public.tenants(uuid);


--
-- Name: cases cases_tracer_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_tracer_uuid_fkey FOREIGN KEY (tracer_uuid) REFERENCES public.users(uuid) ON DELETE SET NULL;


--
-- Name: divisions divisions_organisation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.divisions
    ADD CONSTRAINT divisions_organisation_uuid_fkey FOREIGN KEY (organisation_uuid) REFERENCES public.organisations(uuid) ON DELETE CASCADE;


--
-- Name: emails emails_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: emails emails_tenant_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_tenant_uuid_fkey FOREIGN KEY (tenant_uuid) REFERENCES public.tenants(uuid) ON DELETE CASCADE;


--
-- Name: emails emails_user_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_user_uuid_fkey FOREIGN KEY (user_uuid) REFERENCES public.users(uuid) ON DELETE CASCADE;


--
-- Name: hospitalizations hospitalizations_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hospitalizations
    ADD CONSTRAINT hospitalizations_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: hospitalizations hospitalizations_organisation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hospitalizations
    ADD CONSTRAINT hospitalizations_organisation_uuid_fkey FOREIGN KEY (organisation_uuid) REFERENCES public.organisations(uuid) ON DELETE SET NULL;


--
-- Name: notes notes_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_uuid_fkey FOREIGN KEY (user_uuid) REFERENCES public.users(uuid) ON DELETE CASCADE;


--
-- Name: people people_tenant_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_tenant_uuid_fkey FOREIGN KEY (tenant_uuid) REFERENCES public.tenants(uuid) ON DELETE SET NULL;


--
-- Name: positions positions_organisation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_organisation_uuid_fkey FOREIGN KEY (organisation_uuid) REFERENCES public.organisations(uuid) ON DELETE CASCADE;


--
-- Name: positions positions_person_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_person_uuid_fkey FOREIGN KEY (person_uuid) REFERENCES public.people(uuid) ON DELETE CASCADE;


--
-- Name: possible_index_submissions possible_index_submissions_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.possible_index_submissions
    ADD CONSTRAINT possible_index_submissions_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: sedex_exports sedex_exports_tenant_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sedex_exports
    ADD CONSTRAINT sedex_exports_tenant_uuid_fkey FOREIGN KEY (tenant_uuid) REFERENCES public.tenants(uuid);


--
-- Name: sms sms_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms
    ADD CONSTRAINT sms_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: system_message_tenants system_message_tenants_system_message_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_message_tenants
    ADD CONSTRAINT system_message_tenants_system_message_uuid_fkey FOREIGN KEY (system_message_uuid) REFERENCES public.system_messages(uuid) ON DELETE CASCADE;


--
-- Name: system_message_tenants system_message_tenants_tenant_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_message_tenants
    ADD CONSTRAINT system_message_tenants_tenant_uuid_fkey FOREIGN KEY (tenant_uuid) REFERENCES public.tenants(uuid) ON DELETE CASCADE;


--
-- Name: transmissions transmissions_propagator_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transmissions
    ADD CONSTRAINT transmissions_propagator_case_uuid_fkey FOREIGN KEY (propagator_case_uuid) REFERENCES public.cases(uuid) ON DELETE SET NULL;


--
-- Name: transmissions transmissions_recipient_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transmissions
    ADD CONSTRAINT transmissions_recipient_case_uuid_fkey FOREIGN KEY (recipient_case_uuid) REFERENCES public.cases(uuid) ON DELETE SET NULL;


--
-- Name: user_grants user_grants_tenant_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_grants
    ADD CONSTRAINT user_grants_tenant_uuid_fkey FOREIGN KEY (tenant_uuid) REFERENCES public.tenants(uuid) ON DELETE CASCADE;


--
-- Name: user_grants user_grants_user_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_grants
    ADD CONSTRAINT user_grants_user_uuid_fkey FOREIGN KEY (user_uuid) REFERENCES public.users(uuid) ON DELETE CASCADE;


--
-- Name: versions versions_originator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_originator_id_fkey FOREIGN KEY (originator_id) REFERENCES public.users(uuid) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20201014124504);
INSERT INTO public."schema_migrations" (version) VALUES (20201014151333);
INSERT INTO public."schema_migrations" (version) VALUES (20201014155946);
INSERT INTO public."schema_migrations" (version) VALUES (20201014163827);
INSERT INTO public."schema_migrations" (version) VALUES (20201015091437);
INSERT INTO public."schema_migrations" (version) VALUES (20201015142407);
INSERT INTO public."schema_migrations" (version) VALUES (20201019134503);
INSERT INTO public."schema_migrations" (version) VALUES (20201020081209);
INSERT INTO public."schema_migrations" (version) VALUES (20201022080338);
INSERT INTO public."schema_migrations" (version) VALUES (20201022152603);
INSERT INTO public."schema_migrations" (version) VALUES (20201023164744);
INSERT INTO public."schema_migrations" (version) VALUES (20201026155514);
INSERT INTO public."schema_migrations" (version) VALUES (20201026172126);
INSERT INTO public."schema_migrations" (version) VALUES (20201029122710);
INSERT INTO public."schema_migrations" (version) VALUES (20201105115420);
INSERT INTO public."schema_migrations" (version) VALUES (20201109123119);
INSERT INTO public."schema_migrations" (version) VALUES (20201116140753);
INSERT INTO public."schema_migrations" (version) VALUES (20201117103504);
INSERT INTO public."schema_migrations" (version) VALUES (20201117145701);
INSERT INTO public."schema_migrations" (version) VALUES (20201117180758);
INSERT INTO public."schema_migrations" (version) VALUES (20201117181650);
INSERT INTO public."schema_migrations" (version) VALUES (20201117190605);
INSERT INTO public."schema_migrations" (version) VALUES (20201117204520);
INSERT INTO public."schema_migrations" (version) VALUES (20201117214110);
INSERT INTO public."schema_migrations" (version) VALUES (20201119155625);
INSERT INTO public."schema_migrations" (version) VALUES (20201119162816);
INSERT INTO public."schema_migrations" (version) VALUES (20201123161251);
INSERT INTO public."schema_migrations" (version) VALUES (20201127164315);
INSERT INTO public."schema_migrations" (version) VALUES (20201128174746);
INSERT INTO public."schema_migrations" (version) VALUES (20201128184442);
INSERT INTO public."schema_migrations" (version) VALUES (20201128184930);
INSERT INTO public."schema_migrations" (version) VALUES (20201130101446);
INSERT INTO public."schema_migrations" (version) VALUES (20201130101622);
INSERT INTO public."schema_migrations" (version) VALUES (20201201144543);
INSERT INTO public."schema_migrations" (version) VALUES (20201202133431);
INSERT INTO public."schema_migrations" (version) VALUES (20201203153528);
INSERT INTO public."schema_migrations" (version) VALUES (20201208122417);
INSERT INTO public."schema_migrations" (version) VALUES (20201209102703);
INSERT INTO public."schema_migrations" (version) VALUES (20201215205729);
INSERT INTO public."schema_migrations" (version) VALUES (20201216121734);
INSERT INTO public."schema_migrations" (version) VALUES (20201217100349);
INSERT INTO public."schema_migrations" (version) VALUES (20201217105557);
INSERT INTO public."schema_migrations" (version) VALUES (20201217162450);
INSERT INTO public."schema_migrations" (version) VALUES (20201222151731);
INSERT INTO public."schema_migrations" (version) VALUES (20210104110837);
INSERT INTO public."schema_migrations" (version) VALUES (20210104113911);
INSERT INTO public."schema_migrations" (version) VALUES (20210104120523);
INSERT INTO public."schema_migrations" (version) VALUES (20210104120850);
INSERT INTO public."schema_migrations" (version) VALUES (20210104132101);
INSERT INTO public."schema_migrations" (version) VALUES (20210105103437);
INSERT INTO public."schema_migrations" (version) VALUES (20210106112452);
INSERT INTO public."schema_migrations" (version) VALUES (20210106120215);
INSERT INTO public."schema_migrations" (version) VALUES (20210111161511);
INSERT INTO public."schema_migrations" (version) VALUES (20210125133911);
INSERT INTO public."schema_migrations" (version) VALUES (20210125170552);
INSERT INTO public."schema_migrations" (version) VALUES (20210125183911);
INSERT INTO public."schema_migrations" (version) VALUES (20210127105624);
INSERT INTO public."schema_migrations" (version) VALUES (20210127111138);
INSERT INTO public."schema_migrations" (version) VALUES (20210128121712);
INSERT INTO public."schema_migrations" (version) VALUES (20210202110851);
INSERT INTO public."schema_migrations" (version) VALUES (20210204134512);
INSERT INTO public."schema_migrations" (version) VALUES (20210205151543);
INSERT INTO public."schema_migrations" (version) VALUES (20210205161105);
INSERT INTO public."schema_migrations" (version) VALUES (20210210183541);
INSERT INTO public."schema_migrations" (version) VALUES (20210215124820);
INSERT INTO public."schema_migrations" (version) VALUES (20210302143322);
INSERT INTO public."schema_migrations" (version) VALUES (20210304175730);
INSERT INTO public."schema_migrations" (version) VALUES (20210305203915);
INSERT INTO public."schema_migrations" (version) VALUES (20210315103136);
INSERT INTO public."schema_migrations" (version) VALUES (20210316120150);
INSERT INTO public."schema_migrations" (version) VALUES (20210317121030);
INSERT INTO public."schema_migrations" (version) VALUES (20210318105649);
INSERT INTO public."schema_migrations" (version) VALUES (20210319113229);
INSERT INTO public."schema_migrations" (version) VALUES (20210326144056);
INSERT INTO public."schema_migrations" (version) VALUES (20210415111909);
INSERT INTO public."schema_migrations" (version) VALUES (20210416111804);
INSERT INTO public."schema_migrations" (version) VALUES (20210419130620);
INSERT INTO public."schema_migrations" (version) VALUES (20210419154442);
INSERT INTO public."schema_migrations" (version) VALUES (20210511110755);
INSERT INTO public."schema_migrations" (version) VALUES (20210521094209);
