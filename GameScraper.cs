using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using MySql.Data.MySqlClient;
using System.IO;
using System.Threading;
using HtmlAgilityPack;

namespace YahooSportsStatsScraper
{
    class GameScraper : Scraper
    {
        private const string YAHOO_TEAMS_URL = "http://sports.yahoo.com/ncaab/teams/";

        private const string TEAM_FILE_EXT = ".html";
        private const string SCORE_REGEX = "^[WL] (\\d+)-(\\d+)";

        public override string CacheSubDirectory { get { return "teams"; } }

        public string StartTeam { get; set; }
        public string EndTeam { get; set; }

        public override int processLocalData()
        {
            int gamesFound = 0;
            List<RawGame> playedGames = new List<RawGame>();
            List<RawGame> unplayedGames = new List<RawGame>();

            StringBuilder sb = new StringBuilder();
            MySqlConnection connection = DatabaseHelper.OpenDatabaseConnection();

            foreach (FileInfo cachedTeamFile in getCachedFiles("*" + TEAM_FILE_EXT))
            {
                string team = cachedTeamFile.Name.Substring(0, 3);
                HtmlDocument doc = new HtmlDocument();
                doc.Load(cachedTeamFile.FullName);

                string xpath = "//*[@id=\"ncaab-schedule-table\"]/tr";
                string game_result_xpath = "//*[@class=\"game  link\"]";
                string game_preview_xpath = "//*[@class=\"game pre link\"]";
                if (team.Equals("aaf"))
                {
                    team = team + "";
                }

                HtmlNodeCollection playedGameRows = doc.DocumentNode.SelectNodes(game_result_xpath);

                if (playedGameRows != null)
                {
                    foreach (HtmlNode scheduledGame in playedGameRows)
                    {
                        string dataUrl = scheduledGame.Attributes["data-url"].Value;
                        string dataGID = scheduledGame.Attributes["data-gid"].Value;
                        string gameId = scheduledGame.Attributes["data-gid"].Value.Split('.')[2];
                        string date = gameId.Substring(0, 8);

                        string homeTeam = scheduledGame.SelectSingleNode("//*[@class=\"home\"]/span/em").InnerText.Trim();
                        string awayTeam = scheduledGame.SelectSingleNode("//*[@class=\"away\"]/span/em").InnerText.Trim();
                        string scoreString = scheduledGame.SelectSingleNode("//*[@class=\"score\"]/h4").InnerText.Trim();
                        int homeScore = int.Parse(scoreString.Split('-')[1].Trim());
                        int awayScore = int.Parse(scoreString.Split('-')[0].Trim());

                        RawGame rawGame = new RawGame(gameId, dataUrl, homeTeam, awayTeam, date, homeScore, awayScore);
                        playedGames.Add(rawGame);

                        if (sb.Length == 0)
                        {
                            sb.Append(RawGame.GetGamesInsertStatement());
                        }
                        sb.Append(rawGame.ToString());
                        if (sb.Length > DatabaseHelper.MAX_INSERT_LENGTH)
                        {
                            sb.Append(RawGame.GetGamesInsertStatementEnd());
                            using (MySqlCommand cmd = new MySqlCommand(sb.ToString(), connection))
                            {
                                gamesFound += cmd.ExecuteNonQuery();
                                sb.Clear();
                                sb.Length = 0;
                            }
                        }
                        else
                        {
                            sb.Append(',');
                        }
                    } // END foreach table row
                }
            } // END foreach file

            if (sb.Length > 0)
            {
                sb = new StringBuilder(sb.ToString().Trim(','));
                sb.Append(RawGame.GetGamesInsertStatementEnd());
                using (MySqlCommand cmd = new MySqlCommand(sb.ToString(), connection))
                {
                    gamesFound += cmd.ExecuteNonQuery();
                }
            }

            string updateScheduledGames = @"SET SQL_SAFE_UPDATES=0;
                UPDATE tblschedule AS s, tblgames AS g
                SET
                    s.gameID=g.gameID
                WHERE
                    s.homeTeam=g.homeTeamYahooID
                    AND
                    s.awayTeam=g.visitingTeamYahooID
                    AND
                    DATE(s.date) = g.date;

                SELECT * FROM tblschedule AS s, tblgames AS g
                WHERE
                    s.homeTeam=g.homeTeamYahooID
                    AND
                    s.awayTeam=g.visitingTeamYahooID
                    AND
                    DATE(s.date) = g.date
                    AND
                    s.id > 0;
                SET SQL_SAFE_UPDATES=1;";
            using (MySqlCommand cmd = new MySqlCommand(updateScheduledGames, connection))
            {
                cmd.ExecuteNonQuery();
            }

            return gamesFound;
        }

