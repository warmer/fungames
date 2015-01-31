SELECT
    ((g.attendance)-5187.521484375)/4920.76123046875, ((g.awayDistance)-813.939758300781)/930.7900390625, ((g.homeDistance)-112.617622375488)/631.443664550781, ((log((g.awayDistance+1)*g.attendance))-14.245810508728)/1.70639026165009, ((log((g.homeDistance+1)*g.attendance))-8.6079044342041)/1.99831783771515, ((oppAllow.Ast)-0.0971684828400612)/0.966971755027771, ((oppAllow.Blk)-0.00366165419109166)/0.38516765832901, ((oppAllow.FGA)--0.0263950880616903)/1.24657356739044, ((oppAllow.FGM)-0.130617424845695)/0.900740265846252, ((oppAllow.FTA)-0.0938068106770515)/1.47258353233337, ((oppAllow.FTM)-0.099862702190876)/1.12464153766632, ((oppAllow.Off)-0.0124114453792572)/0.494747221469879, ((oppAllow.PF)--0.11249778419733)/0.80519688129425, ((oppAllow.Reb)-0.111368030309677)/1.02157199382782, ((oppAllow.Stl)-0.0347081422805786)/0.460124373435974, ((oppAllow.TPA)--0.018545238301158)/0.957767069339752, ((oppAllow.TPM)-0.0379068702459335)/0.494581371545792, ((oppAllow.TRN)--0.000394235568819568)/0.735553324222565, ((oppAvg.Ast)-12.6966695785522)/1.76074147224426, ((oppAvg.Blk)-3.60339426994324)/1.12650322914124, ((oppAvg.FGA)-55.3992309570313)/3.1294572353363, ((oppAvg.FGM)-24.452564239502)/1.90345919132233, ((oppAvg.FTA)-22.4206981658936)/2.8437328338623, ((oppAvg.FTM)-15.6458625793457)/2.11405229568481, ((oppAvg.Off)-9.28547096252441)/1.54462146759033, ((oppAvg.PF)-19.2158737182617)/1.7816264629364, ((oppAvg.Reb)-31.4956817626953)/2.59716105461121, ((oppAvg.Stl)-6.18934631347656)/1.14760971069336, ((oppAvg.TPA)-18.2560272216797)/2.97538375854492, ((oppAvg.TPM)-6.30629920959473)/1.24556577205658, ((oppAvg.TRN)-12.1657266616821)/1.45316421985626, ((teamAllow.Ast)-0.0379585325717926)/0.924378156661987, ((teamAllow.Blk)--0.0121135301887989)/0.363699615001678, ((teamAllow.FGA)-0.0493874102830887)/1.1810714006424, ((teamAllow.FGM)-0.0325933732092381)/0.850799798965454, ((teamAllow.FTA)--0.0690044239163399)/1.40525949001312, ((teamAllow.FTM)--0.0415441580116749)/1.05976700782776, ((teamAllow.Off)-0.00259873364120722)/0.457924127578735, ((teamAllow.PF)--0.0594966970384121)/0.735977053642273, ((teamAllow.Reb)-0.0289538986980915)/0.989291489124298, ((teamAllow.Stl)-0.0104702934622765)/0.435762703418732, ((teamAllow.TPA)-0.0387703999876976)/0.91023051738739, ((teamAllow.TPM)-0.0270415507256985)/0.469530314207077, ((teamAllow.TRN)-0.0362332835793495)/0.672839760780334, ((teamAvg.Ast)-12.8445911407471)/1.78750264644623, ((teamAvg.Blk)-3.72841691970825)/1.14879763126373, ((teamAvg.FGA)-55.4446105957031)/3.09061622619629, ((teamAvg.FGM)-24.5804214477539)/1.85914576053619, ((teamAvg.FTA)-22.5865020751953)/2.79626846313477, ((teamAvg.FTM)-15.7612686157227)/2.07902884483337, ((teamAvg.Off)-9.3882417678833)/1.56903982162476, ((teamAvg.PF)-19.070140838623)/1.77354502677917, ((teamAvg.Reb)-31.8278465270996)/2.58636045455933, ((teamAvg.Stl)-6.19021224975586)/1.18296825885773, ((teamAvg.TPA)-18.1630458831787)/2.93048620223999, ((teamAvg.TPM)-6.29776620864868)/1.23994648456573, ((teamAvg.TRN)-12.0126237869263)/1.43314778804779
