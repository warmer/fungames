using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.IO;
using MySql.Data.MySqlClient;
using System.Threading;
using System.Xml;
using HtmlAgilityPack;

namespace YahooSportsStatsScraper
{
    class BoxscoreScraper : Scraper
    {
        private const string BOXSCORE_URL = "http://sports.yahoo.com";
        private const string LOCAL_FILE_EXTENSION = ".html";

        public override string CacheSubDirectory { get { return "boxscores"; } }

        public long StartGame { get; set; }
        public long EndGame { get; set; }

        /// <summary>
        /// 
        /// </summary>
        public override int scrape()
        {
            Dictionary<string, string> gameUrlDict = DatabaseHelper.getGamesWithoutStats();
            //List<string> gameIDs = DatabaseHelper.GetGamesFromDatabase(StartGame, EndGame);
            Console.WriteLine("Found {0} games in the database", gameUrlDict.Count);
            Console.WriteLine("Will be polling for game stats every {0} seconds", ScrapeDelay);
            int pagesDownloaded = 0;
            // get the homepage for each team and derive the games from that
            foreach (string gameId in gameUrlDict.Keys)
            {
                DateTime start = DateTime.UtcNow;
                FileInfo cachedBoxscore = new FileInfo(Path.Combine(CacheDirectory, this.CacheSubDirectory, gameId + LOCAL_FILE_EXTENSION));
                if (getCachedFiles(gameId + LOCAL_FILE_EXTENSION).Count() > 0)
                {
                    Console.WriteLine("Skipping download of already-cached game {0}", gameId);
                    processBoxscore(cachedBoxscore);
                    continue;
                }
                Console.WriteLine("Reading stats for game {0}", gameId);
                cacheFile(BOXSCORE_URL + gameUrlDict[gameId], gameId + LOCAL_FILE_EXTENSION);
                pagesDownloaded++;

                processBoxscore(cachedBoxscore);

                TimeSpan elapsed = DateTime.UtcNow - start;
                if (elapsed.TotalSeconds < ScrapeDelay)
                {
                    Thread.Sleep(TimeSpan.FromSeconds(ScrapeDelay) - elapsed);
                }
            }

            return pagesDownloaded;
        }

        public void DeleteLocationlessGames()
        {
            string cacheDir = Path.Combine(CacheDirectory, this.CacheSubDirectory);
            foreach (string gameId in DatabaseHelper.gamesWithoutLocations())
            {
                FileInfo gameFile = new FileInfo(Path.Combine(cacheDir, gameId + ".html"));
                if (gameFile.Exists)
                {
                    gameFile.Delete();
                }
            }
        }

        #region CheckGames()
        /// <summary>
        /// Checks all games for stats completeness
        /// </summary>
        public void CheckGames()
        {
            DateTime start = DateTime.UtcNow;
            DatabaseHelper.LoadAllPlayerStats();
            Console.WriteLine("Read {1} player stats in {0}", (DateTime.UtcNow - start), Program.allPlayerStats.Count);

            start = DateTime.UtcNow;
            DatabaseHelper.LoadAllRawGames();
            Console.WriteLine("Read {1} raw game objects in {0}", (DateTime.UtcNow - start), Program.allRawGames.Count);

            List<BasketballGameTeam> games = new List<BasketballGameTeam>();

            start = DateTime.UtcNow;
            foreach (RawGame rg in Program.allRawGames)
            {
                BasketballGameTeam homeTeam = new BasketballGameTeam(rg.GameID, rg.HomeTeamYahooID, rg.GameDate, rg.HomeScore, true);
                BasketballGameTeam visitingTeam = new BasketballGameTeam(rg.GameID, rg.VisitingTeamYahooID, rg.GameDate, rg.VisitingScore, false);
                games.Add(homeTeam);
                games.Add(visitingTeam);
            }
            Console.WriteLine("Associated all BasketballGameTeam objects in {0}", (DateTime.UtcNow - start));
            Console.WriteLine("{0} game; {1} are valid", games.Count, games.Count(g => g.StatsAreValid));
        }
        #endregion

