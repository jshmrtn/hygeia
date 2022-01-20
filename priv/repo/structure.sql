--
-- PostgreSQL database dump
--

-- Dumped from database version 14.0 (Debian 14.0-1.pgdg110+1)
-- Dumped by pg_dump version 14.1 (Ubuntu 14.1-1.pgdg21.10+1)

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
    'resident',
    'other'
);


--
-- Name: auto_tracing_problem; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.auto_tracing_problem AS ENUM (
    'unmanaged_tenant',
    'covid_app',
    'vaccination_failure',
    'hospitalization',
    'phase_ends_in_the_past',
    'school_related',
    'high_risk_country_travel',
    'flight_related',
    'new_employer',
    'possible_transmission',
    'link_propagator',
    'residency_outside_country',
    'no_contact_method',
    'no_reaction',
    'possible_index_submission',
    'phase_date_inconsistent'
);


--
-- Name: auto_tracing_step; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.auto_tracing_step AS ENUM (
    'start',
    'address',
    'contact_methods',
    'visits',
    'employer',
    'vaccination',
    'covid_app',
    'clinical',
    'flights',
    'travel',
    'transmission',
    'contact_persons',
    'end'
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
-- Name: case_import_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.case_import_status AS ENUM (
    'pending',
    'discarded',
    'resolved'
);


--
-- Name: case_import_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.case_import_type AS ENUM (
    'ism_2021_06_11_death',
    'ism_2021_06_11_test'
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
    'immune',
    'vaccinated',
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
    'ism_patient',
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
    '012200',
    '0129',
    '0125',
    '014200',
    '014400',
    '0141',
    '0130',
    '0164',
    '014900',
    '012101',
    '032200',
    '0116',
    '031200',
    '023000',
    '0150',
    '014100',
    '012500',
    '0163',
    '0145',
    '014300',
    '017000',
    '0119',
    '012300',
    '012800',
    '0126',
    '0162',
    '016200',
    '011100',
    '016',
    '012700',
    '01',
    '013000',
    '013',
    '0220',
    '022',
    '0230',
    '017',
    '031',
    '0240',
    '03',
    '012600',
    '016300',
    '024',
    '014500',
    '014700',
    '011',
    '0124',
    '0113',
    '031100',
    '015',
    '021000',
    '0161',
    '0111',
    '0143',
    '0149',
    '024000',
    '022000',
    '016400',
    '0146',
    '0128',
    '032',
    '0210',
    '011400',
    '0170',
    '0142',
    '011500',
    '0123',
    '016100',
    '021',
    '011900',
    '0122',
    '011200',
    '0321',
    '0121',
    '0311',
    '014600',
    '011300',
    '012400',
    '012',
    '032100',
    '0147',
    '0114',
    '015000',
    '012102',
    '014',
    '0115',
    '011600',
    '0322',
    '023',
    '012900',
    '0127',
    '0312',
    '0144',
    '0112',
    '02',
    '0520',
    '081',
    '05',
    '0891',
    '0620',
    '089200',
    '09',
    '071000',
    '099',
    '052',
    '071',
    '091',
    '061',
    '0990',
    '061000',
    '072100',
    '0721',
    '052000',
    '0710',
    '08',
    '089100',
    '0510',
    '0899',
    '0610',
    '06',
    '081100',
    '062',
    '0910',
    '0729',
    '099000',
    '0812',
    '089',
    '089300',
    '0892',
    '051000',
    '051',
    '0811',
    '072900',
    '0893',
    '081200',
    '091000',
    '072',
    '07',
    '089900',
    '062000',
    '331',
    '1082',
    '263000',
    '2331',
    '331900',
    '106200',
    '1091',
    '181',
    '2821',
    '1411',
    '2446',
    '2030',
    '1413',
    '309100',
    '282400',
    '222900',
    '256',
    '2899',
    '205300',
    '1071',
    '303000',
    '162303',
    '2733',
    '262',
    '245200',
    '239',
    '245400',
    '323000',
    '272',
    '1086',
    '231400',
    '192000',
    '27',
    '2410',
    '11',
    '101200',
    '2740',
    '162900',
    '104',
    '329',
    '2060',
    '265205',
    '2361',
    '19',
    '1910',
    '22',
    '310900',
    '232000',
    '281',
    '1083',
    '143900',
    '2813',
    '3319',
    '109',
    '259900',
    '139100',
    '29',
    '1399',
    '325004',
    '268000',
    '1511',
    '1622',
    '271200',
    '236',
    '181100',
    '281100',
    '2612',
    '1073',
    '273300',
    '2640',
    '161003',
    '20',
    '324000',
    '205900',
    '109200',
    '106',
    '325',
    '2342',
    '102000',
    '231100',
    '241',
    '1711',
    '243300',
    '161001',
    '3109',
    '265203',
    '2511',
    '131',
    '235100',
    '279',
    '1051',
    '105200',
    '259200',
    '2014',
    '191',
    '141402',
    '139500',
    '205200',
    '264',
    '1092',
    '257300',
    '211000',
    '245100',
    '289500',
    '3314',
    '2841',
    '282500',
    '2896',
    '323',
    '2660',
    '2432',
    '152',
    '259300',
    '2920',
    '132003',
    '139400',
    '142000',
    '13',
    '301100',
    '331200',
    '244300',
    '2443',
    '251200',
    '2222',
    '2611',
    '242',
    '2364',
    '139902',
    '3230',
    '257200',
    '2599',
    '302',
    '2369',
    '1414',
    '2790',
    '182000',
    '3099',
    '321100',
    '171200',
    '181400',
    '110200',
    '259',
    '107200',
    '2931',
    '108400',
    '284',
    '266',
    '293',
    '236200',
    '2451',
    '283',
    '255',
    '256100',
    '1396',
    '275',
    '262000',
    '233200',
    '2341',
    '2752',
    '141303',
    '141100',
    '2894',
    '206000',
    '105102',
    '233',
    '1310',
    '162302',
    '2594',
    '289',
    '237',
    '310100',
    '3101',
    '331500',
    '289200',
    '236500',
    '139903',
    '2013',
    '105103',
    '282',
    '2221',
    '234',
    '1031',
    '3299',
    '261200',
    '3311',
    '202000',
    '1061',
    '151',
    '181302',
    '275100',
    '3250',
    '2910',
    '239100',
    '302000',
    '236400',
    '2343',
    '1394',
    '2363',
    '110300',
    '14',
    '3103',
    '26',
    '253',
    '265202',
    '2391',
    '232',
    '281300',
    '304000',
    '293100',
    '108100',
    '139201',
    '108201',
    '3091',
    '103200',
    '203000',
    '2512',
    '2399',
    '3092',
    '172100',
    '1200',
    '139',
    '273100',
    '332',
    '235200',
    '1102',
    '255000',
    '252100',
    '222',
    '162400',
    '236900',
    '322',
    '2849',
    '332000',
    '1512',
    '2891',
    '2630',
    '1041',
    '2529',
    '2441',
    '2313',
    '245300',
    '2012',
    '2312',
    '2434',
    '2712',
    '291',
    '2320',
    '108300',
    '221100',
    '281400',
    '263',
    '1920',
    '244400',
    '3040',
    '301200',
    '28',
    '2370',
    '282100',
    '105',
    '237000',
    '331600',
    '110600',
    '1013',
    '2680',
    '172300',
    '265204',
    '289400',
    '2592',
    '141200',
    '221',
    '2452',
    '3313',
    '103100',
    '222200',
    '1811',
    '152000',
    '107',
    '1431',
    '108600',
    '204',
    '204100',
    '271100',
    '239902',
    '2042',
    '1085',
    '1723',
    '273200',
    '244600',
    '139202',
    '17',
    '304',
    '141900',
    '2223',
    '2812',
    '325003',
    '265',
    '252',
    '2017',
    '274',
    '3315',
    '281500',
    '267000',
    '331700',
    '2814',
    '141403',
    '282900',
    '212000',
    '2442',
    '141',
    '181203',
    '2319',
    '2892',
    '143100',
    '2561',
    '325002',
    '329900',
    '108900',
    '222300',
    '205100',
    '281200',
    '1624',
    '2053',
    '2824',
    '24',
    '284100',
    '233100',
    '3320',
    '131003',
    '243',
    '181201',
    '289100',
    '3291',
    '3102',
    '2830',
    '10',
    '236100',
    '161002',
    '1107',
    '2211',
    '2365',
    '133',
    '279000',
    '15',
    '257',
    '331100',
    '2041',
    '2311',
    '239901',
    '104100',
    '139203',
    '23',
    '201700',
    '325001',
    '32',
    '132',
    '243400',
    '244500',
    '2349',
    '12',
    '205',
    '321202',
    '310300',
    '1722',
    '172200',
    '2344',
    '265201',
    '3011',
    '243200',
    '251',
    '2895',
    '244100',
    '274000',
    '2052',
    '1105',
    '141301',
    '3212',
    '201500',
    '203',
    '110100',
    '110500',
    '141302',
    '142',
    '282300',
    '172',
    '2815',
    '1712',
    '282200',
    '289901',
    '2051',
    '201100',
    '143',
    '1621',
    '139901',
    '1042',
    '292000',
    '301',
    '2571',
    '2444',
    '192',
    '102',
    '331300',
    '2020',
    '267',
    '2431',
    '1012',
    '2651',
    '30',
    '2652',
    '131002',
    '162200',
    '1420',
    '161',
    '251100',
    '329100',
    '139300',
    '2229',
    '2314',
    '162100',
    '2573',
    '2011',
    '2591',
    '221900',
    '222100',
    '1032',
    '2720',
    '2732',
    '171100',
    '256201',
    '110400',
    '321201',
    '2110',
    '283000',
    '212',
    '310',
    '1629',
    '3020',
    '245',
    '322000',
    '261',
    '3012',
    '321300',
    '202',
    '1812',
    '211',
    '2351',
    '33',
    '1419',
    '2521',
    '1011',
    '2932',
    '131004',
    '1052',
    '265100',
    '2562',
    '289300',
    '201200',
    '1084',
    '31',
    '132002',
    '1395',
    '101',
    '21',
    '1820',
    '331400',
    '108202',
    '2362',
    '252900',
    '1081',
    '1330',
    '2550',
    '2825',
    '105101',
    '172900',
    '253000',
    '1520',
    '309202',
    '3317',
    '110',
    '162301',
    '1724',
    '206',
    '151100',
    '1721',
    '2593',
    '231900',
    '16',
    '2829',
    '201600',
    '108',
    '172400',
    '234100',
    '3316',
    '1106',
    '141401',
    '2219',
    '2530',
    '3030',
    '275200',
    '171',
    '139600',
    '1089',
    '1393',
    '104200',
    '292',
    '1814',
    '309900',
    '244200',
    '289600',
    '324',
    '191000',
    '271',
    '244',
    '107300',
    '1101',
    '132001',
    '2731',
    '25',
    '2332',
    '3240',
    '110700',
    '2822',
    '2751',
    '266000',
    '242000',
    '201',
    '264000',
    '106100',
    '231300',
    '3220',
    '1104',
    '181301',
    '289902',
    '2015',
    '2620',
    '108500',
    '2540',
    '2823',
    '259400',
    '1412',
    '2893',
    '2445',
    '284900',
    '291000',
    '2433',
    '309',
    '231200',
    '236300',
    '201400',
    '18',
    '234300',
    '182',
    '1623',
    '234400',
    '151200',
    '293200',
    '1439',
    '1320',
    '181202',
    '257100',
    '2453',
    '1391',
    '2711',
    '2572',
    '235',
    '1392',
    '162',
    '241000',
    '256202',
    '2454',
    '309201',
    '234200',
    '254',
    '1020',
    '3312',
    '1729',
    '2811',
    '1813',
    '131001',
    '133000',
    '101300',
    '1072',
    '1610',
    '3211',
    '2352',
    '303',
    '2670',
    '1062',
    '2059',
    '101100',
    '321',
    '103',
    '109100',
    '243100',
    '268',
    '120000',
    '256203',
    '272000',
    '261100',
    '1103',
    '254000',
    '234900',
    '2420',
    '181204',
    '120',
    '231',
    '2120',
    '3213',
    '107100',
    '273',
    '1039',
    '310200',
    '201300',
    '2016',
    '103900',
    '259100',
    '204200',
    '3513',
    '351',
    '352',
    '3523',
    '353',
    '352200',
    '3514',
    '3522',
    '3530',
    '352300',
    '3512',
    '3521',
    '352100',
    '353000',
    '35',
    '351200',
    '351100',
    '351300',
    '3511',
    '351400',
    '3900',
    '360000',
    '390',
    '3821',
    '37',
    '360',
    '382',
    '383100',
    '39',
    '383',
    '370',
    '382100',
    '370000',
    '38',
    '383200',
    '3831',
    '390000',
    '3832',
    '3700',
    '3811',
    '381100',
    '381200',
    '381',
    '36',
    '3822',
    '3812',
    '3600',
    '382200',
    '412001',
    '4331',
    '433401',
    '4120',
    '4322',
    '412002',
    '4321',
    '4299',
    '439101',
    '432203',
    '4399',
    '432201',
    '433200',
    '432',
    '432204',
    '432901',
    '433',
    '431',
    '432100',
    '439102',
    '439901',
    '422200',
    '411',
    '4212',
    '4313',
    '411000',
    '421100',
    '421',
    '4311',
    '429',
    '4221',
    '4339',
    '4391',
    '421200',
    '433303',
    '4312',
    '433100',
    '4213',
    '42',
    '4110',
    '439905',
    '433302',
    '439103',
    '4222',
    '422100',
    '4334',
    '431100',
    '412003',
    '431300',
    '421300',
    '4332',
    '4211',
    '4291',
    '4329',
    '433403',
    '433301',
    '439902',
    '412',
    '439903',
    '429900',
    '433402',
    '439',
    '412004',
    '432902',
    '422',
    '41',
    '43',
    '432202',
    '439904',
    '4333',
    '431200',
    '433900',
    '429100',
    '451102',
    '475400',
    '4633',
    '4690',
    '4724',
    '464500',
    '453100',
    '451101',
    '4777',
    '4771',
    '467100',
    '475901',
    '477300',
    '461600',
    '477102',
    '4782',
    '474300',
    '477502',
    '466200',
    '477',
    '4651',
    '461300',
    '476402',
    '4663',
    '461700',
    '479100',
    '462200',
    '472401',
    '4779',
    '4646',
    '4619',
    '477805',
    '466400',
    '4722',
    '464400',
    '461100',
    '4752',
    '463100',
    '461500',
    '463900',
    '461200',
    '467200',
    '4635',
    '464802',
    '4742',
    '476300',
    '4669',
    '4778',
    '4761',
    '464601',
    '4661',
    '463300',
    '464902',
    '4634',
    '477201',
    '464901',
    '4612',
    '464700',
    '4639',
    '46',
    '475903',
    '4789',
    '477202',
    '4754',
    '464201',
    '4616',
    '4623',
    '4622',
    '464801',
    '471901',
    '4649',
    '473',
    '472500',
    '477104',
    '467301',
    '4631',
    '4730',
    '463200',
    '4642',
    '464602',
    '477902',
    '466',
    '477105',
    '4511',
    '4637',
    '464',
    '4645',
    '462',
    '467701',
    '461400',
    '467400',
    '4776',
    '4662',
    '477901',
    '471902',
    '4677',
    '478900',
    '451',
    '4675',
    '4638',
    '452002',
    '4614',
    '478200',
    '472901',
    '466500',
    '464303',
    '451902',
    '476',
    '4719',
    '4531',
    '466900',
    '475100',
    '451901',
    '478100',
    '4644',
    '4743',
    '471104',
    '464202',
    '4652',
    '474100',
    '471',
    '475201',
    '4741',
    '476202',
    '467303',
    '469',
    '4774',
    '4615',
    '472600',
    '466300',
    '4520',
    '4643',
    '4772',
    '462400',
    '477700',
    '471105',
    '4617',
    '4540',
    '463402',
    '4674',
    '471103',
    '4765',
    '454000',
    '477601',
    '477806',
    '467',
    '474200',
    '453200',
    '465101',
    '466600',
    '479900',
    '466100',
    '477602',
    '477801',
    '462300',
    '452001',
    '4613',
    '476401',
    '475202',
    '4671',
    '4611',
    '464906',
    '475300',
    '463500',
    '454',
    '477802',
    '4725',
    '461900',
    '472200',
    '461800',
    '4729',
    '467600',
    '4721',
    '474',
    '45',
    '476500',
    '453',
    '477803',
    '471101',
    '465200',
    '4773',
    '4753',
    '4664',
    '4647',
    '4636',
    '479',
    '476201',
    '47',
    '463700',
    '461',
    '4648',
    '4632',
    '4532',
    '472',
    '467302',
    '473000',
    '472902',
    '4726',
    '4799',
    '4759',
    '4676',
    '464905',
    '4621',
    '4711',
    '464903',
    '464100',
    '477103',
    '4624',
    '472100',
    '472300',
    '467500',
    '464904',
    '463401',
    '4775',
    '463600',
    '462100',
    '475',
    '464301',
    '4672',
    '465',
    '4781',
    '477400',
    '477101',
    '4666',
    '464302',
    '4763',
    '4641',
    '477603',
    '4751',
    '472402',
    '476100',
    '465102',
    '4618',
    '4762',
    '452',
    '463800',
    '4673',
    '4764',
    '477501',
    '463',
    '478',
    '471102',
    '4519',
    '469000',
    '477804',
    '4791',
    '475902',
    '4665',
    '467702',
    '4723',
    '5222',
    '531000',
    '494100',
    '491000',
    '522300',
    '491',
    '532000',
    '5110',
    '502000',
    '522200',
    '493902',
    '5224',
    '531',
    '4920',
    '5310',
    '494',
    '522100',
    '502',
    '522400',
    '512100',
    '5221',
    '4942',
    '495000',
    '5010',
    '4950',
    '495',
    '532',
    '49',
    '5223',
    '4939',
    '493100',
    '493901',
    '503000',
    '522',
    '493903',
    '4910',
    '52',
    '50',
    '51',
    '511000',
    '521000',
    '5210',
    '512200',
    '511',
    '493',
    '504',
    '493200',
    '4932',
    '492',
    '4941',
    '5320',
    '5229',
    '5030',
    '512',
    '5020',
    '521',
    '53',
    '504000',
    '494200',
    '4931',
    '5121',
    '501000',
    '501',
    '503',
    '522900',
    '492000',
    '5122',
    '5040',
    '551002',
    '56',
    '552002',
    '561002',
    '5629',
    '551',
    '559000',
    '5590',
    '563',
    '551003',
    '561001',
    '5610',
    '551001',
    '561003',
    '562',
    '562900',
    '552',
    '552003',
    '553002',
    '553001',
    '553',
    '5530',
    '552001',
    '559',
    '5630',
    '5510',
    '563001',
    '55',
    '562100',
    '563002',
    '561',
    '5621',
    '5520',
    '6203',
    '6311',
    '5912',
    '6190',
    '581300',
    '620200',
    '619',
    '5813',
    '582',
    '6120',
    '611000',
    '591200',
    '592000',
    '592',
    '5812',
    '59',
    '5920',
    '620900',
    '613000',
    '631',
    '620',
    '581900',
    '639900',
    '612',
    '602000',
    '581400',
    '5811',
    '6010',
    '639',
    '619000',
    '620100',
    '6391',
    '5829',
    '5913',
    '5821',
    '60',
    '6202',
    '61',
    '6312',
    '631100',
    '6399',
    '6130',
    '591300',
    '591400',
    '5819',
    '639100',
    '581200',
    '581100',
    '58',
    '591',
    '612000',
    '6201',
    '631200',
    '601',
    '611',
    '601000',
    '620300',
    '613',
    '6209',
    '5914',
    '5911',
    '6110',
    '582900',
    '62',
    '581',
    '5814',
    '6020',
    '591100',
    '582100',
    '602',
    '63',
    '6420',
    '6629',
    '643000',
    '649901',
    '663002',
    '641910',
    '641',
    '662100',
    '649202',
    '661',
    '651204',
    '641909',
    '662901',
    '663',
    '6630',
    '641904',
    '6530',
    '66',
    '661100',
    '6520',
    '641901',
    '649903',
    '663001',
    '6622',
    '661200',
    '642002',
    '643',
    '662200',
    '641911',
    '653000',
    '651202',
    '642',
    '6619',
    '641100',
    '652',
    '649201',
    '6512',
    '649',
    '65',
    '641903',
    '6492',
    '6499',
    '651',
    '641907',
    '6621',
    '662902',
    '641912',
    '649100',
    '651203',
    '6611',
    '651100',
    '641902',
    '6491',
    '6419',
    '661900',
    '641905',
    '64',
    '641906',
    '6511',
    '6430',
    '6411',
    '651201',
    '653',
    '642001',
    '6612',
    '662',
    '649902',
    '641908',
    '652000',
    '6832',
    '681000',
    '682',
    '6820',
    '6810',
    '683100',
    '681',
    '682001',
    '68',
    '6831',
    '682002',
    '683200',
    '683',
    '7120',
    '741001',
    '741002',
    '701002',
    '711205',
    '7022',
    '7320',
    '7111',
    '749000',
    '722000',
    '711102',
    '749',
    '6910',
    '72',
    '7500',
    '7220',
    '701',
    '71',
    '7219',
    '742',
    '7010',
    '7430',
    '732000',
    '69',
    '7211',
    '7311',
    '711204',
    '691001',
    '711201',
    '741003',
    '731200',
    '711',
    '742002',
    '7112',
    '7420',
    '702200',
    '721100',
    '70',
    '73',
    '731',
    '722',
    '711101',
    '691',
    '692',
    '7410',
    '692000',
    '701001',
    '711103',
    '702',
    '743',
    '7021',
    '691002',
    '702100',
    '721',
    '741',
    '731100',
    '7490',
    '721900',
    '711203',
    '7312',
    '750',
    '711202',
    '732',
    '74',
    '712000',
    '75',
    '712',
    '6920',
    '743000',
    '750000',
    '742001',
    '7729',
    '773200',
    '773500',
    '783',
    '8110',
    '783000',
    '813000',
    '78',
    '821100',
    '791100',
    '781',
    '812202',
    '812',
    '773900',
    '80',
    '774000',
    '799',
    '812100',
    '7820',
    '7830',
    '7735',
    '771200',
    '7733',
    '822',
    '7722',
    '772200',
    '7739',
    '8122',
    '803000',
    '77',
    '799001',
    '782000',
    '7911',
    '823',
    '773',
    '82',
    '791200',
    '7721',
    '829',
    '823000',
    '772100',
    '803',
    '773400',
    '8030',
    '7734',
    '8292',
    '772900',
    '811',
    '821902',
    '773300',
    '829900',
    '802',
    '812201',
    '8010',
    '782',
    '7740',
    '79',
    '8020',
    '813',
    '7731',
    '791',
    '822000',
    '7810',
    '801000',
    '771100',
    '811000',
    '7712',
    '802000',
    '8130',
    '8121',
    '7990',
    '801',
    '829100',
    '7912',
    '8230',
    '821',
    '8211',
    '774',
    '829200',
    '772',
    '81',
    '773100',
    '8129',
    '8299',
    '8291',
    '7711',
    '781000',
    '7732',
    '771',
    '821901',
    '8219',
    '799002',
    '8220',
    '812900',
    '8411',
    '8425',
    '841300',
    '842500',
    '842400',
    '8413',
    '841100',
    '842',
    '8422',
    '842301',
    '842201',
    '8412',
    '8430',
    '8423',
    '842302',
    '842100',
    '84',
    '841',
    '8421',
    '843000',
    '8424',
    '841200',
    '843',
    '842202',
    '852003',
    '85',
    '853200',
    '854202',
    '8551',
    '853101',
    '853',
    '853103',
    '855',
    '8552',
    '8531',
    '8553',
    '852002',
    '855902',
    '855200',
    '856',
    '852',
    '8510',
    '856000',
    '855903',
    '8542',
    '855904',
    '853102',
    '854',
    '8560',
    '854100',
    '851000',
    '855901',
    '854201',
    '852001',
    '854203',
    '8532',
    '851',
    '8520',
    '855100',
    '855300',
    '8559',
    '8541',
    '872001',
    '879003',
    '862300',
    '889901',
    '862',
    '879002',
    '8790',
    '8623',
    '869004',
    '86',
    '8899',
    '879001',
    '8610',
    '861002',
    '873',
    '889',
    '861001',
    '862200',
    '873002',
    '869006',
    '88',
    '869001',
    '872',
    '869',
    '8730',
    '8621',
    '879',
    '8720',
    '861',
    '8891',
    '862100',
    '8710',
    '869002',
    '8690',
    '871',
    '869007',
    '8622',
    '8810',
    '872002',
    '881000',
    '869003',
    '889902',
    '889100',
    '87',
    '869005',
    '873001',
    '881',
    '871000',
    '920',
    '9003',
    '9329',
    '9312',
    '900301',
    '9001',
    '9004',
    '920000',
    '900',
    '9102',
    '932100',
    '900200',
    '90',
    '9200',
    '9319',
    '9321',
    '92',
    '9103',
    '910200',
    '932900',
    '900102',
    '9311',
    '931300',
    '91',
    '910100',
    '932',
    '910',
    '93',
    '9313',
    '931200',
    '9101',
    '910300',
    '931',
    '931900',
    '9002',
    '900400',
    '910400',
    '9104',
    '900303',
    '931100',
    '900101',
    '900302',
    '960102',
    '949903',
    '960201',
    '949',
    '9601',
    '960',
    '9602',
    '960401',
    '952200',
    '9521',
    '94',
    '952',
    '952100',
    '9525',
    '96',
    '9529',
    '941100',
    '9511',
    '951200',
    '9492',
    '960900',
    '949200',
    '949901',
    '9522',
    '952400',
    '9420',
    '9491',
    '949102',
    '95',
    '960101',
    '9499',
    '951100',
    '941',
    '9609',
    '960300',
    '949902',
    '949904',
    '941200',
    '9412',
    '960402',
    '9524',
    '9523',
    '952300',
    '942000',
    '9604',
    '952900',
    '9512',
    '9603',
    '960202',
    '949101',
    '9411',
    '951',
    '942',
    '952500',
    '9700',
    '981000',
    '9810',
    '97',
    '982',
    '981',
    '970',
    '98',
    '970000',
    '982000',
    '9820',
    '990',
    '990001',
    '9900',
    '990002',
    '99',
    '990003'
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
-- Name: premature_release_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.premature_release_reason AS ENUM (
    'negative_test',
    'immune',
    'vaccinated'
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
-- Name: school_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.school_type AS ENUM (
    'preschool',
    'primary_school',
    'secondary_school',
    'cantonal_school_or_other_middle_school',
    'professional_school',
    'university_or_college',
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
    'inconclusive',
    'negative'
);


--
-- Name: vaccine_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.vaccine_type AS ENUM (
    'pfizer',
    'moderna',
    'janssen',
    'astra_zeneca',
    'sinopharm',
    'sinovac',
    'covaxin',
    'novavax',
    'other'
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
    'migration',
    'detect_no_reaction_cases_job',
    'detect_unchanged_cases_job'
);


--
-- Name: visit_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.visit_reason AS ENUM (
    'student',
    'professor',
    'employee',
    'visitor',
    'other'
);


--
-- Name: array_disjoint(anyarray, anyarray); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.array_disjoint(a anyarray, b anyarray) RETURNS anyarray
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
    SELECT
      ARRAY(
        SELECT
          UNNEST(a)
        EXCEPT
        SELECT
          UNNEST(b)
      )
  $$;


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
-- Name: check_user_authorization_on_import(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_user_authorization_on_import() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (
    NEW.default_tracer_uuid IS NOT NULL AND
    NOT EXISTS (
      SELECT * FROM user_grants
      WHERE user_grants.tenant_uuid = NEW.tenant_uuid AND
        user_grants.user_uuid = NEW.default_tracer_uuid AND
        user_grants.role = 'tracer'
    )
  ) THEN
    RAISE check_violation
      USING
        MESSAGE = 'user does not have tracer authorization on tenant',
        HINT = 'A user with a tracer authorization should be set into default_tracer_uuid.',
        CONSTRAINT = 'default_tracer_uuid',
        COLUMN = 'default_tracer_uuid',
        TABLE = TG_TABLE_NAME,
        SCHEMA = TG_TABLE_SCHEMA;
  END IF;
  IF (
    NEW.default_supervisor_uuid IS NOT NULL AND
    NOT EXISTS (
      SELECT * FROM user_grants
      WHERE user_grants.tenant_uuid = NEW.tenant_uuid AND
        user_grants.user_uuid = NEW.default_supervisor_uuid AND
        user_grants.role = 'supervisor'
    )
  ) THEN
    RAISE check_violation
      USING
        MESSAGE = 'user does not have supervisor authorization on tenant',
        HINT = 'A user with a tracer authorization should be set into default_supervisor_uuid.',
        CONSTRAINT = 'default_supervisor_uuid',
        COLUMN = 'default_supervisor_uuid',
        TABLE = TG_TABLE_NAME,
        SCHEMA = TG_TABLE_SCHEMA;
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
-- Name: import_close(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.import_close() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    OPEN_ROWS INTEGER;
  BEGIN
  UPDATE
    imports AS update_import
    SET closed_at = CASE
      WHEN totals.count = 0 AND update_import.closed_at IS NULL THEN NOW()
      WHEN totals.count = 0 AND update_import.closed_at IS NOT NULL THEN update_import.closed_at
      ELSE NULL
    END
    FROM (
      SELECT
        select_import.uuid AS uuid,
        COUNT(import_rows.uuid) AS count
      FROM imports select_import
      LEFT JOIN import_rows
        ON select_import.uuid = import_rows.import_uuid AND
          import_rows.status = 'pending'
      WHERE select_import.uuid IN (OLD.import_uuid, NEW.import_uuid)
      GROUP BY select_import.uuid
    ) AS totals
    WHERE totals.uuid = update_import.uuid;

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
-- Name: possible_index_submission_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.possible_index_submission_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      AFFECTED_TRACER_UUID UUID;
    BEGIN
      SELECT tracer_uuid INTO AFFECTED_TRACER_UUID FROM cases WHERE uuid = NEW.case_uuid;
      IF NOT AFFECTED_TRACER_UUID IS NULL AND (AFFECTED_TRACER_UUID <> (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid OR CURRENT_SETTING('versioning.originator_id') = '') THEN
        INSERT INTO notifications
          (uuid, body, user_uuid, inserted_at, updated_at) VALUES
          (
            MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
            JSONB_BUILD_OBJECT('__type__', 'possible_index_submitted', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'case_uuid', NEW.case_uuid, 'possible_index_submission_uuid', NEW.uuid),
            AFFECTED_TRACER_UUID,
            NOW(),
            NOW()
          );
      END IF;

      RETURN NEW;
    END
  $$;


--
-- Name: premature_release_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.premature_release_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      TRACER_UUID UUID;
    BEGIN
      SELECT
      INTO TRACER_UUID cases.tracer_uuid
      FROM cases
      WHERE
        cases.uuid = NEW.case_uuid AND
        cases.tracer_uuid IS NOT NULL AND
        (
          NULLIF(CURRENT_SETTING('versioning.originator_id', true), '') IS NULL OR
          cases.tracer_uuid <> (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid
        );

      IF FOUND THEN
        INSERT INTO notifications
          (uuid, body, user_uuid, inserted_at, updated_at) VALUES
          (
            MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
            JSONB_BUILD_OBJECT('__type__', 'premature_release', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'premature_release_uuid', NEW.uuid),
            TRACER_UUID,
            NOW(),
            NOW()
          );
      END IF;

      RETURN NEW;
    END
  $$;


--
-- Name: premature_release_update_case(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.premature_release_update_case() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      UPDATE
        cases AS update_case
      SET
        phases = ARRAY_REPLACE(
          update_case.phases,
          subquery.search_phase,
          subquery.update_phase
        ),
        status = 'done'
      FROM
        (
          SELECT
            uuid,
            phase AS search_phase,
            JSONB_SET(
              JSONB_SET(
                JSONB_SET(
                  phase,
                  '{send_automated_close_email}',
                  TO_JSONB(FALSE)
                ),
                '{end}',
                TO_JSONB(CURRENT_DATE)
              ),
              '{details,end_reason}',
              TO_JSONB(NEW.reason)
            ) AS update_phase
          FROM cases
          CROSS JOIN UNNEST(cases.phases) AS phase
          WHERE uuid = NEW.case_uuid AND (phase->>'uuid')::uuid = new.phase_uuid
        ) AS subquery
      WHERE update_case.uuid = subquery.uuid;

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
    related_visit_uuid uuid,
    unknown_organisation jsonb,
    unknown_division jsonb,
    CONSTRAINT kind_other_required CHECK (
CASE
    WHEN (kind = 'other'::public.affiliation_kind) THEN (kind_other IS NOT NULL)
    ELSE (kind_other IS NULL)
END),
    CONSTRAINT organisation_info_required CHECK (((organisation_uuid IS NOT NULL) OR (unknown_organisation IS NOT NULL) OR (comment IS NOT NULL)))
);


--
-- Name: auto_tracings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auto_tracings (
    uuid uuid NOT NULL,
    current_step public.auto_tracing_step,
    last_completed_step public.auto_tracing_step,
    problems public.auto_tracing_problem[] DEFAULT ARRAY[]::public.auto_tracing_problem[],
    solved_problems public.auto_tracing_problem[] DEFAULT ARRAY[]::public.auto_tracing_problem[],
    covid_app boolean,
    employed boolean,
    case_uuid uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    scholar boolean,
    has_contact_persons boolean,
    unsolved_problems public.auto_tracing_problem[] GENERATED ALWAYS AS (public.array_disjoint(problems, solved_problems)) STORED,
    propagator_known boolean,
    transmission_known boolean,
    propagator jsonb,
    transmission_uuid uuid,
    started_at timestamp without time zone NOT NULL,
    has_flown boolean,
    flights jsonb[],
    has_travelled_in_risk_country boolean,
    possible_transmission jsonb,
    travels jsonb[]
);


--
-- Name: case_phase_dates; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.case_phase_dates AS
SELECT
    NULL::uuid AS case_uuid,
    NULL::uuid AS phase_uuid,
    NULL::date AS first_test_date,
    NULL::date AS last_test_date,
    NULL::date AS case_first_known_date,
    NULL::date AS case_last_known_date;


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
-- Name: import_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_rows (
    uuid uuid NOT NULL,
    data jsonb NOT NULL,
    corrected jsonb,
    identifiers jsonb NOT NULL,
    status public.case_import_status DEFAULT 'pending'::public.case_import_status,
    import_uuid uuid NOT NULL,
    case_uuid uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imports (
    uuid uuid NOT NULL,
    type public.case_import_type NOT NULL,
    closed_at timestamp without time zone,
    change_date timestamp without time zone NOT NULL,
    tenant_uuid uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_tracer_uuid uuid,
    default_supervisor_uuid uuid,
    filename character varying(255)
);


--
-- Name: mutations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mutations (
    uuid uuid NOT NULL,
    name character varying(255),
    ism_code integer,
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
    updated_at timestamp without time zone NOT NULL,
    pinned boolean DEFAULT false
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
    type_other character varying(255),
    school_type public.school_type
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
    profession_category public.noga_code,
    profession_category_main public.noga_section,
    fulltext tsvector GENERATED ALWAYS AS (((((((to_tsvector('german'::regconfig, (uuid)::text) || to_tsvector('german'::regconfig, (human_readable_id)::text)) || to_tsvector('german'::regconfig, (COALESCE(first_name, ''::character varying))::text)) || to_tsvector('german'::regconfig, (COALESCE(last_name, ''::character varying))::text)) || public.jsonb_array_to_tsvector_with_path(contact_methods, '$[*]."value"'::jsonpath)) || public.jsonb_array_to_tsvector_with_path(external_references, '$[*]."value"'::jsonpath)) || COALESCE(jsonb_to_tsvector('german'::regconfig, address, '["all"]'::jsonb), to_tsvector('german'::regconfig, ''::text)))) STORED,
    is_vaccinated boolean,
    convalescent_externally boolean DEFAULT false NOT NULL
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
-- Name: premature_releases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.premature_releases (
    uuid uuid NOT NULL,
    reason public.premature_release_reason NOT NULL,
    phase_uuid uuid NOT NULL,
    case_uuid uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: risk_countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_countries (
    uuid uuid NOT NULL,
    country text NOT NULL
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
    case_management_enabled boolean DEFAULT false,
    from_email character varying(255),
    sedex_export_enabled boolean DEFAULT false NOT NULL,
    sedex_export_configuration jsonb,
    template_parameters jsonb,
    subdivision character varying(255),
    country character varying(255),
    contact_phone character varying(255),
    contact_email character varying(255),
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
    comment text,
    type public.case_phase_possible_index_type DEFAULT 'contact_person'::public.case_phase_possible_index_type NOT NULL
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
-- Name: statistics_new_registered_cases_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_new_registered_cases_per_day AS
 WITH phases AS (
         SELECT cases.tenant_uuid,
            cases.person_uuid,
            ((phase.phase -> 'details'::text) ->> '__type__'::text) AS count_type,
            COALESCE(((phase.phase ->> 'inserted_at'::text))::date, (cases.inserted_at)::date) AS count_date,
            (cases.status = 'first_contact'::public.case_status) AS first_contact
           FROM (public.cases
             CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
        )
 SELECT tenants.uuid AS tenant_uuid,
    type.type,
    (date.date)::date AS date,
    phases.first_contact,
    count(DISTINCT phases.*) AS count
   FROM (((generate_series(LEAST((( SELECT min(phases_1.count_date) AS min
           FROM phases phases_1))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN unnest(ARRAY['index'::text, 'possible_index'::text]) type(type))
     CROSS JOIN public.tenants)
     LEFT JOIN phases ON (((tenants.uuid = phases.tenant_uuid) AND (date.date = phases.count_date) AND (phases.count_type = type.type))))
  GROUP BY phases.first_contact, date.date, type.type, tenants.uuid
  ORDER BY phases.first_contact, ((date.date)::date), type.type, tenants.uuid
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
-- Name: tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tests (
    uuid uuid NOT NULL,
    tested_at date,
    laboratory_reported_at date,
    kind public.test_kind NOT NULL,
    result public.test_result,
    sponsor jsonb,
    reporting_unit jsonb,
    case_uuid uuid NOT NULL,
    reference character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    mutation_uuid uuid
);


--
-- Name: vaccination_shots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vaccination_shots (
    uuid uuid NOT NULL,
    vaccine_type public.vaccine_type NOT NULL,
    vaccine_type_other character varying(255),
    date date NOT NULL,
    person_uuid uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT vaccine_type_other_required CHECK (
CASE
    WHEN (vaccine_type = 'other'::public.vaccine_type) THEN (vaccine_type_other IS NOT NULL)
    ELSE (vaccine_type_other IS NULL)
END)
);


--
-- Name: vaccination_shot_validity; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.vaccination_shot_validity AS
 SELECT vaccination_shots.person_uuid,
    vaccination_shots.uuid AS vaccination_shot_uuid,
    daterange(((vaccination_shots.date + '22 days'::interval))::date, ((vaccination_shots.date + '1 year 22 days'::interval))::date) AS range
   FROM public.vaccination_shots
  WHERE (vaccination_shots.vaccine_type = 'janssen'::public.vaccine_type)
UNION
 SELECT result.person_uuid,
    result.vaccination_shot_uuid,
    result.range
   FROM ( SELECT vaccination_shots.person_uuid,
            vaccination_shots.uuid AS vaccination_shot_uuid,
                CASE
                    WHEN (row_number() OVER (PARTITION BY vaccination_shots.person_uuid ORDER BY vaccination_shots.date) >= 2) THEN daterange(vaccination_shots.date, ((vaccination_shots.date + '1 year'::interval))::date)
                    ELSE NULL::daterange
                END AS range
           FROM public.vaccination_shots
          WHERE (vaccination_shots.vaccine_type = ANY (ARRAY['pfizer'::public.vaccine_type, 'moderna'::public.vaccine_type, 'astra_zeneca'::public.vaccine_type]))) result
  WHERE (result.range IS NOT NULL)
UNION
 SELECT result.person_uuid,
    result.vaccination_shot_uuid,
    result.range
   FROM ( SELECT vaccination_shots.person_uuid,
            vaccination_shots.uuid AS vaccination_shot_uuid,
                CASE
                    WHEN (row_number() OVER (PARTITION BY vaccination_shots.person_uuid, vaccination_shots.vaccine_type ORDER BY vaccination_shots.date) >= 2) THEN daterange(vaccination_shots.date, ((vaccination_shots.date + '1 year'::interval))::date)
                    ELSE NULL::daterange
                END AS range
           FROM public.vaccination_shots
          WHERE (vaccination_shots.vaccine_type = ANY (ARRAY['astra_zeneca'::public.vaccine_type, 'pfizer'::public.vaccine_type, 'moderna'::public.vaccine_type, 'sinopharm'::public.vaccine_type, 'sinovac'::public.vaccine_type, 'covaxin'::public.vaccine_type]))) result
  WHERE (result.range IS NOT NULL)
UNION
 SELECT result.person_uuid,
    result.vaccination_shot_uuid,
    result.range
   FROM ( SELECT vaccination_shots.person_uuid,
            vaccination_shots.uuid AS vaccination_shot_uuid,
                CASE
                    WHEN (row_number() OVER (PARTITION BY vaccination_shots.person_uuid, vaccination_shots.vaccine_type ORDER BY vaccination_shots.date) = 1) THEN daterange(vaccination_shots.date, ((vaccination_shots.date + '1 year'::interval))::date)
                    ELSE NULL::daterange
                END AS range
           FROM (public.people
             JOIN public.vaccination_shots ON ((vaccination_shots.person_uuid = people.uuid)))
          WHERE (people.convalescent_externally AND (vaccination_shots.vaccine_type = ANY (ARRAY['astra_zeneca'::public.vaccine_type, 'pfizer'::public.vaccine_type, 'moderna'::public.vaccine_type, 'sinopharm'::public.vaccine_type, 'sinovac'::public.vaccine_type, 'covaxin'::public.vaccine_type])))) result
  WHERE (result.range IS NOT NULL)
UNION
 SELECT result.person_uuid,
    result.vaccination_shot_uuid,
    result.range
   FROM ( SELECT people.uuid AS person_uuid,
            vaccination_shots.uuid AS vaccination_shot_uuid,
                CASE
                    WHEN ((row_number() OVER (PARTITION BY vaccination_shots.person_uuid, vaccination_shots.vaccine_type ORDER BY vaccination_shots.date) = 1) AND (vaccination_shots.date > ((case_phase_dates.case_last_known_date + '28 days'::interval))::date)) THEN daterange(vaccination_shots.date, ((vaccination_shots.date + '1 year'::interval))::date)
                    WHEN ((row_number() OVER (PARTITION BY vaccination_shots.person_uuid, vaccination_shots.vaccine_type ORDER BY vaccination_shots.date) = 1) AND ((case_phase_dates.case_last_known_date >= ((vaccination_shots.date + '28 days'::interval))::date) AND (case_phase_dates.case_last_known_date <= ((vaccination_shots.date + '1 year'::interval))::date))) THEN daterange(case_phase_dates.case_last_known_date, ((case_phase_dates.case_last_known_date + '1 year'::interval))::date)
                    ELSE NULL::daterange
                END AS range
           FROM ((((public.people
             JOIN public.vaccination_shots ON ((vaccination_shots.person_uuid = people.uuid)))
             JOIN public.cases ON ((cases.person_uuid = people.uuid)))
             JOIN LATERAL unnest(cases.phases) index_phases(index_phases) ON ((((index_phases.index_phases -> 'details'::text) ->> '__type__'::text) = 'index'::text)))
             JOIN public.case_phase_dates ON (((case_phase_dates.case_uuid = cases.uuid) AND (case_phase_dates.phase_uuid = ((index_phases.index_phases ->> 'uuid'::text))::uuid))))
          WHERE (vaccination_shots.vaccine_type = ANY (ARRAY['astra_zeneca'::public.vaccine_type, 'pfizer'::public.vaccine_type, 'moderna'::public.vaccine_type, 'sinopharm'::public.vaccine_type, 'sinovac'::public.vaccine_type, 'covaxin'::public.vaccine_type]))) result
  WHERE (result.range IS NOT NULL)
  WITH NO DATA;


--
-- Name: statistics_vaccination_breakthroughs_per_day; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.statistics_vaccination_breakthroughs_per_day AS
 WITH last_positive_test_dates AS (
         SELECT tests.case_uuid,
            max(COALESCE(tests.tested_at, tests.laboratory_reported_at)) AS test_date
           FROM public.tests
          GROUP BY tests.case_uuid
        ), case_count_dates AS (
         SELECT cases.uuid,
            cases.tenant_uuid,
            cases.person_uuid,
            COALESCE(last_positive_test_dates.test_date, ((cases.clinical ->> 'symptom_start'::text))::date, ((index_phases.index_phases ->> 'order_date'::text))::date, ((index_phases.index_phases ->> 'inserted_at'::text))::date, (cases.inserted_at)::date) AS count_date
           FROM ((public.cases
             JOIN LATERAL unnest(cases.phases) index_phases(index_phases) ON ((((index_phases.index_phases -> 'details'::text) ->> '__type__'::text) = 'index'::text)))
             LEFT JOIN last_positive_test_dates ON ((last_positive_test_dates.case_uuid = cases.uuid)))
        )
 SELECT tenants.uuid AS tenant_uuid,
    (date.date)::date AS date,
    count(DISTINCT vaccination_shot_validity.person_uuid) AS count
   FROM (((generate_series(LEAST((( SELECT min(case_count_dates_1.count_date) AS min
           FROM case_count_dates case_count_dates_1))::timestamp without time zone, (CURRENT_DATE - '1 year'::interval)), (CURRENT_DATE)::timestamp without time zone, '1 day'::interval) date(date)
     CROSS JOIN public.tenants)
     LEFT JOIN case_count_dates ON (((tenants.uuid = case_count_dates.tenant_uuid) AND (date.date = case_count_dates.count_date))))
     LEFT JOIN public.vaccination_shot_validity ON (((vaccination_shot_validity.range @> (date.date)::date) AND (vaccination_shot_validity.person_uuid = case_count_dates.person_uuid))))
  GROUP BY date.date, tenants.uuid
  ORDER BY ((date.date)::date), tenants.uuid
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
-- Name: visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visits (
    uuid uuid NOT NULL,
    reason public.visit_reason,
    other_reason character varying(255),
    last_visit_at date,
    case_uuid uuid NOT NULL,
    organisation_uuid uuid,
    unknown_organisation jsonb,
    division_uuid uuid,
    unknown_division jsonb,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: affiliations affiliations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliations
    ADD CONSTRAINT affiliations_pkey PRIMARY KEY (uuid);


--
-- Name: auto_tracings auto_tracings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auto_tracings
    ADD CONSTRAINT auto_tracings_pkey PRIMARY KEY (uuid);


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
-- Name: import_rows import_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_rows
    ADD CONSTRAINT import_rows_pkey PRIMARY KEY (uuid);


--
-- Name: imports imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (uuid);


--
-- Name: mutations mutations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutations
    ADD CONSTRAINT mutations_pkey PRIMARY KEY (uuid);


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
-- Name: premature_releases premature_releases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.premature_releases
    ADD CONSTRAINT premature_releases_pkey PRIMARY KEY (uuid);


--
-- Name: risk_countries risk_countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_countries
    ADD CONSTRAINT risk_countries_pkey PRIMARY KEY (uuid);


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
-- Name: tests tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_pkey PRIMARY KEY (uuid);


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
-- Name: vaccination_shots vaccination_shots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vaccination_shots
    ADD CONSTRAINT vaccination_shots_pkey PRIMARY KEY (uuid);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (uuid);


--
-- Name: visits visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (uuid);


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
-- Name: import_rows_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX import_rows_case_uuid_index ON public.import_rows USING btree (case_uuid);


--
-- Name: import_rows_data_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX import_rows_data_index ON public.import_rows USING btree (data);


--
-- Name: import_rows_import_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX import_rows_import_uuid_index ON public.import_rows USING btree (import_uuid);


--
-- Name: imports_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX imports_tenant_uuid_index ON public.imports USING btree (tenant_uuid);


--
-- Name: mutations_ism_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mutations_ism_code_index ON public.mutations USING btree (ism_code);


--
-- Name: notes_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_case_uuid_index ON public.notes USING btree (case_uuid);


--
-- Name: notes_case_uuid_pinned_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_case_uuid_pinned_index ON public.notes USING btree (case_uuid, pinned);


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
-- Name: premature_releases_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX premature_releases_case_uuid_index ON public.premature_releases USING btree (case_uuid);


--
-- Name: resource_views_request_id_action_resource_table_resource_pk_ind; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX resource_views_request_id_action_resource_table_resource_pk_ind ON public.resource_views USING btree (request_id, action, resource_table, resource_pk);


--
-- Name: risk_countries_country_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX risk_countries_country_index ON public.risk_countries USING btree (country);


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
-- Name: statistics_new_registered_cases_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_new_registered_cases_per_day_date_index ON public.statistics_new_registered_cases_per_day USING btree (date);


--
-- Name: statistics_new_registered_cases_per_day_first_contact_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_new_registered_cases_per_day_first_contact_index ON public.statistics_new_registered_cases_per_day USING btree (first_contact);


--
-- Name: statistics_new_registered_cases_per_day_tenant_uuid_date_type_f; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_new_registered_cases_per_day_tenant_uuid_date_type_f ON public.statistics_new_registered_cases_per_day USING btree (tenant_uuid, date, type, first_contact);


--
-- Name: statistics_new_registered_cases_per_day_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_new_registered_cases_per_day_tenant_uuid_index ON public.statistics_new_registered_cases_per_day USING btree (tenant_uuid);


--
-- Name: statistics_new_registered_cases_per_day_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_new_registered_cases_per_day_type_index ON public.statistics_new_registered_cases_per_day USING btree (type);


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
-- Name: statistics_vaccination_breakthroughs_per_day_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_vaccination_breakthroughs_per_day_date_index ON public.statistics_vaccination_breakthroughs_per_day USING btree (date);


--
-- Name: statistics_vaccination_breakthroughs_per_day_tenant_uuid_date_i; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX statistics_vaccination_breakthroughs_per_day_tenant_uuid_date_i ON public.statistics_vaccination_breakthroughs_per_day USING btree (tenant_uuid, date);


--
-- Name: statistics_vaccination_breakthroughs_per_day_tenant_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statistics_vaccination_breakthroughs_per_day_tenant_uuid_index ON public.statistics_vaccination_breakthroughs_per_day USING btree (tenant_uuid);


--
-- Name: tenants_iam_domain_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tenants_iam_domain_index ON public.tenants USING btree (iam_domain);


--
-- Name: tests_case_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tests_case_uuid_index ON public.tests USING btree (case_uuid);


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
-- Name: vaccination_shot_validity_person_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vaccination_shot_validity_person_uuid_index ON public.vaccination_shot_validity USING btree (person_uuid);


--
-- Name: vaccination_shot_validity_range_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vaccination_shot_validity_range_index ON public.vaccination_shot_validity USING btree (range);


--
-- Name: vaccination_shot_validity_vaccination_shot_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vaccination_shot_validity_vaccination_shot_uuid_index ON public.vaccination_shot_validity USING btree (vaccination_shot_uuid);


--
-- Name: vaccination_shot_validity_vaccination_shot_uuid_range_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vaccination_shot_validity_vaccination_shot_uuid_range_index ON public.vaccination_shot_validity USING btree (vaccination_shot_uuid, range);


--
-- Name: vaccination_shots_person_uuid_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vaccination_shots_person_uuid_date_index ON public.vaccination_shots USING btree (person_uuid, date);


--
-- Name: vaccination_shots_person_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vaccination_shots_person_uuid_index ON public.vaccination_shots USING btree (person_uuid);


--
-- Name: vaccination_shots_person_uuid_vaccine_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vaccination_shots_person_uuid_vaccine_type_index ON public.vaccination_shots USING btree (person_uuid, vaccine_type);


--
-- Name: vaccination_shots_vaccine_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vaccination_shots_vaccine_type_index ON public.vaccination_shots USING btree (vaccine_type);


--
-- Name: versions_item_pk_item_table_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_item_pk_item_table_index ON public.versions USING btree (item_pk, item_table);


--
-- Name: versions_originator_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_originator_id_index ON public.versions USING btree (originator_id);


--
-- Name: case_phase_dates _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.case_phase_dates AS
 SELECT cases.uuid AS case_uuid,
    ((phase.phase ->> 'uuid'::text))::uuid AS phase_uuid,
    LEAST(min(tests.tested_at), min(tests.laboratory_reported_at)) AS first_test_date,
    GREATEST(max(tests.tested_at), max(tests.laboratory_reported_at)) AS last_test_date,
    (COALESCE((LEAST(min(tests.tested_at), min(tests.laboratory_reported_at), ((cases.clinical ->> 'symptom_start'::text))::date, ((phase.phase ->> 'start'::text))::date))::timestamp without time zone, (((phase.phase ->> 'order_date'::text))::date)::timestamp without time zone, (((phase.phase ->> 'inserted_at'::text))::date)::timestamp without time zone, cases.inserted_at))::date AS case_first_known_date,
    (COALESCE((GREATEST(max(tests.tested_at), max(tests.laboratory_reported_at), ((cases.clinical ->> 'symptom_start'::text))::date, ((phase.phase ->> 'end'::text))::date))::timestamp without time zone, (((phase.phase ->> 'order_date'::text))::date)::timestamp without time zone, (((phase.phase ->> 'inserted_at'::text))::date)::timestamp without time zone, cases.inserted_at))::date AS case_last_known_date
   FROM ((public.cases
     CROSS JOIN LATERAL unnest(cases.phases) phase(phase))
     LEFT JOIN public.tests ON (((tests.case_uuid = cases.uuid) AND (tests.result = 'positive'::public.test_result))))
  GROUP BY cases.uuid, phase.phase;


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
-- Name: auto_tracings auto_tracing_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER auto_tracing_versioning_delete AFTER DELETE ON public.auto_tracings FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: auto_tracings auto_tracing_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER auto_tracing_versioning_insert AFTER INSERT ON public.auto_tracings FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: auto_tracings auto_tracing_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER auto_tracing_versioning_update AFTER UPDATE ON public.auto_tracings FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


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
-- Name: imports check_user_authorization_on_import; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_user_authorization_on_import BEFORE INSERT OR UPDATE ON public.imports FOR EACH ROW EXECUTE FUNCTION public.check_user_authorization_on_import();


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
-- Name: import_rows import_rows_import_close_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER import_rows_import_close_delete AFTER DELETE ON public.import_rows FOR EACH ROW EXECUTE FUNCTION public.import_close();


--
-- Name: import_rows import_rows_import_close_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER import_rows_import_close_insert AFTER INSERT ON public.import_rows FOR EACH ROW EXECUTE FUNCTION public.import_close();


--
-- Name: import_rows import_rows_import_close_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER import_rows_import_close_update AFTER UPDATE OF status, import_uuid ON public.import_rows FOR EACH ROW EXECUTE FUNCTION public.import_close();


--
-- Name: import_rows import_rows_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER import_rows_versioning_delete AFTER DELETE ON public.import_rows FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: import_rows import_rows_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER import_rows_versioning_insert AFTER INSERT ON public.import_rows FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: import_rows import_rows_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER import_rows_versioning_update AFTER UPDATE ON public.import_rows FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: imports imports_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER imports_versioning_delete AFTER DELETE ON public.imports FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: imports imports_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER imports_versioning_insert AFTER INSERT ON public.imports FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: imports imports_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER imports_versioning_update AFTER UPDATE ON public.imports FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


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
-- Name: possible_index_submissions possible_index_submission_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER possible_index_submission_changed AFTER INSERT OR UPDATE ON public.possible_index_submissions FOR EACH ROW EXECUTE FUNCTION public.possible_index_submission_notification();


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
-- Name: premature_releases premature_releases_created_notification; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER premature_releases_created_notification AFTER INSERT OR UPDATE ON public.premature_releases FOR EACH ROW EXECUTE FUNCTION public.premature_release_notification();


--
-- Name: premature_releases premature_releases_created_update_case; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER premature_releases_created_update_case AFTER INSERT OR UPDATE ON public.premature_releases FOR EACH ROW EXECUTE FUNCTION public.premature_release_update_case();


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
-- Name: tests tests_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tests_versioning_delete AFTER DELETE ON public.tests FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: tests tests_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tests_versioning_insert AFTER INSERT ON public.tests FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: tests tests_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tests_versioning_update AFTER UPDATE ON public.tests FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


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
-- Name: vaccination_shots vaccination_shots_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER vaccination_shots_versioning_delete AFTER DELETE ON public.vaccination_shots FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: vaccination_shots vaccination_shots_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER vaccination_shots_versioning_insert AFTER INSERT ON public.vaccination_shots FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: vaccination_shots vaccination_shots_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER vaccination_shots_versioning_update AFTER UPDATE ON public.vaccination_shots FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


--
-- Name: visits visit_versioning_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER visit_versioning_delete AFTER DELETE ON public.visits FOR EACH ROW EXECUTE FUNCTION public.versioning_delete();


--
-- Name: visits visit_versioning_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER visit_versioning_insert AFTER INSERT ON public.visits FOR EACH ROW EXECUTE FUNCTION public.versioning_insert();


--
-- Name: visits visit_versioning_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER visit_versioning_update AFTER UPDATE ON public.visits FOR EACH ROW EXECUTE FUNCTION public.versioning_update();


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
-- Name: auto_tracings auto_tracings_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auto_tracings
    ADD CONSTRAINT auto_tracings_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: auto_tracings auto_tracings_transmission_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auto_tracings
    ADD CONSTRAINT auto_tracings_transmission_uuid_fkey FOREIGN KEY (transmission_uuid) REFERENCES public.transmissions(uuid) ON DELETE SET NULL;


--
-- Name: cases cases_person_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_person_uuid_fkey FOREIGN KEY (person_uuid) REFERENCES public.people(uuid) ON DELETE CASCADE;


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
-- Name: import_rows import_rows_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_rows
    ADD CONSTRAINT import_rows_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE SET NULL;


--
-- Name: import_rows import_rows_import_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_rows
    ADD CONSTRAINT import_rows_import_uuid_fkey FOREIGN KEY (import_uuid) REFERENCES public.imports(uuid) ON DELETE CASCADE;


--
-- Name: imports imports_default_supervisor_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT imports_default_supervisor_uuid_fkey FOREIGN KEY (default_supervisor_uuid) REFERENCES public.users(uuid);


--
-- Name: imports imports_default_tracer_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT imports_default_tracer_uuid_fkey FOREIGN KEY (default_tracer_uuid) REFERENCES public.users(uuid);


--
-- Name: imports imports_tenant_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT imports_tenant_uuid_fkey FOREIGN KEY (tenant_uuid) REFERENCES public.tenants(uuid) ON DELETE CASCADE;


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
-- Name: premature_releases premature_releases_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.premature_releases
    ADD CONSTRAINT premature_releases_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


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
-- Name: tests tests_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: tests tests_mutation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_mutation_uuid_fkey FOREIGN KEY (mutation_uuid) REFERENCES public.mutations(uuid) ON DELETE SET NULL;


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
-- Name: vaccination_shots vaccination_shots_person_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vaccination_shots
    ADD CONSTRAINT vaccination_shots_person_uuid_fkey FOREIGN KEY (person_uuid) REFERENCES public.people(uuid);


--
-- Name: versions versions_originator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_originator_id_fkey FOREIGN KEY (originator_id) REFERENCES public.users(uuid) ON DELETE SET NULL;


--
-- Name: visits visits_case_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_case_uuid_fkey FOREIGN KEY (case_uuid) REFERENCES public.cases(uuid) ON DELETE CASCADE;


--
-- Name: visits visits_division_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_division_uuid_fkey FOREIGN KEY (division_uuid) REFERENCES public.divisions(uuid) ON DELETE SET NULL;


--
-- Name: visits visits_organisation_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_organisation_uuid_fkey FOREIGN KEY (organisation_uuid) REFERENCES public.organisations(uuid) ON DELETE CASCADE;


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
INSERT INTO public."schema_migrations" (version) VALUES (20210429143724);
INSERT INTO public."schema_migrations" (version) VALUES (20210511110755);
INSERT INTO public."schema_migrations" (version) VALUES (20210521094209);
INSERT INTO public."schema_migrations" (version) VALUES (20210527153512);
INSERT INTO public."schema_migrations" (version) VALUES (20210611101143);
INSERT INTO public."schema_migrations" (version) VALUES (20210616130134);
INSERT INTO public."schema_migrations" (version) VALUES (20210623093359);
INSERT INTO public."schema_migrations" (version) VALUES (20210628141251);
INSERT INTO public."schema_migrations" (version) VALUES (20210713101131);
INSERT INTO public."schema_migrations" (version) VALUES (20210719100312);
INSERT INTO public."schema_migrations" (version) VALUES (20210719122928);
INSERT INTO public."schema_migrations" (version) VALUES (20210728145003);
INSERT INTO public."schema_migrations" (version) VALUES (20210819125948);
INSERT INTO public."schema_migrations" (version) VALUES (20210825152555);
INSERT INTO public."schema_migrations" (version) VALUES (20210827100229);
INSERT INTO public."schema_migrations" (version) VALUES (20210827112204);
INSERT INTO public."schema_migrations" (version) VALUES (20210830092733);
INSERT INTO public."schema_migrations" (version) VALUES (20210830093531);
INSERT INTO public."schema_migrations" (version) VALUES (20210830101202);
INSERT INTO public."schema_migrations" (version) VALUES (20210830102654);
INSERT INTO public."schema_migrations" (version) VALUES (20210830111044);
INSERT INTO public."schema_migrations" (version) VALUES (20210830114650);
INSERT INTO public."schema_migrations" (version) VALUES (20210830121213);
INSERT INTO public."schema_migrations" (version) VALUES (20210830125241);
INSERT INTO public."schema_migrations" (version) VALUES (20210830133345);
INSERT INTO public."schema_migrations" (version) VALUES (20210831165759);
INSERT INTO public."schema_migrations" (version) VALUES (20210901135323);
INSERT INTO public."schema_migrations" (version) VALUES (20210914093248);
INSERT INTO public."schema_migrations" (version) VALUES (20210915111748);
INSERT INTO public."schema_migrations" (version) VALUES (20210916113825);
INSERT INTO public."schema_migrations" (version) VALUES (20210922180638);
INSERT INTO public."schema_migrations" (version) VALUES (20211010093048);
INSERT INTO public."schema_migrations" (version) VALUES (20211012150640);
INSERT INTO public."schema_migrations" (version) VALUES (20211012170218);
INSERT INTO public."schema_migrations" (version) VALUES (20211012203320);
INSERT INTO public."schema_migrations" (version) VALUES (20211012213226);
INSERT INTO public."schema_migrations" (version) VALUES (20211015083935);
INSERT INTO public."schema_migrations" (version) VALUES (20211103105723);
INSERT INTO public."schema_migrations" (version) VALUES (20211117230115);
INSERT INTO public."schema_migrations" (version) VALUES (20211130150556);
INSERT INTO public."schema_migrations" (version) VALUES (20211201143102);
INSERT INTO public."schema_migrations" (version) VALUES (20211202171922);
INSERT INTO public."schema_migrations" (version) VALUES (20211208094932);
INSERT INTO public."schema_migrations" (version) VALUES (20211220095509);
INSERT INTO public."schema_migrations" (version) VALUES (20211223101132);
INSERT INTO public."schema_migrations" (version) VALUES (20211227102423);
INSERT INTO public."schema_migrations" (version) VALUES (20211230121753);
INSERT INTO public."schema_migrations" (version) VALUES (20220103114333);
INSERT INTO public."schema_migrations" (version) VALUES (20220103114334);
INSERT INTO public."schema_migrations" (version) VALUES (20220111093904);
INSERT INTO public."schema_migrations" (version) VALUES (20220117182843);
INSERT INTO public."schema_migrations" (version) VALUES (20220117220433);
INSERT INTO public."schema_migrations" (version) VALUES (20220119201604);
