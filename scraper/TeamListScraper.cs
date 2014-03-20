using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using MySql.Data.MySqlClient;
using System.IO;

namespace YahooSportsStatsScraper
{
    class TeamListScraper : Scraper
    {
        private const string YAHOO_TEAMS_URL = "http://rivals.yahoo.com/ncaa/basketball/teams";
        private const string TEAM_LIST_FILE = "allteams.html";

        public override string CacheSubDirectory
        {
            get { return "teamlist"; }
        }

        public override int scrape()
        {
            cacheFile(YAHOO_TEAMS_URL, TEAM_LIST_FILE);
            return 1;
        }

        public override int processLocalData()
        {
            int numberInserted = 0;
            try
            {
                FileInfo[] cachedFiles = getCachedFiles(TEAM_LIST_FILE);
                //if (cachedFiles.Length > 1)
                //{
                //    throw new Exception("Too many files returned when looking for: " + TEAM_LIST_FILE);
                //}
                foreach(FileInfo file in cachedFiles)
                {
                    Dictionary<string, string> TeamsList = GetTeamsList(file.OpenText().ReadToEnd());
                    numberInserted += InsertTeamsIntoDatabase(TeamsList);
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("Couldn't get teams list: {0}", e.Message);
                return numberInserted;
            }
            return numberInserted;
        }

        #region static Dictionary<string, string> GetTeamsList(string TeamsListWebPage)
        /// <summary>
        /// Returns a list of teams in a Dictionary format with the key being the 3-digit
        /// team code, and the value being the team's name
        /// </summary>
        /// <param name="TeamsListWebPage"></param>
        /// <returns></returns>
        private static Dictionary<string, string> GetTeamsList(string TeamsListWebPage)
        {
            Dictionary<string, string> TeamsList = new Dictionary<string, string>();
            Regex TeamCodeRegex = new Regex("<a href=\"/ncaab/teams/(?<code>\\w*)\">(?<teamName>[^<]*)</a>");
            MatchCollection matches = TeamCodeRegex.Matches(TeamsListWebPage);
            foreach (Match m in matches)
            {
                if (m.Success)
                {
                    string teamName = m.Groups["teamName"].Value.Replace("&nbsp;", " ");
                    TeamsList.Add(m.Groups["code"].Value, teamName);
                }
            }
            return TeamsList;
        }
        #endregion


        #region static int InsertTeamsIntoDatabase(Dictionary<string, string> TeamsList)
        /// <summary>
        /// Uses the default database connection and a Dictionary of team names and team codes
        /// to populate the "teams" table
        /// </summary>
        /// <param name="TeamsList">key: team_name, value: yahooID</param>
        /// <returns>the number of teams that were inserted</returns>
        public static int InsertTeamsIntoDatabase(Dictionary<string, string> TeamsList)
        {
            int numRowsAffected = 0;
            using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
            {
                string insertString = "INSERT IGNORE INTO tblteams (team, yahooID) VALUES ";

                foreach (KeyValuePair<string, string> pair in TeamsList)
                {
                    insertString += String.Format("('{0}', '{1}'), ", pair.Value.Replace("'", "\\'"), pair.Key);
                }
                insertString = insertString.Substring(0, insertString.Length - 2);
                MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder();
                MySqlCommand cmd = new MySqlCommand(insertString, Program.connection);
                numRowsAffected = cmd.ExecuteNonQuery();
            }
            return numRowsAffected;
        }
        #endregion
    }
}