        private static Dictionary<string, string> stateToAbbr = new Dictionary<string, string>
        {
            {"Alabama","AL"},
            {"Alaska","AK"},
            {"Arizona","AZ"},
            {"Arkansas","AR"},
            {"California","CA"},
            {"Colorado","CO"},
            {"Connecticut","CT"},
            {"Delaware","DE"},
            {"Florida","FL"},
            {"Georgia","GA"},
            {"Hawaii","HI"},
            {"Idaho","ID"},
            {"Illinois","IL"},
            {"Indiana","IN"},
            {"Iowa","IA"},
            {"Kansas","KS"},
            {"Kentucky","KY"},
            {"Louisiana","LA"},
            {"Maine","ME"},
            {"Maryland","MD"},
            {"Massachusetts","MA"},
            {"Michigan","MI"},
            {"Minnesota","MN"},
            {"Mississippi","MS"},
            {"Missouri","MO"},
            {"Montana","MT"},
            {"Nebraska","NE"},
            {"Nevada","NV"},
            {"New Hampshire","NH"},
            {"New Jersey","NJ"},
            {"New Mexico","NM"},
            {"New York","NY"},
            {"North Carolina","NC"},
            {"North Dakota","ND"},
            {"Ohio","OH"},
            {"Oklahoma","OK"},
            {"Oregon","OR"},
            {"Pennsylvania","PA"},
            {"Rhode Island","RI"},
            {"South Carolina","SC"},
            {"South Dakota","SD"},
            {"Tennessee","TN"},
            {"Texas","TX"},
            {"Utah","UT"},
            {"Vermont","VT"},
            {"Virginia","VA"},
            {"Washington","WA"},
            {"West Virginia","WV"},
            {"West VA","WV"},
            {"Wisconsin","WI"},
            {"Wyoming","WY"},
            {"American Samoa","AS"},
            {"District of Columbia","DC"},
            {"Federated States of Micronesia","FM"},
            {"Guam","GU"},
            {"Marshall Islands","MH"},
            {"Northern Mariana Islands","MP"},
            {"Palau","PW"},
            {"Puerto Rico","PR"},
            {"Virgin Islands","VI"}
        };


        [Flags]
        enum BoxscoreTeamKey
        {
            Home = 1,
            Away = 2,
            Name = 4,
            Code = 8,
        };

        private static string getPlayerCodeFromUrl(String url)
        {
            Regex playerCodeFinder = new Regex("/ncaab/players/?(?<playerCode>[0-9]+)?");
            Match m = playerCodeFinder.Match(url);
            string playerCode = "";
            if (m.Success)
            {
                playerCode = m.Groups["playerCode"].Value;
            }
            return playerCode;
        }

        private static string getTeamCodeFromUrl(String url)
        {
            Regex teamCodeFinder = new Regex("/ncaab/teams/?(?<teamCode>[a-z_]+)?/?");
            Match m = teamCodeFinder.Match(url);
            string teamCode = "";
            if (m.Success)
            {
                teamCode = m.Groups["teamCode"].Value;
            }
            return teamCode;
        }

        private static string getGameLocation(HtmlDocument doc)
        {
            string location = "";
            HtmlNode locationNode = doc.DocumentNode.SelectSingleNode("//*[@class='stadium']/abbr");
            if (locationNode != null)
            {
                string stadium = locationNode.InnerText.Trim().Replace("'", "\\'");
                string loc = locationNode.Attributes["title"].Value.Trim().Replace("'", "\\'");
                string city = "";
                string state = "";
                string[] loc_parts = loc.Split(',');
                if (loc_parts.Length > 1)
                {
                    state = loc_parts[loc_parts.Length - 1].Trim();
                    city = loc_parts[loc_parts.Length - 2].Trim();
                    foreach (KeyValuePair<string, string> abbrPair in stateToAbbr)
                    {
                        state = state.Replace(abbrPair.Key, abbrPair.Value);
                    }
                    loc = String.Format("{0}, {1}", city, state);
                }
                location = String.Format("{0}, {1}", stadium, loc);
            }
            return location;
        }

        private static int getGameAttendance(HtmlDocument doc)
        {
            int attendance = -1;
            HtmlNode attendanceNode = doc.DocumentNode.SelectSingleNode("//*[@class='attendance']");
            if (attendanceNode != null)
            {
                string attendanceString = attendanceNode.InnerText;
                if (attendanceNode != null && !String.IsNullOrEmpty(attendanceString))
                {
                    string numAttendended = attendanceString.Split(':')[1];
                    try
                    {
                        attendance = Int32.Parse(numAttendended.Replace(",", ""));
                    }
                    catch (FormatException e)
                    {
                        attendance = -1;
                    }
                }
            }
            return attendance;
        }

