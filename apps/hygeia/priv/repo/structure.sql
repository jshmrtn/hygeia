--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2 (Debian 12.2-1.pgdg100+1)
-- Dumped by pg_dump version 12.5 (Ubuntu 12.5-0ubuntu0.20.04.1)

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
    'done'
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
    '023',
    '0121',
    '024000',
    '0220',
    '0240',
    '016400',
    '023000',
    '0111',
    '015',
    '014',
    '0126',
    '012102',
    '016100',
    '014200',
    '0112',
    '0162',
    '0116',
    '0230',
    '012600',
    '017000',
    '0114',
    '011400',
    '0123',
    '0312',
    '0130',
    '0128',
    '012700',
    '016300',
    '01',
    '011100',
    '0322',
    '016200',
    '02',
    '021000',
    '011300',
    '0163',
    '011',
    '0144',
    '0149',
    '011600',
    '0210',
    '0142',
    '021',
    '0321',
    '013',
    '022000',
    '017',
    '031200',
    '031',
    '022',
    '0119',
    '03',
    '0170',
    '014100',
    '012800',
    '014300',
    '012900',
    '0129',
    '012300',
    '032100',
    '031100',
    '012',
    '014600',
    '012200',
    '016',
    '0146',
    '014900',
    '032',
    '011900',
    '0161',
    '011200',
    '024',
    '015000',
    '011500',
    '0311',
    '0164',
    '013000',
    '0125',
    '0143',
    '014500',
    '0122',
    '014700',
    '0113',
    '0127',
    '012400',
    '012500',
    '0141',
    '014400',
    '0115',
    '032200',
    '012101',
    '0145',
    '0147',
    '0150',
    '0124',
    '089300',
    '0893',
    '09',
    '08',
    '0620',
    '089',
    '061',
    '071',
    '091',
    '0910',
    '0510',
    '0811',
    '0729',
    '0610',
    '089900',
    '089100',
    '072',
    '062000',
    '062',
    '0520',
    '091000',
    '052',
    '0891',
    '0812',
    '0899',
    '072100',
    '051000',
    '061000',
    '081200',
    '0990',
    '081',
    '0710',
    '071000',
    '052000',
    '081100',
    '0892',
    '07',
    '099000',
    '05',
    '051',
    '072900',
    '0721',
    '06',
    '089200',
    '099',
    '245400',
    '281400',
    '2052',
    '1419',
    '325003',
    '3030',
    '234300',
    '2312',
    '1392',
    '244400',
    '161',
    '2434',
    '143900',
    '231200',
    '254',
    '13',
    '139100',
    '259200',
    '2017',
    '2752',
    '293200',
    '172200',
    '191000',
    '2042',
    '14',
    '110100',
    '3211',
    '110500',
    '331400',
    '172300',
    '3012',
    '239901',
    '331500',
    '2790',
    '104200',
    '303',
    '2453',
    '3250',
    '241000',
    '172900',
    '265203',
    '132002',
    '2053',
    '273100',
    '1439',
    '171200',
    '275',
    '331700',
    '2454',
    '289600',
    '204200',
    '259300',
    '29',
    '1629',
    '244600',
    '101100',
    '3320',
    '205300',
    '106200',
    '141302',
    '264000',
    '105200',
    '181203',
    '243400',
    '108400',
    '205900',
    '107',
    '221900',
    '1073',
    '2893',
    '131',
    '2433',
    '2591',
    '291',
    '2341',
    '109',
    '1399',
    '1820',
    '1012',
    '253',
    '142',
    '325002',
    '222200',
    '254000',
    '2342',
    '1013',
    '120000',
    '2511',
    '234400',
    '2364',
    '301',
    '2011',
    '3240',
    '244',
    '3091',
    '2443',
    '2829',
    '1200',
    '310200',
    '2051',
    '161002',
    '291000',
    '268',
    '2015',
    '1032',
    '282200',
    '2712',
    '251',
    '284100',
    '301200',
    '12',
    '281500',
    '2451',
    '162302',
    '171100',
    '2030',
    '2016',
    '212',
    '107100',
    '2444',
    '261200',
    '3020',
    '2540',
    '31',
    '2895',
    '181301',
    '108900',
    '151200',
    '2110',
    '231300',
    '265201',
    '264',
    '284900',
    '3092',
    '281100',
    '1411',
    '2229',
    '25',
    '205',
    '2711',
    '104100',
    '152',
    '110200',
    '105102',
    '2825',
    '257100',
    '1020',
    '236200',
    '1722',
    '281',
    '182',
    '2410',
    '151',
    '2640',
    '2931',
    '2361',
    '282400',
    '2452',
    '1061',
    '257300',
    '2896',
    '332',
    '139902',
    '2442',
    '107300',
    '1071',
    '108500',
    '282500',
    '3109',
    '201',
    '268000',
    '289',
    '310900',
    '231',
    '141200',
    '2120',
    '1039',
    '28',
    '1413',
    '322',
    '272000',
    '265204',
    '1085',
    '2311',
    '2344',
    '139300',
    '251200',
    '1623',
    '2561',
    '139201',
    '245100',
    '2014',
    '332000',
    '261100',
    '256100',
    '201400',
    '1083',
    '309',
    '201500',
    '2849',
    '289400',
    '331300',
    '2020',
    '235100',
    '132',
    '101',
    '2349',
    '131003',
    '1041',
    '162100',
    '106100',
    '1412',
    '331',
    '1395',
    '263000',
    '241',
    '1414',
    '274000',
    '242',
    '103',
    '271',
    '1089',
    '282300',
    '1624',
    '172400',
    '2012',
    '252',
    '2362',
    '1330',
    '292000',
    '257200',
    '139202',
    '110',
    '267000',
    '171',
    '289300',
    '266000',
    '105103',
    '201300',
    '239902',
    '234900',
    '1081',
    '2811',
    '1105',
    '3316',
    '162400',
    '2222',
    '102000',
    '2892',
    '1031',
    '275200',
    '231900',
    '2571',
    '201600',
    '265',
    '234',
    '132003',
    '256201',
    '1320',
    '2420',
    '1723',
    '18',
    '282100',
    '244100',
    '1420',
    '2910',
    '267',
    '239100',
    '1812',
    '142000',
    '2751',
    '2841',
    '282',
    '133000',
    '32',
    '106',
    '1310',
    '259900',
    '20',
    '203000',
    '162200',
    '181302',
    '1910',
    '321202',
    '2830',
    '236',
    '2332',
    '283',
    '1520',
    '289901',
    '2013',
    '2620',
    '30',
    '1082',
    '27',
    '256203',
    '202000',
    '133',
    '2651',
    '2314',
    '1104',
    '2733',
    '162900',
    '289902',
    '139',
    '1610',
    '2630',
    '262000',
    '233',
    '2441',
    '234200',
    '256202',
    '2611',
    '10',
    '105',
    '252100',
    '222',
    '181202',
    '275100',
    '1511',
    '1811',
    '2894',
    '243300',
    '205200',
    '322000',
    '236500',
    '108202',
    '1051',
    '221',
    '161003',
    '2593',
    '1103',
    '131004',
    '103100',
    '259',
    '321',
    '236400',
    '102',
    '331200',
    '274',
    '211000',
    '21',
    '206000',
    '256',
    '3040',
    '251100',
    '141402',
    '2572',
    '263',
    '309100',
    '232000',
    '2445',
    '1062',
    '105101',
    '141303',
    '139203',
    '2573',
    '181204',
    '139400',
    '321300',
    '2822',
    '2319',
    '259400',
    '283000',
    '237000',
    '1396',
    '1721',
    '273300',
    '243',
    '3212',
    '172100',
    '323000',
    '3103',
    '1393',
    '1091',
    '222100',
    '2369',
    '181',
    '3319',
    '324',
    '3220',
    '2720',
    '239',
    '192000',
    '325001',
    '141',
    '3011',
    '1052',
    '2812',
    '2823',
    '108',
    '245300',
    '1920',
    '284',
    '3230',
    '323',
    '141403',
    '257',
    '289100',
    '152000',
    '204100',
    '2932',
    '2562',
    '110300',
    '3102',
    '222900',
    '1102',
    '231100',
    '131001',
    '3313',
    '141301',
    '2652',
    '101200',
    '139901',
    '1042',
    '293',
    '233200',
    '325',
    '108600',
    '2813',
    '109100',
    '302',
    '143100',
    '309202',
    '1814',
    '1072',
    '255000',
    '201700',
    '244200',
    '1011',
    '2391',
    '301100',
    '235',
    '235200',
    '236300',
    '132001',
    '108100',
    '2891',
    '2824',
    '3314',
    '279',
    '2446',
    '231400',
    '201100',
    '2821',
    '262',
    '2211',
    '24',
    '309201',
    '203',
    '1622',
    '324000',
    '282900',
    '289500',
    '1092',
    '101300',
    '273',
    '242000',
    '172',
    '243100',
    '279000',
    '2351',
    '302000',
    '11',
    '244300',
    '104',
    '245',
    '17',
    '265100',
    '266',
    '1724',
    '310',
    '2060',
    '252900',
    '271200',
    '2670',
    '1101',
    '22',
    '3291',
    '243200',
    '233100',
    '109200',
    '162301',
    '162',
    '2313',
    '2814',
    '16',
    '2530',
    '205100',
    '293100',
    '2512',
    '3099',
    '281300',
    '204',
    '110700',
    '265202',
    '272',
    '3312',
    '310100',
    '234100',
    '2599',
    '139500',
    '2732',
    '281200',
    '2920',
    '2041',
    '26',
    '1431',
    '321100',
    '1107',
    '1712',
    '3101',
    '309900',
    '329',
    '271100',
    '329900',
    '1729',
    '19',
    '236900',
    '1394',
    '221100',
    '139600',
    '253000',
    '2399',
    '201200',
    '141401',
    '292',
    '162303',
    '331600',
    '191',
    '108201',
    '331100',
    '151100',
    '2352',
    '1813',
    '222300',
    '2660',
    '139903',
    '141900',
    '265205',
    '107200',
    '103900',
    '289200',
    '108300',
    '325004',
    '2432',
    '321201',
    '1106',
    '141100',
    '331900',
    '259100',
    '261',
    '329100',
    '2815',
    '23',
    '1086',
    '3311',
    '2594',
    '2612',
    '211',
    '1391',
    '2592',
    '2343',
    '2365',
    '2221',
    '212000',
    '244500',
    '206',
    '1512',
    '310300',
    '2740',
    '110400',
    '2223',
    '15',
    '33',
    '232',
    '182000',
    '143',
    '181201',
    '2331',
    '103200',
    '273200',
    '2059',
    '3315',
    '2680',
    '2899',
    '2320',
    '131002',
    '161001',
    '304000',
    '1621',
    '181400',
    '255',
    '181100',
    '1084',
    '2521',
    '2363',
    '237',
    '2219',
    '1711',
    '3213',
    '110600',
    '2431',
    '2731',
    '192',
    '3299',
    '2550',
    '2370',
    '2529',
    '304',
    '245200',
    '303000',
    '202',
    '120',
    '3317',
    '236100',
    '3521',
    '352100',
    '3513',
    '353000',
    '352200',
    '352300',
    '35',
    '353',
    '3522',
    '3511',
    '351300',
    '351200',
    '351',
    '3512',
    '351100',
    '352',
    '3523',
    '351400',
    '3530',
    '3514',
    '381200',
    '37',
    '3900',
    '38',
    '360000',
    '36',
    '390000',
    '370000',
    '3812',
    '381',
    '382',
    '3831',
    '3811',
    '39',
    '382100',
    '383',
    '3832',
    '360',
    '383100',
    '383200',
    '370',
    '3821',
    '390',
    '3822',
    '3600',
    '381100',
    '382200',
    '3700',
    '4391',
    '42',
    '4120',
    '439903',
    '4212',
    '433402',
    '4334',
    '422200',
    '433900',
    '412002',
    '432202',
    '439',
    '429100',
    '421100',
    '433403',
    '432',
    '433302',
    '433',
    '41',
    '439103',
    '4312',
    '433303',
    '421300',
    '4311',
    '432902',
    '433301',
    '429',
    '421200',
    '412001',
    '431300',
    '433401',
    '421',
    '4313',
    '4321',
    '439102',
    '422',
    '431',
    '433200',
    '4333',
    '432203',
    '411000',
    '412',
    '431200',
    '431100',
    '4291',
    '432100',
    '439904',
    '439905',
    '4211',
    '422100',
    '4329',
    '4213',
    '432201',
    '429900',
    '4399',
    '439902',
    '4339',
    '439101',
    '4110',
    '411',
    '412004',
    '4331',
    '4299',
    '4222',
    '4221',
    '432901',
    '433100',
    '4322',
    '43',
    '432204',
    '439901',
    '412003',
    '4332',
    '4676',
    '466400',
    '463900',
    '478100',
    '4519',
    '461500',
    '464901',
    '462100',
    '469',
    '474200',
    '464302',
    '475901',
    '467100',
    '4632',
    '451101',
    '471102',
    '4771',
    '462',
    '4635',
    '472200',
    '453200',
    '467701',
    '4648',
    '477501',
    '477202',
    '477601',
    '4730',
    '4649',
    '478200',
    '461600',
    '4690',
    '475',
    '4782',
    '477300',
    '451901',
    '464905',
    '4754',
    '4669',
    '4511',
    '467303',
    '4753',
    '464802',
    '461100',
    '478',
    '4762',
    '454000',
    '475300',
    '463800',
    '4775',
    '465101',
    '464801',
    '465',
    '464601',
    '453',
    '4639',
    '464700',
    '4616',
    '4618',
    '461',
    '477901',
    '462300',
    '4741',
    '477201',
    '4623',
    '4531',
    '451102',
    '464202',
    '466900',
    '471103',
    '463700',
    '4663',
    '472402',
    '4763',
    '461700',
    '475202',
    '477102',
    '477805',
    '454',
    '466100',
    '4645',
    '471902',
    '4652',
    '464903',
    '461900',
    '451',
    '4726',
    '4613',
    '477603',
    '476500',
    '477700',
    '4729',
    '473',
    '4672',
    '472300',
    '477104',
    '4751',
    '4781',
    '46',
    '471',
    '4662',
    '464902',
    '4752',
    '4532',
    '463',
    '464100',
    '4759',
    '477',
    '4619',
    '471901',
    '4791',
    '476201',
    '466200',
    '477902',
    '4621',
    '461800',
    '4633',
    '4719',
    '4776',
    '467500',
    '4638',
    '479100',
    '452002',
    '464904',
    '473000',
    '467702',
    '471101',
    '4675',
    '465102',
    '479900',
    '4612',
    '467600',
    '4614',
    '4777',
    '472401',
    '476100',
    '4624',
    '477101',
    '4661',
    '4617',
    '472600',
    '4779',
    '464201',
    '477502',
    '4642',
    '4764',
    '453100',
    '4622',
    '45',
    '452001',
    '462400',
    '466600',
    '463200',
    '47',
    '4773',
    '477801',
    '463500',
    '475201',
    '464303',
    '474100',
    '4646',
    '477802',
    '4743',
    '471104',
    '467400',
    '479',
    '474300',
    '472902',
    '472',
    '4651',
    '4677',
    '4724',
    '472500',
    '4673',
    '451902',
    '4647',
    '466500',
    '4666',
    '464500',
    '464400',
    '467301',
    '4789',
    '4644',
    '477400',
    '4631',
    '461200',
    '478900',
    '4637',
    '452',
    '461300',
    '464',
    '464301',
    '463600',
    '4725',
    '476',
    '467302',
    '4615',
    '475903',
    '4721',
    '474',
    '465200',
    '461400',
    '4722',
    '4765',
    '477803',
    '476202',
    '472100',
    '4674',
    '4742',
    '476401',
    '476300',
    '4636',
    '477804',
    '4665',
    '471105',
    '477806',
    '464906',
    '462200',
    '477105',
    '4711',
    '475902',
    '4643',
    '477602',
    '475100',
    '4540',
    '4761',
    '466300',
    '477103',
    '4520',
    '466',
    '463402',
    '464602',
    '4634',
    '4772',
    '4664',
    '4641',
    '476402',
    '4671',
    '463100',
    '4611',
    '4774',
    '472901',
    '463401',
    '469000',
    '467200',
    '4778',
    '467',
    '4799',
    '463300',
    '475400',
    '4723',
    '532000',
    '493100',
    '49',
    '5224',
    '5110',
    '501',
    '5020',
    '512200',
    '491000',
    '511000',
    '531000',
    '4939',
    '522200',
    '522',
    '4942',
    '492',
    '521',
    '493200',
    '504000',
    '522400',
    '52',
    '5030',
    '495',
    '4910',
    '501000',
    '4931',
    '512',
    '50',
    '5122',
    '502',
    '51',
    '503000',
    '53',
    '521000',
    '531',
    '4941',
    '5010',
    '491',
    '512100',
    '511',
    '4932',
    '494200',
    '4920',
    '493',
    '5229',
    '522300',
    '504',
    '5320',
    '5310',
    '494100',
    '5223',
    '493902',
    '5222',
    '5221',
    '4950',
    '5040',
    '5210',
    '522100',
    '5121',
    '494',
    '493901',
    '522900',
    '493903',
    '503',
    '492000',
    '502000',
    '532',
    '495000',
    '552001',
    '56',
    '5630',
    '563001',
    '5510',
    '561003',
    '552',
    '561',
    '553001',
    '563002',
    '559000',
    '5610',
    '5590',
    '5530',
    '5621',
    '55',
    '551002',
    '552002',
    '553',
    '552003',
    '561001',
    '562100',
    '559',
    '553002',
    '562',
    '563',
    '5520',
    '561002',
    '5629',
    '551001',
    '551',
    '551003',
    '562900',
    '5829',
    '591100',
    '591',
    '613000',
    '6120',
    '6201',
    '602',
    '639900',
    '582100',
    '5920',
    '5912',
    '6010',
    '581300',
    '5911',
    '581900',
    '619',
    '601',
    '61',
    '581200',
    '6391',
    '620300',
    '581100',
    '639100',
    '620',
    '6312',
    '631200',
    '601000',
    '63',
    '6110',
    '5814',
    '620100',
    '5813',
    '612000',
    '612',
    '6190',
    '592000',
    '6020',
    '581400',
    '613',
    '5811',
    '582',
    '6399',
    '611',
    '620200',
    '611000',
    '591400',
    '58',
    '62',
    '5914',
    '631100',
    '620900',
    '5913',
    '6209',
    '631',
    '592',
    '639',
    '6311',
    '6202',
    '6130',
    '60',
    '5812',
    '582900',
    '591300',
    '591200',
    '619000',
    '602000',
    '59',
    '6203',
    '581',
    '5821',
    '5819',
    '6612',
    '6530',
    '641912',
    '6611',
    '651204',
    '649901',
    '6499',
    '662902',
    '651201',
    '662901',
    '6511',
    '649201',
    '641905',
    '661200',
    '663002',
    '64',
    '661',
    '6621',
    '6629',
    '641906',
    '661900',
    '641902',
    '651203',
    '6420',
    '652',
    '6520',
    '641904',
    '651',
    '652000',
    '663',
    '649',
    '6622',
    '6491',
    '66',
    '6619',
    '651100',
    '641901',
    '641909',
    '663001',
    '662200',
    '651202',
    '653',
    '662100',
    '641910',
    '653000',
    '642001',
    '661100',
    '662',
    '649903',
    '641907',
    '641903',
    '65',
    '649902',
    '6430',
    '641908',
    '642002',
    '643000',
    '649202',
    '649100',
    '6411',
    '641',
    '6630',
    '642',
    '6512',
    '641100',
    '641911',
    '6419',
    '643',
    '6492',
    '683200',
    '682001',
    '6810',
    '681',
    '683',
    '6831',
    '6820',
    '682002',
    '682',
    '683100',
    '681000',
    '6832',
    '68',
    '73',
    '7120',
    '7021',
    '741002',
    '712000',
    '75',
    '711202',
    '732000',
    '741001',
    '750',
    '743',
    '711203',
    '741003',
    '711102',
    '6910',
    '691001',
    '732',
    '721',
    '70',
    '742',
    '74',
    '7500',
    '711103',
    '7022',
    '741',
    '750000',
    '722000',
    '7311',
    '722',
    '731200',
    '7312',
    '731',
    '7420',
    '742001',
    '71',
    '7410',
    '69',
    '711204',
    '7211',
    '711201',
    '701',
    '701001',
    '7430',
    '7320',
    '742002',
    '749000',
    '712',
    '6920',
    '692',
    '711205',
    '702200',
    '721900',
    '711',
    '7220',
    '702100',
    '711101',
    '701002',
    '7111',
    '721100',
    '7010',
    '691002',
    '731100',
    '7219',
    '692000',
    '7490',
    '7112',
    '743000',
    '691',
    '702',
    '72',
    '749',
    '771200',
    '799002',
    '801',
    '7912',
    '802000',
    '823',
    '8020',
    '773200',
    '803',
    '783',
    '823000',
    '812202',
    '8291',
    '802',
    '772',
    '77',
    '822',
    '7712',
    '80',
    '771',
    '7729',
    '781000',
    '7733',
    '811',
    '773400',
    '782',
    '771100',
    '781',
    '8121',
    '7722',
    '7820',
    '8230',
    '782000',
    '791100',
    '773100',
    '7735',
    '79',
    '799',
    '829',
    '811000',
    '829200',
    '812900',
    '7732',
    '772200',
    '8299',
    '773900',
    '8211',
    '8122',
    '821',
    '7830',
    '821902',
    '7990',
    '7740',
    '8292',
    '8220',
    '8010',
    '772100',
    '7739',
    '803000',
    '7711',
    '8110',
    '8129',
    '7721',
    '82',
    '7734',
    '7810',
    '813',
    '829100',
    '829900',
    '773500',
    '8030',
    '791',
    '783000',
    '812201',
    '821901',
    '821100',
    '774000',
    '822000',
    '8130',
    '81',
    '813000',
    '791200',
    '773',
    '799001',
    '801000',
    '773300',
    '7911',
    '7731',
    '78',
    '8219',
    '812100',
    '812',
    '772900',
    '774',
    '843000',
    '842400',
    '8425',
    '8413',
    '8421',
    '842201',
    '842',
    '842100',
    '8412',
    '842301',
    '843',
    '841300',
    '842302',
    '841',
    '842500',
    '842202',
    '841200',
    '8422',
    '84',
    '841100',
    '8423',
    '8411',
    '8430',
    '8424',
    '8510',
    '855200',
    '8552',
    '8541',
    '856',
    '856000',
    '8542',
    '852',
    '852002',
    '853',
    '852003',
    '855',
    '8532',
    '855903',
    '855904',
    '8560',
    '853101',
    '853200',
    '853103',
    '8559',
    '855901',
    '8520',
    '85',
    '8553',
    '854100',
    '853102',
    '854202',
    '855300',
    '855100',
    '8551',
    '851',
    '851000',
    '8531',
    '854201',
    '852001',
    '854203',
    '854',
    '855902',
    '889100',
    '869003',
    '871000',
    '8610',
    '8720',
    '881',
    '872002',
    '889',
    '869001',
    '8710',
    '8730',
    '869',
    '889901',
    '869002',
    '879',
    '873',
    '879002',
    '881000',
    '873002',
    '861002',
    '871',
    '87',
    '879001',
    '862100',
    '8622',
    '8810',
    '869007',
    '872',
    '861001',
    '869004',
    '862',
    '8621',
    '8790',
    '8899',
    '88',
    '861',
    '8690',
    '879003',
    '86',
    '8891',
    '8623',
    '889902',
    '869005',
    '862300',
    '869006',
    '872001',
    '873001',
    '862200',
    '920000',
    '900102',
    '900301',
    '931300',
    '910200',
    '92',
    '9321',
    '910100',
    '9313',
    '900101',
    '931100',
    '9200',
    '920',
    '91',
    '9319',
    '9311',
    '90',
    '9312',
    '931900',
    '932900',
    '93',
    '900302',
    '9104',
    '9004',
    '910400',
    '9002',
    '9001',
    '932',
    '910300',
    '900200',
    '900',
    '900400',
    '9101',
    '9003',
    '900303',
    '9329',
    '9102',
    '9103',
    '931200',
    '910',
    '931',
    '932100',
    '949904',
    '9492',
    '960300',
    '960202',
    '949101',
    '9603',
    '941',
    '960401',
    '960402',
    '952',
    '949102',
    '95',
    '960',
    '9609',
    '949901',
    '9523',
    '951200',
    '94',
    '952300',
    '949903',
    '960900',
    '949902',
    '942',
    '9601',
    '941200',
    '9525',
    '9491',
    '960101',
    '96',
    '9524',
    '941100',
    '952100',
    '9420',
    '9499',
    '952200',
    '9529',
    '951100',
    '952500',
    '9522',
    '960201',
    '9521',
    '949200',
    '951',
    '9412',
    '952400',
    '9511',
    '9411',
    '960102',
    '952900',
    '9602',
    '942000',
    '9512',
    '9604',
    '949',
    '98',
    '981000',
    '970',
    '97',
    '9820',
    '981',
    '970000',
    '982',
    '9700',
    '9810',
    '982000',
    '990001',
    '990003',
    '990002',
    '9900',
    '990',
    '99'
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
-- Name: template_variation; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.template_variation AS ENUM (
    'sg',
    'ar',
    'ai'
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
    CONSTRAINT comment_required CHECK (((organisation_uuid IS NOT NULL) OR (comment IS NOT NULL))),
    CONSTRAINT kind_other_required CHECK (
CASE
    WHEN (kind = 'other'::public.affiliation_kind) THEN (kind_other IS NOT NULL)
    ELSE (kind_other IS NULL)
END)
);


