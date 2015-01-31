SELECT
    *
FROM tblgames AS g, tblteams as t, tbllocation as gloc, tbllocation as tloc, tblteamgameaverages AS teamAvg, tblteamgameaverages AS oppAvg, tblteamgameavgopptendencies as teamAllow, tblteamgameavgopptendencies as oppAllow, (select 0 as home) as h
WHERE 
    gloc.locationID=g.locationID AND
    tloc.locationID=t.locationID AND
    t.yahooID=g.visitingTeamYahooID AND
    g.visitingTeamYahooID=teamAvg.teamID AND
    g.homeTeamYahooID=oppAvg.teamID AND
    g.visitingTeamYahooID=teamAllow.teamID AND
    g.homeTeamYahooID=oppAllow.teamID AND
    teamAllow.Home=h.home AND
    oppAllow.Home=(1 - h.home)
GROUP BY teamAllow.teamID, oppAllow.teamID, teamAvg.teamID, oppAvg.teamID, g.gameID
;

SELECT
    *
FROM tblgames AS g, tbllocation as gloc
WHERE 
    gloc.locationID=g.locationID

;

SELECT * FROM tblgames ORDER BY gameID;

SELECT count(*), TRIM(SUBSTRING_INDEX(tblgames.location, ',', -2)) AS loc from tblgames group by loc;

SELECT count(*),TRIM(SUBSTRING_INDEX(tblgames.location, ',', -1)) as state FROM tblgames group by state;

SELECT count(*),TRIM(SUBSTRING_INDEX(location, ',', -1)) as state FROM tbllocation group by state;

SELECT * FROM tbltournamentteam_2013;
SELECT * FROM tbltournamentgames_2013;

UPDATE
   tblgames, tbllocation
SET
   tblgames.locationID=tbllocation.locationID
WHERE
   TRIM(SUBSTRING_INDEX(tblgames.location, ',', -2))=tbllocation.location;

SELECT count(*) as num, location FROM tblgames WHERE locationID IS NULL GROUP BY location ORDER BY num DESC;
SELECT * FROM tblgames WHERE locationID IS NULL;

INSERT INTO `nodiffn1_mm2011`.`tbllocation`
(
`location`,
`latitude`,
`longitude`)
VALUES
(
"Lowell, MA",
42.653992, -71.324759
);
SELECT * FROM tbllocation WHERE location = "Frisco, TX";

UPDATE
   tblgames as g,
   tblteams as h,
   tblteams as a,
   tbllocation as gloc,
   tbllocation as hloc,
   tbllocation as aloc
SET
   g.homeDistance=ACOS(SIN(RADIANS(gloc.latitude))*SIN(RADIANS(hloc.latitude))+COS(RADIANS(gloc.latitude))*COS(RADIANS(hloc.latitude))*COS(RADIANS(gloc.longitude) - RADIANS(hloc.longitude)))*6731,
   g.awayDistance=ACOS(SIN(RADIANS(gloc.latitude))*SIN(RADIANS(aloc.latitude))+COS(RADIANS(gloc.latitude))*COS(RADIANS(aloc.latitude))*COS(RADIANS(gloc.longitude) - RADIANS(aloc.longitude)))*6731
WHERE
   g.locationID=gloc.locationID AND
   h.yahooID=g.homeTeamYahooID AND
   a.yahooID=g.visitingTeamYahooID AND
   h.locationID=hloc.locationID AND
   a.locationID=aloc.locationID;

INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Min) (SELECT Name, yahooID, teamID, @NewMin := AVG(Min) FROM tblteamgamestats WHERE Min >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Min=@NewMin;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, FGM) (SELECT Name, yahooID, teamID, @NewFGM := AVG(FGM) FROM tblteamgamestats WHERE FGM >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE FGM=@NewFGM;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, FGA) (SELECT Name, yahooID, teamID, @NewFGA := AVG(FGA) FROM tblteamgamestats WHERE FGA >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE FGA=@NewFGA;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, TPM) (SELECT Name, yahooID, teamID, @NewTPM := AVG(TPM) FROM tblteamgamestats WHERE TPM >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE TPM=@NewTPM;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, TPA) (SELECT Name, yahooID, teamID, @NewTPA := AVG(TPA) FROM tblteamgamestats WHERE TPA >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE TPA=@NewTPA;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, FTM) (SELECT Name, yahooID, teamID, @NewFTM := AVG(FTM) FROM tblteamgamestats WHERE FTM >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE FTM=@NewFTM;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, FTA) (SELECT Name, yahooID, teamID, @NewFTA := AVG(FTA) FROM tblteamgamestats WHERE FTA >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE FTA=@NewFTA;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Off) (SELECT Name, yahooID, teamID, @NewOff := AVG(Off) FROM tblteamgamestats WHERE Off >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Off=@NewOff;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Reb) (SELECT Name, yahooID, teamID, @NewReb := AVG(Reb) FROM tblteamgamestats WHERE Reb >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Reb=@NewReb;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Ast) (SELECT Name, yahooID, teamID, @NewAst := AVG(Ast) FROM tblteamgamestats WHERE Ast >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Ast=@NewAst;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, TRN) (SELECT Name, yahooID, teamID, @NewTRN := AVG(TRN) FROM tblteamgamestats WHERE TRN >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE TRN=@NewTRN;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Stl) (SELECT Name, yahooID, teamID, @NewStl := AVG(Stl) FROM tblteamgamestats WHERE Stl >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Stl=@NewStl;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Blk) (SELECT Name, yahooID, teamID, @NewBlk := AVG(Blk) FROM tblteamgamestats WHERE Blk >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Blk=@NewBlk;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, PF) (SELECT Name, yahooID, teamID, @NewPF := AVG(PF) FROM tblteamgamestats WHERE PF >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE PF=@NewPF;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Pts) (SELECT Name, yahooID, teamID, @NewPts := AVG(Pts) FROM tblteamgamestats WHERE Pts >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Pts=@NewPts;
INSERT INTO tblteamgameaverages (Name, yahooID, teamID, TeamReb) (SELECT Name, yahooID, teamID, @NewTeamReb := AVG(TeamReb) FROM tblteamgamestats WHERE TeamReb >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE TeamReb=@NewTeamReb;

SELECT * from tblteamgameaverages;