        /// <summary>
        /// Gets information about the teams playing in this game, as derived from the given HTML doc
        /// 
        /// Updated 3/15/2014
        /// </summary>
        /// <param name="doc"></param>
        /// <returns></returns>
        private static Dictionary<BoxscoreTeamKey, string> getTeamsPlaying(HtmlDocument doc)
        {
            Dictionary<BoxscoreTeamKey, string> teamScores = new Dictionary<BoxscoreTeamKey, string>();
            HtmlNode awayTeamDiv = doc.DocumentNode.SelectSingleNode("//*[@class='team away']");
            if (awayTeamDiv == null)
            {
                awayTeamDiv = doc.DocumentNode.SelectSingleNode("//*[@class='team away winner']");
            }
            HtmlNode homeTeamDiv = doc.DocumentNode.SelectSingleNode("//*[@class='team home']");
            if (homeTeamDiv == null)
            {
                homeTeamDiv = doc.DocumentNode.SelectSingleNode("//*[@class='team home winner']");
            }
            if (homeTeamDiv != null && awayTeamDiv != null)
            {
                HtmlNode awayTeamLink = awayTeamDiv.SelectSingleNode("a");
                HtmlNode homeTeamLink = homeTeamDiv.SelectSingleNode("a");
                string awayTeamId = getTeamCodeFromUrl(awayTeamLink.GetAttributeValue("href", "").Trim());
                string homeTeamId = getTeamCodeFromUrl(homeTeamLink.GetAttributeValue("href", "").Trim());
                teamScores.Add(BoxscoreTeamKey.Away | BoxscoreTeamKey.Code, awayTeamId);
                teamScores.Add(BoxscoreTeamKey.Home | BoxscoreTeamKey.Code, homeTeamId);
                teamScores.Add(BoxscoreTeamKey.Away | BoxscoreTeamKey.Name, DatabaseHelper.getTeamName(awayTeamId));
                teamScores.Add(BoxscoreTeamKey.Home | BoxscoreTeamKey.Name, DatabaseHelper.getTeamName(homeTeamId));
            }
            else if (homeTeamDiv == null && awayTeamDiv == null)
            {
                HtmlNodeCollection collection = doc.DocumentNode.SelectNodes("//h4");
                if (collection != null && collection.Count == 2)
                {
                    string visitingTeam = collection[0].InnerText;
                    string homeTeam = collection[1].InnerText;
                    teamScores.Add(BoxscoreTeamKey.Away | BoxscoreTeamKey.Code, DatabaseHelper.getTeamId(visitingTeam));
                    teamScores.Add(BoxscoreTeamKey.Home | BoxscoreTeamKey.Code, DatabaseHelper.getTeamId(homeTeam));
                    teamScores.Add(BoxscoreTeamKey.Away | BoxscoreTeamKey.Name, DatabaseHelper.getTeamName(visitingTeam));
                    teamScores.Add(BoxscoreTeamKey.Home | BoxscoreTeamKey.Name, DatabaseHelper.getTeamName(homeTeam));
                }
            }

            //HtmlNode boxscoreDiv = doc.DocumentNode.SelectSingleNode("//*[@class='boxscore']");

            return teamScores;
        }

        /// <summary>
        /// From the given HTML table of boxscore stats, gets a mapping of stat name
        /// to column position within the table
        /// </summary>
        /// <param name="table"></param>
        /// <returns></returns>
        private static Dictionary<string, int> getStatColumnsFromTable(HtmlNode table)
        {
            Dictionary<string, int> statColumns = new Dictionary<string, int>();

            HtmlNode head = table.SelectSingleNode("thead");
            if (head != null)
            {
                HtmlNodeCollection headerNodes = head.SelectNodes("tr/th");
                if (headerNodes != null)
                {
                    for (int colNum = 0; colNum < headerNodes.Count; colNum++)
                    {
                        String statName = headerNodes[colNum].InnerText.Trim();
                        statColumns.Add(statName, colNum);
                    }
                }
            }

            return statColumns;
        }