        /// <summary>
        /// Given a team ID string, gets all of the games and puts them into the database
        /// </summary>
        /// <returns></returns>
        public int processLocalData2()
        {
            int gamesFound = 0;
            foreach (FileInfo cachedTeamFile in getCachedFiles("*" + TEAM_FILE_EXT))
            {
                string team = cachedTeamFile.Name.Substring(0, cachedTeamFile.Name.Length - TEAM_FILE_EXT.Length);
                string page = cachedTeamFile.OpenText().ReadToEnd();
                // parse the page
                Regex GameRegex = new Regex("<tr class=\"ysprow[0-9]?\" valign=\"top\">\\s*<td height=\"18\">&nbsp;</td>\\s*<td nowrap>\\s*\\w{3},\\s*(?<date>\\w{3}\\s*\\d{1,2})\\s*</td>[^<]*<td>\\s*(?<visiting>at)?\\s*(\\((?<oprank>\\d+)\\))?\\s*(<a href=/ncaab/teams/(?<opcode>[a-z]{3})>)?\\s*(?<opname>[^<]*)(</a>)?\\s*</td>[^<]*<td>\\s*(<a href=/ncaab/\\w+\\?gid=(?<gid>\\d{12})>)?\\s*(?<winloss>\\w{1})\\s*(?<teamscore>\\d+)-(?<opscore>\\d+)\\s*(</a>)?\\s*</td>");
                MatchCollection matches = GameRegex.Matches(page);
                using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
                {
                    StringBuilder sb = new StringBuilder("INSERT IGNORE INTO tblgames (gameID, homeTeamYahooID, visitingTeamYahooID, date, homeScore, visitingScore) VALUES ");
                    foreach (Match m in matches)
                    {
                        if (m.Success)
                        {
                            string homeTeamYahooID = team;
                            string visitingTeamYahooID = m.Groups["opcode"].Value;
                            string homeTeamScore = m.Groups["teamscore"].Value; ;
                            string visitingTeamScore = m.Groups["opscore"].Value;
                            if (!String.IsNullOrEmpty(m.Groups["visiting"].Value))
                            {
                                homeTeamYahooID = visitingTeamYahooID;
                                visitingTeamYahooID = team;
                                homeTeamScore = visitingTeamScore;
                                visitingTeamScore = m.Groups["teamscore"].Value;
                            }

                            sb.Append("('");
                            sb.Append(m.Groups["gid"].Value);
                            sb.Append("','");
                            sb.Append(homeTeamYahooID);
                            sb.Append("','");
                            sb.Append(visitingTeamYahooID);
                            sb.Append("','");
                            // DATE
                            string dateString = m.Groups["date"].Value;
                            // if the game ID was there, then use that to get the date
                            if (!String.IsNullOrEmpty(m.Groups["gid"].Value))
                            {
                                dateString += ", " + m.Groups["gid"].Value.Substring(0, 4);
                            }
                            // otherwise, do it the BAD way
                            else
                            {
                                if ((m.Groups["date"].Value.Substring(0, 3) == "Jan") ||
                                    (m.Groups["date"].Value.Substring(0, 3) == "Feb") ||
                                    (m.Groups["date"].Value.Substring(0, 3) == "Mar") ||
                                    (m.Groups["date"].Value.Substring(0, 3) == "Apr"))
                                {
                                    // hey, at least it'll work next year
                                    dateString += ", " + DateTime.Today.Year.ToString();
                                }
                                else
                                {
                                    // hey, at least it'll work next year
                                    dateString += ", " + (DateTime.Today.Year - 1).ToString();
                                }
                            }
                            DateTime gameDate = DateTime.Parse(dateString);
                            sb.Append(gameDate.ToString("yyyy-MM-dd"));
                            // END DATE
                            sb.Append("','");
                            sb.Append(homeTeamScore);
                            sb.Append("','");
                            sb.Append(visitingTeamScore);
                            sb.Append("'), ");
                            gamesFound++;
                        }
                    }
                    sb.Remove(sb.Length - 2, 2);
                    sb.Append(";");
                    try
                    {
                        MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder();
                        MySqlCommand cmd = new MySqlCommand(sb.ToString(), Program.connection);
                        gamesFound = cmd.ExecuteNonQuery();
                        Console.WriteLine(cmd.CommandText);
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine(e.Message);
                    }
                }
                Console.WriteLine("Loaded {0} games!", gamesFound);
            }


            return gamesFound;
        }

        #region static void GetGamesForEachTeam(int pollPeriod)
        /// <summary>
        /// 
        /// </summary>
        public override int scrape()
        {
            List<string> teamIDs = DatabaseHelper.GetTeamsFromDatabase(StartTeam);
            Console.WriteLine("Found {0} teams in the database", teamIDs.Count);
            Console.WriteLine("Will be polling for teams every {0} seconds", ScrapeDelay);
            int numberScraped = 0;
            // get the homepage for each team and derive the games from that
            foreach (string team in teamIDs)
            {
                DateTime start = DateTime.UtcNow;
                Console.WriteLine("Reading team {0}", team);
                cacheFile(YAHOO_TEAMS_URL + team + "/schedule/", team + TEAM_FILE_EXT);

                TimeSpan elapsed = DateTime.UtcNow - start;
                if (elapsed.TotalSeconds < ScrapeDelay)
                {
                    Thread.Sleep(TimeSpan.FromSeconds(ScrapeDelay) - elapsed);
                }
            }
            return numberScraped;
        }
        #endregion
    }
}
