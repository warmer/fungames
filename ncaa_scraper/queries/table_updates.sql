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

REPLACE INTO 
tblteamgameopptendencies
(gameID,
teamID,
oppID,
Home,
Min,
FGM,
FGA,
TPM,
TPA,
FTM,
FTA,
Off,
Reb,
Ast,
TRN,
Stl,
Blk,
PF,
Pts,
TeamReb)
    SELECT
        g.gameID as gameID,
        g.homeTeamYahooID as teamID,
        g.visitingTeamYahooID as oppID,
        1 as isHome,
        if(oppStats.Min >= 0, oppStats.Min - oppAvg.Min, 0),
        oppStats.FGM - oppAvg.FGM,
        oppStats.FGA - oppAvg.FGA,
        oppStats.TPM - oppAvg.TPM,
        oppStats.TPA - oppAvg.TPA,
        oppStats.FTM - oppAvg.FTM,
        oppStats.FTA - oppAvg.FTA,
        if(oppStats.Off >= 0, oppStats.Off - oppAvg.Off, 0),
        if(oppStats.Reb >= 0, oppStats.Reb - oppAvg.Reb, 0),
        if(oppStats.Ast >= 0, oppStats.Ast - oppAvg.Ast, 0),
        if(oppStats.TRN >= 0, oppStats.TRN - oppAvg.TRN, 0),
        if(oppStats.Stl >= 0, oppStats.Stl - oppAvg.Stl, 0),
        if(oppStats.Blk >= 0, oppStats.Blk - oppAvg.Blk, 0),
        oppStats.PF - oppAvg.PF,
        oppStats.Pts - oppAvg.Pts,
        if(oppStats.TeamReb >= 0, oppStats.TeamReb - oppAvg.TeamReb, 0)
    from 
        tblgames g,
        tblteamgamestats oppStats,
        tblteamgameaverages oppAvg
    where
        g.homeTeamYahooID != g.visitingTeamYahooID
        AND
        oppStats.gameID = g.gameID
        AND
        oppAvg.teamID = g.visitingTeamYahooID
        AND
        oppStats.teamID = g.visitingTeamYahooID
UNION
    SELECT
        g.gameID as gameID,
        g.visitingTeamYahooID as teamID,
        g.homeTeamYahooID as oppID,
        0 as isHome,
        if(oppStats.Min >= 0, oppStats.Min - oppAvg.Min, 0),
        oppStats.FGM - oppAvg.FGM,
        oppStats.FGA - oppAvg.FGA,
        oppStats.TPM - oppAvg.TPM,
        oppStats.TPA - oppAvg.TPA,
        oppStats.FTM - oppAvg.FTM,
        oppStats.FTA - oppAvg.FTA,
        if(oppStats.Off >= 0, oppStats.Off - oppAvg.Off, 0),
        if(oppStats.Reb >= 0, oppStats.Reb - oppAvg.Reb, 0),
        if(oppStats.Ast >= 0, oppStats.Ast - oppAvg.Ast, 0),
        if(oppStats.TRN >= 0, oppStats.TRN - oppAvg.TRN, 0),
        if(oppStats.Stl >= 0, oppStats.Stl - oppAvg.Stl, 0),
        if(oppStats.Blk >= 0, oppStats.Blk - oppAvg.Blk, 0),
        oppStats.PF - oppAvg.PF,
        oppStats.Pts - oppAvg.Pts,
        if(oppStats.TeamReb >= 0, oppStats.TeamReb - oppAvg.TeamReb, 0)
    from 
        tblgames g,
        tblteamgamestats oppStats,
        tblteamgameaverages oppAvg
    where
        g.homeTeamYahooID != g.visitingTeamYahooID
        AND
        oppStats.gameID = g.gameID
        AND
        oppAvg.teamID = g.homeTeamYahooID
        AND
        oppStats.teamID = g.homeTeamYahooID
;