        private static BasketballGamePlayer getPlayerFromStatRow(HtmlNode statRow, Dictionary<string, int> statColumnMap)
        {
            BasketballGamePlayer player = new BasketballGamePlayer();

            HtmlNodeCollection dataCells = statRow.SelectNodes("td|th");

            if (dataCells == null || dataCells.Count < statColumnMap.Keys.Count)
            {
                Console.WriteLine("getPlayerStatsFromTable had funky table data - cell# < key#");
            }
            else
            {
                foreach (string stat in statColumnMap.Keys)
                {
                    HtmlNode dataNode = dataCells[statColumnMap[stat]];
                    String innerText = dataNode.InnerText.Trim();
                    String[] splitString = innerText.Split('-');

                    #region long stat switch statement
                    switch (stat)
                    {
                        case "Players":
                            HtmlNode linkNode = dataNode.SelectSingleNode("a");
                            player.Name = innerText;
                            if (linkNode != null)
                            {
                                player.YahooID = getPlayerCodeFromUrl(linkNode.GetAttributeValue("href", ""));
                            }
                            break;

                        case "Min":
                            Int32.TryParse(innerText, out player.Min);
                            break;

                        case "FG":
                            if (splitString.Length == 2)
                            {
                                Int32.TryParse(splitString[0], out player.FGM);
                                Int32.TryParse(splitString[1], out player.FGA);
                            }
                            break;

                        case "3Pt":
                        case "3pt":
                            if (splitString.Length == 2)
                            {
                                Int32.TryParse(splitString[0], out player.TPM);
                                Int32.TryParse(splitString[1], out player.TPA);
                            }
                            break;

                        case "FT":
                            if (splitString.Length == 2)
                            {
                                Int32.TryParse(splitString[0], out player.FTM);
                                Int32.TryParse(splitString[1], out player.FTA);
                            }
                            break;

                        case "Off":
                            Int32.TryParse(innerText, out player.Off);
                            break;

                        case "Def":
                            Int32.TryParse(innerText, out player.Def);
                            break;

                        case "Reb":
                            Int32.TryParse(innerText, out player.Reb);
                            break;

                        case "Ast":
                            Int32.TryParse(innerText, out player.Ast);
                            break;

                        case "TO":
                            Int32.TryParse(innerText, out player.TO);
                            break;

                        case "Stl":
                            Int32.TryParse(innerText, out player.Stl);
                            break;

                        case "Blk":
                            Int32.TryParse(innerText, out player.Blk);
                            break;

                        case "PF":
                            Int32.TryParse(innerText, out player.PF);
                            break;

                        case "Pts":
                            Int32.TryParse(innerText, out player.Pts);
                            break;

                        default:
                            Console.WriteLine("Stat not recognized: " + stat);
                            break;
                    }
                    #endregion
                }
            }
            return player;
        }

        private static int getTeamReabounds(HtmlNode reboundsNode)
        {
            int rebs = -1;
            if (reboundsNode != null)
            {
                string[] split = reboundsNode.InnerText.Split(':');
                if (split.Length == 2)
                {
                    string rebStr = split[1].Trim();
                    Int32.TryParse(rebStr, out rebs);
                }
            }

            return rebs;
        }

        private static TeamGameStat getTotalStatsFromTable(HtmlNode table, string gameId, string teamId)
        {
            TeamGameStat totalStat = new TeamGameStat();

            Dictionary<string, int> statColumnMap = getStatColumnsFromTable(table);

            // only bother if there are stats in the table
            if (statColumnMap.Count != 14)
            {
                Console.WriteLine(gameId);
            }
            if (statColumnMap.Count > 0)
            {
                HtmlNode totalCell = table.SelectSingleNode("./tbody/tr/th[@class='totals']");
                HtmlNode totalRow = totalCell.ParentNode;
                BasketballGamePlayer player = getPlayerFromStatRow(totalRow, statColumnMap);
                totalStat.Copy(player);
                totalStat.Gid = gameId;
                totalStat.TeamID = teamId;
                totalStat.TeamRebounds = getTeamReabounds(table.SelectSingleNode("tfoot/tr[@class='summary']/td[@class='rebounds']"));
            }

            return totalStat;
        }

        /// <summary>
        /// Returns a list of BasketballGamePlayer objects corresponding to stats from
        /// the given boxscore table
        /// </summary>
        /// <param name="table"></param>
        /// <returns></returns>
        private static List<BasketballGamePlayer> getPlayerStatsFromTable(HtmlNode table, string gameId, string teamId)
        {
            List<BasketballGamePlayer> players = new List<BasketballGamePlayer>();

            Dictionary<string, int> statColumnMap = getStatColumnsFromTable(table);

            // only bother if there are stats in the table
            if (statColumnMap.Count > 0)
            {
                // each row will contain a list of <td> objects containing individual stats
                HtmlNodeCollection playerStatRows = table.SelectNodes("tbody/tr");
                if (playerStatRows != null)
                {
                    foreach (HtmlNode statRow in playerStatRows)
                    {
                        BasketballGamePlayer player = getPlayerFromStatRow(statRow, statColumnMap);
                        player.Gid = gameId;
                        player.TeamID = teamId;
                        players.Add(player);
                    }
                }
            }

            return players;
        }