FROM
    tblteamgameaverages AS teamAvg,
    tblteamgameaverages AS oppAvg,
    tblteamgameavgopptendencies as teamAllow,
    tblteamgameavgopptendencies as oppAllow,
    (   SELECT
              ACOS(SIN(RADIANS(location.latitude))*SIN(RADIANS(team.latitude))+COS(RADIANS(location.latitude))*COS(RADIANS(team.latitude))*COS(RADIANS(location.longitude) - RADIANS(team.longitude)))*6731 as homeDistance
            , ACOS(SIN(RADIANS(location.latitude))*SIN(RADIANS(opp.latitude))+COS(RADIANS(location.latitude))*COS(RADIANS(opp.latitude))*COS(RADIANS(location.longitude) - RADIANS(opp.longitude)))*6731 as awayDistance
            , 600 as attendance
        FROM
            tblteams AS team,
            tblteams AS opp,
            tbllocation as location
        WHERE
            team.yahooID='ncf' AND
            opp.yahooID='wheelock' AND
            location.locationID=190
    ) as g
WHERE 
    'ncf'=teamAvg.teamID AND
    'wheelock'=oppAvg.teamID AND
    'ncf'=teamAllow.teamID AND
    'wheelock'=oppAllow.teamID AND
    teamAllow.Home = 2 AND
    oppAllow.Home = 2
GROUP BY teamAllow.teamID, oppAllow.teamID, teamAvg.teamID, oppAvg.teamID
;

SELECT
    ((g.attendance)-5187.521484375)/4920.76123046875, ((g.awayDistance)-813.939758300781)/930.7900390625, ((g.homeDistance)-112.617622375488)/631.443664550781, ((log((g.awayDistance+1)*g.attendance))-14.245810508728)/1.70639026165009, ((log((g.homeDistance+1)*g.attendance))-8.6079044342041)/1.99831783771515, ((oppAllow.Ast)-0.0949271246790886)/0.957362413406372, ((oppAllow.Blk)-0.00650246860459447)/0.382794737815857, ((oppAllow.FGA)--0.0315428413450718)/1.26403343677521, ((oppAllow.FGM)-0.127763047814369)/0.900040209293365, ((oppAllow.FTA)-0.107092536985874)/1.47118091583252, ((oppAllow.FTM)-0.11026719212532)/1.12761104106903, ((oppAllow.Off)-0.0149711091071367)/0.493260979652405, ((oppAllow.PF)--0.119778543710709)/0.784753799438477, ((oppAllow.Reb)-0.113140590488911)/1.03261160850525, ((oppAllow.Stl)-0.036092858761549)/0.463660001754761, ((oppAllow.TPA)--0.0179381854832172)/0.969700038433075, ((oppAllow.TPM)-0.0361227691173553)/0.494040101766586, ((oppAllow.TRN)-0.00605654623359442)/0.726279377937317, ((oppAvg.Ast)-12.6971187591553)/1.76327013969421, ((oppAvg.Blk)-3.60363459587097)/1.12706434726715, ((oppAvg.FGA)-55.3865203857422)/3.14069628715515, ((oppAvg.FGM)-24.4477615356445)/1.91471934318542, ((oppAvg.FTA)-22.437463760376)/2.85700845718384, ((oppAvg.FTM)-15.6644344329834)/2.13050937652588, ((oppAvg.Off)-9.28291034698486)/1.5492445230484, ((oppAvg.PF)-19.2121620178223)/1.77891230583191, ((oppAvg.Reb)-31.498384475708)/2.60499119758606, ((oppAvg.Stl)-6.17923545837402)/1.14242279529572, ((oppAvg.TPA)-18.2615718841553)/2.97759127616882, ((oppAvg.TPM)-6.30846929550171)/1.24554407596588, ((oppAvg.TRN)-12.1670169830322)/1.45087254047394, ((teamAllow.Ast)-0.0368989333510399)/0.916243851184845, ((teamAllow.Blk)--0.0103705022484064)/0.362341672182083, ((teamAllow.FGA)-0.0506598465144634)/1.17899286746979, ((teamAllow.FGM)-0.0289153885096312)/0.849828004837036, ((teamAllow.FTA)--0.0611579790711403)/1.40236294269562, ((teamAllow.FTM)--0.0360191240906715)/1.0602343082428, ((teamAllow.Off)-0.00526154087856412)/0.455312728881836, ((teamAllow.PF)--0.0655975937843323)/0.726861953735352, ((teamAllow.Reb)-0.0353536941111088)/0.986521065235138, ((teamAllow.Stl)-0.00964113418012857)/0.435006022453308, ((teamAllow.TPA)-0.0424043834209442)/0.910397529602051, ((teamAllow.TPM)-0.0262928381562233)/0.466938614845276, ((teamAllow.TRN)-0.0375893115997314)/0.667247653007507, ((teamAvg.Ast)-12.845832824707)/1.78744757175446, ((teamAvg.Blk)-3.72955417633057)/1.1475830078125, ((teamAvg.FGA)-55.4403228759766)/3.09480214118958, ((teamAvg.FGM)-24.5784511566162)/1.86618030071259, ((teamAvg.FTA)-22.5969429016113)/2.80192971229553, ((teamAvg.FTM)-15.7703523635864)/2.08687424659729, ((teamAvg.Off)-9.38914585113525)/1.56871926784515, ((teamAvg.PF)-19.0647354125977)/1.768878698349, ((teamAvg.Reb)-31.8312911987305)/2.58710265159607, ((teamAvg.Stl)-6.18900108337402)/1.18505036830902, ((teamAvg.TPA)-18.1685543060303)/2.9326639175415, ((teamAvg.TPM)-6.29861879348755)/1.23966634273529, ((teamAvg.TRN)-12.0136518478394)/1.43302989006042
