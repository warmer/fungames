SELECT
    h.home, oppAllow.Ast, oppAllow.Blk, oppAllow.FGA, oppAllow.FGM, oppAllow.FTA, oppAllow.FTM, oppAllow.Off, oppAllow.PF, oppAllow.Reb, oppAllow.Stl, oppAllow.TeamReb, oppAllow.TPA, oppAllow.TPM, oppAllow.TRN, oppAvg.Ast, oppAvg.Blk, oppAvg.FGA, oppAvg.FGM, oppAvg.FTA, oppAvg.FTM, oppAvg.Off, oppAvg.PF, oppAvg.Reb, oppAvg.Stl, oppAvg.TeamReb, oppAvg.TPA, oppAvg.TPM, oppAvg.TRN, teamAllow.Ast, teamAllow.Blk, teamAllow.FGA, teamAllow.FGM, teamAllow.FTA, teamAllow.FTM, teamAllow.Off, teamAllow.PF, teamAllow.Reb, teamAllow.Stl, teamAllow.TeamReb, teamAllow.TPA, teamAllow.TPM, teamAllow.TRN, teamAvg.Ast, teamAvg.Blk, teamAvg.FGA, teamAvg.FGM, teamAvg.FTA, teamAvg.FTM, teamAvg.Off, teamAvg.PF, teamAvg.Reb, teamAvg.Stl, teamAvg.TeamReb, teamAvg.TPA, teamAvg.TPM, teamAvg.TRN
    , CAST(g.homeScore - g.visitingScore AS signed) AS score
FROM tblgames AS g, tblteamgameaverages AS teamAvg, tblteamgameaverages AS oppAvg, tblteamgameavgopptendencies as teamAllow, tblteamgameavgopptendencies as oppAllow, (select 1 as home) as h
WHERE 
    g.homeTeamYahooID=teamAvg.teamID AND
    g.visitingTeamYahooID=oppAvg.teamID AND
    g.homeTeamYahooID=teamAllow.teamID AND
    g.visitingTeamYahooID=oppAllow.teamID AND
    teamAllow.Home=h.home AND
    oppAllow.Home=(1 - h.home)
GROUP BY teamAllow.teamID, oppAllow.teamID, teamAvg.teamID, oppAvg.teamID, g.gameID
UNION
SELECT
    h.home, oppAllow.Ast, oppAllow.Blk, oppAllow.FGA, oppAllow.FGM, oppAllow.FTA, oppAllow.FTM, oppAllow.Off, oppAllow.PF, oppAllow.Reb, oppAllow.Stl, oppAllow.TeamReb, oppAllow.TPA, oppAllow.TPM, oppAllow.TRN, oppAvg.Ast, oppAvg.Blk, oppAvg.FGA, oppAvg.FGM, oppAvg.FTA, oppAvg.FTM, oppAvg.Off, oppAvg.PF, oppAvg.Reb, oppAvg.Stl, oppAvg.TeamReb, oppAvg.TPA, oppAvg.TPM, oppAvg.TRN, teamAllow.Ast, teamAllow.Blk, teamAllow.FGA, teamAllow.FGM, teamAllow.FTA, teamAllow.FTM, teamAllow.Off, teamAllow.PF, teamAllow.Reb, teamAllow.Stl, teamAllow.TeamReb, teamAllow.TPA, teamAllow.TPM, teamAllow.TRN, teamAvg.Ast, teamAvg.Blk, teamAvg.FGA, teamAvg.FGM, teamAvg.FTA, teamAvg.FTM, teamAvg.Off, teamAvg.PF, teamAvg.Reb, teamAvg.Stl, teamAvg.TeamReb, teamAvg.TPA, teamAvg.TPM, teamAvg.TRN
    , CAST(g.visitingScore- g.homeScore AS signed) AS score
FROM tblgames AS g, tblteamgameaverages AS teamAvg, tblteamgameaverages AS oppAvg, tblteamgameavgopptendencies as teamAllow, tblteamgameavgopptendencies as oppAllow, (select 0 as home) as h
WHERE 
    g.visitingTeamYahooID=teamAvg.teamID AND
    g.homeTeamYahooID=oppAvg.teamID AND
    g.visitingTeamYahooID=teamAllow.teamID AND
    g.homeTeamYahooID=oppAllow.teamID AND
    teamAllow.Home=h.home AND
    oppAllow.Home=(1 - h.home)
GROUP BY teamAllow.teamID, oppAllow.teamID, teamAvg.teamID, oppAvg.teamID, g.gameID
;