        /// <summary>
        /// Retrieves the table nodes containing the player stats for the game
        /// </summary>
        /// <param name="doc"></param>
        /// <returns></returns>
        private static Dictionary<BoxscoreTeamKey, HtmlNode> getScoreTables(HtmlDocument doc)
        {
            Dictionary<BoxscoreTeamKey, HtmlNode> scoreTables = new Dictionary<BoxscoreTeamKey, HtmlNode>();
            HtmlNodeCollection scoreTable = doc.DocumentNode.SelectNodes("//*[@summary='PLAYERS']");

            if (scoreTable != null && scoreTable.Count == 2)
            {
                scoreTables.Add(BoxscoreTeamKey.Away, scoreTable[0]);
                scoreTables.Add(BoxscoreTeamKey.Home, scoreTable[1]);
            }
            else if (scoreTable != null)
            {
                Console.WriteLine("{0} tables exist, which is really weird", scoreTable.Count);
            }
            else
            {
                Console.WriteLine("Could not find player boxscore data for game");
            }

            return scoreTables;
        }

        public void runUpdateQueries()
        {
            #region rawQueries
            string[] averagesUpdate = {
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Min) (SELECT Name, yahooID, teamID, @NewMin := AVG(Min) FROM tblteamgamestats WHERE Min >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Min=@NewMin;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, FGM) (SELECT Name, yahooID, teamID, @NewFGM := AVG(FGM) FROM tblteamgamestats WHERE FGM >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE FGM=@NewFGM;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, FGA) (SELECT Name, yahooID, teamID, @NewFGA := AVG(FGA) FROM tblteamgamestats WHERE FGA >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE FGA=@NewFGA;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, TPM) (SELECT Name, yahooID, teamID, @NewTPM := AVG(TPM) FROM tblteamgamestats WHERE TPM >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE TPM=@NewTPM;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, TPA) (SELECT Name, yahooID, teamID, @NewTPA := AVG(TPA) FROM tblteamgamestats WHERE TPA >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE TPA=@NewTPA;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, FTM) (SELECT Name, yahooID, teamID, @NewFTM := AVG(FTM) FROM tblteamgamestats WHERE FTM >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE FTM=@NewFTM;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, FTA) (SELECT Name, yahooID, teamID, @NewFTA := AVG(FTA) FROM tblteamgamestats WHERE FTA >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE FTA=@NewFTA;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Off) (SELECT Name, yahooID, teamID, @NewOff := AVG(Off) FROM tblteamgamestats WHERE Off >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Off=@NewOff;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Reb) (SELECT Name, yahooID, teamID, @NewReb := AVG(Reb) FROM tblteamgamestats WHERE Reb >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Reb=@NewReb;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Ast) (SELECT Name, yahooID, teamID, @NewAst := AVG(Ast) FROM tblteamgamestats WHERE Ast >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Ast=@NewAst;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, TRN) (SELECT Name, yahooID, teamID, @NewTRN := AVG(TRN) FROM tblteamgamestats WHERE TRN >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE TRN=@NewTRN;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Stl) (SELECT Name, yahooID, teamID, @NewStl := AVG(Stl) FROM tblteamgamestats WHERE Stl >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Stl=@NewStl;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Blk) (SELECT Name, yahooID, teamID, @NewBlk := AVG(Blk) FROM tblteamgamestats WHERE Blk >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Blk=@NewBlk;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, PF) (SELECT Name, yahooID, teamID, @NewPF := AVG(PF) FROM tblteamgamestats WHERE PF >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE PF=@NewPF;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, Pts) (SELECT Name, yahooID, teamID, @NewPts := AVG(Pts) FROM tblteamgamestats WHERE Pts >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE Pts=@NewPts;",
                @"INSERT INTO tblteamgameaverages (Name, yahooID, teamID, TeamReb) (SELECT Name, yahooID, teamID, @NewTeamReb := AVG(TeamReb) FROM tblteamgamestats WHERE TeamReb >= 0 GROUP BY teamID, yahooID, Name) ON DUPLICATE KEY UPDATE TeamReb=@NewTeamReb;"
            };

            string gameOppTendencyUpdate = @"REPLACE INTO 
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
                        oppStats.teamID = g.homeTeamYahooID";

            string avgGameOppTendQuery1 = @"REPLACE INTO
                tblteamgameavgopptendencies
                (
                    teamID, Home, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, PTS, TeamReb
                )
                SELECT 
                    teamID, Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
                FROM
                    tblteamgameopptendencies
                GROUP BY teamID, Home;";

            string avgGameOppTendQueryHome = @"REPLACE INTO
                tblteamgameavgopptendencies
                (
                    teamID, Home, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, PTS, TeamReb
                )
                SELECT 
                    teamID, Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
                FROM
                    tblteamgameopptendencies
                WHERE Home=1
                GROUP BY teamID;";

            string avgGameOppTendQueryAway = @"REPLACE INTO
                tblteamgameavgopptendencies
                (
                    teamID, Home, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, PTS, TeamReb
                )
                SELECT 
                    oppID, Home, avg(Min), avg(FGM), avg(FGA), avg(TPM), avg(TPA), avg(FTM), avg(FTA), avg(Off), avg(Reb), avg(Ast), avg(TRN), avg(Stl), avg(Blk), avg(PF), avg(Pts), avg(TeamReb)
                FROM
                    tblteamgameopptendencies
                WHERE Home=0
                GROUP BY oppID;";
            #endregion

            string avgGameOppTendQueryCombined = @"REPLACE INTO
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
                GROUP BY team;";

            using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
            {
                foreach (string query in averagesUpdate)
                {
                    MySqlCommand cmd = new MySqlCommand(query, Program.connection);
                    //cmd.Parameters.Add("NewMin", MySqlDbType.Int32);
                    //cmd.Parameters["NewMin"].Value = Int32.MaxValue;
                    cmd.ExecuteNonQuery();
                }

                (new MySqlCommand(gameOppTendencyUpdate, Program.connection)).ExecuteNonQuery();
                (new MySqlCommand(avgGameOppTendQueryHome, Program.connection)).ExecuteNonQuery();
                (new MySqlCommand(avgGameOppTendQueryAway, Program.connection)).ExecuteNonQuery();
                (new MySqlCommand(avgGameOppTendQueryCombined, Program.connection)).ExecuteNonQuery();
            }


        }