SELECT * FROM tblgames WHERE homeTeamYahooID = 'gah';


    SELECT
        g.gameID as gameID,
        g.visitingTeamYahooID as teamID,
        g.homeTeamYahooID as oppID,
        0 as isHome,
        if(oppStats.Min >= 0, oppStats.Min - oppAvg.Min, 0),
        oppStats.FGM - oppAvg.FGM,
        oppStats.FGA - oppAvg.FGA,
        oppStats.TPM - oppAvg.TPM,
        oppStats.TPA - oppAvg.TPA,
        oppStats.FTM - oppAvg.FTM,
        oppStats.FTA - oppAvg.FTA,
        if(oppStats.Off >= 0, oppStats.Off - oppAvg.Off, 0),
        if(oppStats.Reb >= 0, oppStats.Reb - oppAvg.Reb, 0),
        if(oppStats.Ast >= 0, oppStats.Ast - oppAvg.Ast, 0),
        if(oppStats.TRN >= 0, oppStats.TRN - oppAvg.TRN, 0),
        if(oppStats.Stl >= 0, oppStats.Stl - oppAvg.Stl, 0),
        if(oppStats.Blk >= 0, oppStats.Blk - oppAvg.Blk, 0),
        oppStats.PF - oppAvg.PF,
        oppStats.Pts - oppAvg.Pts,
        if(oppStats.TeamReb >= 0, oppStats.TeamReb - oppAvg.TeamReb, 0)
    from 
        tblgames g,
        tblteamgamestats oppStats,
        tblteamgameaverages oppAvg
    where
        g.homeTeamYahooID != g.visitingTeamYahooID
        AND
        oppStats.gameID = g.gameID
        AND
        oppAvg.teamID = g.homeTeamYahooID
        AND
        oppStats.teamID = g.homeTeamYahooID
        AND
        g.homeTeamYahooID = 'gah';

REPLACE INTO
    tblteamgameavgopptendencies
        (
            teamID, Home, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, PTS, TeamReb
        )
    SELECT 
        oppID, Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
    FROM
        tblteamgameopptendencies
    WHERE Home=0
    GROUP BY oppID;

SELECT 
    teamID, Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
FROM
    tblteamgameopptendencies
WHERE Home=1 and teamID='gah'
GROUP BY teamID;

REPLACE INTO
    tblteamgameavgopptendencies
        (
            teamID, Home, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, PTS, TeamReb
        )
    SELECT 
        teamID, Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
    FROM
        tblteamgameopptendencies
    WHERE Home=1
    GROUP BY teamID;
    
REPLACE INTO
    tblteamgameavgopptendencies
        (
            teamID, Home, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, PTS, TeamReb
        )
    SELECT
        team, 2 as Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
    FROM
        (SELECT 
            oppID as team, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, Pts, TeamReb
        FROM
            tblteamgameopptendencies as t
        WHERE Home=0

    UNION
        SELECT 
            teamID as team, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, Pts, TeamReb
        FROM
            tblteamgameopptendencies as t
        WHERE Home=1
    ) as f
    GROUP BY team;
        
SELECT * FROM tblteamgameavgopptendencies WHERE teamID = 'gah';


SELECT
    team, 2 as Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
#        team, 2 as Home, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, Pts, TeamReb
FROM
    (SELECT 
        oppID as team, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, Pts, TeamReb
    FROM
        tblteamgameopptendencies as t
    WHERE Home=0

UNION
    SELECT 
        teamID as team, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, Pts, TeamReb
    FROM
        tblteamgameopptendencies as t
    WHERE Home=1
) as f
group by team;

SELECT 
    teamID, 1 as Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
FROM
    tblteamgameopptendencies
WHERE Home=1
GROUP BY teamID;
SELECT * FROM tblteamgameopptendencies;
SELECT * FROM tblmodel;

SELECT * FROM tblgames WHERE location = '';
SELECT * FROM tblgames WHERE homeTeamYahooID = 'gah' OR visitingTeamYahooID='gah';
SELECT
    s.Pts,
    g.visitingScore,
    s.teamID,
    g.visitingTeamYahooID,
    s.gameID,
    g.gameID
FROM
    tblgames as g,
    tblteamgamestats as s
WHERE
    g.visitingTeamYahooID=s.teamID AND
    g.gameID=s.gameID;

SELECT * FROM tblteamgameopptendencies WHERE teamID='gah';
SELECT teamID,count(*) FROM tblteamgameopptendencies WHERE Home=1 GROUP BY teamID;

SELECT gameID FROM tblgames WHERE location='';

SELECT count(*) FROM tblgames LEFT JOIN tblteamgamestats ON tblgames.gameID=tblteamgamestats.gameID WHERE tblteamgamestats.Name is null;

SELECT count(*) FROM tblgames;
SELECT * FROM tblteamgameopptendencies;
SELECT * FROM tblteamgameavgopptendencies;
SELECT * FROM tblteamgamestats;
SELECT * FROM tblteamgameaverages;