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
        private const string YAHOO_TEAMS_URL = "http://rivals.yahoo.com/ncaa/basketball/teams/";

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
            foreach (FileInfo cachedTeamFile in getCachedFiles("*" + TEAM_FILE_EXT))
            {
                string team = cachedTeamFile.Name.Substring(0, 3);
                HtmlDocument doc = new HtmlDocument();
                doc.Load(cachedTeamFile.FullName);

                string xpath = "//*[@id=\"ncaab-schedule-table\"]/tr";

                HtmlNodeCollection scheduledGames = doc.DocumentNode.SelectNodes(xpath);
                if (scheduledGames != null)
                {
                    foreach (HtmlNode scheduledGame in scheduledGames)
                    {
                        // look only for those rows which are actual game schedules;
                        // note that there are also header rows that we should ignore
                        if (
                            "ysprow1".Equals(scheduledGame.GetAttributeValue("class", "")) ||
                            "ysprow2".Equals(scheduledGame.GetAttributeValue("class", "")))
                        {
                            // only care about three rows; row 1 is a spacer
                            HtmlNode dateNode = scheduledGame.SelectSingleNode("td[2]");
                            HtmlNode oppNode = scheduledGame.SelectSingleNode("td[3]");
                            HtmlNode resultNode = scheduledGame.SelectSingleNode("td[4]");

                            // only attempt to save game data when the columns actually exist
                            if (dateNode != null && oppNode != null && resultNode != null)
                            {
                                string gameId = "";
                                string date = dateNode.InnerText.Trim();
                                string time = "";
                                string oppId = "";
                                bool isVisiting = false;
                                bool isResult = false;
                                int teamScore = 0;
                                int oppScore = 0;

                                // link to the opponent's team page, or null if it does not exist
                                HtmlNode opponent = oppNode.SelectSingleNode("a");
                                // link to the boxscore, or null if it does not exist
                                HtmlNode scoreResult = resultNode.SelectSingleNode("a");
                                if (opponent != null)
                                {
                                    // find the opponent's 3-letter team ID
                                    string[] urlPaths = opponent.GetAttributeValue("href", "///").Split('/');
                                    if (urlPaths.Length == 4)
                                    {
                                        oppId = urlPaths[3];
                                    }
                                }
                                // was this an away game?
                                if (oppNode.InnerText.Trim().Contains("at "))
                                {
                                    isVisiting = true;
                                }

                                // was there a link to a boxscore, with a game results?
                                // note: the regex filters out links to postponed/cancelled games
                                if (scoreResult != null)
                                {
                                    Match match = Regex.Match(scoreResult.InnerText.Trim(), SCORE_REGEX);
                                    // SKIP unplayed/cancelled games
                                    if (!match.Success)
                                    {
                                        Console.WriteLine("Skipping unplayed/cancelled game from " + team + " vs. " + oppId);
                                        continue;
                                    }

                                    string[] urlPaths = scoreResult.GetAttributeValue("href", "").Split('=');
                                    if (urlPaths.Length == 2)
                                    {
                                        gameId = urlPaths[1];
                                    }
                                    teamScore = Int32.Parse(match.Groups[1].Value);
                                    oppScore = Int32.Parse(match.Groups[2].Value);

                                    isResult = true;
                                }
                                else
                                {
                                    time = resultNode.InnerText.Trim();
                                }

                                // load the results if the game has already been played
                                if (isResult)
                                {
                                    if (isVisiting)
                                    {
                                        playedGames.Add(new RawGame(gameId, oppId, team, date, oppScore, teamScore));
                                    }
                                    else
                                    {
                                        playedGames.Add(new RawGame(gameId, team, oppId, date, teamScore, oppScore));
                                    }
                                }
                                // otherwise, add to the schedule of unplayed games
                                else
                                {
                                    if (isVisiting)
                                    {
                                        unplayedGames.Add(new RawGame(oppId, team, date, time));
                                    }
                                    else
                                    {
                                        unplayedGames.Add(new RawGame(team, oppId, date, time));
                                    }
                                }
                            }
                        }
                    } // END foreach table row
                }
            } // END foreach file
            
            using (MySqlConnection connection = DatabaseHelper.OpenDatabaseConnection())
            {
                // load played games
                StringBuilder sb = new StringBuilder();

                foreach(RawGame game in playedGames)
                {
                    if (sb.Length == 0)
                    {
                        sb.Append(RawGame.GetGamesInsertStatement());
                    }
                    sb.Append(game.ToString());

                    if (sb.Length > DatabaseHelper.MAX_INSERT_LENGTH)
                    {
                        MySqlCommand cmd = new MySqlCommand(sb.ToString(), connection);
                        gamesFound += cmd.ExecuteNonQuery();
                        sb.Clear();
                        sb.Length = 0;
                    }
                    else
                    {
                        sb.Append(',');
                    }
                }
                if (sb.Length > 0)
                {
                    MySqlCommand cmd = new MySqlCommand(sb.ToString().Trim(','), connection);
                    gamesFound += cmd.ExecuteNonQuery();
                }

                sb.Clear();
                sb.Length = 0;
                // load unplayed games
                foreach (RawGame game in unplayedGames)
                {
                    if (sb.Length == 0)
                    {
                        sb.Append(RawGame.GetScheduleInsertStatement());
                    }
                    sb.Append(game.ToString());

                    if (sb.Length > DatabaseHelper.MAX_INSERT_LENGTH)
                    {
                        MySqlCommand cmd = new MySqlCommand(sb.ToString(), connection);
                        gamesFound += cmd.ExecuteNonQuery();
                        sb.Clear();
                        sb.Length = 0;
                    }
                    else
                    {
                        sb.Append(',');
                    }
                }
                if (sb.Length > 0)
                {
                    MySqlCommand cmd = new MySqlCommand(sb.ToString().Trim(','), connection);
                    gamesFound += cmd.ExecuteNonQuery();
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
                (new MySqlCommand(updateScheduledGames, connection)).ExecuteNonQuery();
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
                cacheFile(YAHOO_TEAMS_URL + team, team + TEAM_FILE_EXT);

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