--
-- Name: case_related_organisations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.case_related_organisations (
    case_uuid uuid NOT NULL,
    organisation_uuid uuid NOT NULL
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
    hospitalizations jsonb[],
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
-- Name: emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emails (
    uuid uuid NOT NULL,
    direction public.communication_direction NOT NULL,
    status public.email_status NOT NULL,
    message bytea NOT NULL,
    last_try timestamp without time zone,
    case_uuid uuid NOT NULL,
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
    employer character varying(255)
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
    template_variation public.template_variation,
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
             CROSS JOIN LATERAL generate_series((COALESCE(((phase.phase ->> 'start'::text))::date, (cases.inserted_at)::date))::timestamp with time zone, (COALESCE(((phase.phase ->> 'end'::text))::date, CURRENT_DATE))::timestamp with time zone, '1 day'::interval) cmp_date(cmp_date))
          WHERE (((phase.phase -> 'details'::text) ->> '__type__'::text) = 'index'::text)
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
            ((hospitalization.hospitalization ->> 'start'::text))::date AS start_date,
            COALESCE(((hospitalization.hospitalization ->> 'end'::text))::date, ((cases.phases[array_upper(cases.phases, 1)] ->> 'end'::text))::date, CURRENT_DATE) AS end_date
           FROM (public.cases
             CROSS JOIN LATERAL unnest(cases.hospitalizations) hospitalization(hospitalization))
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
    infection_place jsonb
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
             CROSS JOIN LATERAL generate_series((COALESCE(((phase.phase ->> 'start'::text))::date, (cases.inserted_at)::date))::timestamp with time zone, (COALESCE(((phase.phase ->> 'end'::text))::date, CURRENT_DATE))::timestamp with time zone, '1 day'::interval) cmp_date(cmp_date))
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
             CROSS JOIN LATERAL generate_series((COALESCE(((phase.phase ->> 'start'::text))::date, (cases.inserted_at)::date))::timestamp with time zone, (COALESCE(((phase.phase ->> 'end'::text))::date, CURRENT_DATE))::timestamp with time zone, '1 day'::interval) cmp_date(cmp_date))
          WHERE ('{"details": {"__type__": "index"}}'::jsonb <@ phase.phase)
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
             CROSS JOIN LATERAL generate_series((COALESCE(((phase.phase ->> 'start'::text))::date, (cases.inserted_at)::date))::timestamp with time zone, (COALESCE(((phase.phase ->> 'end'::text))::date, CURRENT_DATE))::timestamp with time zone, '1 day'::interval) cmp_date(cmp_date))
          WHERE ('{"details": {"__type__": "possible_index"}}'::jsonb <@ phase.phase)
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
    id bigint NOT NULL,
    event character varying(10) NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id uuid,
    item_changes jsonb NOT NULL,
    originator_id uuid,
    origin character varying(50),
    meta jsonb,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


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
-- Name: emails emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (uuid);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (uuid);


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
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


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
-- Name: sedex_exports_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sedex_exports_tenant_uuid_index ON public.sedex_exports USING btree (tenant_uuid);