FROM
    tblteamgameaverages AS teamAvg,
    tblteamgameaverages AS oppAvg,
    tblteamgameavgopptendencies as teamAllow,
    tblteamgameavgopptendencies as oppAllow,
    (   SELECT
              ACOS(SIN(RADIANS(location.latitude))*SIN(RADIANS(team.latitude))+COS(RADIANS(location.latitude))*COS(RADIANS(team.latitude))*COS(RADIANS(location.longitude) - RADIANS(team.longitude)))*6731 as homeDistance
            , ACOS(SIN(RADIANS(location.latitude))*SIN(RADIANS(opp.latitude))+COS(RADIANS(location.latitude))*COS(RADIANS(opp.latitude))*COS(RADIANS(location.longitude) - RADIANS(opp.longitude)))*6731 as awayDistance
            , 1682 as attendance
        FROM
            tblteams AS team,
            tblteams AS opp,
            tbllocation as location
        WHERE
            team.yahooID='aav' AND
            opp.yahooID='lyon' AND
            location.locationID=16
    ) as g
WHERE 
    'aav'=teamAvg.teamID AND
    'lyon'=oppAvg.teamID AND
    'aav'=teamAllow.teamID AND
    'lyon'=oppAllow.teamID AND
    teamAllow.Home = 2 AND
    oppAllow.Home = 2
GROUP BY teamAllow.teamID, oppAllow.teamID, teamAvg.teamID, oppAvg.teamID
;




SELECT * FROM tblgames WHERE homeTeamYahooID='abilene_christian' OR visitingTeamYahooID='abilene_christian';
SELECT * FROM tblteams WHERE team in('Abilene Christian',
'Incarnate Word',
'Mass-Lowell',
'Grand Canyon');

SELECT * FROM tblteams WHERE yahooID in ('gra','san');

UPDATE tblgames as g SET g.homeTeamYahooID='abi' WHERE g.homeTeamYahooID='abilene_christian';
UPDATE tblgames as g SET g.visitingTeamYahooID='abi' WHERE g.visitingTeamYahooID='abilene_christian';

UPDATE tblgames as g SET g.homeTeamYahooID='gra' WHERE g.homeTeamYahooID='grand_canyon';
UPDATE tblgames as g SET g.visitingTeamYahooID='gra' WHERE g.visitingTeamYahooID='grand_canyon';

UPDATE tblgames as g SET g.homeTeamYahooID='inc' WHERE g.homeTeamYahooID='incarnate_word';
UPDATE tblgames as g SET g.visitingTeamYahooID='inc' WHERE g.visitingTeamYahooID='incarnate_word';

UPDATE tblgames as g SET g.homeTeamYahooID='mas' WHERE g.homeTeamYahooID='massachusetts_lowell';
UPDATE tblgames as g SET g.visitingTeamYahooID='mas' WHERE g.visitingTeamYahooID='abilene_christian';

UPDATE tblgames as g SET g.homeTeamYahooID='' WHERE g.homeTeamYahooID='lyon';
UPDATE tblgames as g SET g.visitingTeamYahooID='' WHERE g.visitingTeamYahooID='lyon';

UPDATE tblgames as g SET g.homeTeamYahooID='' WHERE g.homeTeamYahooID='wheelock';
UPDATE tblgames as g SET g.visitingTeamYahooID='' WHERE g.visitingTeamYahooID='wheelock';

UPDATE tblgames as g SET g.homeTeamYahooID='' WHERE g.homeTeamYahooID='newberry';
UPDATE tblgames as g SET g.visitingTeamYahooID='' WHERE g.visitingTeamYahooID='newberry';

UPDATE tblgames as g SET g.homeTeamYahooID='' WHERE LENGTH(g.homeTeamYahooID) > 3;
UPDATE tblgames as g SET g.visitingTeamYahooID='' WHERE LENGTH(g.visitingTeamYahooID)>3;