        private void deleteIrrelevantNodes(HtmlDocument doc, string filename)
        {
            foreach (HtmlNode node in doc.DocumentNode.SelectNodes("//head"))
            {
                node.Remove();
            }
            foreach (HtmlNode node in doc.DocumentNode.SelectNodes("//*[@id='yog-hd']"))
            {
                node.Remove();
            }
            foreach (HtmlNode node in doc.DocumentNode.SelectNodes("//*[@id='yog-nav']"))
            {
                node.Remove();
            }
            foreach (HtmlNode node in doc.DocumentNode.SelectNodes("//iframe"))
            {
                node.Remove();
            }
            foreach (HtmlNode node in doc.DocumentNode.SelectNodes("//script"))
            {
                node.Remove();
            }
            foreach (HtmlNode node in doc.DocumentNode.SelectNodes("//style"))
            {
                node.Remove();
            }
            foreach (HtmlNode node in doc.DocumentNode.SelectNodes("//img"))
            {
                node.Remove();
            }
            doc.Save(filename);
        }

        private bool processBoxscore(FileInfo file)
        {
            bool success = true;

            HtmlDocument doc = new HtmlDocument();
            doc.Load(file.FullName);
            deleteIrrelevantNodes(doc, file.FullName);
            Dictionary<BoxscoreTeamKey, string> teamInfo = getTeamsPlaying(doc);
            Dictionary<BoxscoreTeamKey, HtmlNode> scoreTables = getScoreTables(doc);
            if (scoreTables.Count == 0 || teamInfo.Count == 0)
            {
                // Delete boxscore downloads that do not contain team info or score tables
                File.Delete(file.FullName);
                success = false;
            }
            else
            {
                string gameId = file.Name.Split('.').First().Trim();
                List<BasketballGamePlayer> homePlayers = getPlayerStatsFromTable(scoreTables[BoxscoreTeamKey.Home], gameId, teamInfo[BoxscoreTeamKey.Home | BoxscoreTeamKey.Code]);
                List<BasketballGamePlayer> awayPlayers = getPlayerStatsFromTable(scoreTables[BoxscoreTeamKey.Away], gameId, teamInfo[BoxscoreTeamKey.Away | BoxscoreTeamKey.Code]);
                TeamGameStat homeTotal = getTotalStatsFromTable(scoreTables[BoxscoreTeamKey.Home], gameId, teamInfo[BoxscoreTeamKey.Home | BoxscoreTeamKey.Code]);
                TeamGameStat awayTotal = getTotalStatsFromTable(scoreTables[BoxscoreTeamKey.Away], gameId, teamInfo[BoxscoreTeamKey.Away | BoxscoreTeamKey.Code]);
                IEnumerable<BasketballGamePlayer> allPlayers = homePlayers.Concat(awayPlayers);

                String gameLocation = getGameLocation(doc);
                int attendance = getGameAttendance(doc);

                StringBuilder sb = new StringBuilder();
                // only perform an insert if there are players to insert
                if (allPlayers.Count() > 0)
                {
                    // get the first part of the insert
                    sb.Append(BasketballGamePlayer.getInsertQuery());
                    foreach (BasketballGamePlayer aPlayer in allPlayers)
                    {
                        sb.Append(aPlayer.ToQuery());
                        sb.Append(',');
                    }
                    sb.Remove(sb.Length - 1, 1);
				    sb.Append(";");
				    try
				    {
					    using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
					    {
						    MySqlCommand cmd = new MySqlCommand(sb.ToString(), Program.connection);
						    int playersFound = cmd.ExecuteNonQuery();
						    //Console.WriteLine("Loaded stats for {0} players!", playersFound);
					    }
				    }
				    catch (Exception e)
				    {
					    Console.WriteLine(e.Message);
				    }
			    }
                else
                {
                    Console.WriteLine("No players found in the boxscore for game " + gameId);
                }
                // Now, write the totals to the DB
                sb = new StringBuilder();
                // create the insert query
                sb.Append(TeamGameStat.getTotalInsertQuery());
                sb.Append(homeTotal.ToQuery());
                sb.Append(',');
                sb.Append(awayTotal.ToQuery());
                sb.Append(TeamGameStat.getUpdateInsertQuery());
                sb.Append(";");
                try
                {
                    using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
                    {
                        MySqlCommand cmd = new MySqlCommand(sb.ToString(), Program.connection);
                        int playersFound = cmd.ExecuteNonQuery();
                        //Console.WriteLine("Loaded stats for {0} totals!", playersFound);
                    }
                }
                catch (Exception e)
                {
                    success = false;
                    Console.WriteLine(e.Message);
                }

                // update the game entry in the database to add attendance and location information
                sb.Clear();
                sb.AppendFormat(
                    "UPDATE tblgames SET attendance={0}, location='{1}', visitingTeamYahooID='{2}', homeTeamYahooID='{3}', homeScore='{4}', visitingScore='{5}' WHERE gameID={6};",
                    attendance,
                    gameLocation,
                    teamInfo[BoxscoreTeamKey.Away | BoxscoreTeamKey.Code],
                    teamInfo[BoxscoreTeamKey.Home | BoxscoreTeamKey.Code],
                    homeTotal.Pts,
                    awayTotal.Pts,
                    gameId);
                try
                {
                    using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
                    {
                        MySqlCommand cmd = new MySqlCommand(sb.ToString(), Program.connection);
                        int gamesUpdated = cmd.ExecuteNonQuery();
                        //Console.WriteLine("Updated location and attendance for for {0} game!", gamesUpdated);
                    }
                }
                catch (Exception e)
                {
                    success = false;
                    Console.WriteLine(e.Message);
                }
            }
            return success;
        }

        public override int processLocalData()
        {
            int totalFiles = 0;
            int filesWithBadData = 0;
            foreach (FileInfo file in getCachedFiles("*" + LOCAL_FILE_EXTENSION))
            {
                totalFiles++;
                if (!processBoxscore(file))
                {
                    filesWithBadData++;
                }
                Console.Write("{0}/{1} have bad data\r", filesWithBadData, totalFiles);
                if (totalFiles % 100 == 0)
                {
                    Console.WriteLine();
                }
            }
            runUpdateQueries();
            return totalFiles - filesWithBadData;
        }

    }
}