--
-- Name: sms_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sms_case_uuid_index ON public.sms USING btree (case_uuid);


--
-- Name: sms_direction_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sms_direction_status_index ON public.sms USING btree (direction, status);


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
-- Name: versions_event_item_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_event_item_type_index ON public.versions USING btree (event, item_type);


--
-- Name: versions_item_id_item_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_item_id_item_type_index ON public.versions USING btree (item_id, item_type);


--
-- Name: versions_item_type_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_item_type_inserted_at_index ON public.versions USING btree (item_type, inserted_at);


--
-- Name: versions_originator_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_originator_id_index ON public.versions USING btree (originator_id);


--
-- Name: affiliations affiliations_organisation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliations
    ADD CONSTRAINT affiliations_organisation_uuid_fkey FOREIGN KEY (organisation_uuid) REFERENCES public.organisations(uuid);


--
-- Name: affiliations affiliations_person_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliations
    ADD CONSTRAINT affiliations_person_uuid_fkey FOREIGN KEY (person_uuid) REFERENCES public.people(uuid);


--
-- Name: case_related_organisations case_related_organisations_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_related_organisations
    ADD CONSTRAINT case_related_organisations_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid);


--
-- Name: case_related_organisations case_related_organisations_organisation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.case_related_organisations
    ADD CONSTRAINT case_related_organisations_organisation_uuid_fkey FOREIGN KEY (organisation_uuid) REFERENCES public.organisations(uuid);


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
-- Name: emails emails_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: notes notes_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: people people_tenant_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_tenant_uuid_fkey FOREIGN KEY (tenant_uuid) REFERENCES public.tenants(uuid) ON DELETE SET NULL;


--
-- Name: positions positions_organisation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_organisation_uuid_fkey FOREIGN KEY (organisation_uuid) REFERENCES public.organisations(uuid);


--
-- Name: positions positions_person_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_person_uuid_fkey FOREIGN KEY (person_uuid) REFERENCES public.people(uuid);


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
